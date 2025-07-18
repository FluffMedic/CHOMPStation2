GLOBAL_LIST_BOILERPLATE(all_portals, /obj/effect/portal)

/obj/effect/portal
	name = "portal"
	desc = "Looks unstable. Best to test it with the clown."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "portal"
	density = TRUE
	unacidable = TRUE//Can't destroy energy portals.
	var/failchance = 5
	var/obj/item/target = null
	var/creator = null
	anchored = TRUE
	var/event = FALSE

/obj/effect/portal/Bumped(mob/M as mob|obj)
	if(ismob(M) && !(isliving(M)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	spawn(0)
		src.teleport(M)
		return
	return

/obj/effect/portal/Crossed(atom/movable/AM as mob|obj)
	if(AM.is_incorporeal())
		if(!event)
			return
		if(isliving(AM))
			var/mob/living/L = AM
			var/datum/component/shadekin/SK = L.get_shadekin_component()
			if(SK)
				SK.attack_dephase(null, src)
	if(ismob(AM) && !(isliving(AM)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	spawn(0)
		src.teleport(AM)
		return
	return

/obj/effect/portal/attack_hand(mob/user as mob)
	if(istype(user) && !(isliving(user)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	spawn(0)
		src.teleport(user)
		return
	return

/obj/effect/portal/Initialize(mapload)
	. = ..()
	QDEL_IN(src, 30 SECONDS)

/obj/effect/portal/proc/teleport(atom/movable/M as mob|obj)
	if(istype(M, /obj/effect)) //sparks don't teleport
		return
	if (M.anchored&&istype(M, /obj/mecha))
		return
	if (icon_state == "portal1")
		return
	if (!( target ))
		qdel(src)
		return
	if (istype(M, /atom/movable))
		//VOREStation Addition Start: Prevent taurriding abuse
		if(isliving(M))
			var/mob/living/L = M
			if(LAZYLEN(L.buckled_mobs))
				var/datum/riding/R = L.riding_datum
				for(var/rider in L.buckled_mobs)
					R.force_dismount(rider)
		//VOREStation Addition End: Prevent taurriding abuse
		// CHOMPAdd Start
		if(isbelly(target))
			if(target == M)
				return
			if(istype(M, /mob/living))
				var/mob/living/L = M
				if(L.can_be_drop_prey && L.devourable)
					do_teleport(M, target)
					return
		// CHOMPAdd End
		if(prob(failchance)) //oh dear a problem, put em in deep space
			src.icon_state = "portal1"
			do_teleport(M, locate(rand(5, world.maxx - 5), rand(5, world.maxy -5), 3), 0)
		else
			do_teleport(M, target, 1) ///You will appear adjacent to the beacon
