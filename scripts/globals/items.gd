class_name Items
## The item catalogue. Everything the backpack can hold lives here: what it
## is, what examining it says (dry wit encouraged), and what it can do.
## kind: "equip" (suit pieces), "use" (consumed or toggled), "read" (opens
## the reader via text_id), "material" (salvage and parts), "key" (access).

const DB := {
	"suit_torso": {
		"name": "Pressure Suit",
		"kind": "equip",
		"desc": "EVA-rated pressure suit, size M. The previous owner has no further use for it, which is both convenient and best not dwelt on.",
	},
	"suit_helmet": {
		"name": "Suit Helmet",
		"kind": "equip",
		"desc": "The transparent part is called a visor. The manual is very insistent that the helmet be attached BEFORE depressurisation.",
	},
	"wrench": {
		"name": "Torque Wrench",
		"kind": "use",
		"desc": "Calibrated to exactly the torque you are going to ignore and just do up as tight as it goes.",
	},
	"duct_tape": {
		"name": "Duct Tape",
		"kind": "use",
		"desc": "Three hundred years of materials science, and the answer is still duct tape.",
	},
	"fuse": {
		"name": "Ceramic Fuse",
		"kind": "material",
		"desc": "Rated 40A. Slightly scorched. Somewhere on this ship is a socket that misses it terribly.",
	},
	"wire_coil": {
		"name": "Wire Coil",
		"kind": "material",
		"desc": "Copper, insulated, tangled beyond the reach of conventional physics.",
	},
	"power_cell": {
		"name": "Power Cell",
		"kind": "material",
		"desc": "Holds a charge the way you hold a grudge: imperfectly, but for a surprisingly long time.",
	},
	"scrap_metal": {
		"name": "Hull Scrap",
		"kind": "material",
		"desc": "A piece of the ship that decided to explore space independently. Retrieved.",
	},
	"sample_rock": {
		"name": "Unidentified Fragment",
		"kind": "material",
		"desc": "Rock? Debris? Ancient alien artefact? The lab scanner has opinions; you have a rock.",
	},
	"keycard_lab": {
		"name": "Science Lab Keycard",
		"kind": "key",
		"desc": "Property of Dr. E. Okonkwo, Mission Science Officer. The photo shows someone who trusted this journey more than it deserved.",
	},
	"protein_bar": {
		"name": "Protein Bar",
		"kind": "use",
		"desc": "Best before: two hundred and seventy-one years ago. The wrapper says 'NOW TASTIER'. Than what, it does not say.",
	},
	"manual_airlock": {
		"name": "Airlock Operations Manual",
		"kind": "read",
		"text_id": "manual_airlock",
		"desc": "Laminated, ring-bound, and written by someone who had clearly met users before.",
	},
	"mission_brief": {
		"name": "Mission Brief: SEEDBEARER",
		"kind": "read",
		"text_id": "mission_brief",
		"desc": "Your job, in writing. Five hundred and twelve reasons in cold storage to get this right.",
	},
	"crew_log_medic": {
		"name": "Medical Officer's Log",
		"kind": "read",
		"text_id": "crew_log_medic",
		"desc": "The handwriting deteriorates toward the end. You have not read it twice.",
	},
}

static func get_def(id: String) -> Dictionary:
	return DB.get(id, {})

static func display_name(id: String) -> String:
	return String(DB.get(id, {}).get("name", id))
