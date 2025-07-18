/obj/machinery/beehive
	name = "beehive"
	icon = 'icons/obj/beekeeping.dmi'
	icon_state = "beehive"
	density = TRUE
	anchored = TRUE

	var/closed = 0
	var/bee_count = 0 // Percent
	var/smoked = 0 // Timer
	var/honeycombs = 0 // Percent
	var/list/frames = list()	// List of frames inside.
	var/maxFrames = 5

/obj/machinery/beehive/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/climbable)

/obj/machinery/beehive/update_icon()
	cut_overlays()
	icon_state = "beehive"
	if(closed)
		add_overlay("lid")
	if(length(frames))
		add_overlay("empty[length(frames)]")
	if(honeycombs >= 100)
		add_overlay("full[round(honeycombs / 100)]")
	if(!smoked)
		switch(bee_count)
			if(1 to 40)
				add_overlay("bees1")
			if(41 to 80)
				add_overlay("bees2")
			if(81 to 100)
				add_overlay("bees3")

/obj/machinery/beehive/examine(var/mob/user)
	. = ..()
	if(!closed)
		. += "The lid is open."

/obj/machinery/beehive/attackby(var/obj/item/I, var/mob/user)
	if(I.has_tool_quality(TOOL_CROWBAR))
		closed = !closed
		user.visible_message(span_notice("[user] [closed ? "closes" : "opens"] \the [src]."), span_notice("You [closed ? "close" : "open"] \the [src]."))
		update_icon()
		return
	else if(I.has_tool_quality(TOOL_WRENCH))
		anchored = !anchored
		playsound(src, I.usesound, 50, 1)
		user.visible_message(span_notice("[user] [anchored ? "wrenches" : "unwrenches"] \the [src]."), span_notice("You [anchored ? "wrench" : "unwrench"] \the [src]."))
		return
	else if(istype(I, /obj/item/bee_smoker))
		if(closed)
			to_chat(user, span_notice("You need to open \the [src] with a crowbar before smoking the bees."))
			return
		user.visible_message(span_notice("[user] smokes the bees in \the [src]."), span_notice("You smoke the bees in \the [src]."))
		smoked = 30
		update_icon()
		return
	else if(istype(I, /obj/item/honey_frame))
		if(closed)
			to_chat(user, span_notice("You need to open \the [src] with a crowbar before inserting \the [I]."))
			return
		if(length(frames) >= maxFrames)
			to_chat(user, span_notice("There is no place for an another frame."))
			return
		var/obj/item/honey_frame/H = I
		if(H.honey)
			to_chat(user, span_notice("\The [I] is full with beeswax and honey, empty it in the extractor first."))
			return
		user.visible_message(span_notice("[user] loads \the [I] into \the [src]."), span_notice("You load \the [I] into \the [src]."))
		update_icon()
		user.drop_from_inventory(H)
		H.forceMove(src)
		frames.Add(H)
		return
	else if(istype(I, /obj/item/bee_pack))
		var/obj/item/bee_pack/B = I
		if(B.full && bee_count)
			to_chat(user, span_notice("\The [src] already has bees inside."))
			return
		if(!B.full && bee_count < 90)
			to_chat(user, span_notice("\The [src] is not ready to split."))
			return
		if(!B.full && !smoked)
			to_chat(user, span_notice("Smoke \the [src] first!"))
			return
		if(closed)
			to_chat(user, span_notice("You need to open \the [src] with a crowbar before moving the bees."))
			return
		if(B.full)
			user.visible_message(span_notice("[user] puts the queen and the bees from \the [I] into \the [src]."), span_notice("You put the queen and the bees from \the [I] into \the [src]."))
			bee_count = 20
			B.empty()
		else
			user.visible_message(span_notice("[user] puts bees and larvae from \the [src] into \the [I]."), span_notice("You put bees and larvae from \the [src] into \the [I]."))
			bee_count /= 2
			B.fill()
		update_icon()
		return
	else if(istype(I, /obj/item/analyzer/plant_analyzer))
		to_chat(user, span_notice("Scan result of \the [src]..."))
		to_chat(user, "Beehive is [bee_count ? "[round(bee_count)]% full" : "empty"].[bee_count > 90 ? " Colony is ready to split." : ""]")
		if(length(frames))
			to_chat(user, "[length(frames)] frames installed, [round(honeycombs / 100)] filled.")
			if(honeycombs < length(frames) * 100)
				to_chat(user, "Next frame is [round(honeycombs % 100)]% full.")
		else
			to_chat(user, "No frames installed.")
		if(smoked)
			to_chat(user, "The hive is smoked.")
		return 1
	else if(I.has_tool_quality(TOOL_SCREWDRIVER))
		if(bee_count)
			to_chat(user, span_notice("You can't dismantle \the [src] with these bees inside."))
			return
		if(length(frames))
			to_chat(user, span_notice("You can't dismantle \the [src] with [length(frames)] frames still inside!"))
			return
		to_chat(user, span_notice("You start dismantling \the [src]..."))
		playsound(src, I.usesound, 50, 1)
		if(do_after(user, 30))
			user.visible_message(span_notice("[user] dismantles \the [src]."), span_notice("You dismantle \the [src]."))
			new /obj/item/beehive_assembly(loc)
			qdel(src)
		return

/obj/machinery/beehive/attack_hand(var/mob/user)
	if(!closed)
		if(honeycombs < 100)
			to_chat(user, span_notice("There are no filled honeycombs."))
			return
		if(!smoked && bee_count)
			to_chat(user, span_notice("The bees won't let you take the honeycombs out like this, smoke them first."))
			return
		user.visible_message(span_notice("[user] starts taking the honeycombs out of \the [src]."), span_notice("You start taking the honeycombs out of \the [src]..."))
		while(honeycombs >= 100 && length(frames) && do_after(user, 30))
			var/obj/item/honey_frame/H = pop(frames)
			H.honey = 20
			honeycombs -= 100
			H.update_icon()
			H.forceMove(get_turf(src))
			update_icon()
		if(honeycombs < 100)
			to_chat(user, span_notice("You take all filled honeycombs out."))
		return

