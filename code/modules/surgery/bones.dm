//Procedures in this file: Fracture repair surgery
//////////////////////////////////////////////////////////////////
//						BONE SURGERY							//
//////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////
// Bone Glue Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/glue_bone
	surgery_name = "Glue Bone"
	allowed_tools = list(
		/obj/item/surgical/bonegel = 100
	)

	allowed_procs = list(IS_SCREWDRIVER = 75)

	can_infect = 1
	blood_level = 1

	min_duration = 30 //CHOMPedit
	max_duration = 40 //CHOMPedit

/datum/surgery_step/glue_bone/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && (affected.robotic < ORGAN_ROBOT) && affected.open >= 2 && affected.stage == 0

/datum/surgery_step/glue_bone/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (affected.stage == 0)
		user.visible_message(span_notice("[user] starts applying medication to the damaged bones in [target]'s [affected.name] with \the [tool].") , \
		span_notice("You start applying medication to the damaged bones in [target]'s [affected.name] with \the [tool]."))
		user.balloon_alert_visible("Applies medication to the damaged bones.", "Applying medication to the damaged bones.") // CHOMPEdit
	target.custom_pain("Something in your [affected.name] is causing you a lot of pain!", 50)
	..()

/datum/surgery_step/glue_bone/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] applies some [tool] to [target]'s bone in [affected.name]"), \
		span_notice("You apply some [tool] to [target]'s bone in [affected.name] with \the [tool]."))
	user.balloon_alert_visible("Applies [tool] to [target]'s bone.", "Applying [tool] to [target]'s bone.") // CHOMPEdit
	affected.stage = 1

/datum/surgery_step/glue_bone/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, smearing [tool] in the incision in [target]'s [affected.name]!") , \
	span_danger("Your hand slips, smearing [tool] in the incision in [target]'s [affected.name]!"))
	user.balloon_alert_visible("Slips, damaging [target]'s [affected.name]", "Your hand slips.") // CHOMPEdit

///////////////////////////////////////////////////////////////
// Bone Setting Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/set_bone
	surgery_name = "Set Bone"
	allowed_tools = list(
		/obj/item/surgical/bonesetter = 100
	)

	allowed_procs = list(IS_WRENCH = 75)

	min_duration = 30 //CHOMPedit
	max_duration = 45 //CHOMPedit

/datum/surgery_step/set_bone/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && affected.organ_tag != BP_HEAD && !(affected.robotic >= ORGAN_ROBOT) && affected.open >= 2 && affected.stage == 1

/datum/surgery_step/set_bone/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] is beginning to set the bone in [target]'s [affected.name] in place with \the [tool].") , \
		span_notice("You are beginning to set the bone in [target]'s [affected.name] in place with \the [tool]."))
	user.balloon_alert_visible("Begins to set the bone in place.", "Setting the bone in place.") // CHOMPEdit - Balloon alert
	target.custom_pain("The pain in your [affected.name] is going to make you pass out!", 50)
	..()

/datum/surgery_step/set_bone/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (affected.status & ORGAN_BROKEN)
		user.visible_message(span_notice("[user] sets the bone in [target]'s [affected.name] in place with \the [tool]."), \
			span_notice("You set the bone in [target]'s [affected.name] in place with \the [tool]."))
		user.balloon_alert_visible("Sets the bone in place.", "Bone set in place.") // CHOMPEdit - Balloon alert
		affected.stage = 2
	else
		user.visible_message("[user] sets the bone in [target]'s [affected.name] " + span_danger("in the WRONG place with \the [tool]."), \
			"You set the bone in [target]'s [affected.name] " + span_danger("in the WRONG place with \the [tool]."))
		user.balloon_alert_visible("Sets the bone in the WRONG place.", "Bone set in the WRONG place.") // CHOMPEdit - Balloon alert
		affected.fracture()

/datum/surgery_step/set_bone/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, damaging the bone in [target]'s [affected.name] with \the [tool]!") , \
		span_danger("Your hand slips, damaging the bone in [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("Slips, damaging the bone.", "Your hand slips, damaging the bone") // CHOMPEdit - Balloon alert
	affected.createwound(BRUISE, 5)

///////////////////////////////////////////////////////////////
// Skull Mending Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/mend_skull
	surgery_name = "Mend Skull"
	allowed_tools = list(
		/obj/item/surgical/bonesetter = 100
	)

	allowed_procs = list(IS_WRENCH = 75)

	min_duration = 40 //CHOMPedit
	max_duration = 50 //CHOMPedit

/datum/surgery_step/mend_skull/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && affected.organ_tag == BP_HEAD && (affected.robotic < ORGAN_ROBOT) && affected.open >= 2 && affected.stage == 1

