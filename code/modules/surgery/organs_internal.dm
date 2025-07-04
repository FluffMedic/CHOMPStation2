// Internal surgeries.
/datum/surgery_step/internal
	priority = 2
	can_infect = 1
	blood_level = 1

/datum/surgery_step/internal/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

	if (!hasorgans(target))
		return 0

	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && affected.open == (affected.encased ? 3 : 2)

//Removed unused Embryo Surgery, derelict and broken.

//////////////////////////////////////////////////////////////////
//				CHEST INTERNAL ORGAN SURGERY					//
//////////////////////////////////////////////////////////////////
/datum/surgery_step/internal/fix_organ
	surgery_name = "Treat Organ"

	allowed_tools = list(
	/obj/item/stack/medical/advanced/bruise_pack= 100,		\
	/obj/item/stack/medical/bruise_pack = 20
	)

	min_duration = 60
	max_duration = 60

/datum/surgery_step/internal/fix_organ/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!affected)
		return
	var/is_organ_damaged = 0
	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && (I.damage > 0 || I.status == ORGAN_DEAD))
			is_organ_damaged = 1
			break
	return ..() && is_organ_damaged

/datum/surgery_step/internal/fix_organ/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/tool_name = "\the [tool]"
	if (istype(tool, /obj/item/stack/medical/advanced/bruise_pack))
		tool_name = "regenerative membrane"
	else if (istype(tool, /obj/item/stack/medical/bruise_pack))
		tool_name = "the bandaid"

	if (!hasorgans(target))
		return

	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && (I.damage > 0 || I.status == ORGAN_DEAD))
			if(!(I.robotic >= ORGAN_ROBOT))
				user.visible_message(span_filter_notice("[user] starts treating damage to [target]'s [I.name] with [tool_name]."), \
				span_filter_notice("You start treating damage to [target]'s [I.name] with [tool_name].") )
				user.balloon_alert_visible("starts treating damage to [target]'s [I.name]", "treating damage on \the [I.name]")

	target.custom_pain("The pain in your [affected.name] is living hell!", 100)
	..()

/datum/surgery_step/internal/fix_organ/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/tool_name = "\the [tool]"
	if (istype(tool, /obj/item/stack/medical/advanced/bruise_pack))
		tool_name = "regenerative membrane"
	if (istype(tool, /obj/item/stack/medical/bruise_pack))
		tool_name = "the bandaid"

	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/internal/I in affected.internal_organs)
		if(I && (I.damage > 0 || I.status == ORGAN_DEAD))
			if(!(I.robotic >= ORGAN_ROBOT))
				user.visible_message(span_notice("[user] treats damage to [target]'s [I.name] with [tool_name]."), \
				span_notice("You treat damage to [target]'s [I.name] with [tool_name].") )
				user.balloon_alert_visible("starts treating damage to [target]'s [I.name]", "treating damage to \the [I.name]")
				if(I.organ_tag == O_BRAIN && I.status == ORGAN_DEAD && target.can_defib == 0) //Let people know they still got more work to get the brain back into working order.
					to_chat(user, span_warning("You fix their [I] but the neurological structure is still heavily damaged and in need of repair."))
					user.balloon_alert(user, "fixed \the [I], neurological structure still in neeed of repair.")
				I.damage = 0
				I.status = 0
				if(I.organ_tag == O_EYES)
					target.sdisabilities &= ~BLIND
				if(I.organ_tag == O_LUNGS)
					target.SetLosebreath(0)

