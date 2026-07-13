class_name Interactable
extends Area2D
## Anything the player can act on: doors, lockers, consoles, bodies, panels.
## Walk into range and press E (the prompt shows above the hotbar), or click
## it while in range. Clicking never steers the player - that got annoying.
## Subclasses override _interact(); `enabled` gates broken/unpowered things.

@export var prompt: String = "Look"
@export var enabled: bool = true

func _ready() -> void:
	add_to_group("interactable")
	input_pickable = true
	input_event.connect(_on_click)
	collision_layer = 0
	collision_mask = 2  # the player
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("notify_range_entered"):
		body.notify_range_entered(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("notify_range_exited"):
		body.notify_range_exited(self)

func _on_click(_viewport: Node, event: InputEvent, _shape: int) -> void:
	var tapped: bool = event is InputEventScreenTouch and not event.pressed
	var clicked: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if not (tapped or clicked):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and "in_range" in player and player.in_range.has(self):
		try_interact(player)
		get_viewport().set_input_as_handled()

func try_interact(player: Node) -> void:
	if enabled:
		_interact(player)
	else:
		_interact_disabled(player)

## Override in subclasses.
func _interact(_player: Node) -> void:
	pass

## What a broken / unpowered version says. Override for flavour.
func _interact_disabled(_player: Node) -> void:
	Hud.toast("Nothing happens.")
