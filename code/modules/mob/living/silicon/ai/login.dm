/mob/living/silicon/ai/Login()	//ThisIsDumb(TM) TODO: tidy this up °_° ~Carn
	..()
	for(var/obj/effect/rune/rune in GLOB.rune_list)
		client.images += rune.blood_image
	if(stat != DEAD)
		for(var/obj/machinery/ai_status_display/O in GLOB.machines) //change status
			O.mode = 1
			O.emotion = "Neutral"
	if(multicam_on)
		end_multicam()
	src.view_core()
	return
