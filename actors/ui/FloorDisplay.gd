extends Panel

signal clicked


@export var floor_number = 1


func _ready():
	$Label.text = str(floor_number)


func _on_gui_input(event):
	if event is InputEventScreenTouch and !event.pressed:
		clicked.emit(floor_number)
