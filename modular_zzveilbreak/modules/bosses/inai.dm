
/mob/living/simple_animal/hostile/megafauna/inai
	name = "Inai"
	desc = "Spirit of the Void, enduring the mortal indignities of the coil."
	icon = 'modular_zzveilbreak/icons/bosses/inai.dmi'
	icon_state = "inai"
	maxHealth = 3000
	health = 3000
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	friendly_verb_continuous = "observes"
	friendly_verb_simple = "observe"
	melee_damage_lower = 15
	melee_damage_upper = 25
	attack_sound = 'modular_zzveilbreak/sound/weapons/inai_attack.ogg'
	speak_emote = list("says", "declares", "utters")
	speak_chance = 50
	faction = list("hostile")
	speed = 1.2
	del_on_death = TRUE
	environment_smash = 2
	armour_penetration = 20
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	dodging = TRUE
	dodge_prob = 40
	move_to_delay = 3
	loot = list(/obj/item/voidshard)  // Fixed drop for now; can use table later
	var/datum/action/cooldown/mob_cooldown/astral_step/astral_step
	var/datum/action/cooldown/mob_cooldown/resonant_pulse/resonant_pulse
	// List of death messages
	var/list/death_messages = list(
		"This will open a dark path.",
		"The void beckons.",
		"Reality unravels.",
		"Your victory is impermanent."
	)

	// List of astral step messages
	var/list/astral_messages = list(
		"There's nowhere to run.",
		"I took a shortcut.",
		"Behind you.",
		"You're already too late.",
		"I'm everywhere and nowhere.",
		"A merry chase you lead."
		// Add more here
	)

	// List of resonant pulse messages
	var/list/pulse_messages = list(
		"A field of nothing.",
		"Harm unseen.",
		"Null efforts.",
		"It isnt shadow that bathes me.",
		"Void Resonance."
		// Add more here
	)

	// Abilities
	var/astral_step_cooldown = 20 SECONDS
	var/resonant_pulse_cooldown = 15 SECONDS

	Initialize()
		. = ..()
		astral_step = new(src)
		resonant_pulse = new(src)
		astral_step.Grant(src)
		resonant_pulse.Grant(src)

	Destroy()
		QDEL_NULL(astral_step)
		QDEL_NULL(resonant_pulse)
		return ..()

	death(message)
		// Spawn loot before deletion
		var/loot = pick_loot_from_table(inai_drops)
		if(loot)
			new loot(loc)
		var/msg = pick(death_messages)
		visible_message("<span style='color:#8a2be2; font-style:italic;'>[msg]</span>")
		..()

// Astral Step ability
/datum/action/cooldown/mob_cooldown/astral_step
	name = "Astral Step"
	desc = "Teleport behind a target within 11 tiles and strike with extra damage."
	cooldown_time = 20 SECONDS
	button_icon = 'modular_zzveilbreak/icons/bosses/inai.dmi'
	button_icon_state = "astral_step"

/datum/action/cooldown/mob_cooldown/astral_step/Activate(atom/target)
	var/mob/living/simple_animal/hostile/megafauna/inai/inai = owner
	if(!isliving(target) || get_dist(inai, target) > 11)
		return
	// Teleport behind target
	var/turf/target_turf = get_turf(target)
	var/dir_to_inai = get_dir(target, inai)
	var/turf/behind_turf = get_step(target_turf, dir_to_inai)
	if(behind_turf && !behind_turf.density)
		inai.forceMove(behind_turf)
	// Attack with extra damage
	var/mob/living/victim = target
	var/extra_damage = 10
	var/damage_type = pick(BRUTE, BURN, TOX, OXY)  // Random damage type
	victim.apply_damage(extra_damage, damage_type)
	var/msg = pick(inai.astral_messages)
	inai.visible_message("<span style='color:#8a2be2; font-style:italic;'>[msg]</span>")
	StartCooldown()

// Resonant Pulse ability
/datum/action/cooldown/mob_cooldown/resonant_pulse
	name = "Resonant Pulse"
	desc = "Emit a pulse that damages all in a 6-tile radius."
	cooldown_time = 15 SECONDS
	button_icon = 'modular_zzveilbreak/icons/bosses/inai.dmi'
	button_icon_state = "resonant_pulse"

/datum/action/cooldown/mob_cooldown/resonant_pulse/Activate(atom/target)
	var/mob/living/simple_animal/hostile/megafauna/inai/inai = owner
	for(var/mob/living/victim in range(6, inai))
		var/damage = 15
		var/damage_type = pick(BRUTE, BURN, TOX, OXY)
		victim.apply_damage(damage, damage_type)
	var/msg = pick(inai.pulse_messages)
	inai.visible_message("<span style='color:#8a2be2; font-style:italic;'>[msg]</span>")
	StartCooldown()

