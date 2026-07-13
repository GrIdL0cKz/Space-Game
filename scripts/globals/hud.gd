extends CanvasLayer
## The whole in-game interface, built in code: toast strip, suit indicator,
## backpack, the reader, the ship-computer line box, pause with labelled
## save/load, and a modal host for minigames. One modal at a time; modals
## pause the world. Hidden entirely outside gameplay scenes (group "world").

const INK := Color(0.80, 0.88, 0.93)
const DIM := Color(0.55, 0.63, 0.70)
const PANEL := Color(0.07, 0.086, 0.118, 0.97)
const PANEL_EDGE := Color(0.35, 0.45, 0.52)
const ACCENT := Color(0.47, 0.78, 0.90)
const WARN := Color(1.0, 0.74, 0.31)

var toast_label: Label
var prompt_line: Label
var toast_queue: Array[String] = []
var toast_busy: bool = false

var suit_panel: PanelContainer
var suit_label: Label

var inv_panel: PanelContainer
var inv_grid: GridContainer
var inv_big_icon: TextureRect
var inv_name: Label
var inv_desc: Label
var inv_use_btn: Button
var inv_selected: String = ""

var reader_panel: PanelContainer
var reader_title: Label
var reader_body: RichTextLabel
var reader_page_label: Label
var reader_pages: Array = []
var reader_page: int = 0

var computer_box: PanelContainer
var computer_label: Label
var computer_queue: Array[String] = []
var computer_typing: bool = false

var pause_panel: PanelContainer
var save_panel: PanelContainer
var save_line: LineEdit
var save_list_box: VBoxContainer
var load_panel: PanelContainer
var load_list_box: VBoxContainer

var modal: Control = null

func _ready() -> void:
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	_build_toast()
	_build_suit_indicator()
	_build_inventory()
	_build_reader()
	_build_computer_box()
	_build_pause()
	_build_save_panel()
	_build_load_panel()
	_build_hotbar()
	_build_objective()
	GameState.suit_changed.connect(_refresh_suit_indicator)
	GameState.suit_changed.connect(_refresh_hotbar)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.inventory_changed.connect(_refresh_objective)
	GameState.flags_changed.connect(_refresh_objective)
	_refresh_suit_indicator()
	_refresh_objective()

func _in_world() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("world")

var _retch_timer: float = 12.0

func _process(_delta: float) -> void:
	# The load panel is also the main menu's Load Game screen, so the layer
	# stays alive for it outside gameplay scenes.
	visible = _in_world() or load_panel.visible
	# Cryosickness: the first while awake, the body disagrees with having
	# been thawed. Passes on its own, with commentary.
	if visible and not get_tree().paused:
		var left := int(GameState.get_flag("cryosick", 0))
		if left > 0:
			_retch_timer -= _delta
			if _retch_timer <= 0.0:
				_retch(left)

func _retch(left: int) -> void:
	_retch_timer = randf_range(20.0, 28.0)
	var p: Node = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	p.controls_locked = true
	Sd.play(&"eat", -4.0, 0.55)
	toast("Your stomach convulses and you are briefly, violently reacquainted with nutrient gel. Cryosickness. 'Mild', said the brochure.")
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(func():
		if is_instance_valid(p):
			p.controls_locked = false
		GameState.set_flag("cryosick", left - 1)
		if left - 1 <= 0:
			toast("Your stomach files one final complaint, then settles. You decide to call that recovery."))

func any_overlay_open() -> bool:
	return inv_panel.visible or reader_panel.visible or pause_panel.visible \
			or save_panel.visible or load_panel.visible or modal != null

