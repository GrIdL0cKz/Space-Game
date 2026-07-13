class_name Texts
## Every readable in the game: manuals, logs, briefs. Reading is content -
## some of these teach real procedures (the airlock manual is a tutorial
## wearing a lanyard), some carry the story, all of them carry the tone.

const DB := {
	"manual_airlock": {
		"title": "AIRLOCK OPERATIONS MANUAL - Rev. 11",
		"pages": [
			"SECTION 1: WHY THIS MANUAL EXISTS

An airlock is a machine for being in two places safely. Used correctly, it moves a crew member between pressure and vacuum. Used incorrectly, it moves them between alive and otherwise.

Read Section 3 before touching anything shiny.",
			"SECTION 3: CYCLING PROCEDURE (EGRESS)

1. EQUALISE - match chamber pressure to source side.
2. SEAL INNER DOOR - confirm indicator reads LOCKED.
3. PUMP DOWN - evacuate chamber atmosphere to reclaim tanks.
4. RELEASE OUTER DOOR.

The order matters. The order has always mattered. Rev. 11 of this manual exists because someone believed otherwise.",
			"SECTION 4: SUIT REQUIREMENTS

A full EVA ensemble comprises TORSO ASSEMBLY and HELMET, sealed. Skin is not an approved pressure vessel.

If you can feel a breeze inside the chamber during pump-down, you have made a sequencing error and, shortly, your last one.",
		],
	},
	"mission_brief": {
		"title": "MISSION BRIEF: SEEDBEARER",
		"pages": [
			"CLASSIFICATION: PUBLIC (it was in all the papers)

You are the sole waking crew complement of the colony vessel PERENNIAL, outbound to Kepler-442b. Transit time: 297 years. You will sleep for most of it. You are, and we say this with the greatest respect, cargo with a medical licence.",
			"PAYLOAD MANIFEST (ABBREVIATED)

- 512 cryopreserved human embryos (THE POINT OF ALL THIS)
- Automated gestation and rearing complex (Decks 2-3)
- Crew complement, hibernating: 6
- One (1) copy, complete works of humanity, compressed
- Emergency rations, 40 years (see note on optimism)",
			"IN THE EVENT OF AUTOMATED SYSTEMS FAILURE

The ship wakes whoever it can. If you are reading this, that is you. Restore the vessel, restore the course, deliver the payload.

Humanity is not coming to help. Humanity is 297 years behind you.

(That last sentence aged poorly. - Ed.)",
		],
	},
	"crew_log_medic": {
		"title": "MEDICAL LOG - DR. S. VASHCHENKO",
		"pages": [
			"Y122 D14

Woke for scheduled rotation. Ship reports all nominal. Spent my four weeks running diagnostics on five sleeping friends and talking to a coffee dispenser with a stutter. Recommend future missions include a dog.",
			"Y204 D02

Cryo bay 3 threw a fault during the night cycle. Fixed the coolant loop myself - two hours in the crawlspace with the wrench and some words I am not recording. The others sleep on. I have started narrating my movements aloud. The ship does not object.",
			"Y204 D06

The fault was not the coolant loop.

I have moved what I can to bays 1 and 2 and written up full notes for whoever wakes next. Whoever you are: it was quiet, and they were asleep, and it was nobody's fault. Not even yours. Fix the ship. Finish the trip.

The eggs are fine. Keep them that way.",
		],
	},
	"reprieve_captains_log": {
		"title": "CAPTAIN'S LOG - CSV REPRIEVE (RECOVERED)",
		"pages": [
			"D4,012

Eleven years of looking and there she is on the long scope, right where the projections said she had no business being. Target confirmed. I bought the ship's company a round of the good ration syrup. Approach begins tomorrow, dawn cycle.",
			"D4,013

I will write this plainly because someone will read it someday and deserve plainness.

We came in shedding velocity and her automation flinched - hard avoidance burn, no hail, no handshake. We clipped her stern. Their strike shed debris; our drives took it worse. Reprieve is dead in the water. So, apparently, is her bow watch. She never even woke up.",
			"D4,201

Six months of repairs that did not repair. The pods leave tomorrow - coordinates home are thirty years stale, but the pods know the way better than the ship does now.

We are leaving the lights on for her. Orders were orders, and I will not write them here where she might someday read them and feel about it the way I do.

- Cpt. A. Reyes, CSV Reprieve",
		],
	},
	"note_galley": {
		"title": "NOTE, TAPED TO THE GALLEY WALL",
		"pages": [
			"The dispenser marked COFFEE produces a liquid that is not coffee. The dispenser marked SOUP produces the coffee. Nobody fixed this in three hundred years because, and I quote the commissioning engineer, 'it works.'

- M.",
		],
	},
}

static func get_text(id: String) -> Dictionary:
	return DB.get(id, {"title": "UNREADABLE", "pages": ["The ink gave up before you got here."]})
