SUBSYSTEM_DEF(machines)
	name = "Machines"
	dependencies = list(
		/datum/controller/subsystem/atoms,
	)
	flags = SS_KEEP_TIMING
	wait = 2 SECONDS

	/// Assosciative list of all machines that exist.
	VAR_PRIVATE/list/machines_by_type = list()

	/// All machines, not just those that are processing.
	VAR_PRIVATE/list/all_machines = list()

	var/list/processing = list()
	var/list/processing_early = list()
	var/list/processing_late = list()
	var/list/processing_apcs = list()

	var/list/currentrun = list()
	var/current_part = SSMACHINES_MACHINES_EARLY
	var/list/apc_steps = list(
		SSMACHINES_APCS_EARLY,
		SSMACHINES_APCS_ENVIRONMENT,
		SSMACHINES_APCS_LIGHTS,
		SSMACHINES_APCS_EQUIPMENT,
		SSMACHINES_APCS_LATE
		)
	///List of all powernets on the server.
	var/list/datum/powernet/powernets = list()

/datum/controller/subsystem/machines/Initialize()
	makepowernets()
	fire()
	return SS_INIT_SUCCESS

/// Registers a machine with the machine subsystem; should only be called by the machine itself during its creation.
/datum/controller/subsystem/machines/proc/register_machine(obj/machinery/machine)
	LAZYADD(machines_by_type[machine.type], machine)
	all_machines |= machine

/// Removes a machine from the machine subsystem; should only be called by the machine itself inside Destroy.
/datum/controller/subsystem/machines/proc/unregister_machine(obj/machinery/machine)
	var/list/existing = machines_by_type[machine.type]
	existing -= machine
	if(!length(existing))
		machines_by_type -= machine.type
	all_machines -= machine

/// Gets a list of all machines that are either the passed type or a subtype.
/datum/controller/subsystem/machines/proc/get_machines_by_type_and_subtypes(obj/machinery/machine_type)
	if(!ispath(machine_type))
		machine_type = machine_type.type
	if(!ispath(machine_type, /obj/machinery))
		CRASH("called get_machines_by_type_and_subtypes with a non-machine type [machine_type]")
	var/list/machines = list()
	for(var/next_type in typesof(machine_type))
		var/list/found_machines = machines_by_type[next_type]
		if(found_machines)
			machines += found_machines
	return machines


/// Gets a list of all machines that are the exact passed type.
/datum/controller/subsystem/machines/proc/get_machines_by_type(obj/machinery/machine_type)
	if(!ispath(machine_type))
		machine_type = machine_type.type
	if(!ispath(machine_type, /obj/machinery))
		CRASH("called get_machines_by_type with a non-machine type [machine_type]")

	var/list/machines = machines_by_type[machine_type]
	return machines?.Copy() || list()

/datum/controller/subsystem/machines/proc/get_all_machines()
	return all_machines.Copy()

/datum/controller/subsystem/machines/proc/makepowernets()
	for(var/datum/powernet/power_network as anything in powernets)
		qdel(power_network)
	powernets.Cut()

	for(var/obj/structure/cable/power_cable as anything in GLOB.cable_list)
		if(!power_cable.powernet)
			var/datum/powernet/new_powernet = new()
			new_powernet.add_cable(power_cable)
			propagate_network(power_cable, power_cable.powernet)

/datum/controller/subsystem/machines/stat_entry(msg)
	msg = "\n  M:[length(all_machines)]|MT:[length(machines_by_type)]|PM:[length(processing)]|PN:[length(powernets)]"
	return ..()

