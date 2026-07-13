class_name HotbarSlot
extends PanelContainer
## One hotbar slot. Drag it onto another slot to reorder; drop a backpack
## item onto it to bind that item there. GameState.hotbar owns the truth.

var index: int = 0
var item_id: String = ""

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id == "":
		return null
	var prev := TextureRect.new()
	prev.texture = Hud._icon(item_id)
	prev.custom_minimum_size = Vector2(48, 48)
	prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(prev)
	return {"source": "hotbar", "index": index, "id": item_id}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and String(data.get("source", "")) in ["hotbar", "inventory"]

func _drop_data(_at: Vector2, data: Variant) -> void:
	Hud.hotbar_drop(data, index)
