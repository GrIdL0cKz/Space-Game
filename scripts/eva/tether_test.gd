extends Node2D
## THE SIGNATURE MECHANIC, prototyped in a black void: you, a tether, a dead
## ship, and physics. WASD nudges the suit thrusters. Q/E reels the tether
## in and out. Walk to debris, grab it with SPACE, throw it with a click -
## and feel the ship's mass answer through the line.
##
## This scene exists to answer one question honestly: does being a human
## outboard motor FEEL good? Run it from the editor: scenes/eva/tether_test.tscn

const THRUST := 160.0
const REEL_SPEED := 140.0
const TETHER_MIN := 60.0
const TETHER_MAX_START := 420.0
const SPRING := 14.0
const DAMP := 0.4
const THROW_SPEED := 520.0
const THROW_REACTION := 180.0

var anchor := Vector2(240, 540)
var tether_max := TETHER_MAX_START
var player: CharacterBody2D
var held_debris: Node2D = null
var debris_list: Array = []
var info: Label

func _ready() -> void:
	add_to_group("world")
	Sd.set_eva_silence(true)
	_backdrop()
	player = preload("res://actors/entities/player.tscn").instantiate()
	player.global_position = anchor + Vector2(220, 0)
	player.set_physics_process(false)
	add_child(player)
	for i in 7:
		_spawn_debris(Vector2(randf_range(500, 1800), randf_range(120, 960)))
	_hud_text()

func _exit_tree() -> void:
	Sd.set_eva_silence(false)

func _backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.018, 0.035)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -20
	add_child(bg)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 8
	for i in 150:
		var s := ColorRect.new()
		s.color = Color(0.9, 0.92, 0.95, rnd.randf_range(0.3, 0.9))
		s.size = Vector2.ONE * 2
		s.position = Vector2(rnd.randf_range(0, 1920), rnd.randf_range(0, 1080))
		s.z_index = -19
		add_child(s)
	# the dead ship: a stern slab you are tied to
	var hull := ColorRect.new()
	hull.color = Color(0.66, 0.72, 0.77)
	hull.size = Vector2(180, 700)
	hull.position = Vector2(60, 190)
	hull.z_index = -10
	add_child(hull)

func _hud_text() -> void:
	info = Label.new()
	info.text = "TETHER TEST  -  WASD thrust · Q/E reel · SPACE grab · CLICK throw (mass = motion) · the line is elastic"
	info.position = Vector2(30, 20)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.7, 0.8, 0.87))
	add_child(info)

func _spawn_debris(pos: Vector2) -> void:
	var d := Node2D.new()
	var visual := ColorRect.new()
	var s := randf_range(20, 44)
	visual.size = Vector2(s, s * 0.8)
	visual.position = -visual.size / 2.0
	visual.color = Color(0.55, 0.6, 0.65)
	visual.rotation = randf_range(-0.5, 0.5)
	d.add_child(visual)
	d.position = pos
	d.set_meta("vel", Vector2(randf_range(-12, 12), randf_range(-12, 12)))
	d.set_meta("mass", s / 30.0)
	add_child(d)
	debris_list.append(d)

func _physics_process(delta: float) -> void:
	# --- player thrust
	var input := Vector2(Input.get_axis("move_left", "move_right"), 0)
	if Input.is_action_pressed("jump"):
		input.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		input.y += 1.0
	if input != Vector2.ZERO:
		player.velocity += input.normalized() * THRUST * delta
	# --- reel
	if Input.is_key_pressed(KEY_Q):
		tether_max = maxf(TETHER_MIN, tether_max - REEL_SPEED * delta)
	if Input.is_key_pressed(KEY_E):
		tether_max = minf(900.0, tether_max + REEL_SPEED * delta)
	# --- tether spring: only pulls when the line is taut
	var to_anchor := anchor - player.global_position
	var dist := to_anchor.length()
	if dist > tether_max:
		var stretch := dist - tether_max
		player.velocity += to_anchor.normalized() * stretch * SPRING * delta
		player.velocity -= player.velocity * DAMP * delta
	player.move_and_slide()
	# --- grab
	if Input.is_action_just_pressed("jump") and held_debris == null:
		for d in debris_list:
			if is_instance_valid(d) and d.position.distance_to(player.global_position) < 80.0:
				held_debris = d
				debris_list.erase(d)
				break
	if held_debris != null:
		held_debris.position = player.global_position + Vector2(40, -10)
	# --- drift the field
	for d in debris_list:
		if is_instance_valid(d):
			d.position += (d.get_meta("vel") as Vector2) * delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if held_debris != null and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var dir := (get_global_mouse_position() - player.global_position).normalized()
		var mass := float(held_debris.get_meta("mass"))
		held_debris.set_meta("vel", dir * THROW_SPEED)
		debris_list.append(held_debris)
		held_debris = null
		# Newton's third: the throw shoves YOU (and through the taut line,
		# eventually, the ship). Heavier junk, harder shove.
		player.velocity -= dir * THROW_REACTION * mass

func _draw() -> void:
	# the tether: sags when slack, straightens and pales when taut
	var dist := anchor.distance_to(player.global_position)
	var taut := dist >= tether_max * 0.98
	if taut:
		draw_line(anchor, player.global_position, Color(0.9, 0.94, 1.0, 0.9), 3.0)
	else:
		var mid := (anchor + player.global_position) / 2.0 + Vector2(0, (tether_max - dist) * 0.35)
		var pts := PackedVector2Array()
		for i in 21:
			var t := i / 20.0
			var p := anchor.lerp(mid, t).lerp(mid.lerp(player.global_position, t), t)
			pts.append(p)
		draw_polyline(pts, Color(0.6, 0.68, 0.75, 0.8), 2.0)
	draw_circle(anchor, 7.0, Color(0.85, 0.9, 0.95))
	# reel length indicator
	draw_rect(Rect2(30, 1040, 300, 8), Color(0.2, 0.24, 0.3))
	draw_rect(Rect2(30, 1040, 300 * (tether_max / 900.0), 8), Color(0.47, 0.78, 0.90))
