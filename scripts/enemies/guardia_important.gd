extends EnemyBase
## Guardia !important: tanque con escudo frontal. Los golpes de frente se
## bloquean; hay que atacarlo por la espalda o desde arriba (pogo).

var shield_flash := 0.0
var turn_timer := 0.0


func _setup() -> void:
	enemy_id = "guardia_important"
	max_hp = 5
	bits_drop = 10
	body_size = Vector2(62, 88)
	knock_resist = 0.7


func take_hit(hit: Dictionary) -> Dictionary:
	var dir: Vector2 = hit.get("dir", Vector2.ZERO)
	var src: Vector2 = hit.get("position", global_position)
	var from_front := dir.y == 0.0 and signf(src.x - global_position.x) == facing
	if from_front and not dead:
		shield_flash = 1.0
		AudioManager.play_sfx("sello_bad", 0.2)
		FX.burst(get_parent(), global_position + Vector2(facing * 34, -50), Color(2.4, 1.6, 0.5), 8, 280.0, 0.3, 0.3, Vector2.ZERO)
		if not GameState.get_flag("tip:important"):
			GameState.set_flag("tip:important")
			Events.notify.emit("!important bloquea de frente: atácalo por la espalda o desde arriba")
		return {"solid": true, "energy": false, "pogo": false}
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	shield_flash = maxf(0.0, shield_flash - delta * 3.0)
	turn_timer -= delta
	var tp := to_player()
	if absf(tp.x) < 500.0 and absf(tp.y) < 200.0 and turn_timer <= 0.0:
		# Se gira despacio hacia el jugador: da tiempo a pasar por detrás.
		var want := signf(tp.x)
		if want != facing:
			facing = want
			turn_timer = 1.1
	if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
		facing = -facing
		turn_timer = 1.1
	velocity.x = facing * 60.0
	move_and_slide()


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.12, 0.08, 0.06)
	var step := sin(t * 5.0) * 3.0
	draw_line(Vector2(-12, -22), Vector2(-14 + step, 0), dark, 10.0)
	draw_line(Vector2(12, -22), Vector2(10 - step, 0), dark, 10.0)
	draw_rect(Rect2(-24, -86, 48, 66), dark)
	draw_rect(Rect2(-24, -86, 48, 66), Color(0.5, 0.35, 0.2), false, 2.0)
	eye(Vector2(10, -72), 3.5, Color(2.4, 1.2, 0.4))
	# Escudo frontal.
	var shield := Rect2(24, -92, 16, 80)
	var sc := Color(2.2, 1.4, 0.4).lerp(Color(3, 3, 3), shield_flash)
	draw_rect(shield, Color(0.25, 0.16, 0.08))
	draw_rect(shield, sc, false, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(UITheme.mono_font(), Vector2(-46, -100), "!important", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(2.4, 1.3, 0.4, 0.9))
