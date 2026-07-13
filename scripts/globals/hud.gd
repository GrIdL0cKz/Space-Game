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
	GameState.suit_changed.connect(_refresh_suit_indicator)
	GameState.suit_changed.connect(_refresh_hotbar)
	GameState.inventory_changed.connect(_refresh_inventory)
	_refresh_suit_indicator()

func _in_world() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("world")

func _process(_delta: float) -> void:
	# The load panel is also the main menu's Load Game screen, so the layer
	# stays alive for it outside gameplay scenes.
	visible = _in_world() or load_panel.visible

func any_overlay_open() -> bool:
	return inv_panel.visible or reader_panel.visible or pause_panel.visible \
			or save_panel.visible or load_panel.visible or modal != null

func _unhandled_input(event: InputEvent) -> void:
	if not _in_world():
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
	toast_label.position = Vector2(0, 812)
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
	var b := Button.new()
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
		var slot := PanelContainer.new()
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

func _build_computer_box() -> void:
	computer_box = _panel(Vector2(548, 0), false)
	computer_box.position = Vector2(24, 930)
	computer_label = _label("", 21, ACCENT)
	computer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	computer_label.custom_minimum_size = Vector2(508, 0)
	computer_box.add_child(computer_label)

func computer_say(text: String) -> void:
	computer_queue.append(text)
	if not computer_typing:
		_computer_next()

func _computer_next() -> void:
	if computer_queue.is_empty():
		computer_typing = false
		var tw := create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func(): computer_box.visible = not computer_queue.is_empty() and computer_box.visible)
		tw.tween_property(computer_box, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): computer_box.visible = false)
		return
	computer_typing = true
	computer_box.visible = true
	computer_box.modulate.a = 1.0
	var line: String = computer_queue.pop_front()
	computer_label.text = ""
	var tw := create_tween()
	for i in line.length():
		tw.tween_callback(func():
			computer_label.text = line.substr(0, computer_label.text.length() + 1)
			# Grow upward from a fixed bottom edge so long speeches never
			# run off-screen into the hotbar.
			computer_box.position.y = 990.0 - computer_box.size.y
			if computer_label.text.length() % 3 == 0:
				Sd.play(&"computer_blip", -18.0, 1.4)
		)
		tw.tween_interval(0.018)
	tw.tween_interval(2.2)
	tw.tween_callback(_computer_next)

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
