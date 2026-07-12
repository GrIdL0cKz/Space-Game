class_name Minigames
## The five hands-on jobs, all code-built Controls hosted by Hud.open_modal.
## Shared visual language: dark panel, pale ink, amber warnings. Each game
## is diegetic - you are operating the ship, not playing a pop-up.

const INK := Color(0.80, 0.88, 0.93)
const DIM := Color(0.55, 0.63, 0.70)
const PANEL := Color(0.07, 0.086, 0.118, 0.98)
const EDGE := Color(0.35, 0.45, 0.52)
const ACCENT := Color(0.47, 0.78, 0.90)
const WARN := Color(1.0, 0.74, 0.31)
const GOOD := Color(0.45, 0.75, 0.5)
const BAD := Color(0.85, 0.35, 0.3)

const WIRE_COLOURS := [Color(0.85, 0.3, 0.3), Color(0.35, 0.7, 0.4), Color(0.35, 0.55, 0.9), Color(0.9, 0.75, 0.3)]

static func _shell(title: String, size: Vector2) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = size
	panel.position = Vector2(1920, 1080) / 2.0 - size / 2.0
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", ACCENT)
	v.add_child(t)
	return {"root": root, "v": v}

static func _label(text: String, size: int, col: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

# =============================================================== 1. WIRING
# The attic junction box: match wire pairs by colour, left bank to right
# bank. Order scrambles every attempt; a wrong match sparks and resets.
# Completing it powers the science lab.

static func open_wiring() -> void:
	var ui := _shell("JUNCTION BOX 7C - DECK POWER", Vector2(820, 560))
	var v: VBoxContainer = ui["v"]
	v.add_child(_label("Four circuits, severed. Match live end to lab end. The colours survived the damage; the labels did not.", 20, DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 60)
	v.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	row.add_child(left)
	var status := _label("", 22, WARN)
	row.add_child(status)
	row.add_child(right)
	var picked: Array = [-1]
	var solved: Array = []
	var left_order := [0, 1, 2, 3]
	var right_order := [0, 1, 2, 3]
	left_order.shuffle()
	right_order.shuffle()
	var right_btns: Array = []
	for i in 4:
		var li: int = left_order[i]
		var lb := _button("LIVE " + "ABCD"[i], func():
			picked[0] = li
			status.text = "Live wire in hand. Choose its other half."
			Sd.play(&"switch_click", -8.0))
		lb.add_theme_color_override("font_color", WIRE_COLOURS[li])
		left.add_child(lb)
	for i in 4:
		var ri: int = right_order[i]
		var rb := _button("LAB " + "WXYZ"[i], func():
			if picked[0] == -1:
				status.text = "Pick a live end first."
				return
			if picked[0] == ri and not solved.has(ri):
				solved.append(ri)
				Sd.play(&"wire_connect")
				status.text = "%d / 4 spliced." % solved.size()
				picked[0] = -1
				if solved.size() == 4:
					GameState.set_flag("powered_lab_wiring")
					GameState.set_flag("powered_lab")
					Hud.close_modal()
					Sd.play(&"breaker_thunk")
					Hud.toast("Deck power restored to the science lab.")
					Hud.computer_say("Lab circuit is live. The scanner is asking for samples like nothing happened.")
			else:
				Sd.play(&"wire_spark")
				solved.clear()
				picked[0] = -1
				status.text = "SPARK. Wrong pair. Your fingertips file a complaint. Starting over."
			)
		rb.add_theme_color_override("font_color", WIRE_COLOURS[ri])
		right.add_child(rb)
		right_btns.append(rb)
	v.add_child(_button("Step away", func(): Hud.close_modal()))
	Hud.open_modal(ui["root"])

# ========================================================== 2. LAB SCANNER
# Feed the scanner anything analysable from the backpack; it identifies the
# sample and, for story items, says something worth hearing.

const SCAN_RESULTS := {
	"sample_rock": "Composition: nickel-iron, trace iridium. Verdict: asteroid shrapnel, the same family that hit the ship. It travelled further than you did to be here.",
	"scrap_metal": "Composition: hull alloy, YOUR hull alloy. The scanner suggests, dryly, putting it back where it came from.",
	"fuse": "A fuse. Working. The scanner resents being used as a continuity tester.",
	"protein_bar": "Analysis: 4% protein, 96% commitment. Edible in the way that decisions are reversible.",
	"power_cell": "Charge at 61%. Chemistry stable. Would very much like to be inside a machine again.",
}

static func open_lab_scanner() -> void:
	var ui := _shell("SAMPLE SCANNER", Vector2(760, 560))
	var v: VBoxContainer = ui["v"]
	v.add_child(_label("Place a sample on the tray.", 20, DIM))
	var result := _label("", 21, INK)
	result.custom_minimum_size = Vector2(680, 160)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	v.add_child(list)
	v.add_child(result)
	var candidates: Array = []
	for id in GameState.inventory.keys():
		if SCAN_RESULTS.has(id):
			candidates.append(id)
	if candidates.is_empty():
		list.add_child(_label("(nothing in the backpack survives scrutiny - find samples to analyse)", 19, DIM))
	for id in candidates:
		list.add_child(_button("Scan: %s" % Items.display_name(String(id)), func():
			result.text = "..."
			Sd.play(&"scanner_sweep")
			var tw: Tween = result.create_tween()
			tw.tween_interval(1.2)
			tw.tween_callback(func():
				Sd.play(&"scanner_done")
				result.text = String(SCAN_RESULTS[id])
				GameState.set_flag("scanned_" + String(id))
				if String(id) == "sample_rock":
					GameState.set_flag("rock_analysed")
					Hud.computer_say("Logging that fragment. If more of those are inbound, I would like the fighter fuelled. Just noting it.")
			)))
	v.add_child(_button("Done", func(): Hud.close_modal()))
	Hud.open_modal(ui["root"])

# ========================================================= 3. COURSE PLOT
# Align the heading against the star chart: nudge the marker onto the
# target while it drifts. Hold inside tolerance to lock.

static func open_course_plot() -> void:
	var ui := _shell("NAVIGATION - MANUAL HEADING", Vector2(860, 620))
	var v: VBoxContainer = ui["v"]
	v.add_child(_label("Bring the heading marker onto the target star and hold it there while the gyros settle. The ship drifts; so will your marker.", 20, DIM))
	var plot := CoursePlot.new()
	plot.custom_minimum_size = Vector2(780, 360)
	v.add_child(plot)
	var hint := _label("A / D to trim. Hold steady.", 20, WARN)
	v.add_child(hint)
	plot.locked.connect(func():
		GameState.set_flag("course_plotted")
		Hud.close_modal()
		Sd.play(&"breaker_thunk")
		Hud.toast("Heading locked: Kepler-442b, resumed.")
		Hud.computer_say("Course corrected. For the record: two hundred ninety-seven years of automation, undone by one impact - and redone by a person with a headache. Well flown.")
	)
	v.add_child(_button("Abort", func(): Hud.close_modal()))
	Hud.open_modal(ui["root"])

class CoursePlot extends Control:
	signal locked
	var marker := -220.0
	var drift := 40.0
	var hold := 0.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		drift = sin(t * 0.7) * 55.0 + sin(t * 1.9) * 25.0
		var trim := Input.get_axis("move_left", "move_right")
		marker += (trim * 180.0 + drift * 0.35) * delta
		marker = clampf(marker, -360.0, 360.0)
		if absf(marker) < 18.0:
			hold += delta
			if hold >= 2.5:
				set_process(false)
				locked.emit()
		else:
			hold = maxf(0.0, hold - delta * 2.0)
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.1))
		var rnd := RandomNumberGenerator.new()
		rnd.seed = 3
		for i in 40:
			draw_circle(Vector2(rnd.randf_range(10, size.x - 10), rnd.randf_range(10, size.y - 10)), 1.5, Color(0.8, 0.85, 0.9, 0.5))
		# target star + tolerance ring
		draw_circle(c, 6.0, Color(0.95, 0.9, 0.6))
		draw_arc(c, 20.0, 0, TAU, 40, Minigames.GOOD if hold > 0.0 else Minigames.DIM, 2.0)
		# heading marker
		var mpos := c + Vector2(marker, 0)
		draw_line(mpos + Vector2(0, -26), mpos + Vector2(0, 26), Minigames.ACCENT, 3.0)
		draw_line(mpos + Vector2(-12, 0), mpos + Vector2(12, 0), Minigames.ACCENT, 3.0)
		# hold progress
		if hold > 0.0:
			draw_rect(Rect2(10, size.y - 22, (size.x - 20) * (hold / 2.5), 10), Minigames.GOOD)

