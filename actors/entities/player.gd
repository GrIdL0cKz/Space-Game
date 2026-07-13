extends CharacterBody2D
## The scientist. Keyboard only (A/D + Space/W); E interacts with the
## nearest thing in range, or click the thing itself while in range. The
## prompt shows on the HUD above the hotbar. The body is the contractor's;
## the hands are new.

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim: AnimationPlayer = get_node("AnimationPlayer")
@onready var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")

var in_range: Array[Interactable] = []
var controls_locked: bool = false
var crawling: bool = false

const CRAWL_SPEED_MULT := 0.4

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	# In front of doors, signs and wall lights; behind nothing that matters.
	z_index = 15
	# Spawns land a few pixels above the deck; a generous snap length
	# swallows the drop so entering a room doesn't look like a hop.
	floor_snap_length = 16.0
	GameState.suit_changed.connect(_refresh_helmet_frames)
	_refresh_helmet_frames()

## Crawlspace mode: the sprite lies prone, the collider flattens, jumping
## stops, and everything slows to elbows-and-knees pace.
func set_crawling(on: bool) -> void:
	if crawling == on:
		return
	crawling = on
	var cs: CollisionShape2D = get_node("CollisionShape2D")
	var rect: RectangleShape2D = cs.shape
	if on:
		rect.size = Vector2(110, 56)
		cs.position = Vector2(0, -24)
		sprite.rotation = PI / 2.0 if sprite.flip_h else -PI / 2.0
		sprite.position = Vector2(0, -26)
		# Prone means prone: freeze on one frame, no walk cycle, no idle.
		anim.stop()
		sprite.stop()
		sprite.frame = 0
	else:
		rect.size = Vector2(62, 120)
		cs.position = Vector2(0, -55)
		sprite.rotation = 0.0
		sprite.position = Vector2(0, -53)

## Rob's art has helmet-off walk frames; the wardrobe and the suit system
## use them. Idle borrows the first no-helm walk frame (no idle set exists).
var _helm_frames_cached := {}

func _refresh_helmet_frames() -> void:
	if sprite == null:
		return
	var helm_on := GameState.is_equipped("suit_helmet") or not GameState.has_item("suit_helmet")
	# Default frames in the scene ARE the helmet-on set; only override when
	# the helmet is demonstrably off.
	if helm_on:
		if _helm_frames_cached.has("on"):
			sprite.sprite_frames = _helm_frames_cached["on"]
	else:
		if not _helm_frames_cached.has("on"):
			_helm_frames_cached["on"] = sprite.sprite_frames
		if not _helm_frames_cached.has("off"):
			var off: SpriteFrames = (sprite.sprite_frames as SpriteFrames).duplicate(true)
			var walks: Array = []
			for i in range(1, 5):
				var path := "res://astronaught/Player/astro walk right no helm %d.png" % i
				if ResourceLoader.exists(path):
					walks.append(load(path))
			if walks.size() == 4:
				# No no-helm jump art exists, so Jump borrows a mid-stride
				# walk frame - otherwise the helmet pops back on every hop.
				for anim in ["Run", "Idle", "Jump", "RunFree"]:
					if off.has_animation(anim):
						off.clear(anim)
						if anim == "Run" or anim == "RunFree":
							for t in walks:
								off.add_frame(anim, t)
						elif anim == "Jump":
							off.add_frame(anim, walks[1])
						else:
							off.add_frame(anim, walks[0])
			_helm_frames_cached["off"] = off
		sprite.sprite_frames = _helm_frames_cached["off"]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if controls_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			anim.play("Idle")
		move_and_slide()
		return
	_handle_keyboard_movement()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if controls_locked:
		return
	if event.is_action_pressed("interact"):
		var target := _nearest_in_range()
		if target != null:
			target.try_interact(self)
			get_viewport().set_input_as_handled()

func _handle_keyboard_movement() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not crawling:
		velocity.y = JUMP_VELOCITY
		anim.play("Jump")
	var direction := Input.get_axis("move_left", "move_right")
	var speed := SPEED * (CRAWL_SPEED_MULT if crawling else 1.0)
	if direction:
		sprite.flip_h = direction < 0
		if crawling:
			sprite.rotation = PI / 2.0 if sprite.flip_h else -PI / 2.0
		velocity.x = direction * speed
		if velocity.y == 0 and not crawling:
			anim.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0 and not crawling:
			anim.play("Idle")
	move_and_slide()

# ------------------------------------------------------------- range + prompt

func _nearest_in_range() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for i in in_range:
		if not is_instance_valid(i) or not i.visible:
			continue
		var d := global_position.distance_squared_to(i.global_position)
		if d < best_d:
			best_d = d
			best = i
	return best

func notify_range_entered(i: Interactable) -> void:
	if not in_range.has(i):
		in_range.append(i)

func notify_range_exited(i: Interactable) -> void:
	in_range.erase(i)

func _update_prompt() -> void:
	# The prompt lives on the HUD above the hotbar now, not over the
	# character's head, so it can afford full sentences.
	var target := _nearest_in_range()
	Hud.set_prompt("[E]  %s" % target.prompt if target != null else "")

func _exit_tree() -> void:
	Hud.set_prompt("")
