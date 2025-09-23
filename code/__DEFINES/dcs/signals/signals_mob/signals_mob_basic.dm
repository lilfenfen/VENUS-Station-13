/// Sent from /mob/living/basic/proc/look_dead() : ()
#define COMSIG_BASICMOB_LOOK_DEAD "basicmob_look_dead"
/// Sent from /mob/living/basic/proc/look_alive() : ()
#define COMSIG_BASICMOB_LOOK_ALIVE "basicmob_look_alive"

///from the ranged_attacks component for basic mobs: (mob/living/basic/firer, atom/target, modifiers)
#define COMSIG_BASICMOB_PRE_ATTACK_RANGED "basicmob_pre_attack_ranged"
	#define COMPONENT_CANCEL_RANGED_ATTACK COMPONENT_CANCEL_ATTACK_CHAIN //! Cancel to prevent the attack from happening

///from the ranged_attacks component for basic mobs: (mob/living/basic/firer, atom/target, modifiers)
#define COMSIG_BASICMOB_POST_ATTACK_RANGED "basicmob_post_attack_ranged"

/// Called whenever an animal is pet via the /datum/element/pet_bonus element: (mob/living/petter, modifiers)
#define COMSIG_ANIMAL_PET "animal_pet"

///from base of mob/living/basic/regal_rat: (mob/living/basic/regal_rat/king)
#define COMSIG_RAT_INTERACT "rat_interaction"
	#define COMPONENT_RAT_INTERACTED (1<<0) //! If this is returned, cancel any further interactions.

///from /datum/status_effect/slime_leech: (mob/living/basic/slime/draining_slime)
#define COMSIG_SLIME_DRAINED "slime_drained"

/// from /mob/living/basic/mutate(): (mob/living/basic/mutated_mob)
#define COMSIG_BASICMOB_MUTATED "basicmob_mutated"
	///cancel further mutation modifications to the mob such as shiny mutation.
	#define MUTATED_NO_FURTHER_MUTATIONS (1 << 0)
