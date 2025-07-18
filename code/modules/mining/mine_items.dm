/******************************Lantern*******************************/

/obj/item/flashlight/lantern
	name = "lantern"
	icon_state = "lantern"
	desc = "A mining lantern."
	light_range = 6			// luminosity when on
	light_color = "FF9933" // A slight yellow/orange color.

/*****************************Pickaxe********************************/

/obj/item/pickaxe
	name = "pickaxe"
	desc = "A miner's best friend."
	icon = 'icons/obj/items.dmi'
	slot_flags = SLOT_BELT
	force = 15.0
	throwforce = 4.0
	icon_state = "pickaxe"
	item_state = "pickaxe"
	w_class = ITEMSIZE_LARGE
	matter = list(MAT_STEEL = 2500)
	var/digspeed = 36 //moving the delay to an item var so R&D can make improved picks. --NEO
	var/sand_dig = FALSE // does this thing dig sand?
	origin_tech = list(TECH_MATERIAL = 1)
	attack_verb = list("hit", "pierced", "sliced", "attacked")
	var/drill_sound = "pickaxe"
	var/drill_verb = "picking"
	sharp = TRUE

	var/excavation_amount = 200
	var/destroy_artefacts = FALSE // some mining tools will destroy artefacts completely while avoiding side-effects.
	var/borg_flags = COUNTS_AS_ROBOTIC_MELEE //The ONLY reason this gets this here is because pickaxes are SO hardcoded that it's easier to add it here than everywhere else. Please do not attach this to everything that you desire. Only VERY SPECIFIC THINGS under CERTAIN CIRCUMSTANCES, PLEASE. 99% of things can be added to code\modules\projectiles\guns\energy\cyborg.dm


/obj/item/pickaxe/silver
	name = "silver pickaxe"
	icon_state = "spickaxe"
	item_state = "spickaxe"
	digspeed = 27
	origin_tech = list(TECH_MATERIAL = 3)
	desc = "This makes no metallurgic sense."

/obj/item/pickaxe/gold
	name = "golden pickaxe"
	icon_state = "gpickaxe"
	item_state = "gpickaxe"
	digspeed = 18
	origin_tech = list(TECH_MATERIAL = 4)
	desc = "This makes no metallurgic sense."
	drill_verb = "picking"

/obj/item/pickaxe/diamond
	name = "diamond pickaxe"
	icon_state = "dpickaxe"
	item_state = "dpickaxe"
	digspeed = 9
	origin_tech = list(TECH_MATERIAL = 6, TECH_ENGINEERING = 4)
	desc = "A pickaxe with a diamond pick head."
	drill_verb = "picking"

/*****************************Drill********************************/

/obj/item/pickaxe/drill
	name = "mining drill" // Can dig sand as well!
	icon_state = "drill"
	item_state = "jackhammer"
	digspeed = 30 //Only slighty better than a pickaxe
	sand_dig = TRUE
	origin_tech = list(TECH_MATERIAL = 1, TECH_POWER = 2, TECH_ENGINEERING = 1)
	matter = list(MAT_STEEL = 3750)
	desc = "The most basic of mining drills, for short excavations and small mineral extractions."
	drill_verb = "drilling"

/obj/item/pickaxe/advdrill
	name = "advanced mining drill" // Can dig sand as well!
	icon_state = "advdrill"
	item_state = "jackhammer"
	digspeed = 27
	sand_dig = TRUE
	origin_tech = list(TECH_MATERIAL = 2, TECH_POWER = 3, TECH_ENGINEERING = 2)
	matter = list(MAT_STEEL = 4000, MAT_PLASTEEL = 2500)
	desc = "Yours is the drill that will pierce through the rock walls."
	drill_verb = "drilling"

/obj/item/pickaxe/diamonddrill //When people ask about the badass leader of the mining tools, they are talking about ME!
	name = "diamond mining drill"
	icon_state = "diamonddrill"
	item_state = "jackhammer"
	digspeed = 4 //Digs through walls, girders, and can dig up sand
	sand_dig = TRUE
	origin_tech = list(TECH_MATERIAL = 6, TECH_POWER = 4, TECH_ENGINEERING = 5)
	matter = list(MAT_STEEL = 4500, MAT_PLASTEEL = 3000, MAT_DIAMONDS = 1000)
	desc = "Yours is the drill that will pierce the heavens!"
	drill_verb = "drilling"

