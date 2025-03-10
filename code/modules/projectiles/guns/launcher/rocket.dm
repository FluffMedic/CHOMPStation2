/obj/item/gun/launcher/rocket
	name = "rocket launcher"
	desc = "MAGGOT."
	icon_state = "rocket"
	item_state = "rocket"
	w_class = ITEMSIZE_HUGE //CHOMP Edit.
	throw_speed = 2
	throw_range = 10
	force = 5.0
	slot_flags = 0
	origin_tech = list(TECH_COMBAT = 8, TECH_MATERIAL = 5)
	fire_sound = 'sound/weapons/rpg.ogg'

	release_force = 15
	throw_distance = 30
	var/max_rockets = 1
	var/list/rockets = new/list()

/obj/item/gun/launcher/rocket/examine(mob/user)
	. = ..()
	if(get_dist(user, src) <= 2)
		. += span_blue("[rockets.len] / [max_rockets] rockets.")

/obj/item/gun/launcher/rocket/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/ammo_casing/rocket))
		if(rockets.len < max_rockets)
			user.drop_item()
			I.loc = src
			rockets += I
			to_chat(user, span_blue("You put the rocket in [src]."))
			to_chat(user, span_blue("[rockets.len] / [max_rockets] rockets."))
		else
			to_chat(user, span_red(">[src] cannot hold more rockets."))

/obj/item/gun/launcher/rocket/consume_next_projectile()
	if(rockets.len)
		var/obj/item/ammo_casing/rocket/I = rockets[1]
		rockets -= I
		return new I.projectile_type(src)
	return null

/obj/item/gun/launcher/rocket/handle_post_fire(mob/user, atom/target)
	message_admins("[key_name_admin(user)] fired a rocket from a rocket launcher ([src.name]) at [target].")
	log_game("[key_name_admin(user)] used a rocket launcher ([src.name]) at [target].")
	..()
