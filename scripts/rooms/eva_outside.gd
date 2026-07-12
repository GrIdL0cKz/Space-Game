extends Node2D
## Outside, aft of the ship. No gravity, no sound - the mute is total and
## deliberate. Drift with gentle thrusts (heard only as suit-conducted
## puffs... no. Heard as nothing. THE RULE.), gather what the asteroid
## field left embedded in the neighbourhood, and come home to the loudest
## TSHHHH in the game.

const DRIFT_THRUST := 220.0
const MAX_SPEED := 420.0

var player: CharacterBody2D
var salvage_taken: int = 0

func _ready() -> void:
	add_to_group("world")
	Sd.set_eva_silence(true)
	_build_backdrop()
	_build_player()
	_build_salvage()
	_build_airlock_return()

func _exit_tree() -> void:
	Sd.set_eva_silence(false)

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.024, 0.047)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -20
	add_child(bg)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 42
	for i in 130:
		var star := ColorRect.new()
		star.color = Color(0.9, 0.93, 0.96, rnd.randf_range(0.4, 1.0))
		star.size = Vector2.ONE * (2 if rnd.randf() < 0.85 else 3)
		star.position = Vector2(rnd.randf_range(0, 1920), rnd.randf_range(0, 1080))
		star.z_index = -19
		add_child(star)
	# The stern of the Perennial along the left edge: hull plates, a slice
	# of the ship you have spent all game inside, seen from the cold side.
	var hull := ColorRect.new()
	hull.color = Color(0.72, 0.78, 0.82)
	hull.size = Vector2(150, 1080)
	hull.z_index = -10
	add_child(hull)
	var hull_edge := ColorRect.new()
	hull_edge.color = Color(0, 0, 0)
	hull_edge.position = Vector2(150, 0)
	hull_edge.size = Vector2(6, 1080)
	hull_edge.z_index = -9
	add_child(hull_edge)
	for y in range(60, 1080, 170):
		var seam := ColorRect.new()
		seam.color = Color(0.5, 0.56, 0.6)
		seam.position = Vector2(0, y)
		seam.size = Vector2(150, 4)
		seam.z_index = -9
		add_child(seam)

func _build_player() -> void:
	player = preload("res://actors/entities/player.tscn").instantiate()
	var pending: Variant = SaveManager.consume_pending_position()
	player.global_position = pending if pending is Vector2 else Vector2(220, 540)
	add_child(player)
	# Weightless: no gravity, no floor. The player script's physics loop is
	# superseded by drift.
	player.set_physics_process(false)
	player.controls_locked = false

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
	# Nothing out here slows you down. Newton is the level designer now.
	player.move_and_slide()
	player.global_position.y = clampf(player.global_position.y, 40, 1040)
	player.global_position.x = clampf(player.global_position.x, 170, 1880)
	player._update_prompt()

func _build_salvage() -> void:
	var spots := [
		[Vector2(700, 300), "scrap_metal", "A shard of your own hull. You take it personally, and then just take it."],
		[Vector2(1200, 620), "sample_rock", "A fragment of whatever hit the ship. The lab will want a word with it."],
		[Vector2(1500, 240), "fuse", "A supply crate, split open years ago. One fuse survived the escape attempt."],
		[Vector2(950, 850), "scrap_metal", "Hull plating, drifting in slow formation with its old address."],
	]
	for s in spots:
		var pickup := SalvagePickup.new()
		pickup.item_id = String(s[1])
		pickup.line = String(s[2])
		pickup.prompt = "Salvage"
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(160, 160)
		cs.shape = rect
		pickup.add_child(cs)
		pickup.position = s[0]
		var visual := ColorRect.new()
		visual.color = Color(0.62, 0.66, 0.7)
		visual.size = Vector2(34, 26)
		visual.position = Vector2(-17, -13)
		visual.rotation = randf_range(-0.6, 0.6)
		pickup.add_child(visual)
		add_child(pickup)

func _build_airlock_return() -> void:
	var door := ReturnDoor.new()
	door.prompt = "Airlock - go inside"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(220, 400)
	cs.shape = rect
	door.add_child(cs)
	door.position = Vector2(150, 540)
	add_child(door)

class SalvagePickup extends Interactable:
	var item_id: String = ""
	var line: String = ""

	func _interact(_player: Node) -> void:
		# add_item quietly: its toast is silent anyway out here, but the
		# TEXT still matters - vacuum doesn't mute reading.
		GameState.add_item(item_id, 1, true)
		Hud.toast(line)
		queue_free()

class ReturnDoor extends Interactable:
	func _interact(_player: Node) -> void:
		GameState.set_flag("airlock_cycled", false)
		SaveManager._pending_pos = [1650.0, 860.0]
		get_tree().change_scene_to_file.call_deferred("res://scenes/rooms/airlock_room.tscn")
		# The loudest sound in the game, precisely because of what preceded it.
		Sd.set_eva_silence(false)
		Sd.play(&"airlock_hiss")
		Sd.play(&"airlock_clunk", -4.0)
