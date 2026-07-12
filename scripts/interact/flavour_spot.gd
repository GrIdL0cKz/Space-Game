class_name FlavourSpot
extends Interactable
## Look-at-things: cycles through its lines, one per interaction. The cheap
## joke delivery system, and the loneliness delivery system - same pipe.

var lines: Array = []
var computer_lines: Array = []  # spoken by the ship computer box instead
var _idx: int = 0

static func make(p_prompt: String, p_lines: Array, p_computer: Array = []) -> FlavourSpot:
	var f := FlavourSpot.new()
	f.prompt = p_prompt
	f.lines = p_lines
	f.computer_lines = p_computer
	return f

func _interact(_player: Node) -> void:
	if not computer_lines.is_empty():
		for l in computer_lines:
			Hud.computer_say(String(l))
		computer_lines = []
		return
	if lines.is_empty():
		Hud.toast("Nothing more to see.")
		return
	Hud.toast(String(lines[_idx % lines.size()]))
	_idx += 1
