extends Interactable
## The deck elevator. Walk up, press E (or click it): doors open with a hum
## and the floor panel appears - one action, no open/close toggle dance.
## The old version listened only for touch-release events and fought the
## click-to-move handler; that was the "sticky" feel.

@export var floor_number: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super()
	prompt = "Call elevator"
	add_to_group("Elevator")

func _interact(_player: Node) -> void:
	Sd.play(&"elevator_hum", -6.0)
	sprite.play("open")
	var panel: Node = load("res://actors/ui/popups/ElevatorFloorSelectView.tscn").instantiate()
	ManagerGame.global_player_ui_ref.pop_to_ui(panel)
	# Close the doors again once the panel is gone.
	panel.tree_exited.connect(func():
		if is_instance_valid(sprite):
			sprite.play("close"))
