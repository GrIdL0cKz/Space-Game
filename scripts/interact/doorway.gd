class_name Doorway
extends Interactable
## A door between scenes. Optionally locked behind an item (keycards) or a
## flag; walking through slides the door and lands you at spawn_pos in the
## target scene. Deadly doors are NOT this class - see the airlock.

var target_scene: String = ""
var spawn_pos := Vector2(200, 860)
var required_item: String = ""
var locked_line: String = "It's locked."

static func make(p_prompt: String, scene: String, spawn: Vector2,
		req_item: String = "", p_locked_line: String = "") -> Doorway:
	var d := Doorway.new()
	d.prompt = p_prompt
	d.target_scene = scene
	d.spawn_pos = spawn
	d.required_item = req_item
	if p_locked_line != "":
		d.locked_line = p_locked_line
	return d

func _interact(_player: Node) -> void:
	if required_item != "" and not GameState.has_item(required_item):
		Hud.toast(locked_line)
		Sd.play(&"switch_click", -10.0, 0.7)
		return
	Sd.play(&"door_slide")
	SaveManager._pending_pos = [spawn_pos.x, spawn_pos.y]
	get_tree().change_scene_to_file.call_deferred(target_scene)
