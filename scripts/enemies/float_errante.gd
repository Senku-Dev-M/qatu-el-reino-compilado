extends EnemyBase
## Float Errante: caja flotada que patrulla y salta hacia los lados de
## improviso (los layouts con float se desordenan con facilidad).

var hop_timer := 2.0


func _setup() -> void:
	enemy_id = "float_errante"
	max_hp = 3
	bits_drop = 5
	body_size = Vector2(58, 44)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	hop_timer -= delta
	if is_on_floor():
		if is_wall_ahead() or is_edge_ahead():
			facing = -facing
		velocity.x = facing * 105.0
		if hop_timer <= 0.0:
			hop_timer = randf_range(1.8, 3.0)
			velocity = Vector2(facing * 320.0, -620.0)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -24)
	var squash := 1.0 + (0.12 if not is_on_floor() else sin(t * 10.0) * 0.03)
	var r := Rect2(c - Vector2(29, 22 * squash), Vector2(58, 44 * squash))
	draw_rect(r, Color(0.14, 0.08, 0.05))
	draw_rect(r, Color(0.8, 0.5, 0.2), false, 2.0)
	draw_line(r.position + Vector2(6, 12), r.position + Vector2(40, 12), Color(0.6, 0.4, 0.2), 3.0)
	draw_line(r.position + Vector2(6, 22), r.position + Vector2(30, 22), Color(0.6, 0.4, 0.2), 3.0)
	eye(c + Vector2(facing * 14, -8), 3.5, Color(2.4, 1.4, 0.4))
	draw_string(UITheme.mono_font(), Vector2(-40, -56), "float: left", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.2, 1.4, 0.5, 0.85))
