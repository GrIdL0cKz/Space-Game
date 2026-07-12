# Space Game — Design Document

*Vision captured 2026-04-28, ahead of indefinite parking until The Shape of Quiet and Keeping Up have shipped.*

## Concept

You are humanity's first interstellar pioneer. 300 years ago you boarded a sleeper ship carrying every preserved human embryo Earth had to send forward — the genetic seed of a future colony — and entered cryo for the long crossing to a new home.

You wake on the descent.

The ship is wrong. An asteroid field has hit it during the long sleep. Parts are missing. Engines are dead. The ship is drifting on momentum alone toward a planet you were supposed to land on with grace and engineering, not desperation.

You have to bring it back to life with your bare hands and land it.

When you finally land, scorched and exhausted, you step out of the hatch — and humans are already there, waiting for you.

In the 300 years you slept, mankind invented a new way of travel. They beat you here.

The world's first interstellar mission arrives last.

## Tone

Loneliness, irony, futility, and pioneering grit. The tension is mostly internal. The game ends with a punchline that recontextualises everything you just suffered through. Closer to *Wall-E*, *Moon*, and *Dead Space*'s isolation than space-opera shooters.

## Phase structure

The game is in four phases, each with distinct mechanics:

### Phase 1 — Interior (search & repair)
Side-scrolling exploration of the ship interior. Multi-floor, elevator-traversed. Search for missing components, find logs, piece together what happened during the long sleep.

### Phase 2 — Exterior / EVA (tether-and-boost) — *signature mechanic*
The ship is dead in space — drifting on momentum only. You leave the airlock, tether yourself to the hull, and physically push the ship by grabbing salvageable mass from asteroid debris and using it as reaction propellant. You become a human outboard motor for a corpse ship.

### Phase 3 — Combat (asteroid defence)
Targeting and shooting asteroids that threaten the hull or your tether line. Defensive shooter rather than aggressive; the threat is the environment, not enemies.

### Phase 4 — Landing (setpiece)
A complex, hand-flown landing procedure. Multi-step, demanding, the climax. Hand-flying re-pressurised systems through atmospheric entry while the ship strains to hold together.

### Epilogue
Hatch opens. Welcoming committee. The 300-year punchline lands. End credits.

## Current build state

Foundation exists from a Feb 2024 prototype phase by external contractor (rockgem) plus owner art assets. The codebase has been dormant for ~2 years.

**What works:**
- Astronaut character with keyboard (A/D + Space) and click/touch-to-move (Idle / Run / Jump animations)
- Multi-floor ship interior with elevator system (open/close, floor-select panel, teleport between decks)
- Ambient lamp with random flicker (10–20s intervals)
- Inventory popup scaffolding (items file with placeholder Ore + Stardust, no textures yet)
- Parallax space background scripts (`SpaceBg.gd`, `BG.gd`, `ParallaxBackground.gd`)
- Custom astronaut mouse cursor
- Dialogic dialogue addon installed but not wired to story content

**Engine:** Godot 4.2, GL Compatibility renderer (low-spec friendly).

**Known issues:**
- Elevator input feels slow / sticky on tap

## Gap between prototype and vision

| System | Status |
|---|---|
| Phase 1 — Interior movement | ~30% — foundation built, content empty |
| Phase 2 — EVA tether & boost | 0% — not started; this is the signature mechanic |
| Phase 3 — Asteroid combat | 0% |
| Phase 4 — Landing setpiece | 0% |
| Story / Dialogic content | 0% |
| Inventory population (parts, components) | scaffolding only |
| Repair minigames or part-fitting | 0% |
| Sound design / ambient audio | 0% |
| Art beyond placeholders | 0% — `craft interior.xcf` GIMP source exists |

Realistic estimate: 10–15% of the game's scope is built. The 85% remaining contains everything that makes the game distinctive.

## Recommended build order when picked up

1. **Vertical-slice the EVA tether-and-boost mechanic** in isolation, in a black void. Most distinctive, riskiest feel-test. If it's not fun, the project isn't worth doing as designed. If it is, the spine is validated.
2. Extend the interior phase with actual interactables, repair points, and Dialogic-driven story beats
3. Asteroid combat layer
4. Landing sequence as a self-contained setpiece
5. Wire all four phases together with story scaffolding
6. Final polish + ending

## Risks worth noting

- **Multi-genre scope.** Platforming + EVA physics + shooter + puzzle + narrative is the riskiest indie shape. Burnout at the join-points is the typical failure mode.
- **EVA mechanic is unproven.** Until it's prototyped, it's unknown whether the core idea actually feels good to play.
- **Solo workload.** Story, art, code, sound across four phases is a lot for one person. Re-engaging the contractor (or another) for systems work is plausible if the vertical slice proves the concept.

## Status

**Parked** as of 2026-04-28. Project order:
1. Ship **The Shape of Quiet**
2. Ship **Keeping Up** (currently blocked on artwork)
3. Pick up **Space Game**, starting with the EVA vertical slice


## Bones build — 2026-07-12 overnight

The skeleton now exists (commits `80e6176` → `07e4ba5`). Story refinement from Rob's brief: the automation stops SHORT of the destination (not "wake on descent"); ~512 embryos; crew dead, not horror; the wormhole punchline unchanged.

**Playable now:** interaction system (E + click-to-walk-and-use, floating prompts), backpack with examine/wear/read/use, unlimited labelled saves + silent checkpoints before lethal choices, Space Quest death cards, the reader (manuals/logs/briefs carry both tutorials and story), the ship-computer companion's first lines, five rooms off Rob's hull (science lab behind a keycard, viewing deck with the destination in the window, cockpit, fighter bay, aft airlock), the crawlspace via hatches, five minigames (attic wiring → lab power, sample scanner, course plotting, the airlock sequence — wrong order kills, the manual teaches it — and the two-of-three breaker board), the full airlock/EVA loop (suit rules enforced, salvage outside, total silence in vacuum, TSHHHH on re-entry), and `scenes/eva/tether_test.tscn` — the signature tether prototype: elastic line, reel, grab, throw-for-reaction.

**The audio rule is law:** no music anywhere; every sound synthesised placeholder is diegetic and replaceable file-for-file in `assets/sfx/`.

**Not built, by design:** the dogfight (the fighter has a seat and an excuse), the lander/planet phase (a door that doesn't open), story completion, real foley, Dialogic removal (installed but dormant; the custom reader + computer lines replaced it).
