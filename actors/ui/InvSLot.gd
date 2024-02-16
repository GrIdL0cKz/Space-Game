extends Panel


var item_data = {}


func put_item(data: Dictionary):
	item_data = data
	
	$Icon.texture = load(item_data['texture_path'])


func clear():
	item_data = {}