func _unhandled_input(event: InputEvent) -> void:
	if not _in_world():
		return
	# The computer has the floor: clicks and E turn its pages, nothing else.
	if computer_active() and not any_overlay_open():
		var clicked: bool = event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT
		if clicked or event.is_action_pressed("interact"):
			computer_advance()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and not any_overlay_open():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_hotbar_key(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("inventory") and not (reader_panel.visible or pause_panel.visible or save_panel.visible or load_panel.visible or modal != null):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if modal != null:
			close_modal()
		elif reader_panel.visible:
			_close_reader()
		elif inv_panel.visible:
			_toggle_inventory()
		elif save_panel.visible or load_panel.visible:
			save_panel.visible = false
			load_panel.visible = false
			pause_panel.visible = true
		elif pause_panel.visible:
			_unpause()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------ helpers

func _panel(size: Vector2, centre := true) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = PANEL_EDGE
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	p.add_theme_stylebox_override("panel", style)
	p.custom_minimum_size = size
	if centre:
		p.position = Vector2(1920, 1080) / 2.0 - size / 2.0
	p.visible = false
	add_child(p)
	return p

func _label(text: String, size: int, col: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b

# ------------------------------------------------------------------ toast

func _build_toast() -> void:
	toast_label = _label("", 24)
	# Sits clear of the hotbar (y1004), the prompt line (y948) and the
	# bottom-anchored computer box (grows up from y990, left side).
	toast_label.position = Vector2(0, 744)
	toast_label.size = Vector2(1920, 40)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	toast_label.add_theme_constant_override("outline_size", 6)
	toast_label.modulate.a = 0.0
	add_child(toast_label)
	# The interaction prompt: one line above the hotbar, room for detail.
	prompt_line = _label("", 22)
	prompt_line.position = Vector2(0, 948)
	prompt_line.size = Vector2(1920, 36)
	prompt_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_line.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	prompt_line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_line.add_theme_constant_override("outline_size", 5)
	add_child(prompt_line)

func set_prompt(text: String) -> void:
	if prompt_line != null:
		prompt_line.text = text

var _toast_tween: Tween = null

func toast(text: String) -> void:
	# The newest line wins immediately: a fresh interaction clears whatever
	# was still fading, so re-pressing E always re-shows the text.
	toast_queue = [text]
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_busy = false
	_next_toast()

func _next_toast() -> void:
	if toast_queue.is_empty():
		toast_busy = false
		return
	toast_busy = true
	toast_label.text = toast_queue.pop_front()
	# Long lines earn long holds; nobody speed-reads a captain's epitaph.
	var hold := clampf(1.2 + toast_label.text.length() * 0.05, 2.0, 8.0)
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(hold)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_next_toast)

# ------------------------------------------------------------- objective
## SOLACE's standing directive, top-left: what the ship thinks you should
## be doing. Derived from flags, so it always matches reality, and the
## story beats (debris alert, getting under way) fire off the same watch.

var objective_label: Label

func _build_objective() -> void:
	objective_label = _label("", 18, DIM)
	objective_label.position = Vector2(24, 16)
	objective_label.size = Vector2(1200, 30)
	objective_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	objective_label.add_theme_constant_override("outline_size", 5)
	add_child(objective_label)

func _refresh_objective() -> void:
	if objective_label == null:
		return
	objective_label.text = _current_objective()
	_story_beats()

func _current_objective() -> String:
	var f := func(k: String) -> bool: return bool(GameState.get_flag(k))
	if not f.call("woke_up"):
		return ""
	if not f.call("solace_online"):
		if GameState.has_item("fuse"):
			return "▶ Seat the spare fuse in the AI core rack (Cockpit, Deck 3)"
		return "▶ Find a spare fuse for the AI core (stores crate, Deck 1)"
	if not f.call("visited_derelict"):
		return "▶ Take the lander (Deck 2) to the object holding station off the bow"
	if not f.call("read_reprieve_log"):
		return "▶ Search the Reprieve - the captain's log terminal is aft"
	if not f.call("derelict_debriefed"):
		return "▶ Fly home. SOLACE wants to hear about it"
	if not f.call("course_plotted"):
		return "▶ Plot the course at the nav console (Cockpit)"
	if not f.call("debris_cleared"):
		if not f.call("powered_fighter"):
			return "▶ Debris ahead - route power to the bay chargers (breaker board, Fighter Bay)"
		if not f.call("rock_analysed"):
			return "▶ Debris ahead - scan a debris fragment in the Science Lab so targeting knows rock from ship"
		return "▶ Clear the debris field in the P-1 (Fighter Bay)"
	return "▶ Under way. Next stop: the depot moon, for coolant"

func _story_beats() -> void:
	if bool(GameState.get_flag("course_plotted")) and not bool(GameState.get_flag("debris_alerted")):
		GameState.set_flag("debris_alerted")
		computer_say("Course locked. One complication: the avoidance manoeuvre parked us in our own debris shadow. Anomalies ahead, on the route, moving the way we want to move.")
		computer_say("I will not fly us through that. The P-1 can clear it. I can only watch, loudly.")
	if bool(GameState.get_flag("debris_cleared")) and not bool(GameState.get_flag("underway_said")):
		GameState.set_flag("underway_said")
		computer_say("Route clear. Spinning the drive up... feel that? That is the floor humming with purpose again. Depot moon first, for coolant. Then Kepler.")

# ------------------------------------------------------------- suit status

func _build_suit_indicator() -> void:
	suit_panel = _panel(Vector2(230, 66), false)
	suit_panel.position = Vector2(1660, 20)
	suit_label = _label("", 20)
	suit_panel.add_child(suit_label)

func _refresh_suit_indicator() -> void:
	var bits: Array[String] = []
	bits.append("SUIT " + ("ON" if GameState.is_equipped("suit_torso") else "--"))
	bits.append("HELM " + ("ON" if GameState.is_equipped("suit_helmet") else "--"))
	suit_label.text = "  ".join(bits)
	suit_label.add_theme_color_override("font_color", ACCENT if GameState.eva_safe() else DIM)
	suit_panel.visible = GameState.has_item("suit_torso") or GameState.has_item("suit_helmet") \
			or GameState.is_equipped("suit_torso") or GameState.is_equipped("suit_helmet")

# ------------------------------------------------------------- inventory

const ICON_DIR := "res://assets/icons"

func _icon(id: String) -> Texture2D:
	var path := "%s/%s.png" % [ICON_DIR, id]
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _build_inventory() -> void:
	inv_panel = _panel(Vector2(980, 620))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	inv_panel.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(500, 0)
	row.add_child(left)
	left.add_child(_label("BACKPACK", 30, ACCENT))
	inv_grid = GridContainer.new()
	inv_grid.columns = 5
	inv_grid.add_theme_constant_override("h_separation", 12)
	inv_grid.add_theme_constant_override("v_separation", 12)
	left.add_child(inv_grid)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(400, 0)
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	inv_big_icon = TextureRect.new()
	inv_big_icon.custom_minimum_size = Vector2(96, 96)
	inv_big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inv_big_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right.add_child(inv_big_icon)
	inv_name = _label("", 26, INK)
	right.add_child(inv_name)
	inv_desc = _label("", 20, DIM)
	inv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_desc.custom_minimum_size = Vector2(400, 200)
	inv_desc.size_flags_vertical = Control.SIZE_FILL
	right.add_child(inv_desc)
	inv_use_btn = _button("USE", _on_inv_use)
	inv_use_btn.visible = false
	right.add_child(inv_use_btn)

func _toggle_inventory() -> void:
	inv_panel.visible = not inv_panel.visible
	get_tree().paused = inv_panel.visible
	if inv_panel.visible:
		Sd.play(&"switch_click", -8.0)
		_refresh_inventory()

func _slot_button(id: String, count: int) -> Button:
	var b := InvSlotButton.new()
	b.item_id = id
	b.custom_minimum_size = Vector2(84, 84)
	b.pressed.connect(_on_inv_select.bind(id))
	var tex := TextureRect.new()
	tex.texture = _icon(id)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.offset_left = 8
	tex.offset_top = 8
	tex.offset_right = -8
	tex.offset_bottom = -8
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tex)
	if count > 1:
		var badge := Label.new()
		badge.text = "x%d" % count
		badge.add_theme_font_size_override("font_size", 15)
		badge.add_theme_color_override("font_color", INK)
		badge.position = Vector2(52, 60)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(badge)
	if id in ["suit_torso", "suit_helmet"] and GameState.is_equipped(id):
		var worn := Label.new()
		worn.text = "WORN"
		worn.add_theme_font_size_override("font_size", 12)
		worn.add_theme_color_override("font_color", ACCENT)
		worn.position = Vector2(6, 2)
		worn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(worn)
	b.tooltip_text = Items.display_name(id)
	return b

