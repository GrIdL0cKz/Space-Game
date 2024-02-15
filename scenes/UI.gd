extends Control



func pop_to_ui(instance):
	for child in $Popups.get_children():
		child.queue_free()
	
	$Popups.add_child(instance)