/obj/item/pickaxe/jackhammer
	name = "sonic jackhammer"
	icon_state = "jackhammer"
	item_state = "jackhammer"
	digspeed = 18 //faster than drill, but cannot dig
	origin_tech = list(TECH_MATERIAL = 3, TECH_POWER = 2, TECH_ENGINEERING = 2)
	desc = "Cracks rocks with sonic blasts, perfect for killing cave lizards."
	drill_verb = "hammering"
	destroy_artefacts = TRUE

/obj/item/pickaxe/borgdrill
	name = "jackhammer"
	icon_state = "borg_pick"
	item_state = "jackhammer"
	digspeed = 13
	sand_dig = TRUE
	desc = "Cracks rocks with a hardened pneumatic bit."
	drill_verb = "hammering"
	destroy_artefacts = TRUE

/obj/item/pickaxe/plasmacutter
	name = "plasma cutter"
	desc = "A rock cutter that uses bursts of hot plasma. You could use it to cut limbs off of xenos! Or, you know, mine stuff."
	icon_state = "plasmacutter"
	item_state = "plasmacutter"
	w_class = ITEMSIZE_NORMAL //it is smaller than the pickaxe
	damtype = "fire"
	digspeed = 18 //Can slice though normal walls, all girders, or be used in reinforced wall deconstruction/light thermite on fire
	origin_tech = list(TECH_MATERIAL = 4, TECH_PHORON = 3, TECH_ENGINEERING = 3)
	matter = list(MAT_STEEL = 3000, MAT_PLASTEEL = 1500, MAT_DIAMONDS = 500, MAT_PHORON = 500)
	drill_verb = "cutting"
	drill_sound = 'sound/items/Welder.ogg'
	sharp = TRUE
	edge = TRUE

/obj/item/pickaxe/plasmacutter/borg
	name = "mounted plasma cutter"
	icon_state = "pcutter_borg"

/*****************************Shovel********************************/

/obj/item/shovel
	name = "shovel"
	desc = "A large tool for digging and moving dirt. Alt click to switch modes."
	icon = 'icons/obj/items.dmi'
	icon_state = "shovel"
	item_state = "shovel"
	slot_flags = SLOT_BELT
	force = 8.0
	throwforce = 4.0
	w_class = ITEMSIZE_NORMAL
	origin_tech = list(TECH_MATERIAL = 1, TECH_ENGINEERING = 1)
	matter = list(MAT_STEEL = 50)
	attack_verb = list("bashed", "bludgeoned", "thrashed", "whacked")
	sharp = FALSE
	edge = TRUE
	var/digspeed = 40
	var/grave_mode = FALSE

/obj/item/shovel/AltClick(mob/user)
	grave_mode = !grave_mode
	to_chat(user, span_notice("You'll now dig [grave_mode ? "out graves" : "for loot"]."))
	. = ..()

/obj/item/shovel/wood
	icon_state = "whiteshovel"
	item_state = "whiteshovel"
	var/datum/material/material

/obj/item/shovel/wood/Initialize(mapload, var/_mat)
	. = ..()
	material = get_material_by_name(_mat)
	if(!istype(material))
		material = null
	else
		name = "[material.display_name] shovel"
		matter = list("[material.name]" = 50)
		update_icon()

/obj/item/shovel/wood/update_icon()
	. = ..()
	color = material ? material.icon_colour : initial(color)
	alpha = min(max(255 * material.opacity, 80), 255)

/obj/item/shovel/spade
	name = "spade"
	desc = "A small tool for digging and moving dirt."
	icon_state = "spade"
	item_state = "spade"
	force = 5.0
	throwforce = 7.0
	w_class = ITEMSIZE_SMALL

/obj/item/shovel/wood
	name = "wooden shovel"
	desc = "An improvised tool for digging and moving dirt."
	icon = 'icons/obj/items.dmi'
	icon_state = "woodshovel"
	slot_flags = SLOT_BELT
	item_state = "woodshovel"
	w_class = ITEMSIZE_NORMAL
	matter = list(MAT_WOOD = 50)
	sharp = 0
	edge = 1