func _refresh_inventory() -> void:
	_refresh_hotbar()
	if not inv_panel.visible:
		return
	for c in inv_grid.get_children():
		c.queue_free()
	var ids: Array = GameState.inventory.keys()
	ids.sort()
	for id in ids:
		inv_grid.add_child(_slot_button(String(id), int(GameState.inventory[id])))
	if ids.is_empty():
		inv_grid.add_child(_label("(an empty backpack, a full heart)", 18, DIM))
	if not ids.has(inv_selected):
		inv_selected = ""
		inv_big_icon.texture = null
		inv_name.text = ""
		inv_desc.text = ""
		inv_use_btn.visible = false

func _on_inv_select(id: String) -> void:
	inv_selected = id
	var def := Items.get_def(id)
	inv_big_icon.texture = _icon(id)
	inv_name.text = Items.display_name(id)
	inv_desc.text = String(def.get("desc", ""))
	var kind := String(def.get("kind", "material"))
	inv_use_btn.visible = kind in ["use", "equip", "read"]
	match kind:
		"equip":
			inv_use_btn.text = "TAKE OFF" if GameState.is_equipped(id) else "PUT ON"
		"read":
			inv_use_btn.text = "READ"
		_:
			inv_use_btn.text = "USE"

func _on_inv_use() -> void:
	if inv_selected == "":
		return
	_item_action(inv_selected)

