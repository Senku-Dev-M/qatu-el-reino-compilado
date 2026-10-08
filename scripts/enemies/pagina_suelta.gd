extends EnemyBase
## Hoja suelta: esbirro volador de la Consulta N+1 y del Scroll Infinito.


func _setup() -> void:
	enemy_id = ""
	max_hp = 1
	bits_drop = 1
	body_size = Vector2(30, 36)
	uses_gravity = false
	collision_mask = 0


func _ai(delta: float) -> void:
	var tp := to_player() + Vector2(0, -40)
	var want := tp.normalized() * 150.0 if tp.length() < 900.0 else Vector2(sin(t) * 40.0, cos(t * 0.8) * 30.0)
	velocity = velocity.lerp(want + Vector2(0, sin(t * 5.0) * 60.0), 1.0 - exp(-2.0 * delta))
	position += velocity * delta
	facing = signf(velocity.x) if absf(velocity.x) > 5.0 else facing


func _draw_body() -> void:
	var c := Vector2(0, -18)
	var sway := sin(t * 6.0) * 0.25
	draw_set_transform(c, sway, Vector2.ONE)
	draw_rect(Rect2(-14, -18, 28, 36), Color(0.9, 0.85, 0.72))
	for i in 4:
		draw_line(Vector2(-9, -10 + i * 7), Vector2(9, -10 + i * 7), Color(0.4, 0.35, 0.3), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	eye(c + Vector2(-5, -6), 2.0, Color(2.4, 0.8, 0.4))
	eye(c + Vector2(5, -6), 2.0, Color(2.4, 0.8, 0.4))