/datum/surgery_step/internal/fix_organ/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(span_warning("[user]'s hand slips, getting mess and tearing the inside of [target]'s [affected.name] with \the [tool]!"), \
	span_warning("Your hand slips, getting mess and tearing the inside of [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("slips, gettng mess and tearing the inside of [target]'s [affected.name]", "your hand slips, getting mess and tearng the [affected.name]'s insides")
	var/dam_amt = 2

	if (istype(tool, /obj/item/stack/medical/advanced/bruise_pack))
		target.adjustToxLoss(5)
	else if (istype(tool, /obj/item/stack/medical/bruise_pack))
		dam_amt = 5
		target.adjustToxLoss(10)
		affected.createwound(CUT, 5)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && I.damage > 0)
			I.take_damage(dam_amt,0)






//Robo internal organ fix. For when an organic has robotic limbs.
/datum/surgery_step/fix_organic_organ_robotic //For artificial organs
	surgery_name = "Mend Organ"

	allowed_tools = list(
	/obj/item/stack/nanopaste = 100,
	/obj/item/stack/cable_coil = 75,
	/obj/item/tool/wrench = 50,
	/obj/item/storage/toolbox = 10 	//Percussive Maintenance
	)

	min_duration = 60
	max_duration = 60

/datum/surgery_step/fix_organic_organ_robotic/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!affected) return
	var/is_organ_damaged = 0
	for(var/obj/item/organ/I in affected.internal_organs)
		if(I.damage > 0 && (I.robotic >= ORGAN_ROBOT))
			is_organ_damaged = 1
			break
	return affected.open != 3 && is_organ_damaged //Robots have their own code.

/datum/surgery_step/fix_organic_organ_robotic/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && I.damage > 0)
			if(I.robotic >= ORGAN_ROBOT)
				user.visible_message("[user] starts mending the damage to [target]'s [I.name]'s mechanisms.", \
				"You start mending the damage to [target]'s [I.name]'s mechanisms." )
				user.balloon_alert_visible("mends damage to [target]'s [I.name]'s mechanisms.", "mending damage to [I.name]'s mechanisms")

	target.custom_pain("The pain in your [affected.name] is living hell!",1)
	..()

/datum/surgery_step/fix_organic_organ_robotic/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I && I.damage > 0)
			if(I.robotic >= ORGAN_ROBOT)
				user.visible_message(span_notice("[user] repairs [target]'s [I.name] with [tool]."), \
				span_notice("You repair [target]'s [I.name] with [tool].") )
				user.balloon_alert_visible("repairs [target]'s [I.name]", "repaired \the [I.name]")
				I.damage = 0
				if(I.organ_tag == O_EYES)
					target.sdisabilities &= ~BLIND

/datum/surgery_step/fix_organic_organ_robotic/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(span_warning("[user]'s hand slips, gumming up the mechanisms inside of [target]'s [affected.name] with \the [tool]!"), \
	span_warning("Your hand slips, gumming up the mechanisms inside of [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("slips, gumming up the mechanisms inside of [target]'s [affected.name]", "your hand slips, gumming up the mechanisms inside \the [affected.name]")

	target.adjustBruteLoss(5)

	for(var/obj/item/organ/I in affected.internal_organs)
		if(I)
			I.take_damage(rand(3,5),0)


//Robo limb fix end


///////////////////////////////////////////////////////////////
// Organ Detaching Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/internal/detatch_organ/
	surgery_name = "Detach Organ"

	allowed_tools = list(
	/obj/item/surgical/scalpel = 100,		\
	/obj/item/material/knife = 75,	\
	/obj/item/material/shard = 50, 		\
	)

	min_duration = 60
	max_duration = 60

/datum/surgery_step/internal/detatch_organ/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!..())
		return 0

	if(!istype(tool))
		return 0

	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	if(!(affected && !(affected.robotic >= ORGAN_ROBOT)))
		return 0

	target.op_stage.current_organ = null

	var/list/attached_organs = list()
	for(var/organ in target.internal_organs_by_name)
		var/obj/item/organ/I = target.internal_organs_by_name[organ]
		if(I && !(I.status & ORGAN_CUT_AWAY) && I.parent_organ == target_zone)
			attached_organs[I.name] = organ

	var/organ_to_remove = tgui_input_list(user, "Which organ do you want to prepare for removal?", "Organ Choice", attached_organs)
	if(!organ_to_remove)
		return 0
	if(!attached_organs[organ_to_remove])
		return 0

	target.op_stage.current_organ = attached_organs[organ_to_remove]

	return ..() && attached_organs[organ_to_remove]

/datum/surgery_step/internal/detatch_organ/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message(span_filter_notice("[user] starts to separate [target]'s [target.op_stage.current_organ] with \the [tool]."), \
	span_filter_notice("You start to separate [target]'s [target.op_stage.current_organ] with \the [tool].") )
	user.balloon_alert_visible("starts to separate [target]'s [target.op_stage.current_organ]", "separating \the [target.op_stage.current_organ]")
	target.custom_pain("The pain in your [affected.name] is living hell!", 100)
	..()

/datum/surgery_step/internal/detatch_organ/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] has separated [target]'s [target.op_stage.current_organ] with \the [tool].") , \
	span_notice("You have separated [target]'s [target.op_stage.current_organ] with \the [tool]."))
	user.balloon_alert_visible("separates [target]'s [target.op_stage.current_organ]", "separated \the [target.op_stage.current_organ]")

	var/obj/item/organ/I = target.internal_organs_by_name[target.op_stage.current_organ]
	if(I && istype(I))
		I.status |= ORGAN_CUT_AWAY

