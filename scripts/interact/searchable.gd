class_name Searchable
extends Interactable
## A place worth rummaging: locker, drawer, crate, desk, crew bunk. Yields
## its items once (flag-gated), then gives an empty line. The find_line is
## the room's chance to say something in the game's voice.

var items: Array = []
var flag_key: String = ""
var find_line: String = ""
var empty_line: String = "Nothing else in there."
var read_id: String = ""  # if set, opens the reader instead of/after loot

static func make(p_prompt: String, p_flag: String, p_items: Array,
		p_find := "", p_empty := "", p_read := "") -> Searchable:
	var s := Searchable.new()
	s.prompt = p_prompt
	s.flag_key = p_flag
	s.items = p_items
	s.find_line = p_find
	if p_empty != "":
		s.empty_line = p_empty
	s.read_id = p_read
	return s

func _interact(_player: Node) -> void:
	if bool(GameState.get_flag(flag_key)):
		Hud.toast(empty_line)
		return
	GameState.set_flag(flag_key)
	Sd.play(&"door_slide", -8.0, 1.3)
	if find_line != "":
		Hud.toast(find_line)
	for id in items:
		GameState.add_item(String(id))
	if read_id != "":
		Hud.open_reader(read_id)
