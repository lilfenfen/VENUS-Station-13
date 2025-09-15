/datum/quirk/vacuum_resistance
	name = "Vacuum Resistance"
	// VENUS EDIT START
	//ORIGINAL: desc = "Your body is specially adapted to withstand and operate in zero-pressure environments. You may still need a source of breathable air, however."
	desc = "Your body is specially adapted to withstand zero-pressure environments. However, you may still need a source of breathable air and insulation against the cold."
	// VENUS EDIT END
	value = 8
	gain_text = span_notice("Your physique attunes to the silence of space, now able to operate in zero pressure.")
	lose_text = span_notice("Your physiology reverts as your space faring gifts lay dormant once more.")
	medical_record_text = "Patient's body has fully adapted to zero-pressure environments."
	mob_trait = TRAIT_VACUUM_RESIST
	hardcore_value = -6
	icon = FA_ICON_ROCKET
	mail_goodies = list (
		/obj/item/storage/box/emergency_spacesuit = 1
	)

/datum/quirk/vacuum_resistance/add(client/client_source)
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Add quirk traits
	quirk_mob.add_traits(list(TRAIT_RESISTLOWPRESSURE), TRAIT_VACUUM_RESIST) //VENUS EDIT - Removed TRAIT_RESISTCOLD

/datum/quirk/vacuum_resistance/remove()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Remove quirk traits
	quirk_mob.remove_traits(list(TRAIT_RESISTLOWPRESSURE), TRAIT_VACUUM_RESIST) //VENUS EDIT - Removed TRAIT_RESISTCOLD
