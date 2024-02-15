extends Panel






func _ready():
	for child in $VBoxContainer/CenterContainer/Grid.get_children():
		child.clicked.connect(on_clicked)


func on_clicked(floor_number):
	ManagerGame.elevator_floor_selected.emit(floor_number)
	
	get_parent().close()


func _on_close_pressed():
	get_parent().close()