## The one item-verb pipeline: inventory button and hotbar keys both land here.
func _item_action(id: String) -> void:
	var def := Items.get_def(id)
	match String(def.get("kind", "")):
		"equip":
			var worn := not GameState.is_equipped(id)
			GameState.set_equipped(id, worn)
			Sd.play(&"helmet_seal" if id == "suit_helmet" else &"suit_equip")
			toast("%s: %s" % [Items.display_name(id), "sealed" if worn else "removed"])
			_refresh_inventory()
			if inv_panel.visible:
				_on_inv_select(id)
		"read":
			if inv_panel.visible:
				_toggle_inventory()
			open_reader(String(def.get("text_id", "")))
		"use":
			match id:
				"protein_bar":
					GameState.remove_item("protein_bar")
					Sd.play(&"eat")
					toast("Chewy. Historically chewy.")
					_refresh_inventory()
				"medkit":
					GameState.remove_item("medkit")
					Sd.play(&"suit_equip", -6.0)
					toast("Antiseptic, analgesic, and a sticker that says BRAVE. You feel patched.")
					_refresh_inventory()
				"duct_tape":
					toast("You feel prepared for approximately everything.")
				"wrench":
					toast("You give it a confident spin. Morale +1 (not a real stat).")
				_:
					toast("No obvious application. Yet.")
		_:
			toast("It is what it is. The lab scanner might say more.")

# ------------------------------------------------------------- hotbar

var hotbar_box: HBoxContainer
var hotbar_ids: Array = []

func _build_hotbar() -> void:
	hotbar_box = HBoxContainer.new()
	hotbar_box.add_theme_constant_override("separation", 8)
	hotbar_box.position = Vector2(586, 1004)
	add_child(hotbar_box)
	_refresh_hotbar()