/datum/surgery_step/internal/detatch_organ/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_warning("[user]'s hand slips, slicing an artery inside [target]'s [affected.name] with \the [tool]!"), \
	span_warning("Your hand slips, slicing an artery inside [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("slips, slicing an artery inside [target]'s [affected.name]", "your hand slips, slicing anrtery inside [affected.name]")
	affected.createwound(CUT, rand(30,50), 1)

///////////////////////////////////////////////////////////////
// Organ Removal Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/internal/remove_organ
	surgery_name = "Remove Organ"

	allowed_tools = list(
	/obj/item/surgical/hemostat = 100,	\
	/obj/item/material/kitchen/utensil/fork = 20
	)

	allowed_procs = list(IS_WIRECUTTER = 100) //FBP code also uses this, so let's be nice. Roboticists won't know to use hemostats.

	min_duration = 60
	max_duration = 60

/datum/surgery_step/internal/remove_organ/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!..())
		return 0

	if(!istype(tool))
		return 0

	var/list/removable_organs = list()
	for(var/organ in target.internal_organs_by_name)
		var/obj/item/organ/internal/I = target.internal_organs_by_name[organ]
		if(istype(I) && (I.status & ORGAN_CUT_AWAY) && I.parent_organ == target_zone)
			removable_organs |= organ

	if(!removable_organs.len)
		return 0

	return ..()

/datum/surgery_step/internal/remove_organ/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	var/list/removable_organs = list()
	for(var/organ in target.internal_organs_by_name)
		var/obj/item/organ/internal/I = target.internal_organs_by_name[organ]
		if(istype(I) && (I.status & ORGAN_CUT_AWAY) && I.parent_organ == target_zone)
			removable_organs[I.name] = organ

	var/organ_to_remove = tgui_input_list(user, "Which organ do you want to remove?", "Organ Choice", removable_organs)
	if(!organ_to_remove) //They chose cancel!
		to_chat(user, span_notice("You decide against preparing any organs for removal."))
		user.visible_message(span_filter_notice("[user] starts pulling \the [tool] from [target]'s [affected]."), \
		span_filter_notice("You start pulling \the [tool] from [target]'s [affected]."))
		user.balloon_alert_visible("starts pulling \the [tool] from [target]'s [affected]", "pulling \the [tool] from \the [affected]")
	if(!removable_organs[organ_to_remove])
		return

	target.op_stage.current_organ = removable_organs[organ_to_remove]

	user.visible_message(span_filter_notice("[user] starts removing [target]'s [target.op_stage.current_organ] with \the [tool]."), \
	span_filter_notice("You start removing [target]'s [target.op_stage.current_organ] with \the [tool]."))
	user.balloon_alert_visible("starts removing [target]'s [target.op_stage.current_organ]", "removing \the [target.op_stage.current_organ]")
	target.custom_pain("Someone's ripping out your [target.op_stage.current_organ]!", 100)
	..()

