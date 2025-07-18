
//---------- shield capacitor
//pulls energy out of a power net and charges an adjacent generator

/obj/machinery/shield_capacitor
	name = "shield capacitor"
	desc = "A machine that charges a shield generator."
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "capacitor"
	var/active = 0
	density = TRUE
	var/stored_charge = 0	//not to be confused with power cell charge, this is in Joules
	var/last_stored_charge = 0
	var/time_since_fail = 100
	var/max_charge = 8e6	//8 MJ
	var/max_charge_rate = 400000	//400 kW
	var/locked = 0
	use_power = USE_POWER_OFF //doesn't use APC power
	var/charge_rate = 100000	//100 kW
	var/obj/machinery/shield_gen/owned_gen
	interact_offline = TRUE

/obj/machinery/shield_capacitor/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/climbable)

/obj/machinery/shield_capacitor/advanced
	name = "advanced shield capacitor"
	desc = "A machine that charges a shield generator.  This version can store, input, and output more electricity."
	max_charge = 12e6
	max_charge_rate = 600000

/obj/machinery/shield_capacitor/emag_act(var/remaining_charges, var/mob/user)
	if(prob(75))
		src.locked = !src.locked
		to_chat(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
		. = 1
		updateDialog()
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(5, 1, src)
	s.start()

/obj/machinery/shield_capacitor/attackby(obj/item/W, mob/user)

	if(istype(W, /obj/item/card/id))
		var/obj/item/card/id/C = W
		if((access_captain in C.GetAccess()) || (access_security in C.GetAccess()) || (access_engine in C.GetAccess()))
			src.locked = !src.locked
			to_chat(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
			updateDialog()
		else
			to_chat(user, span_red("Access denied."))
	else if(W.has_tool_quality(TOOL_WRENCH))
		src.anchored = !src.anchored
		playsound(src, W.usesound, 75, 1)
		src.visible_message(span_blue("[icon2html(src,viewers(src))] [src] has been [anchored ? "bolted to the floor" : "unbolted from the floor"] by [user]."))

		if(anchored)
			spawn(0)
				for(var/obj/machinery/shield_gen/gen in range(1, src))
					if(get_dir(src, gen) == src.dir)
						owned_gen = gen
						owned_gen.capacitors |= src
						owned_gen.updateDialog()
		else
			if(owned_gen && (src in owned_gen.capacitors))
				owned_gen.capacitors -= src
			owned_gen = null
	else
		..()

/obj/machinery/shield_capacitor/attack_hand(mob/user)
	if(stat & (BROKEN))
		return
	tgui_interact(user)

/obj/machinery/shield_capacitor/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShieldCapacitor", name)
		ui.open()

/obj/machinery/shield_capacitor/tgui_status(mob/user)
	if(stat & BROKEN)
		return STATUS_CLOSE
	return ..()

/obj/machinery/shield_capacitor/tgui_data(mob/user)
	var/list/data = list()

	data["active"] = active
	data["time_since_fail"] = time_since_fail
	data["stored_charge"] = stored_charge
	data["max_charge"] = max_charge
	data["charge_rate"] = charge_rate
	data["max_charge_rate"] = max_charge_rate

	return data

/obj/machinery/shield_capacitor/process()
	if (!anchored)
		active = 0

	//see if we can connect to a power net.
	var/datum/powernet/PN
	var/turf/T = get_turf(src)
	var/obj/structure/cable/C = T.get_cable_node()
	if (C && anchored) //Make sure its anchored too.
		PN = C.powernet

	if (PN)
		var/power_draw = between(0, max_charge - stored_charge, charge_rate) //what we are trying to draw
		power_draw = PN.draw_power(power_draw) //what we actually get
		stored_charge += power_draw

	time_since_fail++
	if(stored_charge < last_stored_charge)
		time_since_fail = 0 //losing charge faster than we can draw from PN
	last_stored_charge = stored_charge

/obj/machinery/shield_capacitor/tgui_act(action, params, datum/tgui/ui)
	if(..())
		return TRUE

	switch(action)
		if("toggle")
			if(!active && !anchored)
				to_chat(ui.user, span_red("The [src] needs to be firmly secured to the floor first."))
				return
			active = !active
			. = TRUE
		if("charge_rate")
			charge_rate = clamp(text2num(params["rate"]), 10000, max_charge_rate)
			. = TRUE

/obj/machinery/shield_capacitor/power_change()
	if(stat & BROKEN)
		icon_state = "broke"
	else
		..()

/obj/machinery/shield_capacitor/verb/rotate_clockwise()
	set name = "Rotate Capacitor Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored)
		to_chat(usr, "It is fastened to the floor!")
		return

	src.set_dir(turn(src.dir, 270))
	return

//VOREstation edit: counter-clockwise rotation
/obj/machinery/shield_capacitor/verb/rotate_counterclockwise()
	set name = "Rotate Capacitor Counter-Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored)
		to_chat(usr, "It is fastened to the floor!")
		return

	src.set_dir(turn(src.dir, 90))
	return