func _refresh_hotbar() -> void:
	# Nine slots, always on screen. GameState.hotbar owns which item lives
	# where: pickup order, stable, gaps stay gaps. No sorting here.
	if hotbar_box == null:
		return
	for c in hotbar_box.get_children():
		c.queue_free()
	hotbar_ids = GameState.hotbar.duplicate()
	for i in hotbar_ids.size():
		var id := String(hotbar_ids[i])
		var slot := HotbarSlot.new()
		slot.index = i
		slot.item_id = id
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.07, 0.086, 0.118, 0.85 if id != "" else 0.45)
		style.border_color = PANEL_EDGE if id != "" else Color(PANEL_EDGE, 0.4)
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		slot.add_theme_stylebox_override("panel", style)
		slot.custom_minimum_size = Vector2(64, 64)
		if id != "":
			var tex := TextureRect.new()
			tex.texture = _icon(id)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot.add_child(tex)
			var n := int(GameState.inventory.get(id, 0))
			if n > 1:
				var badge := Label.new()
				badge.text = "x%d" % n
				badge.add_theme_font_size_override("font_size", 12)
				badge.add_theme_color_override("font_color", Color(0.9, 0.93, 0.96))
				badge.position = Vector2(36, 44)
				badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(badge)
		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 13)
		num.add_theme_color_override("font_color", DIM)
		num.position = Vector2(4, 2)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(num)
		if id in ["suit_torso", "suit_helmet"] and GameState.is_equipped(id):
			var dot := ColorRect.new()
			dot.color = ACCENT
			dot.size = Vector2(10, 10)
			dot.position = Vector2(48, 4)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(dot)
		hotbar_box.add_child(slot)

func _hotbar_key(index: int) -> void:
	if index < hotbar_ids.size() and String(hotbar_ids[index]) != "":
		_item_action(String(hotbar_ids[index]))
		Sd.play(&"switch_click", -12.0)

## Drag-and-drop lands here: hotbar-to-hotbar swaps, backpack-to-hotbar
## binds (the displaced item takes the dragged one's old slot, or the
## first free one).
func hotbar_drop(data: Dictionary, to_index: int) -> void:
	var id := String(data.get("id", ""))
	if id == "":
		return
	var hb: Array = GameState.hotbar
	var from := int(data.get("index", -1)) if String(data.get("source", "")) == "hotbar" else hb.find(id)
	if from == to_index:
		return
	var displaced := String(hb[to_index])
	hb[to_index] = id
	if from != -1:
		hb[from] = displaced
	elif displaced != "":
		var free := hb.find("")
		hb[free if free != -1 else to_index] = displaced
	Sd.play(&"switch_click", -10.0)
	_refresh_hotbar()

# ------------------------------------------------------------- reader

