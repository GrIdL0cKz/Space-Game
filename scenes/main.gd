extends Control
## Rob's main menu, kept as he drew it. Play starts a fresh run; the old
## Options button now earns its keep as Load Game (options can join later -
## there is admittedly not much to opt about yet).

func _ready() -> void:
	$Options.text = "Load Game"
	if not $Options.pressed.is_connected(_on_load_pressed):
		$Options.pressed.connect(_on_load_pressed)

func _on_play_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/craft_world.tscn")

func _on_load_pressed() -> void:
	Hud.open_load_panel()

func _on_quit_pressed() -> void:
	get_tree().quit()
