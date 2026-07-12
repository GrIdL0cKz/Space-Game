extends CharacterBody2D
## The scientist. Keyboard (A/D + Space/W) and click-to-move both work; E
## interacts with the nearest thing in range, clicking a thing walks over
## and interacts on arrival. A small prompt floats overhead when something
## is in reach. The body is the contractor's; the hands are new.

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ARRIVE_DISTANCE = 12.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim: AnimationPlayer = get_node("AnimationPlayer")
@onready var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")

var towards: Vector2 = Vector2.ZERO
var is_auto_moving: bool = false
var pending_interact: Interactable = null
var in_range: Array[Interactable] = []
var prompt_label: Label = null
var controls_locked: bool = false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	_make_prompt_label()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if controls_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			anim.play("Idle")
		move_and_slide()
		return
	if is_auto_moving:
		_handle_click_movement()
	else:
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
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim.play("Jump")
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		# Manual steering always overrides a queued walk order.
		pending_interact = null
		sprite.flip_h = direction < 0
		velocity.x = direction * SPEED
		if velocity.y == 0:
			anim.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			anim.play("Idle")
	move_and_slide()

func _handle_click_movement() -> void:
	var dif := global_position.direction_to(towards)
	velocity.x = dif.x * SPEED
	sprite.flip_h = velocity.x < -0.5
	anim.play("Run" if absf(velocity.x) > 0.5 else "Idle")
	move_and_slide()
	if absf(global_position.x - towards.x) < ARRIVE_DISTANCE:
		is_auto_moving = false
		towards = Vector2.ZERO
		anim.play("Idle")
		if pending_interact != null and is_instance_valid(pending_interact):
			var target := pending_interact
			pending_interact = null
			target.try_interact(self)

func move_to(g_pos: Vector2) -> void:
	# A plain walk order cancels any queued interaction.
	pending_interact = null
	towards = g_pos
	is_auto_moving = true

func approach_and_interact(target: Interactable) -> void:
	if in_range.has(target):
		target.try_interact(self)
		return
	pending_interact = target
	towards = Vector2(target.global_position.x, global_position.y)
	is_auto_moving = true

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

func _make_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.position = Vector2(-60, -110)
	prompt_label.size = Vector2(120, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 4)
	prompt_label.visible = false
	add_child(prompt_label)

func _update_prompt() -> void:
	var target := _nearest_in_range()
	if target != null:
		prompt_label.text = "[E] %s" % target.prompt
		prompt_label.visible = true
	else:
		prompt_label.visible = false
