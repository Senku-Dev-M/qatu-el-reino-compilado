class_name Fade
extends CanvasLayer
## Fundido a negro para transiciones.

var rect: ColorRect
var _tween: Tween


func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func fade_to(alpha: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	if duration <= 0.0:
		rect.color.a = alpha
		await get_tree().process_frame
		return
	_tween = create_tween()
	_tween.tween_property(rect, "color:a", alpha, duration)
	await _tween.finished
