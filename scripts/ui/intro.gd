extends Control
## The story, told in space text before the first frame of play. Each beat
## fades in over the starfield, holds, and yields to the next. Any key
## skips a beat; holding Esc skips the lot. Silence throughout - the first
## sound in the game belongs to the cryo pod.

const BEATS := [
	"In the year the crossing began, Earth had one engine fast enough to matter.\n\nIt was pointed at Kepler-442b, and it was called PERENNIAL.",
	"The cargo: five hundred and twelve human embryos in cold storage.\n\nThe crew: six specialists, asleep beside them.\n\nThe trip: two hundred and ninety-seven years.",
	"You are the mission scientist. You boarded knowing every friend you had would be gone before you woke.\n\nYou slept anyway. It seemed important.",
	"The automation was supposed to wake you on arrival, in orbit, to applause from nobody.\n\nThe automation has woken you early.\n\nThat is all you know.",
]
const FADE := 1.2
const HOLD := 4.2

var beat_index: int = 0
var label: Label
var tween: Tween
var advancing: bool = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.012, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 297
	for i in 160:
		var star := ColorRect.new()
		star.color = Color(0.9, 0.92, 0.96, rnd.randf_range(0.25, 0.9))
		star.size = Vector2.ONE * (2 if rnd.randf() < 0.85 else 3)
		star.position = Vector2(rnd.randf_range(0, 1920), rnd.randf_range(0, 1080))
		add_child(star)
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.93))
	label.custom_minimum_size = Vector2(900, 0)
	label.position = Vector2(0, 0)
	label.modulate.a = 0.0
	add_child(label)
	var skip := Label.new()
	skip.text = "any key: next    esc: skip"
	skip.position = Vector2(20, 1040)
	skip.add_theme_font_size_override("font_size", 16)
	skip.add_theme_color_override("font_color", Color(0.4, 0.46, 0.52))
	add_child(skip)
	_show_beat()

func _show_beat() -> void:
	if beat_index >= BEATS.size():
		_finish()
		return
	advancing = false
	label.text = BEATS[beat_index]
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, FADE)
	tween.tween_interval(HOLD)
	tween.tween_property(label, "modulate:a", 0.0, FADE)
	tween.tween_callback(_next_beat)

func _next_beat() -> void:
	beat_index += 1
	_show_beat()

func _advance_now() -> void:
	if advancing:
		return
	advancing = true
	if tween != null and tween.is_valid():
		tween.kill()
	var out := create_tween()
	out.tween_property(label, "modulate:a", 0.0, 0.25)
	out.tween_callback(_next_beat)

func _finish() -> void:
	get_tree().change_scene_to_file("res://scenes/craft_world.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_finish()
		else:
			_advance_now()
	elif event is InputEventMouseButton and event.pressed:
		_advance_now()
