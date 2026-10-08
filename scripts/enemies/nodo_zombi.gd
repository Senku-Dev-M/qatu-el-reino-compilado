extends EnemyBase
## Tanque lento que, al "morir" la primera vez, vuelve a levantarse
## (ocultar un nodo no es eliminarlo).

enum S { WALK, WINDUP, LUNGE, DOWN }

var s := S.WALK
var timer := 0.0
var revived := false


func _setup() -> void:
	enemy_id = "nodo_zombi"
	max_hp = 5
	bits_drop = 9
	body_size = Vector2(60, 84)
	knock_resist = 0.6


func take_hit(hit: Dictionary) -> Dictionary:
	if s == S.DOWN:
		return {"solid": true, "energy": false, "pogo": true}
	if hp - int(hit.get("damage", 1)) <= 0 and not revived:
		hp = 0
		flash = 1.0
		AudioManager.play_sfx("enemy_death")
		s = S.DOWN
		timer = 1.8
		contact.set_enabled(false)
		FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.5, 0.5, 0.5), 14, 300.0, 0.6, 0.4)
		if not GameState.get_flag("tip:zombi"):
			GameState.set_flag("tip:zombi")
			Events.notify.emit("display: none no elimina el nodo... ¡sigue en el DOM!")
		return {"solid": true, "energy": true, "pogo": true}
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	timer -= delta
	var tp := to_player()
	match s:
		S.WALK:
			if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
				facing = -facing
			velocity.x = facing * 70.0
			if absf(tp.x) < 280.0 and absf(tp.y) < 120.0 and signf(tp.x) == facing:
				s = S.WINDUP
				timer = 0.45
				velocity.x = 0.0
		S.WINDUP:
			velocity.x = 0.0
			if timer <= 0.0:
				s = S.LUNGE
				timer = 0.4
				AudioManager.play_sfx("spit", 0.1)
		S.LUNGE:
			velocity.x = facing * 460.0
			if timer <= 0.0 or is_wall_ahead():
				s = S.WALK
		S.DOWN:
			velocity.x = 0.0
			if timer <= 0.0:
				revived = true
				hp = 3
				s = S.WALK
				contact.set_enabled(true)
				flash = 1.0
				FX.burst(get_parent(), global_position + Vector2(0, -40), Color(2.2, 0.5, 1.8), 20, 400.0, 0.6, 0.4)
				AudioManager.play_sfx("boss_roar", 0.3)
	move_and_slide()


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.06, 0.05, 0.07)
	var down_k := 1.0 if s == S.DOWN else 0.0
	if s == S.DOWN:
		draw_rect(Rect2(-40, -22, 80, 22), Color(0.1, 0.1, 0.12))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-50, -34), "display: none", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.6, 0.7, 0.6 + 0.4 * sin(t * 8.0)))
		return
	var lean := 8.0 if s == S.WINDUP else (14.0 if s == S.LUNGE else 0.0)
	var step := sin(t * 5.0) * 3.0
	# Piernas.
	draw_line(Vector2(-12, -20), Vector2(-14 + step, 0), dark, 9.0)
	draw_line(Vector2(12, -20), Vector2(10 - step, 0), dark, 9.0)
	# Cuerpo: caja-nodo cosida.
	var body := Rect2(-30 + lean, -86, 60, 68)
	draw_rect(body, dark)
	draw_rect(body, Color(0.35, 0.3, 0.4), false, 2.0)
	for i in 3:
		draw_line(Vector2(-10 + lean, -76 + i * 18), Vector2(10 + lean, -70 + i * 18), Color(0.4, 0.35, 0.45), 2.0)
	# Brazos colgantes.
	draw_line(Vector2(28 + lean, -76), Vector2(40 + lean * 2, -40 + step), dark, 7.0)
	draw_line(Vector2(-28 + lean, -76), Vector2(-34, -44 - step), dark, 7.0)
	eye(Vector2(14 + lean, -70), 4.0)
	eye(Vector2(-2 + lean, -72), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-26, -96), "<div>", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.7, 0.9, 0.8 - down_k))
	if revived:
		draw_string(font, Vector2(-30, -116), "ref", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(2.2, 0.5, 1.8, 0.8))
