extends Node
## Windowed screenshot tour, launcher half. change_scene frees the current
## scene - which this launcher IS - so the actual tour logic rides a driver
## node parked under /root where scene changes can't reach it.
##   Godot --path . res://tests/visual_tour.tscn   (windowed, never headless)

func _ready() -> void:
	var driver := Node.new()
	driver.set_script(load("res://tests/tour_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
