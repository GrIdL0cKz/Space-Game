extends Node2D
## The P-1's cockpit, first person: canopy struts, a dash, a crosshair on
## your mouse, and debris coming at the ship. Rocks spawn deep and grow as
## they approach; shoot them before they reach the canopy. Three get
## through and the fighter - and you - stop being distinct objects.
## Clearing the wave flags debris_cleared and flies you home.

const WAVE_SIZE := 14
const HULL_MAX := 3
const APPROACH_TIME := 5.2
const SPAWN_EVERY := 1.15

var crosshair := Vector2(960, 500)
var targets: Array = []
var spawned: int = 0
var destroyed: int = 0
var hull: int = HULL_MAX
var spawn_timer: float = 1.0
var over: bool = false
var stars: Array = []

func _ready() -> void:
	add_to_group("world")
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 77
	for i in 90:
		stars.append([Vector2(rnd.randf_range(0, 1920), rnd.randf_range(0, 900)), rnd.randf_range(0.3, 1.0)])
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if over:
		return
	crosshair = get_global_mouse_position()
	spawn_timer -= delta
	if spawn_timer <= 0.0 and spawned < WAVE_SIZE:
		_spawn_target()
		# The back half of the wave comes in pairs.
		if spawned >= 6 and spawned < WAVE_SIZE:
			_spawn_target()
		spawn_timer = SPAWN_EVERY
	for t in targets:
		t["p"] += delta / APPROACH_TIME
		t["pos"] += t["vel"] * delta
	# impacts
	for t in targets.duplicate():
		if t["p"] >= 1.0:
			targets.erase(t)
			hull -= 1
			Sd.play(&"death_thud", -6.0)
			if hull <= 0:
				_lose()
				return
	if spawned >= WAVE_SIZE and targets.is_empty():
		_win()
	queue_redraw()

func _spawn_target() -> void:
	spawned += 1
	targets.append({
		"pos": Vector2(randf_range(300, 1620), randf_range(160, 700)),
		"p": 0.0,
		"seed": randi() % 1000,
		"vel": Vector2(randf_range(-46, 46), randf_range(-26, 26)),
	})

func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Sd.play(&"switch_click", -4.0, 1.6)
		for t in targets.duplicate():
			var r: float = 10.0 + t["p"] * 70.0
			if crosshair.distance_to(t["pos"]) <= r + 5.0:
				targets.erase(t)
				destroyed += 1
				Sd.play(&"airlock_clunk", -8.0, 1.5)
				break
		queue_redraw()

func _win() -> void:
	over = true
	GameState.set_flag("debris_cleared")
	Hud.toast("Scope clear. The ship keeps its paint.")
	Hud.computer_say("All fragments dispersed or disappointed. Refuelling the P-1 and reopening the bay. That was flying.")
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_callback(func():
		SaveManager._pending_pos = [800.0, 631.0]
		get_tree().change_scene_to_file("res://scenes/rooms/fighter_bay.tscn"))

func _lose() -> void:
	over = true
	Death.die("PYRRHIC AERODYNAMICS",
		"The third rock came through the canopy, which is not how canopies or rocks are supposed to work together. The P-1 is now a statistic; so, briefly, were you.")

func _draw() -> void:
	# --- space
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.016, 0.035))
	for s in stars:
		draw_circle(s[0], 1.5, Color(0.9, 0.92, 0.96, s[1]))
	# --- targets (drawn far-to-near so close rocks overlap distant ones)
	var sorted := targets.duplicate()
	sorted.sort_custom(func(a, b): return a["p"] < b["p"])
	for t in sorted:
		var r: float = 10.0 + t["p"] * 70.0
		var col := Color(0.55, 0.5, 0.46).lerp(Color(0.75, 0.55, 0.4), t["p"])
		var rnd := RandomNumberGenerator.new()
		rnd.seed = t["seed"]
		var pts := PackedVector2Array()
		for i in 8:
			var ang := TAU * i / 8.0
			pts.append(t["pos"] + Vector2.from_angle(ang) * r * rnd.randf_range(0.75, 1.15))
		draw_colored_polygon(pts, col)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.8), 2.0)
	# --- canopy frame: struts + dash
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(120, 0), Vector2(30, 1080), Vector2(0, 1080)]),
			PackedColorArray([Color(0.13, 0.15, 0.19)]))
	draw_polygon(PackedVector2Array([Vector2(1920, 0), Vector2(1800, 0), Vector2(1890, 1080), Vector2(1920, 1080)]),
			PackedColorArray([Color(0.13, 0.15, 0.19)]))
	draw_rect(Rect2(0, 0, 1920, 46), Color(0.13, 0.15, 0.19))
	# dash
	draw_rect(Rect2(0, 900, 1920, 180), Color(0.16, 0.18, 0.23))
	draw_line(Vector2(0, 900), Vector2(1920, 900), Color(0, 0, 0), 4.0)
	draw_rect(Rect2(80, 930, 300, 120), Color(0.05, 0.09, 0.12))
	draw_rect(Rect2(1540, 930, 300, 120), Color(0.05, 0.09, 0.12))
	# hull pips + wave count on the dash
	for i in HULL_MAX:
		var col := Color(0.45, 0.75, 0.5) if i < hull else Color(0.3, 0.12, 0.1)
		draw_rect(Rect2(120 + i * 60, 960, 44, 22), col)
	draw_string(ThemeDB.fallback_font, Vector2(130, 1020), "HULL", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.6, 0.68, 0.74))
	draw_string(ThemeDB.fallback_font, Vector2(1570, 985), "TARGETS %d/%d" % [destroyed, WAVE_SIZE],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.47, 0.78, 0.9))
	# --- crosshair
	var c := crosshair
	draw_arc(c, 22.0, 0, TAU, 24, Color(0.47, 0.78, 0.9), 2.0)
	draw_line(c + Vector2(-34, 0), c + Vector2(-12, 0), Color(0.47, 0.78, 0.9), 2.0)
	draw_line(c + Vector2(12, 0), c + Vector2(34, 0), Color(0.47, 0.78, 0.9), 2.0)
	draw_line(c + Vector2(0, -34), c + Vector2(0, -12), Color(0.47, 0.78, 0.9), 2.0)
	draw_line(c + Vector2(0, 12), c + Vector2(0, 34), Color(0.47, 0.78, 0.9), 2.0)
