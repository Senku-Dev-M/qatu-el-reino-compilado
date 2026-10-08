extends "res://scripts/enemies/guardia_important.gd"
## Portero 403: sabe quién eres, pero no te deja pasar. Bloquea de frente.


func _setup() -> void:
	super._setup()
	enemy_id = "portero_403"
	max_hp = 5
	bits_drop = 11


func take_hit(hit: Dictionary) -> Dictionary:
	if not GameState.get_flag("tip:403"):
		var dir: Vector2 = hit.get("dir", Vector2.ZERO)
		var src: Vector2 = hit.get("position", global_position)
		if dir.y == 0.0 and signf(src.x - global_position.x) == facing:
			GameState.set_flag("tip:403")
			GameState.set_flag("tip:important")
			Events.notify.emit("403: autenticado, pero sin permiso. Rodéalo o golpéalo desde arriba")
	return super.take_hit(hit)


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.12, 0.1, 0.2)
	var step := sin(t * 5.0) * 3.0
	draw_line(Vector2(-12, -22), Vector2(-14 + step, 0), dark, 10.0)
	draw_line(Vector2(12, -22), Vector2(10 - step, 0), dark, 10.0)
	draw_rect(Rect2(-24, -86, 48, 66), dark)
	draw_rect(Rect2(-24, -86, 48, 66), Color(2.2, 1.5, 0.5), false, 2.0)
	eye(Vector2(10, -72), 3.5, Color(2.4, 1.4, 0.5))
	var shield := Rect2(24, -92, 16, 80)
	var sc := Color(2.4, 1.3, 0.4).lerp(Color(3, 3, 3), shield_flash)
	draw_rect(shield, Color(0.2, 0.14, 0.06))
	draw_rect(shield, sc, false, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(UITheme.mono_font(), Vector2(-20, -100), "403", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(2.4, 1.4, 0.5, 0.9))
