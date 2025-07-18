#define overlay_cache_LEN 50

/obj/item/t_scanner
	name = "\improper T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	icon = 'icons/obj/device.dmi'
	icon_state = "t-ray0"
	item_state = "t-ray"
	slot_flags = SLOT_BELT
	w_class = ITEMSIZE_SMALL
	matter = list(MAT_STEEL = 150)
	origin_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)

	var/scan_range = 1

	var/on = 0
	var/list/active_scanned = list() //assoc list of objects being scanned, mapped to their overlay
	var/client/user_client //since making sure overlays are properly added and removed is pretty important, so we track the current user explicitly
	var/flicker = 0

	pickup_sound = 'sound/items/pickup/device.ogg'
	drop_sound = 'sound/items/drop/device.ogg'

/obj/item/t_scanner/update_icon()
	icon_state = "t-ray[on]"

/obj/item/t_scanner/attack_self(mob/user)
	set_active(!on)

/obj/item/t_scanner/proc/set_active(var/active)
	on = active
	if(on)
		START_PROCESSING(SSobj, src)
		flicker = 0
	else
		STOP_PROCESSING(SSobj, src)
		set_user_client(null)
	update_icon()

//If reset is set, then assume the client has none of our overlays, otherwise we only send new overlays.
/obj/item/t_scanner/process()
	if(!on) return

	//handle clients changing
	var/client/loc_client = null
	if(ismob(src.loc))
		var/mob/M = src.loc
		loc_client = M.client
	set_user_client(loc_client)

	//no sense processing if no-one is going to see it.
	if(!user_client) return

	//get all objects in scan range
	var/list/scanned = get_scanned_objects(scan_range)
	var/list/update_add = scanned - active_scanned
	var/list/update_remove = active_scanned - scanned

	//Add new overlays
	for(var/obj/O in update_add)
		var/image/overlay = get_overlay(O)
		active_scanned[O] = overlay
		user_client.images += overlay

	//Remove stale overlays
	for(var/obj/O in update_remove)
		user_client.images -= active_scanned[O]
		active_scanned -= O

	//Flicker effect
	for(var/obj/O in active_scanned)
		var/image/overlay = active_scanned[O]
		if(flicker)
			overlay.alpha = 0
		else
			overlay.alpha = 128
	flicker = !flicker

//creates a new overlay for a scanned object
/obj/item/t_scanner/proc/get_overlay(obj/scanned)
	//Use a cache so we don't create a whole bunch of new images just because someone's walking back and forth in a room.
	//Also means that images are reused if multiple people are using t-rays to look at the same objects.
	if(scanned in GLOB.overlay_cache)
		. = GLOB.overlay_cache[scanned]
	else
		var/image/I = image(loc = scanned, icon = scanned.icon, icon_state = scanned.icon_state, layer = HUD_LAYER)

		//Pipes are special
		if(istype(scanned, /obj/machinery/atmospherics/pipe))
			var/obj/machinery/atmospherics/pipe/P = scanned
			I.color = P.pipe_color
			I.add_overlay(P.overlays)

		I.alpha = 128
		I.mouse_opacity = 0
		. = I

	// Add it to cache, cutting old entries if the list is too long
	GLOB.overlay_cache[scanned] = .
	if(GLOB.overlay_cache.len > overlay_cache_LEN)
		GLOB.overlay_cache.Cut(1, GLOB.overlay_cache.len-overlay_cache_LEN-1)

/obj/item/t_scanner/proc/get_scanned_objects(var/scan_dist)
	. = list()

	var/turf/center = get_turf(src.loc)
	if(!center) return

	for(var/turf/T in range(scan_range, center))
		if(!!T.is_plating())
			continue

		for(var/obj/O in T.contents)
			if(O.level != 1)
				continue
			if(!O.invisibility)
				continue //if it's already visible don't need an overlay for it
			. += O

/obj/item/t_scanner/proc/set_user_client(var/client/new_client)
	if(new_client == user_client)
		return
	if(user_client)
		for(var/scanned in active_scanned)
			user_client.images -= active_scanned[scanned]
	if(new_client)
		for(var/scanned in active_scanned)
			new_client.images += active_scanned[scanned]
	else
		active_scanned.Cut()

	user_client = new_client

/obj/item/t_scanner/dropped(mob/user)
	set_user_client(null)
	..()

/obj/item/t_scanner/upgraded
	name = "Upgraded T-ray Scanner"
	desc = "An upgraded version of the terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	matter = list(MAT_STEEL = 500, PHORON = 150)
	origin_tech = list(TECH_MAGNET = 4, TECH_ENGINEERING = 5)
	scan_range = 3

/obj/item/t_scanner/advanced
	name = "Advanced T-ray Scanner"
	desc = "An advanced version of the terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	matter = list(MAT_STEEL = 1500, PHORON = 200, SILVER = 250)
	origin_tech = list(TECH_MAGNET = 7, TECH_ENGINEERING = 7, TECH_MATERIAL = 6)
	scan_range = 7


#undef overlay_cache_LEN
