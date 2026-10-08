extends "res://scripts/enemies/guardia_important.gd"
## Guardia CORS: bloquea de frente las peticiones de otro origen. Hay que
## rodearlo (atacarlo por la espalda o desde arriba).


func _setup() -> void:
	super._setup()
	enemy_id = "guardia_cors"
	max_hp = 5
	bits_drop = 10


func take_hit(hit: Dictionary) -> Dictionary:
	# Mostrar el aviso propio antes que el de !important.
	if not GameState.get_flag("tip:cors"):
		var dir: Vector2 = hit.get("dir", Vector2.ZERO)
		var src: Vector2 = hit.get("position", global_position)
		if dir.y == 0.0 and signf(src.x - global_position.x) == facing:
			GameState.set_flag("tip:cors")
			GameState.set_flag("tip:important")
			Events.notify.emit("Bloqueado por CORS: rodéalo o atácalo desde arriba")
	return super.take_hit(hit)


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.12, 0.2, 0.24)
	var step := sin(t * 5.0) * 3.0
	draw_line(Vector2(-12, -22), Vector2(-14 + step, 0), dark, 10.0)
	draw_line(Vector2(12, -22), Vector2(10 - step, 0), dark, 10.0)
	draw_rect(Rect2(-24, -86, 48, 66), dark)
	draw_rect(Rect2(-24, -86, 48, 66), Color(0.4, 0.9, 1.0), false, 2.0)
	eye(Vector2(10, -72), 3.5, Color(0.6, 2.2, 2.4))
	var shield := Rect2(24, -92, 16, 80)
	var sc := Color(0.5, 2.0, 2.2).lerp(Color(3, 3, 3), shield_flash)
	draw_rect(shield, Color(0.06, 0.16, 0.2))
	draw_rect(shield, sc, false, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(UITheme.mono_font(), Vector2(-26, -100), "CORS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 2.0, 2.3, 0.9))
