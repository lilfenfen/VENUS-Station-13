// code/modules/admin/IsBanned.dm
// Refactored IsBanned + whitelist handling + post-connect client.New() enforcement
// Preserves stickyban logic and includes restore_stickybans proc used by that subsystem.

#define STICKYBAN_MAX_MATCHES 15
#define STICKYBAN_MAX_EXISTING_USER_MATCHES 3
#define STICKYBAN_MAX_ADMIN_MATCHES 1

/******************************************************************************
 * Whitelist DB helper - uses datum/db_query typing so the compiler knows types
 ******************************************************************************/
proc/check_database_whitelist(ckey)
	// Basic guard
	if(!ckey)
		return FALSE

	// Cache lookup (GLOB.whitelist_cache should be declared in globals.dm)
	if(GLOB.whitelist_cache && (ckey in GLOB.whitelist_cache))
		return GLOB.whitelist_cache[ckey]

	// If SQL isn't enabled, we can't check; deny and cache negative to avoid loops.
	if(!CONFIG_GET(flag/sql_enabled))
		log_world("Whitelist check attempted but SQL disabled for [ckey]")
		GLOB.whitelist_cache[ckey] = FALSE
		return FALSE

	// Ensure DB subsystem is connected
	if(!SSdbcore.Connect())
		log_world("Whitelist DB connect failed for [ckey]")
		// cache negative to avoid repeated heavy hits; admins will be notified elsewhere
		GLOB.whitelist_cache[ckey] = FALSE
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT 1 FROM whitelist WHERE ckey = :ckey LIMIT 1",
		list("ckey" = ckey)
	)

	// Execute synchronously — we need the result now
	if(!query.Execute(async = FALSE))
		log_world("Whitelist query failed for [ckey]: [query.ErrorMsg()]")
		qdel(query)
		GLOB.whitelist_cache[ckey] = FALSE
		return FALSE

	var/allowed = query.NextRow()
	qdel(query)

	GLOB.whitelist_cache[ckey] = !!allowed
	return !!allowed

/******************************************************************************
 * world/IsBanned - main entry the server uses during connect attempts
 * NOTE: keep signature exactly as BYOND expects (include real_bans_only)
 ******************************************************************************/