/obj/machinery/beehive/process()
	if(closed && !smoked && bee_count)
		pollinate_flowers()
		update_icon()
	smoked = max(0, smoked - 1)
	if(!smoked && bee_count)
		bee_count = min(bee_count * 1.005, 100)
		update_icon()

/obj/machinery/beehive/proc/pollinate_flowers()
	var/coef = bee_count / 100
	var/trays = 0
	for(var/obj/machinery/portable_atmospherics/hydroponics/H in view(7, src))
		if(H.seed && !H.dead)
			H.health += 0.05 * coef
			++trays
	honeycombs = min(honeycombs + 0.1 * coef * min(trays, 5), length(frames) * 100)

/obj/machinery/honey_extractor
	name = "honey extractor"
	desc = "A machine used to turn honeycombs on the frame into honey and wax."
	icon = 'icons/obj/beekeeping.dmi'
	icon_state = "centrifuge"

	density = TRUE

	var/processing = 0
	var/honey = 0

/obj/machinery/honey_extractor/attackby(var/obj/item/I, var/mob/user)
	if(processing)
		to_chat(user, span_notice("\The [src] is currently spinning, wait until it's finished."))
		return
	else if(istype(I, /obj/item/honey_frame))
		var/obj/item/honey_frame/H = I
		if(!H.honey)
			to_chat(user, span_notice("\The [H] is empty, put it into a beehive."))
			return
		user.visible_message(span_notice("[user] loads \the [H]'s comb into \the [src] and turns it on."), span_notice("You load \the [H] into \the [src] and turn it on."))
		processing = H.honey
		icon_state = "[initial(icon_state)]_moving"
		H.honey = 0
		H.update_icon()
		spawn(50)
			new /obj/item/stack/material/wax(loc)
			honey += processing
			processing = 0
			icon_state = "[initial(icon_state)]"
	else if(istype(I, /obj/item/reagent_containers/glass))
		if(!honey)
			to_chat(user, span_notice("There is no honey in \the [src]."))
			return
		var/obj/item/reagent_containers/glass/G = I
		var/transferred = min(G.reagents.maximum_volume - G.reagents.total_volume, honey)
		G.reagents.add_reagent(REAGENT_ID_HONEY, transferred)
		honey -= transferred
		user.visible_message(span_notice("[user] collects honey from \the [src] into \the [G]."), span_notice("You collect [transferred] units of honey from \the [src] into \the [G]."))
		return 1

/obj/item/bee_smoker
	name = "bee smoker"
	desc = "A device used to calm down bees before harvesting honey."
	icon = 'icons/obj/device.dmi'
	icon_state = "battererburnt"
	w_class = ITEMSIZE_SMALL

/obj/item/honey_frame
	name = "beehive frame"
	desc = "A frame for the beehive that the bees will fill with honeycombs."
	icon = 'icons/obj/beekeeping.dmi'
	icon_state = "honeyframe"
	w_class = ITEMSIZE_SMALL

	var/honey = 0

/obj/item/honey_frame/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/honey_frame/update_icon()
	..()

	overlays.Cut()
	if(honey > 0)
		add_overlay("honeycomb")

/obj/item/honey_frame/filled
	name = "filled beehive frame"
	desc = "A frame for the beehive that the bees have filled with honeycombs."
	honey = 20

/obj/item/beehive_assembly
	name = "beehive assembly"
	desc = "Contains everything you need to build a beehive."
	icon = 'icons/obj/apiary_bees_etc.dmi'
	icon_state = "apiary"

/obj/item/beehive_assembly/attack_self(var/mob/user)
	to_chat(user, span_notice("You start assembling \the [src]..."))
	if(do_after(user, 30))
		user.visible_message(span_notice("[user] constructs a beehive."), span_notice("You construct a beehive."))
		new /obj/machinery/beehive(get_turf(user))
		user.drop_from_inventory(src)
		qdel(src)
	return

/obj/item/stack/material/wax
	name = "wax"
	singular_name = "wax piece"
	desc = "Soft substance produced by bees. Used to make candles."
	icon = 'icons/obj/beekeeping.dmi'
	icon_state = "wax"
	default_type = "wax"
	pass_color = TRUE
	strict_color_stacking = TRUE

/obj/item/stack/material/wax/Initialize(mapload)
	. = ..()
	recipes = wax_recipes

/datum/material/wax
	name = "wax"
	stack_type = /obj/item/stack/material/wax
	icon_colour = "#fff343"
	melting_point = T0C+300
	weight = 1
	pass_stack_colors = TRUE



/obj/item/bee_pack
	name = "bee pack"
	desc = "Contains a queen bee and some worker bees. Everything you'll need to start a hive!"
	icon = 'icons/obj/beekeeping.dmi'
	icon_state = "beepack"
	var/full = 1

/obj/item/bee_pack/Initialize(mapload)
	. = ..()
	add_overlay("beepack-full")

/obj/item/bee_pack/proc/empty()
	full = 0
	name = "empty bee pack"
	desc = "A stasis pack for moving bees. It's empty."
	cut_overlays()
	add_overlay("beepack-empty")

/obj/item/bee_pack/proc/fill()
	full = initial(full)
	name = initial(name)
	desc = initial(desc)
	cut_overlays()
	add_overlay("beepack-full")
