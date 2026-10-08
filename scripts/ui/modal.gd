class_name Modal
extends Control
## Base de pantallas modales: pausan el juego mientras están abiertas.

signal closed(result: Variant)

var dim: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


func open_modal() -> void:
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	AudioManager.play_sfx("ui_open")


func close_modal(result: Variant = null) -> void:
	if not visible:
		return
	visible = false
	AudioManager.play_sfx("ui_close")
	closed.emit(result)


func accept_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")


func cancel_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
