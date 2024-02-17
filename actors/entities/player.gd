extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = get_node("AnimationPlayer")

var towards
var is_auto_moving = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if is_auto_moving == false:
		handle_keyboard_movements()
	else:
		handle_click_movements()


func handle_click_movements():
	var dif = global_position.direction_to(towards)
	
	velocity.x = dif.x * SPEED
	
	if velocity.x < -0.5:
		get_node("AnimatedSprite2D").flip_h = true
	elif velocity.x > 0.5:
		get_node("AnimatedSprite2D").flip_h = false
	if velocity.x != 0.0:
		anim.play("Run")
	else:
		anim.play("Idle")
	
	move_and_slide()
	
	if global_position.distance_to(towards) < 10.0:
		is_auto_moving = false
		towards = Vector2.ZERO


func handle_keyboard_movements():
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim.play("Jump")
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction == -1:
		get_node("AnimatedSprite2D").flip_h = true
	elif direction == 1:
		get_node("AnimatedSprite2D").flip_h = false
	if direction:
		velocity.x = direction * SPEED
		if velocity.y == 0:
			anim.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			anim.play("Idle")
	move_and_slide()


func move_to(g_pos):
	towards = g_pos
	is_auto_moving = true
