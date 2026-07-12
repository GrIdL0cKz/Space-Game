class_name RoomBase
extends Node2D
## A ship room: backdrop, floor, walls, the player, and whatever the room
## declares in _populate(). Rooms are code-built - no per-room .tscn beyond
## a stub - so the whole deck plan lives in readable GDScript.

const PLAYER_SCENE := preload("res://actors/entities/player.tscn")
const FLOOR_Y := 900.0

var bg_texture: String = ""
var default_spawn := Vector2(200, 860)
var player: CharacterBody2D

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
	_populate()

func _make_floor() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for shape_data in [
		[Vector2(960, FLOOR_Y + 90), Vector2(1920, 180)],   # floor
		[Vector2(-20, 540), Vector2(40, 1080)],             # left wall
		[Vector2(1940, 540), Vector2(40, 1080)],            # right wall
	]:
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = shape_data[1]
		cs.shape = rect
		cs.position = shape_data[0]
		body.add_child(cs)

## Rooms override this to place doors, props and consoles.
func _populate() -> void:
	pass

func add_spot(inst: Interactable, pos: Vector2, reach := Vector2(180, 220)) -> Interactable:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = reach
	cs.shape = rect
	inst.add_child(cs)
	inst.position = pos
	add_child(inst)
	return inst

func _unhandled_input(event: InputEvent) -> void:
	if Hud.any_overlay_open() or player == null:
		return
	var tapped: bool = event is InputEventScreenTouch and not event.pressed
	if tapped:
		player.move_to(Vector2(event.position.x, player.global_position.y))