func _build_reader() -> void:
	reader_panel = _panel(Vector2(900, 660))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	reader_panel.add_child(v)
	reader_title = _label("", 28, WARN)
	v.add_child(reader_title)
	reader_body = RichTextLabel.new()
	reader_body.custom_minimum_size = Vector2(840, 470)
	reader_body.add_theme_font_size_override("normal_font_size", 22)
	reader_body.add_theme_color_override("default_color", INK)
	reader_body.bbcode_enabled = false
	v.add_child(reader_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	row.add_child(_button("< PREV", _reader_flip.bind(-1)))
	reader_page_label = _label("", 20, DIM)
	row.add_child(reader_page_label)
	row.add_child(_button("NEXT >", _reader_flip.bind(1)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_button("CLOSE", _close_reader))

func open_reader(text_id: String) -> void:
	var t := Texts.get_text(text_id)
	reader_title.text = String(t.get("title", ""))
	reader_pages = t.get("pages", [])
	reader_page = 0
	_reader_show()
	reader_panel.visible = true
	get_tree().paused = true
	Sd.play(&"paper")
	GameState.set_flag("read_" + text_id)

func _reader_show() -> void:
	if reader_pages.is_empty():
		reader_body.text = ""
		return
	reader_body.text = String(reader_pages[reader_page])
	reader_page_label.text = "%d / %d" % [reader_page + 1, reader_pages.size()]

func _reader_flip(dir: int) -> void:
	var n := reader_pages.size()
	if n == 0:
		return
	reader_page = clampi(reader_page + dir, 0, n - 1)
	Sd.play(&"paper", -6.0)
	_reader_show()

func _close_reader() -> void:
	reader_panel.visible = false
	get_tree().paused = false

# ------------------------------------------------- ship computer line box

## The computer speaks in a FIXED box: same size always, text paginated to
## fit, a flashing arrow when there is more, and nothing moves on without a
## click (or E). No timers deciding what you had time to read.

const COMPUTER_CHARS_PER_PAGE := 200

var computer_pages: Array[String] = []
var computer_page_idx: int = 0
var computer_waiting: bool = false
var computer_arrow: Label
var _computer_tween: Tween = null

func _build_computer_box() -> void:
	computer_box = _panel(Vector2(548, 200), false)
	computer_box.position = Vector2(24, 790)
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(508, 160)
	computer_box.add_child(inner)
	computer_label = _label("", 21, ACCENT)
	computer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	computer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	computer_label.clip_text = true
	computer_label.size_flags_vertical = Control.SIZE_FILL
	inner.add_child(computer_label)
	computer_arrow = _label("▼", 22, ACCENT)
	computer_arrow.position = Vector2(484, 130)
	computer_arrow.visible = false
	inner.add_child(computer_arrow)
	var blink := create_tween().set_loops()
	blink.tween_property(computer_arrow, "modulate:a", 0.15, 0.45)
	blink.tween_property(computer_arrow, "modulate:a", 1.0, 0.45)

func computer_active() -> bool:
	return computer_box != null and computer_box.visible

func computer_say(text: String) -> void:
	computer_queue.append(text)
	if not computer_typing:
		_computer_next()

func _paginate(text: String) -> Array[String]:
	var pages: Array[String] = []
	var words := text.split(" ")
	var cur := ""
	for w in words:
		if cur.length() + w.length() + 1 > COMPUTER_CHARS_PER_PAGE and cur != "":
			pages.append(cur)
			cur = String(w)
		else:
			cur = String(w) if cur == "" else cur + " " + String(w)
	if cur != "":
		pages.append(cur)
	return pages

func _computer_next() -> void:
	if computer_queue.is_empty():
		computer_typing = false
		computer_waiting = false
		computer_arrow.visible = false
		var tw := create_tween()
		tw.tween_property(computer_box, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func(): computer_box.visible = false)
		return
	computer_typing = true
	computer_pages = _paginate(String(computer_queue.pop_front()))
	computer_page_idx = 0
	_computer_show_page()

func _computer_show_page() -> void:
	computer_box.visible = true
	computer_box.modulate.a = 1.0
	computer_waiting = false
	computer_arrow.visible = false
	var line: String = computer_pages[computer_page_idx]
	computer_label.text = ""
	_computer_tween = create_tween()
	for i in line.length():
		_computer_tween.tween_callback(func():
			computer_label.text = line.substr(0, computer_label.text.length() + 1)
			if computer_label.text.length() % 3 == 0:
				Sd.play(&"computer_blip", -18.0, 1.4)
		)
		_computer_tween.tween_interval(0.018)
	_computer_tween.tween_callback(_computer_page_done)

func _computer_page_done() -> void:
	computer_waiting = true
	computer_arrow.visible = true

## Click or E lands here: finish typing first, then turn the page.
func computer_advance() -> void:
	if not computer_active():
		return
	if not computer_waiting:
		if _computer_tween != null and _computer_tween.is_valid():
			_computer_tween.kill()
		computer_label.text = computer_pages[computer_page_idx]
		_computer_page_done()
		return
	computer_page_idx += 1
	if computer_page_idx < computer_pages.size():
		_computer_show_page()
	else:
		_computer_next()

# ------------------------------------------------------------- pause

func _build_pause() -> void:
	pause_panel = _panel(Vector2(420, 420))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pause_panel.add_child(v)
	v.add_child(_label("PAUSED", 32, ACCENT))
	v.add_child(_button("Resume", _unpause))
	v.add_child(_button("Save Game", _open_save))
	v.add_child(_button("Load Game", open_load_panel))
	v.add_child(_button("Main Menu", func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")))

func _open_pause() -> void:
	pause_panel.visible = true
	get_tree().paused = true

func _unpause() -> void:
	pause_panel.visible = false
	get_tree().paused = false

# ------------------------------------------------------------- save / load

func _build_save_panel() -> void:
	save_panel = _panel(Vector2(560, 620))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	save_panel.add_child(v)
	v.add_child(_label("SAVE GAME", 30, ACCENT))
	v.add_child(_label("Label this moment:", 20, DIM))
	save_line = LineEdit.new()
	save_line.placeholder_text = "e.g. before opening the scary door"
	save_line.add_theme_font_size_override("font_size", 22)
	v.add_child(save_line)
	v.add_child(_button("SAVE", _do_save))
	v.add_child(_label("Or overwrite an existing save:", 20, DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 260)
	v.add_child(scroll)
	save_list_box = VBoxContainer.new()
	save_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(save_list_box)
	v.add_child(_button("BACK", func():
		save_panel.visible = false
		pause_panel.visible = true))

func _open_save() -> void:
	pause_panel.visible = false
	save_panel.visible = true
	save_line.text = ""
	_fill_save_list()

func _fill_save_list() -> void:
	for c in save_list_box.get_children():
		c.queue_free()
	for s in SaveManager.list_saves():
		if String(s.get("slug", "")) == SaveManager.CHECKPOINT:
			continue
		var b := _button("%s  (%s)" % [String(s.get("label", "?")), String(s.get("time", ""))],
				_do_overwrite.bind(String(s.get("label", "save"))))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		save_list_box.add_child(b)

func _do_save() -> void:
	var label := save_line.text.strip_edges()
	if label == "":
		label = "Save %s" % Time.get_datetime_string_from_system(false, true)
	_do_overwrite(label)

func _do_overwrite(label: String) -> void:
	if SaveManager.save_game(label):
		toast("Saved: %s" % label)
		Sd.play(&"switch_click", -6.0)
	else:
		toast("Save failed. The universe apologises.")
	save_panel.visible = false
	get_tree().paused = false

func _build_load_panel() -> void:
	load_panel = _panel(Vector2(640, 620))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	load_panel.add_child(v)
	v.add_child(_label("LOAD GAME", 30, ACCENT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 420)
	v.add_child(scroll)
	load_list_box = VBoxContainer.new()
	load_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(load_list_box)
	v.add_child(_button("BACK", func():
		load_panel.visible = false
		if _in_world():
			pause_panel.visible = true
		else:
			get_tree().paused = false))

func open_load_panel() -> void:
	pause_panel.visible = false
	load_panel.visible = true
	get_tree().paused = true
	for c in load_list_box.get_children():
		c.queue_free()
	var saves := SaveManager.list_saves()
	if saves.is_empty():
		load_list_box.add_child(_label("(no saves yet)", 20, DIM))
	for s in saves:
		var slug := String(s.get("slug", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := String(s.get("label", slug))
		if slug == SaveManager.CHECKPOINT:
			label = "[checkpoint] " + String(s.get("time", ""))
		var b := _button("%s  (%s)" % [label, String(s.get("time", ""))], func():
			load_panel.visible = false
			SaveManager.load_game(slug))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		var d := _button("X", func():
			SaveManager.delete_save(slug)
			open_load_panel())
		d.tooltip_text = "Delete this save"
		row.add_child(d)
		load_list_box.add_child(row)

# ------------------------------------------------------------- modal host

func open_modal(control: Control) -> void:
	if modal != null:
		close_modal()
	modal = control
	add_child(control)
	get_tree().paused = true

func close_modal() -> void:
	if modal != null:
		modal.queue_free()
		modal = null
	get_tree().paused = false