/datum/surgery_step/mend_skull/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] is beginning to piece together [target]'s skull with \the [tool].")  , \
		span_notice("You are beginning to piece together [target]'s skull with \the [tool]."))
	user.balloon_alert_visible("Pieces the skull together", "Piecing skull together.") // CHOMPEdit
	..()

/datum/surgery_step/mend_skull/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] sets [target]'s skull with \the [tool].") , \
		span_notice("You set [target]'s skull with \the [tool]."))
	user.balloon_alert_visible("Sets the skull back.", "Skull set back.") // CHOMPEdit
	affected.stage = 2

/datum/surgery_step/mend_skull/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, damaging [target]'s face with \the [tool]!")  , \
		span_danger("Your hand slips, damaging [target]'s face with \the [tool]!"))
	user.balloon_alert_visible("Slips, damaging [target]'s face", "Your hand slips, damaging [target]'s face") // CHOMPEdit
	var/obj/item/organ/external/head/h = affected
	h.createwound(BRUISE, 10)
	h.disfigured = 1

///////////////////////////////////////////////////////////////
// Bone Fixing Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/finish_bone
	surgery_name = "Finish Mending Bone"
	allowed_tools = list(
		/obj/item/surgical/bonegel = 100
	)

	allowed_procs = list(IS_SCREWDRIVER = 75)

	can_infect = 1
	blood_level = 1

	min_duration = 30 //CHOMPedit
	max_duration = 30 //CHOMPedit

/datum/surgery_step/finish_bone/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && affected.open >= 2 && !(affected.robotic >= ORGAN_ROBOT) && affected.stage == 2

/datum/surgery_step/finish_bone/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] starts to finish mending the damaged bones in [target]'s [affected.name] with \the [tool]."), \
	span_notice("You start to finish mending the damaged bones in [target]'s [affected.name] with \the [tool]."))
	user.balloon_alert_visible("Begins mending damaged bones.", "Mending damaged bones.") // CHOMPEdit
	..()

/datum/surgery_step/finish_bone/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] has mended the damaged bones in [target]'s [affected.name] with \the [tool].")  , \
		span_notice("You have mended the damaged bones in [target]'s [affected.name] with \the [tool].") )
	user.balloon_alert_visible("Mends damaged bones.", "Mended damaged bones.") // CHOMPEdit
	affected.status &= ~ORGAN_BROKEN
	affected.stage = 0

/datum/surgery_step/finish_bone/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, smearing [tool] in the incision in [target]'s [affected.name]!") , \
	span_danger("Your hand slips, smearing [tool] in the incision in [target]'s [affected.name]!"))
	user.balloon_alert_visible("Slips, smearing [tool] in the incision.", "Your hand slips, smearing [tool].") // CHOMPEdit

///////////////////////////////////////////////////////////////
// Bone Clamp Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/clamp_bone
	surgery_name = "Clamp Bone"
	allowed_tools = list(
		/obj/item/surgical/bone_clamp = 100
		)

	can_infect = 1
	blood_level = 1

	min_duration = 45 //CHOMPedit
	max_duration = 55 //CHOMPedit

/datum/surgery_step/clamp_bone/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(coverage_check(user, target, affected, tool))
		return 0
	return affected && (affected.robotic < ORGAN_ROBOT) && affected.open >= 2 && affected.stage == 0

/datum/surgery_step/clamp_bone/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (affected.stage == 0)
		user.visible_message(span_notice("[user] starts repairing the damaged bones in [target]'s [affected.name] with \the [tool].") , \
		span_notice("You starts repairing the damaged bones in [target]'s [affected.name] with \the [tool]."))
		user.balloon_alert_visible("Begins repairing damaged bones.", "Repairing damaged bones.") // CHOMPEdit
	target.custom_pain("Something in your [affected.name] is causing you a lot of pain!", 50)
	..()

/datum/surgery_step/clamp_bone/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] sets the bone in [target]'s [affected.name] with \the [tool]."), \
		span_notice("You sets [target]'s bone in [affected.name] with \the [tool]."))
	user.balloon_alert_visible("Sets the bone back in.", "Bone set in.") // CHOMPEdit
	affected.status &= ~ORGAN_BROKEN

/datum/surgery_step/clamp_bone/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, damaging the bone in [target]'s [affected.name] with \the [tool]!") , \
		span_danger("Your hand slips, damaging the bone in [target]'s [affected.name] with \the [tool]!"))
	user.balloon_alert_visible("Slips, damaging [target]'s [affected.name]", "Your hand slips, damaging the bone.") // CHOMPEdit
	affected.createwound(BRUISE, 5)
