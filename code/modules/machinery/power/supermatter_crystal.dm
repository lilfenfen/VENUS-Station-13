// Supermatter Processing Code

// Constants for delirium gas handling
const
	DELIRIUM_CONSUMPTION_PP = 0.1 // Partial pressure threshold for delirium consumption
	DELIRIUM_PRESSURE_SCALING = 2 // Scaling factor for delirium pressure
	DELIRIUM_POWER_GAIN = 50 // Base power gain from delirium gas
	DELIRIUM_GASMIX_SCALING = 0.5 // Gas mix scaling factor
	DELIRIUM_WASTE_MODIFIER = 1.5 // Waste multiplier for delirium gas

// Robust Delirium gas handling
var/delirium_pp = 0
if(environment && environment.gases && environment.gases[/datum/gas/delirium])
	var/del_moles = environment.gases[/datum/gas/delirium][MOLES]
	if(del_moles)
		if(environment.get_breath_partial_pressure)
			delirium_pp = environment.get_breath_partial_pressure(del_moles)
		else if(environment.total_moles)
			delirium_pp = (del_moles / max(1, environment.total_moles())) * ONE_ATMOSPHERE
if(delirium_pp > DELIRIUM_CONSUMPTION_PP)
	var/del_power = (delirium_pp / DELIRIUM_PRESSURE_SCALING) * DELIRIUM_POWER_GAIN * (1 + (environment.power_ratio * DELIRIUM_GASMIX_SCALING))
	power += del_power
	waste_multiplier *= DELIRIUM_WASTE_MODIFIER
	// Debug: display once when delirium processing occurs
	if(world.time % (10 SECONDS) == 0)
		visible_message("<span class='notice'>Delirium active on SM: pp=[delirium_pp], power=[del_power]</span>")
	// Trigger hallucinations for nearby humans using delirium hallucination list
	for(var/mob/M in view(7, src))
		if(ishuman(M) && M.client)
			var/msg = pick(GLOB.delirium_hallucination_table)
			to_chat(M, "<span class='hallucination'>[msg]</span>")
