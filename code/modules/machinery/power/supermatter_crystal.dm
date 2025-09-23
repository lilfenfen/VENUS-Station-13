// Supermatter Processing Code

// Constants for delirium gas handling
const
	DELIRIUM_CONSUMPTION_PP = 0.1 // Partial pressure threshold for delirium consumption
	DELIRIUM_PRESSURE_SCALING = 2 // Scaling factor for delirium pressure
	DELIRIUM_POWER_GAIN = 50 // Base power gain from delirium gas
	DELIRIUM_GASMIX_SCALING = 0.5 // Gas mix scaling factor
	DELIRIUM_WASTE_MODIFIER = 1.5 // Waste multiplier for delirium gas

// ...existing code...

// Delirium gas handling
var/delirium_pp = 0
if(environment)
	delirium_pp = environment.get_breath_partial_pressure(environment.gases[/datum/gas/delirium][MOLES])
if(delirium_pp > DELIRIUM_CONSUMPTION_PP)
	// Scale power gain with pressure and gasmix
	var/del_power = (delirium_pp / DELIRIUM_PRESSURE_SCALING) * DELIRIUM_POWER_GAIN * (1 + (environment.power_ratio * DELIRIUM_GASMIX_SCALING))
	power += del_power
	// Increase waste
	waste_multiplier *= DELIRIUM_WASTE_MODIFIER
	// Cause hallucinations in nearby humans
	if(delirium_pp > 0)
		var/list/near = world.find_mobs(get_turf(src), 7)
		for(var/mob in near)
			if(ishuman(mob) && mob.client)
				var/msg = pick(GLOB.delirium_hallucination_table)
				to_chat(mob, "<span class='hallucination'>[msg]</span>")

// ...existing code...