/datum/surgery_step/internal/remove_organ/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!target.op_stage.current_organ) //They chose to remove their tool instead.
		user.visible_message(span_notice("[user] has removed \the [tool] from [target]'s [affected]."), \
		span_notice("You have removed \the [tool] from [target]'s [affected]."))
		user.balloon_alert_visible("removes \the [tool] from [target]'s [affected]", "removed \the [tool] from \the [affected]")

	// Extract the organ!
	if(target.op_stage.current_organ)
		user.visible_message(span_notice("[user] has removed [target]'s [target.op_stage.current_organ] with \the [tool]."), \
		span_notice("You have removed [target]'s [target.op_stage.current_organ] with \the [tool]."))
		user.balloon_alert_visible("removes [target]'s [target.op_stage.current_organ]", "removed \the [target.op_stage.current_organ]")
		var/obj/item/organ/O = target.internal_organs_by_name[target.op_stage.current_organ]
		if(O && istype(O))
			O.removed(user)
	target.op_stage.current_organ = null

/datum/surgery_step/internal/remove_organ/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_warning("[user]'s hand slips, damaging [target]'s [affected.name] with \the [tool]!"), \
	span_warning("Your hand slips, damaging [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("slips, damaging [target]'s [affected.name]", "your hand slips, damaging \the [affected.name]")
	affected.createwound(BRUISE, 20)

///////////////////////////////////////////////////////////////
// Organ Replacement Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/internal/replace_organ
	surgery_name = "Replace Organ"
	allowed_tools = list(
	/obj/item/organ = 100
	)

	min_duration = 40
	max_duration = 40

/datum/surgery_step/internal/replace_organ/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/internal/O = tool
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	if(!affected || !istype(O))
		return

	var/organ_compatible
	var/organ_missing

	if(!istype(O))
		return 0

	if((affected.robotic >= ORGAN_ROBOT) && !(O.robotic >= ORGAN_ROBOT))
		to_chat(user, span_danger("You cannot install a naked organ into a robotic body."))
		user.balloon_alert(user, "you cannot install a naked organ into a robotic body.")
		return SURGERY_FAILURE

	if(!target.species)
		to_chat(user, span_danger("You have no idea what species this person is. Report this on the bug tracker."))
		return SURGERY_FAILURE

	var/o_a =  (O.gender == PLURAL) ? "" : "a "
	var/o_do = (O.gender == PLURAL) ? "don't" : "doesn't"

	if(!target.internal_organs_by_name[O.organ_tag])
		organ_missing = 1
	else
		to_chat(user, span_warning("\The [target] already has [o_a][O.organ_tag]."))
		user.balloon_alert(user, "there is a [o_a][O.organ_tag] already!")
		return SURGERY_FAILURE

	// CHOMPadd begin - Malignant organs
	if(O && istype(O,/obj/item/organ/internal/malignant))
		// malignant organs use a whitelist for allowed locations, and may be placed anywhere in it, not just one organ slot!
		var/obj/item/organ/internal/malignant/ML = O
		if(affected.organ_tag in ML.surgeryAllowedSites)
			ML.parent_organ = affected.organ_tag
			organ_compatible = 1
		else
			to_chat(user, span_warning("\The [O] won't fit in \the [affected.name]."))
			return SURGERY_FAILURE
	// CHOMPadd end

	if(O && affected.organ_tag == O.parent_organ)
		organ_compatible = 1

	else
		to_chat(user, span_warning("\The [O.organ_tag] [o_do] normally go in \the [affected.name]."))
		user.balloon_alert(user, "\the [O.organ_tag] [o_do] normally go in \the [affected.name]")
		return SURGERY_FAILURE

	return ..() && organ_missing && organ_compatible

/datum/surgery_step/internal/replace_organ/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_filter_notice("[user] starts transplanting \the [tool] into [target]'s [affected.name]."), \
	span_filter_notice("You start transplanting \the [tool] into [target]'s [affected.name]."))
	user.balloon_alert_visible("strats transplanting \the [tool] into [target]'s [affected.name]", "transplanting \the [tool] into \the [affected.name]")
	target.custom_pain("Someone's rooting around in your [affected.name]!", 100)
	..()

