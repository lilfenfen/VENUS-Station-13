// Database-based whitelist system for MariaDB (Simplified)

/proc/check_whitelist(ckey)
	if(!SSdbcore.Connect())
		// If database is unavailable, we can't verify whitelist status
		log_world("Database connection failed during whitelist check for [ckey]")
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT 1 FROM whitelist WHERE ckey = :ckey LIMIT 1",
		list("ckey" = ckey)
	)

	if(!query.Execute(async = FALSE))
		log_world("Whitelist query failed for [ckey]: [query.ErrorMsg()]")
		qdel(query)
		return FALSE

	var/is_whitelisted = query.NextRow()
	qdel(query)

	return is_whitelisted

ADMIN_VERB(whitelist_player, R_BAN, "Whitelist CKey", "Adds a ckey to the Whitelist database.", ADMIN_CATEGORY_MAIN)
	var/input_ckey = input("CKey to whitelist: (Adds CKey to the whitelist database)") as null|text
	// The ckey proc "sanitizes" it to be its "true" form
	var/canon_ckey = ckey(input_ckey)
	if(!input_ckey || !canon_ckey)
		return

	// Check if they're already whitelisted
	if(check_whitelist(canon_ckey))
		to_chat(user, span_warning("[canon_ckey] is already whitelisted."), confidential = TRUE)
		return

	// Add to database
	if(!SSdbcore.Connect())
		to_chat(user, span_warning("Failed to connect to database."), confidential = TRUE)
		return

	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO whitelist (ckey) VALUES (:ckey)",
		list("ckey" = canon_ckey)
	)

	if(!query.Execute())
		to_chat(user, span_warning("Failed to whitelist [canon_ckey]: [query.ErrorMsg()]"), confidential = TRUE)
		qdel(query)
		return

	qdel(query)

	message_admins("[input_ckey] has been whitelisted by [key_name(user)]")
	log_admin("[input_ckey] has been whitelisted by [key_name(user)]")

ADMIN_VERB_CUSTOM_EXIST_CHECK(whitelist_player)
	return CONFIG_GET(flag/usewhitelist)

ADMIN_VERB(remove_whitelist, R_BAN, "Remove Whitelist", "Removes a ckey from the Whitelist database.", ADMIN_CATEGORY_MAIN)
	var/input_ckey = input("CKey to remove from whitelist:") as null|text
	var/canon_ckey = ckey(input_ckey)
	if(!input_ckey || !canon_ckey)
		return

	// Check if they're actually whitelisted
	if(!check_whitelist(canon_ckey))
		to_chat(user, span_warning("[canon_ckey] is not whitelisted."), confidential = TRUE)
		return

	// Remove from database
	if(!SSdbcore.Connect())
		to_chat(user, span_warning("Failed to connect to database."), confidential = TRUE)
		return

	var/datum/db_query/query = SSdbcore.NewQuery(
		"DELETE FROM whitelist WHERE ckey = :ckey",
		list("ckey" = canon_ckey)
	)

	if(!query.Execute())
		to_chat(user, span_warning("Failed to remove [canon_ckey] from whitelist: [query.ErrorMsg()]"), confidential = TRUE)
		qdel(query)
		return

	qdel(query)

	message_admins("[input_ckey] has been removed from the whitelist by [key_name(user)]")
	log_admin("[input_ckey] has been removed from the whitelist by [key_name(user)]")

ADMIN_VERB_CUSTOM_EXIST_CHECK(remove_whitelist)
	return CONFIG_GET(flag/usewhitelist)

ADMIN_VERB(view_whitelist, R_BAN, "View Whitelist", "Shows all whitelisted players.", ADMIN_CATEGORY_MAIN)
	if(!SSdbcore.Connect())
		to_chat(user, span_warning("Failed to connect to database."), confidential = TRUE)
		return

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT ckey, created_at FROM whitelist ORDER BY created_at DESC"
	)

	if(!query.Execute())
		to_chat(user, span_warning("Failed to retrieve whitelist: [query.ErrorMsg()]"), confidential = TRUE)
		qdel(query)
		return

	var/output = "<h2>Whitelisted Players</h2><table border='1'><tr><th>CKey</th><th>Added On</th></tr>"

	while(query.NextRow())
		var/ckey = query.item[1]
		var/added_date = query.item[2]
		output += "<tr><td>[ckey]</td><td>[added_date]</td></tr>"

	output += "</table>"

	qdel(query)

	// Show the output in a window
	user << browse(output, "window=whitelist;size=600x400")

ADMIN_VERB_CUSTOM_EXIST_CHECK(view_whitelist)
	return CONFIG_GET(flag/usewhitelist)
