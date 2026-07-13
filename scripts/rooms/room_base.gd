class_name RoomBase
extends Node2D
## A slice of the Perennial at the hull's own scale: one deck strip in
## space, per Rob's tube section. A 2x camera rides the deck and follows
## the player, so rooms feel like rooms instead of gymnasiums. Rooms
## declare their furniture in _populate().

const PLAYER_SCENE := preload("res://actors/entities/player.tscn")
const DOOR_TEX := "res://astronaught/interior assets/door closed.png"

# Deck geometry, matched to tools/gen_rooms.py and the hull art.
const INT_TOP := 528.0
const FLOOR_TOP := 620.0
const STAND_Y := 631.0  # player origin (feet) 16px into the floor band, hull-style

var bg_texture: String = ""
var default_spawn := Vector2(200, STAND_Y)
var camera_zoom := 2.0
var player: CharacterBody2D
var camera: Camera2D

func _ready() -> void:
	add_to_group("world")
	if bg_texture != "":
		var bg := Sprite2D.new()
		bg.texture = load(bg_texture)
		bg.centered = false
		bg.z_index = -10
		add_child(bg)
	_make_floor()
	player = PLAYER_SCENE.instantiate()
	var pending: Variant = SaveManager.consume_pending_position()
	player.global_position = pending if pending is Vector2 else default_spawn
	add_child(player)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * camera_zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 1920
	camera.limit_top = 0
	camera.limit_bottom = 1080
	player.add_child(camera)
	camera.position = Vector2(0, -80)
	camera.make_current()
	_populate()

func _make_floor() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for shape_data in [
		[Vector2(960, FLOOR_TOP + 46), Vector2(1920, 60)],
		[Vector2(-20, 540), Vector2(40, 1080)],
		[Vector2(1940, 540), Vector2(40, 1080)],
	]:
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = shape_data[1]
		cs.shape = rect
		cs.position = shape_data[0]
		body.add_child(cs)

func _populate() -> void:
	pass

## Interactable placed on the deck with a sensible reach box.
func add_spot(inst: Interactable, x: float, reach := Vector2(150, 170)) -> Interactable:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = reach
	cs.shape = rect
	inst.add_child(cs)
	inst.position = Vector2(x, STAND_Y - 60.0)
	add_child(inst)
	return inst

## A visible door (Rob's art) + an overhead sign, wrapping a Doorway spot.
func add_door(label: String, x: float, target: String, spawn: Vector2,
		req_item := "", locked_line := "") -> void:
	# Steel tint: the door art is white line-work and vanishes against the
	# pale interior walls without it.
	var door_sprite := Sprite2D.new()
	door_sprite.texture = load(DOOR_TEX)
	door_sprite.position = Vector2(x, FLOOR_TOP - 64.0)
	door_sprite.scale = Vector2(0.8, 0.8)
	door_sprite.modulate = Color(0.62, 0.7, 0.78)
	door_sprite.z_index = -5
	add_child(door_sprite)
	add_sign(label, x)
	add_spot(Doorway.make("To: %s" % label, target, spawn, req_item, locked_line), x)

## An overhead sign plate with engine-rendered text (crisp at any zoom).
func add_sign(text: String, x: float, y: float = INT_TOP - 16.0) -> void:
	var plate := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.32, 0.38)
	style.border_color = Color(0, 0, 0)
	style.set_border_width_all(2)
	plate.add_theme_stylebox_override("panel", style)
	var w := maxf(84.0, text.length() * 11.0 + 18.0)
	plate.size = Vector2(w, 24)
	plate.position = Vector2(x - w / 2.0, y - 12.0)
	plate.z_index = -4
	add_child(plate)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(l)

func _unhandled_input(event: InputEvent) -> void:
	if Hud.any_overlay_open() or player == null:
		return
	var tapped: bool = event is InputEventScreenTouch and not event.pressed
	if tapped:
		var world_pos: Vector2 = camera.get_global_mouse_position() if camera != null else event.position
		player.move_to(Vector2(world_pos.x, player.global_position.y))
