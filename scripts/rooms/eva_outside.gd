extends Node2D
## EVA, aft of the Perennial: a 4,200px side-scrolling drift through the
## debris the impact left behind. The stern towers at the left, the field
## scatters right, the camera follows, and there is NO sound - the mute is
## total until the airlock takes you back.

const WORLD_W := 4200.0
const DRIFT_THRUST := 240.0
const MAX_SPEED := 460.0

var player: CharacterBody2D
var camera: Camera2D

func _ready() -> void:
	add_to_group("world")
	Sd.set_eva_silence(true)
	_build_backdrop()
	_build_stern()
	_build_player()
	_build_salvage()
	_build_airlock_return()

func _exit_tree() -> void:
	Sd.set_eva_silence(false)

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.024, 0.018, 0.04)
	bg.size = Vector2(WORLD_W, 1080)
	bg.z_index = -20
	add_child(bg)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 42
	for i in 420:
		var star := ColorRect.new()
		var deep := rnd.randf() < 0.5
		star.color = Color(0.9, 0.93, 0.96, rnd.randf_range(0.25, 1.0) * (0.5 if deep else 1.0))
		star.size = Vector2.ONE * (2 if rnd.randf() < 0.85 else 3)
		star.position = Vector2(rnd.randf_range(0, WORLD_W), rnd.randf_range(0, 1080))
		star.z_index = -19
		add_child(star)

func _build_stern() -> void:
	# The back of the ship, drawn in the hull's own flat-outline style by
	# tools/gen_rooms.py - the same ship you know, from the side nobody visits.
	var stern := Sprite2D.new()
	stern.texture = load("res://astronaught/environs/rooms/eva_stern.png")
	stern.centered = false
	stern.position = Vector2(0, 40)
	stern.z_index = -10
	add_child(stern)

func _build_player() -> void:
	player = preload("res://actors/entities/player.tscn").instantiate()
	var pending: Variant = SaveManager.consume_pending_position()
	player.global_position = pending if pending is Vector2 else Vector2(430, 530)
	add_child(player)
	player.set_physics_process(false)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * 1.4
	camera.position_smoothing_enabled = true
	camera.limit_left = 0
	camera.limit_right = int(WORLD_W)
	camera.limit_top = 0
	camera.limit_bottom = 1080
	player.add_child(camera)
	camera.make_current()

func _physics_process(delta: float) -> void:
	if player == null or Hud.any_overlay_open():
		return
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	if Input.is_action_pressed("jump"):
		input.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		input.y += 1.0
	if input != Vector2.ZERO:
		player.velocity += input.normalized() * DRIFT_THRUST * delta
	player.velocity = player.velocity.limit_length(MAX_SPEED)
	player.move_and_slide()
	player.global_position.y = clampf(player.global_position.y, 60, 1020)
	player.global_position.x = clampf(player.global_position.x, 250, WORLD_W - 60)
	player._update_prompt()

func _build_salvage() -> void:
	var spots := [
		[Vector2(760, 320), "scrap_metal", "A shard of your own hull. You take it personally, and then just take it."],
		[Vector2(1240, 700), "fuse", "A supply crate, split open years ago. One fuse survived the escape attempt."],
		[Vector2(1750, 260), "scrap_metal", "Hull plating, drifting in slow formation with its old address."],
		[Vector2(2260, 620), "sample_rock", "A fragment of whatever hit the ship. The lab will want a word with it."],
		[Vector2(2840, 380), "wire_coil", "A whole coil of insulated wire, orbiting nothing in particular. Finders keepers."],
		[Vector2(3380, 760), "power_cell", "An emergency cell, ejected with a panel during the strike. Still warm with charge."],
		[Vector2(3900, 480), "scrap_metal", "The furthest piece. From here the ship is small enough to forgive."],
	]
	for s in spots:
		var pickup := SalvagePickup.new()
		pickup.item_id = String(s[1])
		pickup.line = String(s[2])
		pickup.prompt = "Salvage"
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(170, 170)
		cs.shape = rect
		pickup.add_child(cs)
		pickup.position = s[0]
		var visual := ColorRect.new()
		visual.color = Color(0.62, 0.66, 0.7)
		visual.size = Vector2(36, 28)
		visual.position = Vector2(-18, -14)
		visual.rotation = randf_range(-0.6, 0.6)
		pickup.add_child(visual)
		var glint := ColorRect.new()
		glint.color = Color(0.9, 0.94, 1.0, 0.8)
		glint.size = Vector2(6, 6)
		glint.position = Vector2(-3, -22)
		pickup.add_child(glint)
		add_child(pickup)

func _build_airlock_return() -> void:
	var door := ReturnDoor.new()
	door.prompt = "Airlock - go inside"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(220, 420)
	cs.shape = rect
	door.add_child(cs)
	door.position = Vector2(230, 540)
	add_child(door)

class SalvagePickup extends Interactable:
	var item_id: String = ""
	var line: String = ""

	func _interact(_player: Node) -> void:
		GameState.add_item(item_id, 1, true)
		Hud.toast(line)
		queue_free()

class ReturnDoor extends Interactable:
	func _interact(_player: Node) -> void:
		GameState.set_flag("airlock_cycled", false)
		SaveManager._pending_pos = [1650.0, 631.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/airlock_room.tscn")
		Sd.set_eva_silence(false)
		Sd.play(&"airlock_hiss")
		Sd.play(&"airlock_clunk", -4.0)
