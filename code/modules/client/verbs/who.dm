#define NO_ADMINS_ONLINE_MESSAGE "Adminhelps are also sent through TGS to services like Discord. If no admins are available in game, sending an adminhelp might still be noticed and responded to."

/client/verb/who()
	set name = "Who"
	set category = "OOC.Resources"

	var/msg = span_bold("Current Players:") + "\n"

	var/list/Lines = list()

	for(var/client/C in GLOB.clients)
		if(!check_rights_for(src, R_ADMIN|R_MOD))
			Lines += "\t[C.holder?.fakekey || C.key]"
			continue
		var/entry = "\t[C.key]"
		if(C.holder?.fakekey)
			entry += " " + span_italics("as [C.holder.fakekey])")
		entry += " - Playing as [C.mob.real_name]"
		switch(C.mob.stat)
			if(UNCONSCIOUS)
				entry += " - [span_darkgray(span_bold("Unconscious"))]"
			if(DEAD)
				if(isobserver(C.mob))
					var/mob/observer/dead/O = C.mob
					if(O.started_as_observer)
						entry += " - [span_gray("Observing")]"
					else
						entry += " - [span_black(span_bold("DEAD"))]"
				else
					entry += " - [span_black(span_bold("DEAD"))]"

		if(C.player_age != initial(C.player_age) && isnum(C.player_age)) // database is on
			var/age = C.player_age
			switch(age)
				if(0 to 1)
					age = span_red(span_bold("[age] days old"))
				if(1 to 10)
					age = span_orange(span_bold("[age] days old"))
				else
					entry += " - [age] days old"

		if(is_special_character(C.mob))
			entry += " - [span_red(span_bold("Antagonist"))]"

		if(C.is_afk())
			var/seconds = C.last_activity_seconds()
			entry += " (AFK - [round(seconds / 60)] minutes, [seconds % 60] seconds)"

		entry += " [ADMIN_QUE(C.mob)]"
		Lines += entry

	for(var/line in sortList(Lines))
		msg += "[line]\n"

	msg += span_bold("Total Players: [length(Lines)]")
	msg = span_filter_notice("[jointext(msg, "<br>")]")
	to_chat(src,msg)

/client/verb/staffwho()
	set category = "Admin"
	set name = "Staffwho"

	var/header = GLOB.admins.len == 0 ? "No Admins Currently Online" : "Current Admins"

	var/msg = ""
	var/modmsg = ""
	var/devmsg = ""
	var/eventMmsg = ""
	var/mentormsg = ""
	var/num_mods_online = 0
	var/num_admins_online = 0
	var/num_devs_online = 0
	var/num_event_managers_online = 0
	var/num_mentors_online = 0
	for(var/client/C in GLOB.admins) // VOREStation Edit - GLOB
		var/temp = ""
		var/category = R_ADMIN
		// VOREStation Edit - Apply stealthmin protection to all levels
		if(C.holder.fakekey && !check_rights_for(src, R_ADMIN|R_MOD))	// Only admins and mods can see stealthmins
			continue
		// VOREStation Edit End
		if(check_rights_for(C, R_BAN)) // admins //VOREStation Edit
			num_admins_online++
		else if(check_rights_for(C, R_ADMIN) && !check_rights_for(C, R_SERVER)) // mods //VOREStation Edit: Game masters
			category = R_MOD
			num_mods_online++
		else if(check_rights_for(C, R_SERVER)) // developers
			category = R_SERVER
			num_devs_online++
		else if(check_rights_for(C, R_STEALTH)) // event managers //VOREStation Edit: Retired Staff
			category = R_EVENT
			num_event_managers_online++
		else if(check_rights_for(C, R_MENTOR))
			category = R_MENTOR
			num_mentors_online++

		temp += "\t[C] is a [C.holder.rank_names()]"
		if(holder)
			if(C.holder.fakekey)
				temp += " " + span_italics("(as [C.holder.fakekey])")

			if(isobserver(C.mob))
				temp += " - Observing"
			else if(isnewplayer(C.mob))
				temp += " - Lobby"
			else
				temp += " - Playing"

			if(C.is_afk())
				var/seconds = C.last_activity_seconds()
				temp += " (AFK - [round(seconds / 60)] minutes, [seconds % 60] seconds)"
		temp += "\n"
		switch(category)
			if(R_ADMIN)
				msg += temp
			if(R_MOD)
				modmsg += temp
			if(R_SERVER)
				devmsg += temp
			if(R_EVENT)
				eventMmsg += temp
			if(R_MENTOR)
				mentormsg += temp

	msg = span_bold("Current Admins ([num_admins_online]):") + "\n" + msg

	if(CONFIG_GET(flag/show_mods))
		msg += "\n" + span_bold(" Current Moderators ([num_mods_online]):") + "\n" + modmsg // CHOMPEdit

	if(CONFIG_GET(flag/show_devs))
		msg += "\n" + span_bold(" Current Developers ([num_devs_online]):") + "\n" + devmsg

	if(CONFIG_GET(flag/show_event_managers))
		msg += "\n" + span_bold(" Current Miscellaneous ([num_event_managers_online]):") + "\n" + eventMmsg

	if(CONFIG_GET(flag/show_mentors))
		msg += "\n" + span_bold(" Current Mentors ([num_mentors_online]):") + "\n" + mentormsg

	msg += "\n" + span_info(NO_ADMINS_ONLINE_MESSAGE)

	to_chat(src, fieldset_block(span_bold(header), span_filter_notice("[jointext(msg, "<br>")]"), "boxed_message"), type = MESSAGE_TYPE_INFO)

#undef NO_ADMINS_ONLINE_MESSAGE
