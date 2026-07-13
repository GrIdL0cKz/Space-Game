extends Node2D
## EVA, aft of the Perennial: a 4,200px side-scrolling drift through the
## debris the impact left behind. The stern towers at the left, the field
## scatters right, the camera follows, and there is NO sound - the mute is
## total until the airlock takes you back.

const WORLD_W := 4200.0
const DRIFT_THRUST := 240.0
const MAX_SPEED := 460.0
# The tether pays out to just past the farthest salvage; beyond that it
# goes taut and hauls you back like the safety line it is.
const TETHER_ANCHOR := Vector2(262, 535)
const TETHER_MAX := 3850.0

var player: CharacterBody2D
var camera: Camera2D
var player_sprite: AnimatedSprite2D
var tether: Line2D
var drift_time: float = 0.0

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
	# Frozen mid-jump pose + a slow sway: an astronaut adrift, not a
	# commuter standing at a bus stop in hard vacuum.
	player_sprite = player.get_node("AnimatedSprite2D")
	player_sprite.animation = &"Jump"
	player_sprite.frame = 1
	player_sprite.pause()
	# The safety line, clipped to the hatch.
	tether = Line2D.new()
	tether.width = 3.0
	tether.default_color = Color(0.85, 0.89, 0.93, 0.75)
	tether.z_index = -2
	add_child(tether)
	var clip := ColorRect.new()
	clip.color = Color(0.85, 0.89, 0.93)
	clip.size = Vector2(10, 10)
	clip.position = TETHER_ANCHOR - Vector2(5, 5)
	clip.z_index = -2
	add_child(clip)
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
	# Past full payout the tether goes taut and pulls back, hard with the
	# overshoot - a spring, not a wall.
	var to_anchor := TETHER_ANCHOR - player.global_position
	var overshoot := to_anchor.length() - TETHER_MAX
	if overshoot > 0.0:
		player.velocity += to_anchor.normalized() * overshoot * 6.0 * delta
	player.velocity = player.velocity.limit_length(MAX_SPEED)
	player.move_and_slide()
	player.global_position.y = clampf(player.global_position.y, 60, 1020)
	player.global_position.x = clampf(player.global_position.x, 250, WORLD_W - 60)
	player._update_prompt()
	_update_drift_pose(delta)
	_update_tether()

func _update_drift_pose(delta: float) -> void:
	drift_time += delta
	if player_sprite == null:
		return
	if absf(player.velocity.x) > 12.0:
		player_sprite.flip_h = player.velocity.x < 0.0
	player_sprite.rotation = sin(drift_time * 0.9) * 0.1 \
			+ clampf(player.velocity.x * 0.0004, -0.18, 0.18)

func _update_tether() -> void:
	# A slack line sags; a taut line is a straight, worried thing.
	var a := TETHER_ANCHOR
	var b := player.global_position + Vector2(0, -60)
	var dist := a.distance_to(b)
	var slack := clampf(1.0 - dist / TETHER_MAX, 0.0, 1.0)
	var sag := 30.0 + slack * 220.0
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * sag
		pts.append(p)
	tether.points = pts

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