world/IsBanned(key, address, computer_id, type, real_bans_only=FALSE)
	debug_world_log("isbanned(): '[args.Join("', '")]'")

	// Validate basic args
	if (!key || (!real_bans_only && (!address || !computer_id)))
		if(real_bans_only)
			return FALSE
		log_access("Failed Login (invalid data): [key] [address]-[computer_id]")
		return list("reason"="invalid login data", "desc"="Error: Could not check ban status, Please try again. Error message: Your computer provided invalid or blank information to the server on connection (byond username, IP, and Computer ID.) Provided information for reference: Username:'[key]' IP:'[address]' Computer ID:'[computer_id]'. (If you continue to get this error, please restart byond or contact byond support.)")

	// Let byond handle world topic checks
	if (type == "world")
		return ..()

	var/ckey = ckey(key)
	var/admin = FALSE

	// If client already exists and matches connect info, skip repeated checks
	var/client/C = GLOB.directory[ckey]
	if (C && ckey == C.ckey && computer_id == C.computer_id && address == C.address)
		return

	// Prevent spamming admins repeatedly about the same user connecting
	var/static/list/checkedckeys = list()
	var/message = !checkedckeys[ckey]++

	// admin detection
	if(GLOB.admin_datums[ckey] || GLOB.deadmins[ckey])
		admin = TRUE

	/* Panic bunker code intentionally omitted as in original (preserved commented block) */

	// ---- WHITELIST FALLBACK ----
	// Don't aggressively reject here for non-whitelisted users so client.New() can present friendly chat messages.
	// But if whitelist is enabled AND DB is clearly down, return a short denial so connection fails fast.
	if(!real_bans_only && !C && CONFIG_GET(flag/usewhitelist))
		if(CONFIG_GET(flag/sql_enabled) && !SSdbcore.Connect())
			var/shortmsg = "Server is currently unable to verify whitelist status (database connection failure). Please try again shortly."
			log_world("Whitelist DB connection failure while handling IsBanned() for [ckey]")
			if (message)
				message_admins("Whitelist DB connection failure while handling IsBanned() for [ckey]")
			return list("reason"="whitelist", "desc" = shortmsg)
		// otherwise do not reject here; client.New() will perform user-visible enforcement

	// Guest checks (preserve original behavior)
	if(!real_bans_only && !C && is_guest_key(key))
		if (CONFIG_GET(flag/guest_ban))
			log_access("Failed Login: [ckey] - Guests not allowed")
			return list("reason"="guest", "desc"="\nReason: Guests not allowed. Please sign in with a byond account.")
		if (CONFIG_GET(flag/panic_bunker) && SSdbcore.Connect())
			log_access("Failed Login: [ckey] - Guests not allowed during panic bunker")
			return list("reason"="guest", "desc"="\nReason: Sorry but the server is currently not accepting connections from never before seen players or guests. If you have played on this server with a byond account before, please log in to the byond account you have played from.")

	// Population cap checks
	var/extreme_popcap = CONFIG_GET(number/extreme_popcap)
	if(!real_bans_only && !C && extreme_popcap && !admin)
		var/popcap_value = GLOB.clients.len
		if(popcap_value >= extreme_popcap && !GLOB.joined_player_list.Find(ckey))
			if(!CONFIG_GET(flag/byond_member_bypass_popcap) || !world.IsSubscribed(ckey, "BYOND"))
				log_access("Failed Login: [ckey] - Population cap reached")
				return list("reason"="popcap", "desc"= "\nReason: [CONFIG_GET(string/extreme_popcap_message)]")

	// SQL-based ban checks (preserve original logic)
	if(CONFIG_GET(flag/sql_enabled))
		if(!SSdbcore.Connect())
			var/msg = "Ban database connection failure. Key [ckey] not checked"
			log_world(msg)
			if (message)
				message_admins(msg)
		else
			var/list/ban_details = is_banned_from_with_details(ckey, address, computer_id, "Server")
			for(var/i in ban_details)
				if(admin)
					if(text2num(i["applies_to_admins"]))
						var/msg = "Admin [ckey] is admin banned, and has been disallowed access."
						log_admin(msg)
						if (message)
							message_admins(msg)
					else
						var/msg = "Admin [ckey] has been allowed to bypass a matching non-admin ban on [ckey(i["key"])] [i["ip"]]-[i["computerid"]]."
						log_admin(msg)
						if (message)
							message_admins(msg)
							addclientmessage(ckey,span_adminnotice("Admin [ckey] has been allowed to bypass a matching non-admin ban on [i["key"]] [i["ip"]]-[i["computerid"]]."))
						continue
				var/expires = "This is a permanent ban."
				var/global_ban = "This is a global ban from all of our servers."
				if(i["expiration_time"])
					expires = " The ban is for [DisplayTimeText(text2num(i["duration"]) MINUTES)] and expires on [i["expiration_time"]] (server time)."
				if(!text2num(i["global_ban"]))
					global_ban = "This is a  single-server ban, and only applies to [i["server_name"]]."
				var/desc = {"You, or another user of this computer or connection ([i["key"]]) is banned from playing here.
				The ban reason is: [i["reason"]]
				This ban (BanID #[i["id"]]) was applied by [i["admin_key"]] on [i["bantime"]] during round ID [i["round_id"]].
				[global_ban]
				[expires]"}
				log_suspicious_login("Failed Login: [ckey] [computer_id] [address] - Banned (#[i["id"]]) [text2num(i["global_ban"]) ? "globally" : "locally"]")
				return list("reason"="Banned","desc"="[desc]")

	// Admin stickyban exemption handling (preserve original)
	if (admin)
		if (GLOB.directory[ckey])
			return

		if (!length(GLOB.stickybanadminexemptions))
			for (var/banned_ckey in world.GetConfig("ban"))
				GLOB.stickybanadmintexts[banned_ckey] = world.GetConfig("ban", banned_ckey)
				world.SetConfig("ban", banned_ckey, null)
		if (!SSstickyban.initialized)
			return
		GLOB.stickybanadminexemptions[ckey] = world.time
		stoplag() // sleep a byond tick
		GLOB.stickbanadminexemptiontimerid = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(restore_stickybans)), 5 SECONDS, TIMER_STOPPABLE|TIMER_UNIQUE|TIMER_OVERRIDE)
		return

	// Default pager ban flow (preserved)
	var/list/ban = ..()

	if (ban)
		if (!admin)
			. = ban
		if (real_bans_only)
			return
		var/bannedckey = "ERROR"
		if (ban["ckey"])
			bannedckey = ban["ckey"]

		var/newmatch = FALSE
		var/list/cachedban = SSstickyban.cache[bannedckey]
		//rogue ban in the process of being reverted.
		if (cachedban && (cachedban["reverting"] || cachedban["timeout"]))
			world.SetConfig("ban", bannedckey, null)
			return null

		if (cachedban && ckey != bannedckey)
			newmatch = TRUE
			if (cachedban["keys"])
				if (cachedban["keys"][ckey])
					newmatch = FALSE
			if (cachedban["matches_this_round"][ckey])
				newmatch = FALSE

		if (newmatch && cachedban)
			var/list/newmatches = cachedban["matches_this_round"]
			var/list/pendingmatches = cachedban["matches_this_round"]
			var/list/newmatches_connected = cachedban["existing_user_matches_this_round"]
			var/list/newmatches_admin = cachedban["admin_matches_this_round"]

			if (C)
				newmatches_connected[ckey] = ckey
				newmatches_connected = cachedban["existing_user_matches_this_round"]
				pendingmatches[ckey] = ckey
				sleep(STICKYBAN_ROGUE_CHECK_TIME)
				pendingmatches -= ckey
			if (admin)
				newmatches_admin[ckey] = ckey

			if (cachedban["reverting"] || cachedban["timeout"])
				return null

			newmatches[ckey] = ckey

			if (\
				newmatches.len+pendingmatches.len > STICKYBAN_MAX_MATCHES || \
				newmatches_connected.len > STICKYBAN_MAX_EXISTING_USER_MATCHES || \
				newmatches_admin.len > STICKYBAN_MAX_ADMIN_MATCHES \
			)

				var/action
				if (ban["fromdb"])
					cachedban["timeout"] = TRUE
					action = "putting it on timeout for the remainder of the round"
				else
					cachedban["reverting"] = TRUE
					action = "reverting to its roundstart state"

				world.SetConfig("ban", bannedckey, null)
				log_game("Stickyban on [bannedckey] detected as rogue, [action]")
				message_admins("Stickyban on [bannedckey] detected as rogue, [action]")
				spawn (5)
					world.SetConfig("ban", bannedckey, null)
					sleep(1 TICKS)
					world.SetConfig("ban", bannedckey, null)
					if (!ban["fromdb"])
						cachedban = cachedban.Copy()
						cachedban["matches_this_round"] = list()
						cachedban["existing_user_matches_this_round"] = list()
						cachedban["admin_matches_this_round"] = list()
						cachedban -= "reverting"
						SSstickyban.cache[bannedckey] = cachedban
						world.SetConfig("ban", bannedckey, list2stickyban(cachedban))
				return null

		if (ban["fromdb"])
			if(SSdbcore.Connect())
				INVOKE_ASYNC(SSdbcore, TYPE_PROC_REF(/datum/controller/subsystem/dbcore, QuerySelect), list(
					SSdbcore.NewQuery(
						"INSERT INTO [format_table_name("stickyban_matched_ckey")] (matched_ckey, stickyban) VALUES (:ckey, :bannedckey) ON DUPLICATE KEY UPDATE last_matched = now()",
						list("ckey" = ckey, "bannedckey" = bannedckey)
					),
					SSdbcore.NewQuery(
						"INSERT INTO [format_table_name("stickyban_matched_ip")] (matched_ip, stickyban) VALUES (INET_ATON(:address), :bannedckey) ON DUPLICATE KEY UPDATE last_matched = now()",
						list("address" = address, "bannedckey" = bannedckey)
					),
					SSdbcore.NewQuery(
						"INSERT INTO [format_table_name("stickyban_matched_cid")] (matched_cid, stickyban) VALUES (:computer_id, :bannedckey) ON DUPLICATE KEY UPDATE last_matched = now()",
						list("computer_id" = computer_id, "bannedckey" = bannedckey)
					)
				), FALSE, TRUE)


		// Admin bypass for host/sticky bans (preserved)
		if (admin)
			log_admin("The admin [ckey] has been allowed to bypass a matching host/sticky ban on [bannedckey]")
			if (message)
				message_admins(span_adminnotice("The admin [ckey] has been allowed to bypass a matching host/sticky ban on [bannedckey]"))
				addclientmessage(ckey,span_adminnotice("You have been allowed to bypass a matching host/sticky ban on [bannedckey]"))
			return null

		if (C) //user is already connected!.
			to_chat(C, span_redtext("You are about to get disconnected for matching a sticky ban after you connected. If this turns out to be the ban evasion detection system going haywire, we will automatically detect this and revert the matches. if you feel that this is the case, please wait EXACTLY 6 seconds then reconnect using file -> reconnect to see if the match was automatically reversed."), confidential = TRUE)

		var/desc = "\nReason:(StickyBan) You, or another user of this computer or connection ([bannedckey]) is banned from playing here. The ban reason is:\n[ban["message"]]\nThis ban was applied by [ban["admin"]]\nThis is a BanEvasion Detection System ban, if you think this ban is a mistake, please wait EXACTLY 6 seconds, then try again before filing an appeal.\n"
		. = list("reason" = "Stickyban", "desc" = desc)
		log_suspicious_login("Failed Login: [ckey] [computer_id] [address] - StickyBanned [ban["message"]] Target Username: [bannedckey] Placed by [ban["admin"]]")

	return .

/proc/restore_stickybans()
	// Restore saved stickyban texts (used when temporarily removing stickybans for admin bypass)
	for (var/banned_ckey in GLOB.stickybanadmintexts)
		world.SetConfig("ban", banned_ckey, GLOB.stickybanadmintexts[banned_ckey])
	GLOB.stickybanadminexemptions = list()
	GLOB.stickybanadmintexts = list()
	if (GLOB.stickbanadminexemptiontimerid)
		deltimer(GLOB.stickbanadminexemptiontimerid)
	GLOB.stickbanadminexemptiontimerid = null

#undef STICKYBAN_MAX_MATCHES
#undef STICKYBAN_MAX_EXISTING_USER_MATCHES
#undef STICKYBAN_MAX_ADMIN_MATCHES
