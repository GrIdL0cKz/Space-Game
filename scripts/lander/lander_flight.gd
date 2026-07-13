extends Node2D
## The crossing: our stern behind you, the Reprieve ahead, and a lot of
## nothing in between. Drift physics like the EVA but with a ship around
## you. Arrive at the belly hatch slowly or arrive as wreckage.

const WORLD_W := 5200.0
const THRUST := 320.0
const MAX_SPEED := 560.0
const DOCK_SPEED := 190.0

const DERELICT_POS := Vector2(4050, 240)  # exterior sprite top-left
const HATCH_OFFSET := Vector2(515, 416)   # belly hatch centre in that art
const DOCK_RADIUS := 130.0

var lander: Sprite2D
var velocity := Vector2.ZERO
var camera: Camera2D
var done: bool = false

func _ready() -> void:
	add_to_group("world")
	_build_backdrop()
	var stern := Sprite2D.new()
	stern.texture = load("res://astronaught/environs/rooms/eva_stern.png")
	stern.centered = false
	stern.position = Vector2(0, 40)
	stern.z_index = -10
	add_child(stern)
	var derelict := Sprite2D.new()
	derelict.texture = load("res://astronaught/environs/rooms/derelict_exterior.png")
	derelict.centered = false
	derelict.position = DERELICT_POS
	derelict.z_index = -10
	add_child(derelict)
	lander = Sprite2D.new()
	lander.texture = load("res://astronaught/environs/rooms/lander.png")
	var pending: Variant = SaveManager.consume_pending_position()
	lander.position = pending if pending is Vector2 else Vector2(820, 560)
	add_child(lander)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * 1.1
	camera.position_smoothing_enabled = true
	camera.limit_left = 0
	camera.limit_right = int(WORLD_W)
	camera.limit_top = 0
	camera.limit_bottom = 1080
	lander.add_child(camera)
	camera.make_current()
	Hud.toast("Thrusters: A/D and W/S (or SPACE up). Gently does it.")

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.024, 0.018, 0.04)
	bg.size = Vector2(WORLD_W, 1080)
	bg.z_index = -20
	add_child(bg)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 77
	for i in 480:
		var star := ColorRect.new()
		star.color = Color(0.9, 0.93, 0.96, rnd.randf_range(0.25, 1.0))
		star.size = Vector2.ONE * (2 if rnd.randf() < 0.85 else 3)
		star.position = Vector2(rnd.randf_range(0, WORLD_W), rnd.randf_range(0, 1080))
		star.z_index = -19
		add_child(star)

func _physics_process(delta: float) -> void:
	if done or Hud.any_overlay_open():
		return
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	if Input.is_action_pressed("jump"):
		input.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		input.y += 1.0
	if input != Vector2.ZERO:
		velocity += input.normalized() * THRUST * delta
	velocity = velocity.limit_length(MAX_SPEED)
	lander.position += velocity * delta
	lander.position.y = clampf(lander.position.y, 60, 1020)
	lander.position.x = clampf(lander.position.x, 380, WORLD_W - 120)
	lander.rotation = clampf(velocity.y * 0.0006, -0.22, 0.22)
	if velocity.length() > 8.0:
		lander.flip_h = velocity.x < -12.0
	_check_docks()

func _check_docks() -> void:
	var hatch := DERELICT_POS + HATCH_OFFSET
	if lander.position.distance_to(hatch) < DOCK_RADIUS:
		if velocity.length() > DOCK_SPEED:
			done = true
			Death.die("UNSCHEDULED BOARDING",
				"You docked with the derelict at ramming speed. Technically you are now aboard. Practically, so is the lander's nose cone, and so are you, in a wider sense than before.")
			return
		done = true
		GameState.set_flag("visited_derelict")
		Sd.play(&"airlock_clunk")
		SaveManager._pending_pos = [180.0, 631.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/derelict_ship.tscn")
		return
	# Home again: anywhere along the Perennial's stern counts.
	if lander.position.x < 520.0 and velocity.length() < DOCK_SPEED and \
			bool(GameState.get_flag("visited_derelict")):
		done = true
		Sd.play(&"airlock_clunk")
		SaveManager._pending_pos = [1150.0, 631.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/lander_dock.tscn")
