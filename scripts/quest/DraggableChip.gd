class_name DraggableChip
extends Button
## DraggableChip — A chip button that supports both tap-to-place AND drag-and-drop.
## Emits drag_started so the parent can track the source.

signal drag_started(chip: DraggableChip)

var chip_text: String = ""
var from_bank: bool = true  # true = in word bank, false = in drop zone


func _get_drag_data(_at_position: Vector2) -> Variant:
	# Build a small visual preview shown while dragging
	var preview := Button.new()
	preview.text = chip_text
	preview.add_theme_font_size_override("font_size", int(get_theme_font_size("font_size")))
	preview.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = StyleFactory.STAGE_TUTORIAL_ACCENT
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	preview.add_theme_stylebox_override("normal", style)
	set_drag_preview(preview)
	modulate.a = 0.35  # dim original while dragging
	drag_started.emit(self)
	return {"chip_text": chip_text, "from_bank": from_bank}


func _notification(what: int) -> void:
	# Restore visibility if drag was cancelled (dropped on invalid target)
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
