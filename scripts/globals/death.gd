extends CanvasLayer
## Space Quest rules: dying is content. A death card names the mistake with
## affection, then offers the checkpoint (written silently before every
## lethal choice), the save list, or the menu. Nobody loses an evening here.

const INK := Color(0.85, 0.9, 0.94)
const RED := Color(0.86, 0.3, 0.25)

var card: PanelContainer = null
var title_label: Label
var body_label: Label
var portrait: TextureRect
var restore_btn: Button

func _ready() -> void:
	layer = 20
	process_mode = PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.99)
	style.border_color = RED
	style.set_border_width_all(2)
	style.set_content_margin_all(36)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(760, 560)
	card.position = Vector2(1920, 1080) / 2.0 - Vector2(760, 560) / 2.0
	card.visible = false
	add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", RED)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_label)
	portrait = TextureRect.new()
	portrait.texture = load("res://astronaught/Player/astro 1 dead.png")
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(0, 160)
	v.add_child(portrait)
	body_label = Label.new()
	body_label.add_theme_font_size_override("font_size", 24)
	body_label.add_theme_color_override("font_color", INK)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(680, 120)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(body_label)
	restore_btn = _btn("RESTORE (checkpoint)", func():
		card.visible = false
		SaveManager.load_game(SaveManager.CHECKPOINT))
	v.add_child(restore_btn)
	v.add_child(_btn("LOAD A SAVE", func():
		card.visible = false
		Hud.open_load_panel()))
	v.add_child(_btn("MAIN MENU", func():
		card.visible = false
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")))

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(cb)
	return b

## The one entry point. Title is the epitaph, body is the lesson.
func die(title: String, body: String) -> void:
	if card.visible:
		return
	GameState.deaths += 1
	Sd.set_eva_silence(false)
	Sd.play(&"death_thud")
	title_label.text = title
	body_label.text = body + "\n\n(Death #%d. The embryos remain optimistic.)" % GameState.deaths
	restore_btn.visible = SaveManager.has_checkpoint()
	card.visible = true
	get_tree().paused = true