# ==================================================== 4. AIRLOCK SEQUENCE
# Four controls, one correct order, taught by the manual. A wrong order is
# not a fail state; it is a death state. The checkpoint was written before
# this panel opened.

const AIRLOCK_ORDER := ["EQUALISE", "SEAL INNER DOOR", "PUMP DOWN", "RELEASE OUTER LOCK"]

static func open_airlock_sequence() -> void:
	var ui := _shell("AIRLOCK CYCLE - MANUAL CONTROL", Vector2(760, 560))
	var v: VBoxContainer = ui["v"]
	v.add_child(_label("Chamber controls. The manual had opinions about the order. Hopefully somebody read it.", 20, DIM))
	var status := _label("Awaiting first input.", 22, WARN)
	var progress: Array = [0]
	var buttons := [AIRLOCK_ORDER[2], AIRLOCK_ORDER[0], AIRLOCK_ORDER[3], AIRLOCK_ORDER[1]]
	for b_text in buttons:
		v.add_child(_button(String(b_text), func():
			Sd.play(&"valve_turn")
			if String(b_text) == AIRLOCK_ORDER[progress[0]]:
				progress[0] += 1
				status.text = "%s: confirmed. (%d/4)" % [b_text, progress[0]]
				if progress[0] == 4:
					GameState.set_flag("airlock_cycled")
					Hud.close_modal()
					Sd.play(&"airlock_hiss")
					Hud.toast("Chamber at vacuum. Outer door released. The silence outside is total.")
			else:
				Hud.close_modal()
				match String(b_text):
					"RELEASE OUTER LOCK":
						Death.die("PREMATURE EXIT",
							"You released the outer lock of a pressurised chamber. The chamber, the paperwork, and you all left together.")
					"PUMP DOWN":
						Death.die("THOROUGHLY VENTILATED",
							"You pumped the chamber down with the inner door still live. The ship kept its air. You were less careful with yours.")
					_:
						Death.die("PROCEDURAL IRREGULARITY",
							"The airlock did something loud and final that Rev. 12 of the manual will describe in detail.")
			))
	v.add_child(status)
	v.add_child(_button("Step back", func(): Hud.close_modal()))
	Hud.open_modal(ui["root"])

