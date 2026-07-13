class_name InvSlotButton
extends Button
## A backpack grid button that can also be dragged onto a hotbar slot.

var item_id: String = ""

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id == "":
		return null
	var prev := TextureRect.new()
	prev.texture = Hud._icon(item_id)
	prev.custom_minimum_size = Vector2(48, 48)
	prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(prev)
	return {"source": "inventory", "id": item_id}
