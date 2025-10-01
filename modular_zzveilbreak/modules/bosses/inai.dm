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

	)

	// List of resonant pulse messages
	var/list/pulse_messages = list(
		"A field of nothing.",
		"Harm unseen.",
		"Null efforts.",
		"It isnt shadow that bathes me.",
		"Void Resonance."
	)

	var/datum/action/cooldown/mob_cooldown/astral_step/astral_step
	var/datum/action/cooldown/mob_cooldown/resonant_wave/resonant_wave
	// Abilities
	var/astral_step_cooldown = 20 SECONDS
	var/resonant_wave_cooldown = 35 SECONDS

	Initialize()
		. = ..()
		astral_step = new(src)
		resonant_wave = new(src)
		astral_step.Grant(src)
		resonant_wave.Grant(src)

	Destroy()
		QDEL_NULL(astral_step)
		QDEL_NULL(resonant_wave)
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

// Resonant Wave ability
/datum/action/cooldown/mob_cooldown/resonant_wave
	name = "Resonant Wave"
	desc = "Channel a wave that releases random waves, damaging along paths."
	cooldown_time = 35 SECONDS
	button_icon = 'modular_zzveilbreak/icons/bosses/inai.dmi'
	button_icon_state = "resonant_wave"

/datum/action/cooldown/mob_cooldown/resonant_wave/Activate(atom/target)
	var/mob/living/simple_animal/hostile/megafauna/inai/inai = owner
	if(inai.stat)
		return
	// Start channeling: stand still and don't attack for up to 6 seconds
	inai.visible_message(span_danger("[inai] begins to channel a resonant wave..."))
	// Add animation: flick an icon state for channeling
	flick("inai_channeling", inai)
	if(!do_after(inai, 6 SECONDS, target = inai, progress = TRUE))
		inai.visible_message(span_warning("[inai]'s channeling is interrupted!"))
		return
	// After channeling, fire random waves
	inai.visible_message(span_danger("[inai] releases a resonant wave!"))
	var/msg = pick(inai.pulse_messages)
	inai.visible_message("<span style='color:#8a2be2; font-style:italic;'>[msg]</span>")
	// Fire random waves in 3-5 random directions
	var/num_waves = rand(3, 5)
	var/list/directions = shuffle(GLOB.alldirs)  // Shuffle for randomness
	for(var/i in 1 to num_waves)
		var/dir = directions[i]
		var/turf/start_turf = get_turf(inai)
		for(var/j in 1 to 15)
			var/turf/current_turf = get_step(start_turf, dir)
			if(!current_turf || current_turf.density)
				break
			// Add visual effect: spawn a temporary effect or particle
			new /obj/effect/temp_visual/resonant_wave(current_turf)
			for(var/mob/living/victim in current_turf)
				var/damage = 15
				var/damage_type = pick(BRUTE, BURN, TOX, OXY)
				victim.apply_damage(damage, damage_type)
			start_turf = current_turf
	StartCooldown()

// Temporary visual effect for the wave
/obj/effect/temp_visual/resonant_wave
	icon = 'modular_zzveilbreak/icons/bosses/inai.dmi'  // Add this icon
	icon_state = "resonant_wave"
	duration = 1 SECONDS
