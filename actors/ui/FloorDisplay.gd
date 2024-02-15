extends Panel


@export var floor_number = 1


func _ready():
	$Label.text = str(floor_number)
