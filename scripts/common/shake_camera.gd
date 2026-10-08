class_name ShakeCamera
extends Camera2D
## Cámara que sigue al jugador con anticipación, paneo al mirar
## arriba/abajo y sacudida.

var target: Node2D
var look_ahead := 0.0
var look_vertical := 0.0
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_total := 0.0
var _look_hold := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	Events.camera_shake.connect(shake)


func shake(strength: float, duration: float) -> void:
	if strength >= _shake_strength * (_shake_time / maxf(_shake_total, 0.001)):
		_shake_strength = strength
		_shake_time = duration
		_shake_total = duration


func set_room_limits(size: Vector2) -> void:
	var view := get_viewport_rect().size
	var extra_x := maxf(0.0, (view.x - size.x) * 0.5)
	var extra_y := maxf(0.0, (view.y - size.y) * 0.5)
	limit_left = int(-extra_x)
	limit_top = int(-extra_y)
	limit_right = int(size.x + extra_x)
	limit_bottom = int(size.y + extra_y - (40 if extra_y == 0.0 else 0))


func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector2(0, -80)
		reset_smoothing()


func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var facing: float = target.get("facing") if target.get("facing") != null else 1.0
		look_ahead = lerpf(look_ahead, facing * 110.0, 1.0 - exp(-2.5 * delta))
		var want_v := 0.0
		var looking: int = target.call("look_intent") if target.has_method("look_intent") else 0
		if looking != 0:
			_look_hold += delta
			if _look_hold > 0.45:
				want_v = looking * 300.0
		else:
			_look_hold = 0.0
		look_vertical = lerpf(look_vertical, want_v, 1.0 - exp(-4.0 * delta))
		global_position = target.global_position + Vector2(look_ahead, -80 + look_vertical)
	if _shake_time > 0.0:
		_shake_time -= delta
		var k := _shake_time / maxf(_shake_total, 0.001)
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength * k
	else:
		offset = Vector2.ZERO
		_shake_strength = 0.0