/datum/surgery_step/internal/replace_organ/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] has transplanted \the [tool] into [target]'s [affected.name]."), \
	span_notice("You have transplanted \the [tool] into [target]'s [affected.name]."))
	user.balloon_alert_visible("transplants \the [tool] into [target]'s [affected.name]", "transplanted \the [tool] into [affected.name]")
	var/obj/item/organ/O = tool
	if(istype(O))
		user.remove_from_mob(O)
		O.replaced(target,affected)

/datum/surgery_step/internal/replace_organ/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_warning("[user]'s hand slips, damaging \the [tool]!"), \
	span_warning("Your hand slips, damaging \the [tool]!"))
	user.balloon_alert_visible("slips, damaging \the [tool]", "your hand slips, damaging \the [tool]")
	var/obj/item/organ/I = tool
	if(istype(I))
		I.take_damage(rand(3,5),0)

///////////////////////////////////////////////////////////////
// Organ Attaching Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/internal/attach_organ
	surgery_name = "Attach Organ"
	allowed_tools = list(
	/obj/item/surgical/FixOVein = 100, \
	/obj/item/stack/cable_coil = 75
	)

	min_duration = 40 //CHOMPedit
	max_duration = 40 //CHOMPedit

/datum/surgery_step/internal/attach_organ/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!..())
		return 0

	if(!istype(tool))
		return 0

	target.op_stage.current_organ = null

	var/list/removable_organs = list()
	for(var/organ in target.internal_organs_by_name)
		var/obj/item/organ/I = target.internal_organs_by_name[organ]
		if(istype(I) && (I.status & ORGAN_CUT_AWAY) && !(I.robotic >= ORGAN_ROBOT) && I.parent_organ == target_zone)
			removable_organs[I.name] = organ

	var/organ_to_replace = tgui_input_list(user, "Which organ do you want to reattach?", "Organ Choice", removable_organs)
	if(!organ_to_replace)
		return 0

	target.op_stage.current_organ = removable_organs[organ_to_replace]
	return ..()

/datum/surgery_step/internal/attach_organ/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_filter_notice("[user] begins reattaching [target]'s [target.op_stage.current_organ] with \the [tool]."), \
	span_filter_notice("You start reattaching [target]'s [target.op_stage.current_organ] with \the [tool]."))
	user.balloon_alert_visible("begins reattaching [target]'s [target.op_stage.current_organ]", "reattaching [target.op_stage.current_organ]")
	target.custom_pain("Someone's digging needles into your [target.op_stage.current_organ]!", 100)
	..()

/datum/surgery_step/internal/attach_organ/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] has reattached [target]'s [target.op_stage.current_organ] with \the [tool].") , \
	span_notice("You have reattached [target]'s [target.op_stage.current_organ] with \the [tool]."))
	user.balloon_alert_visible("reattached [target]'s [target.op_stage.current_organ]", "reattached [target.op_stage.current_organ]")

	var/obj/item/organ/I = target.internal_organs_by_name[target.op_stage.current_organ]
	if(I && istype(I))
		I.status &= ~ORGAN_CUT_AWAY

/datum/surgery_step/internal/attach_organ/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_warning("[user]'s hand slips, damaging the flesh in [target]'s [affected.name] with \the [tool]!"), \
	span_warning("Your hand slips, damaging the flesh in [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("slips, damaging the flesh in [target]'s [affected.name]", "your hand slips, damaging the flesh in [affected.name]")
	affected.createwound(BRUISE, 20)
