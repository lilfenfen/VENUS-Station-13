/datum/status_effect/delirious
	id = "delirious"
	tick_interval = 2 SECONDS
	alert_type = null
	remove_on_fullheal = TRUE
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	var_lower_tick_interval = 10 SECONDS
	var_upper_tick_interval = 40 SECONDS

	COOLDOWN_DECLARE(delirious_cooldown)

GLOBAL_LIST(delirious_table, list(
	"You feel delirious. Reality bends and whispers surround you.",
	"Your vision blurs and shifts, making it hard to focus.",
	"You hear faint, unsettling whispers that seem to come from nowhere.",
	"The world around you seems to warp and twist in impossible ways.",
	"You feel a creeping sense of paranoia, as if something is watching you.",
	"Colors seem unnaturally vibrant, almost overwhelming your senses.",
	"You struggle to keep your thoughts straight as reality feels fluid.",
	"Shadows in the corners of your vision seem to move on their own.",
	"You feel disconnected from your own body, as if you're floating outside yourself.",
	"Time seems to stretch and compress unpredictably.",
	"You feel a strange compulsion to laugh or cry without reason.",
	"The ceiling bends lower as if it wants to hear your thoughts.",
	"A whisper circles your ears, syllables backwards, like language unraveling.",
	"The silence hums, deep and patient, like it’s choosing its moment to answer.",
	"Your skin prickles in places you can’t reach, moving like insects beneath it.",
	"The world stutters, skipping like a broken reel of film; you’re unsure what frame you belong in.",
	"One person's beginning is another's end. I wonder what your end will begin...",
	"New paths lead to new nightmares.",
	"Are you being led into a trap?",
	"Can you feel it? Despair, thick as cloth.",
	"Great works require a touch of insanity. Seems like you're on the right track.",
	"You seek to end the madness, yet you are its herald.",
	"Order is ephemeral. Chaos is the natural state of things. Void, the final state.",
	"You walk through the corridors of madness and into the mouth of death itself. I do believe you have finally lost your mind.”,
	"These whispers are not just your imagination. They are real, sometimes even true. You'll never know when they are.",
	"The company does not care for your soul. All they want is whats MINE.",
	"Do not trust the voices. They will lead you astray."
))

/datum/status_effect/delirious/on_creation(mob/living/new_owner, new_duration)
	if(isnum(new_duration))
		src.duration = new_duration
	return ..()

/datum/status_effect/hallucination/on_apply()
	var/msg = pick(GLOB.delirious_table)
	to_chat(owner, "<span class='hallucination'>[msg]</span>")
