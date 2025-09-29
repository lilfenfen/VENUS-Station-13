/mob/living/simple_animal/hostile/Voidling
    name = "Voidling"
    desc = "You struggle to comprehend the details of this creature, it keeps shifting and changing constantly."
    icon = 'modular_zzveilbreak/icons/mob/mobs.dmi'
    icon_state = "voidling"
    icon_living = "voidling"
    speak_chance = 0
    turns_per_move = 5
    speed = 1
    maxHealth = 75
    health = 75
    harm_intent_damage = 10
    melee_damage_lower = 5
    melee_damage_upper = 15
    attack_verb_continuous = "slashes"
    attack_verb_simple = "slash"
    attack_sound = 'modular_zzveilbreak\sound\weapons\voidling_attack.ogg'
    faction = list("hostile")
    environment_smash = ENVIRONMENT_SMASH_STRUCTURES
    stat_attack = HARD_CRIT
    robust_searching = TRUE
    dodging = TRUE
    dodge_prob = 50
    del_on_death = TRUE

    ai_controller = /datum/ai_controller/simple_hostile

    death(message)
        ..()
        visible_message(span_danger("[src] And the void reclaims."))
        var/loot = pick_loot_from_table(voidling_loot_table)
        if(loot)
            new loot(loc)

    /datum/ai_controller/simple_hostile/voidling
        // Custom logic here