// Flags.

/obj/item/stack/flag
	name = "flags"
	desc = "Some colourful flags."
	singular_name = "flag"
	amount = 10
	max_amount = 10
	icon = 'icons/obj/mining.dmi'
	var/upright = 0
	var/base_state

/obj/item/stack/flag/Initialize(mapload)
	. = ..()
	base_state = icon_state
	update_icon()

/obj/item/stack/flag/blue
	name = "blue flags"
	singular_name = "blue flag"
	icon_state = "blueflag"

/obj/item/stack/flag/red
	name = "red flags"
	singular_name = "red flag"
	icon_state = "redflag"

/obj/item/stack/flag/yellow
	name = "yellow flags"
	singular_name = "yellow flag"
	icon_state = "yellowflag"

/obj/item/stack/flag/green
	name = "green flags"
	singular_name = "green flag"
	icon_state = "greenflag"

/obj/item/stack/flag/attackby(obj/item/W as obj, mob/user as mob)
	if(upright && istype(W,src.type))
		src.attack_hand(user)
	else
		..()

/obj/item/stack/flag/attack_hand(user as mob)
	if(upright)
		upright = 0
		icon_state = base_state
		anchored = FALSE
		src.visible_message(span_infoplain(span_bold("[user]") + " knocks down [src]."))
	else
		..()

/obj/item/stack/flag/attack_self(mob/user as mob)

	var/obj/item/stack/flag/F = locate() in get_turf(src)

	var/turf/T = get_turf(src)
	if(!T || !ismineralturf(T))
		to_chat(user, "The flag won't stand up in this terrain.")
		return

	if(F && F.upright)
		to_chat(user, "There is already a flag here.")
		return

	var/obj/item/stack/flag/newflag = new src.type(T)
	newflag.amount = 1
	newflag.upright = 1
	newflag.anchored = TRUE
	newflag.name = newflag.singular_name
	newflag.icon_state = "[newflag.base_state]_open"
	newflag.visible_message(span_infoplain(span_bold("[user]") + " plants [newflag] firmly in the ground."))
	src.use(1)

// Lightpoles for lumber colony
/obj/item/stack/lightpole
	name = "Trailblazers"
	desc = "Some colourful trail lights."
	singular_name = "flag"
	amount = 10
	max_amount = 10
	icon = 'icons/obj/mining.dmi'
	var/upright = 0
	var/base_state
	var/on = 0
	var/brightness_on = 4 //luminosity when on

/obj/item/stack/lightpole/Initialize(mapload)
	. = ..()
	base_state = icon_state

/obj/item/stack/lightpole/blue
	name = "blue trail blazers"
	singular_name = "blue trail blazer"
	icon_state = "bluetrail_light"
	light_color = "#599DFF"

/obj/item/stack/lightpole/red
	name = "red flags"
	singular_name = "red trail blazer"
	icon_state = "redtrail_light"
	light_color = "#FC0F29"

/obj/item/stack/lightpole/attackby(obj/item/W as obj, mob/user as mob)
	if(upright && istype(W,src.type))
		src.attack_hand(user)
	else
		..()

/obj/item/stack/lightpole/attack_hand(user as mob)
	if(upright)
		upright = 0
		icon_state = base_state
		anchored = 0
		src.visible_message("<b>[user]</b> knocks down [src].")
	else
		..()

/obj/item/stack/lightpole/attack_self(mob/user as mob)

	var/obj/item/stack/lightpole/F = locate() in get_turf(src)

	var/turf/T = get_turf(src)
	if(!T || !istype(T,/turf/snow/snow2))
		user << "The flag won't stand up in this terrain."
		return

	if(F && F.upright)
		user << "There is already a flag here."
		return

	var/obj/item/stack/lightpole/newlightpole = new src.type(T)
	newlightpole.amount = 1
	newlightpole.upright = 1
	brightness_on = 2
	set_light(brightness_on)
	anchored = 1
	newlightpole.name = newlightpole.singular_name
	newlightpole.icon_state = "[newlightpole.base_state]_on"
	newlightpole.visible_message("<b>[user]</b> plants [newlightpole] firmly in the ground.")
	src.use(1)
