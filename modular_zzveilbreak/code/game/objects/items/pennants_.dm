/obj/item/clothing/neck/aether_pennant
	name = "Aether Pennant"
	desc = "A mysterious pennant. Protects the user from harm."
	icon = 'modular_zzveilbreak/icons/item_icons/pennants.dmi'
	icon_state = "aether_pennant"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_NECK

	var/active = FALSE  // For active ability
	var/on_cooldown = FALSE
	var/cooldown_time = 20 SECONDS

/obj/item/clothing/neck/aether_pennant/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK)
		RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))

/obj/item/clothing/neck/aether_pennant/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMAGE)

/obj/item/clothing/neck/aether_pennant/proc/on_damage(datum/source, damage, damagetype, def_zone, blocked, forced)
	SIGNAL_HANDLER
	if(prob(1) || active)  // 1% chance or active
		damage = 0  // Nullify damage
		if(active)
			active = FALSE
			to_chat(source, span_notice("The void fully blocks the damage!"))
		else
			to_chat(source, span_notice("The void passively blocks the damage!"))

/obj/item/clothing/neck/aether_pennant/attack_self(mob/user)
	if(on_cooldown)
		to_chat(user, span_warning("The pennant is on cooldown!"))
		return
	if(active)
		to_chat(user, span_warning("The pennant is already active!"))
		return
	active = TRUE
	on_cooldown = TRUE
	to_chat(user, span_notice("You activate the Aether Pennant, nullifying damage for the next 1.5 seconds."))
	addtimer(CALLBACK(src, PROC_REF(deactivate)), 1.5 SECONDS)  // Active for 1.5 seconds
	addtimer(CALLBACK(src, PROC_REF(end_cooldown)), cooldown_time)  // 20 second cooldown

/obj/item/clothing/neck/aether_pennant/proc/end_cooldown()
	on_cooldown = FALSE
	if(ismob(loc))
		to_chat(loc, span_notice("The Aether Pennant is ready to use again."))

/obj/item/clothing/neck/aether_pennant/proc/deactivate()
	if(active)
		active = FALSE
		if(ismob(loc))
			to_chat(loc, span_warning("The Aether Pennant's activation fades."))

/obj/item/clothing/neck/life_pennant
	name = "Life Pennant"
	desc = "A vibrant pennant that pulses with life energy. Heals the user."
	icon = 'modular_zzveilbreak/icons/item_icons/pennants.dmi'
	icon_state = "life_pennant"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_NECK

	var/on_cooldown = FALSE
	var/cooldown_time = 35 SECONDS

/obj/item/clothing/neck/life_pennant/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK)
		START_PROCESSING(SSobj, src)  // Start passive healing

/obj/item/clothing/neck/life_pennant/dropped(mob/user)
	. = ..()
	STOP_PROCESSING(SSobj, src)  // Stop passive healing

/obj/item/clothing/neck/life_pennant/process(seconds_per_tick)
	if(!ismob(loc))
		return
	var/mob/living/user = loc
	if(user.health < user.maxHealth)
		user.adjustBruteLoss(-1 * seconds_per_tick)  // Heal 1 per second, scaled by tick
		user.adjustFireLoss(-1 * seconds_per_tick)
		user.adjustToxLoss(-1 * seconds_per_tick)
		user.adjustOxyLoss(-1 * seconds_per_tick)

/obj/item/clothing/neck/life_pennant/attack_self(mob/user)
	if(on_cooldown)
		to_chat(user, span_warning("The pennant is on cooldown!"))
		return
	on_cooldown = TRUE
	var/healed_total = 0
	for(var/mob/living/target in range(3, user))
		if(healed_total >= 100)
			break
		var/heal_amount = min(20, 100 - healed_total)
		target.adjustBruteLoss(-heal_amount)
		target.adjustFireLoss(-heal_amount)
		target.adjustToxLoss(-heal_amount)
		target.adjustOxyLoss(-heal_amount)
		healed_total += heal_amount
	to_chat(user, span_notice("The Life Pennant heals nearby allies!."))
	addtimer(CALLBACK(src, PROC_REF(end_cooldown)), cooldown_time)

/obj/item/clothing/neck/life_pennant/proc/end_cooldown()
	on_cooldown = FALSE
	if(ismob(loc))
		to_chat(loc, span_notice("The Life Pennant is ready to use again."))