/datum/controller/subsystem/machines/fire(resumed = FALSE)
	// Precompute
	var/f = wait // local alias
	var/tick_scale = f * 0.1

	// Reset powernets only when not resumed (we still want power reset each full fire cycle)
	if (!resumed)
		for (var/datum/powernet/pn in powernets)
			pn.reset()
		current_part = SSMACHINES_MACHINES_EARLY
		// We will iterate the lists directly without creating heavy copies.
		// We use a local reference and an index-based pop-from-end loop for speed.
		// Expectation: processing_early contains objects and is mutated when items die.
		// No .Copy() allocation here.
		// NOTE: when stopping processing we remove from the list via swapping/pop trick in helper.
		src.currentrun = processing_early // keep for Recover compatibility; not copying

	// -------------------------
	// EARLY PROCESSING
	// -------------------------
	if (current_part == SSMACHINES_MACHINES_EARLY)
		while(processing_early.len)
			var/obj/machinery/thing = processing_early[processing_early.len]
			processing_early.len--
			if(!thing) // null guard
				continue
			// fast-path QDELETED only when necessary: check early return value
			var/result = thing.process_early(tick_scale)
			if(result == PROCESS_KILL || QDELETED(thing))
				// centralized cleanup
				_remove_machine_from_processing(thing)
			// tick-safety
			if (MC_TICK_CHECK)
				// preserve current location so we continue later from same stage
				return
		current_part = apc_steps[1]
		src.currentrun = processing_apcs

	// -------------------------
	// APC Processing (multi-stage)
	// -------------------------
	// Use an integer index to walk apc_steps rather than Find() each loop.
	var/apc_index = 1
	while(apc_index <= apc_steps.len)
		var/step = apc_steps[apc_index]
		// process current APC list
		while(processing_apcs.len)
			var/obj/machinery/power/apc/apc = processing_apcs[processing_apcs.len]
			processing_apcs.len--
			if(!apc)
				continue
			if(QDELETED(apc))
				_remove_apc_from_processing(apc)
				continue
			// Per-step behaviour
			if(step == SSMACHINES_APCS_EARLY)
				apc.early_process(tick_scale)
			else if(step == SSMACHINES_APCS_LATE)
				apc.charge_channel(null, tick_scale)
				apc.late_process(tick_scale)
			else
				apc.charge_channel(step, tick_scale)
			// tick-safety
			if (MC_TICK_CHECK)
				return
		// move to next apc step
		apc_index++
		if (apc_index > apc_steps.len)
			current_part = SSMACHINES_MACHINES
			break
		// ensure currentrun points to the APC processing list before next iteration
		src.currentrun = processing_apcs

	// -------------------------
	// MAIN MACHINE PROCESSING
	// -------------------------
	if (current_part == SSMACHINES_MACHINES)
		while(processing.len)
			var/obj/machinery/thing = processing[processing.len]
			processing.len--
			if(!thing)
				continue
			var/result = thing.process(tick_scale)
			if(result == PROCESS_KILL || QDELETED(thing))
				_remove_machine_from_processing(thing)
			if (MC_TICK_CHECK)
				return
		current_part = SSMACHINES_MACHINES_LATE
		src.currentrun = processing_late

	// -------------------------
	// LATE MACHINE PROCESSING
	// -------------------------
	if (current_part == SSMACHINES_MACHINES_LATE)
		while(processing_late.len)
			var/obj/machinery/thing = processing_late[processing_late.len]
			processing_late.len--
			if(!thing)
				continue
			var/result = thing.process_late(tick_scale)
			if(result == PROCESS_KILL || QDELETED(thing))
				_remove_machine_from_processing(thing)
			if (MC_TICK_CHECK)
				return

/datum/controller/subsystem/machines/proc/setup_template_powernets(list/cables)
	var/obj/structure/cable/PC
	for(var/A in 1 to cables.len)
		PC = cables[A]
		if(!PC.powernet)
			var/datum/powernet/NewPN = new()
			NewPN.add_cable(PC)
			propagate_network(PC,PC.powernet)

/datum/controller/subsystem/machines/Recover()
	if(islist(SSmachines.processing))
		processing = SSmachines.processing
	if(islist(SSmachines.powernets))
		powernets = SSmachines.powernets
	if(islist(SSmachines.all_machines))
		all_machines = SSmachines.all_machines
	if(islist(SSmachines.machines_by_type))
		machines_by_type = SSmachines.machines_by_type

/datum/controller/subsystem/machines
	/// Tracks which machines are currently scheduled, avoids duplicates
	var/list/processing_set = list() // key: machine -> TRUE

/datum/controller/subsystem/machines/proc/_remove_machine_from_processing(obj/machinery/machine)
	if(!machine) return
	src.processing -= machine
	src.processing_early -= machine
	src.processing_late -= machine
	src.processing_apcs -= machine
	src.processing_set -= machine
	machine.datum_flags &= ~DF_ISPROCESSING

/datum/controller/subsystem/machines/proc/_remove_apc_from_processing(obj/machinery/power/apc/apc)
	if(!apc) return
	src.processing_apcs -= apc
	src.processing_set -= apc
	apc.datum_flags &= ~DF_ISPROCESSING

/datum/controller/subsystem/machines/proc/start_processing_machine(obj/machinery/m)
	if(src.processing_set[m]) // already scheduled
		return
	src.processing_set[m] = TRUE
	src.processing += m
	m.datum_flags |= DF_ISPROCESSING

/datum/controller/subsystem/machines/proc/stop_processing_machine(obj/machinery/m)
	if(!src.processing_set[m]) // not scheduled
		return
	_remove_machine_from_processing(m)