# ====================================================== 5. POWER ROUTING
# The breaker board: the generator carries two of three circuits. What you
# leave dark stays dark - rooms notice.

static func open_power_routing() -> void:
	var ui := _shell("MAIN BREAKER BOARD", Vector2(760, 540))
	var v: VBoxContainer = ui["v"]
	v.add_child(_label("Generator output holds TWO circuits. The third stays dark until you choose otherwise. Choose otherwise any time.", 20, DIM))
	var circuits := [
		["powered_lab", "SCIENCE LAB"],
		["powered_viewing", "VIEWING DECK LIGHTS"],
		["powered_fighter", "FIGHTER BAY CHARGERS"],
	]
	var labels: Array = []
	for i in circuits.size():
		var flag_name: String = circuits[i][0]
		var b := _button("", func():
			var currently := bool(GameState.get_flag(flag_name))
			if currently:
				GameState.set_flag(flag_name, false)
				Sd.play(&"breaker_thunk", -4.0, 0.8)
			else:
				var live := 0
				for c in circuits:
					if bool(GameState.get_flag(String(c[0]))):
						live += 1
				if live >= 2:
					Sd.play(&"switch_click", -8.0, 0.6)
					Hud.toast("The generator declines. Two circuits is the deal.")
					return
				GameState.set_flag(flag_name, true)
				Sd.play(&"breaker_thunk")
			refresh_call(labels, circuits))
		labels.append(b)
		v.add_child(b)
	refresh_call(labels, circuits)
	# note: wiring job is a prerequisite for the lab circuit to matter
	v.add_child(_label("Note: the lab circuit also needs the deck junction spliced (crawlspace).", 17, DIM))
	v.add_child(_button("Done", func(): Hud.close_modal()))
	Hud.open_modal(ui["root"])

static func refresh_call(labels: Array, circuits: Array) -> void:
	for i in circuits.size():
		var on := bool(GameState.get_flag(String(circuits[i][0])))
		var lbl: Button = labels[i]
		lbl.text = "%s  [%s]" % [circuits[i][1], "LIVE" if on else "dark"]
		lbl.add_theme_color_override("font_color", GOOD if on else DIM)
