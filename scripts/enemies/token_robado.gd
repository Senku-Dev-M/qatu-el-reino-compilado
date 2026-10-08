extends EnemyBase
## Ladrón de Tokens: vuela hacia ti y, al alcanzarte, se lleva tu access
## token (el refresh sigue siendo tuyo: renuévalo).

var swoop := 0.0
var cooldown := 1.2
var fleeing := 0.0
var carried := false
var home := Vector2.ZERO


func _setup() -> void:
	enemy_id = "token_robado"
	max_hp = 3
	bits_drop = 8
	body_size = Vector2(46, 42)
	uses_gravity = false
	collision_mask = 0


func _after_setup() -> void:
	position.y -= 110
	home = position


func _ai(delta: float) -> void:
	cooldown -= delta
	fleeing = maxf(0.0, fleeing - delta)
	var p := player()
	var tp := to_player()
	if fleeing > 0.0:
		velocity = velocity.lerp((-tp).normalized() * 280.0 + Vector2(0, -60), 1.0 - exp(-3.0 * delta))
	elif swoop > 0.0:
		swoop -= delta
		velocity = velocity.lerp(tp.normalized() * 420.0, 1.0 - exp(-6.0 * delta))
	elif cooldown <= 0.0 and tp.length() < 520.0:
		swoop = 1.0
		cooldown = 2.6
		AudioManager.play_sfx("spit", 0.2)
	else:
		var goal := home + Vector2(sin(t * 1.1) * 120.0, sin(t * 1.7) * 34.0)
		velocity = velocity.lerp((goal - position) * 2.2, 1.0 - exp(-3.0 * delta))
	position += velocity * delta
	facing = signf(tp.x) if absf(tp.x) > 5.0 else facing
	# Robo del token al tocar al jugador.
	if p and tp.length() < 62.0 and fleeing <= 0.0 and p.token_valid():
		p.revoke_token()
		carried = true
		fleeing = 2.4
		flash = 1.0
		Events.camera_shake.emit(6.0, 0.25)


func _on_death() -> void:
	if carried:
		var p := player()
		if p and p.has_refresh:
			p.grant_token(p.token_scope, 0.0, false)
			Events.notify.emit("Recuperas el access token robado")


func _draw_body() -> void:
	var c := Vector2(0, -21)
	var col := Color(2.4, 1.3, 0.5)
	var flap := sin(t * 14.0) * 8.0
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(side * 30, -10 - flap), c + Vector2(side * 42, 10), c + Vector2(side * 16, 8)]), Color(0.1, 0.08, 0.14))
	draw_circle(c, 17, Color(0.12, 0.1, 0.16))
	draw_arc(c, 17, 0, TAU, 20, Color(col, 0.7), 2.0, true)
	eye(c + Vector2(-5, -3), 2.5, col)
	eye(c + Vector2(5, -3), 2.5, col)
	if carried:
		var badge := Rect2(c + Vector2(-22, 16), Vector2(44, 16))
		draw_rect(badge, Color(0.06, 0.05, 0.02))
		draw_rect(badge, Color(2.4, 1.9, 0.8), false, 1.5)
		draw_string(UITheme.mono_font(), badge.position + Vector2(4, 12), "token", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(2.4, 1.9, 0.8))
	draw_string(UITheme.mono_font(), Vector2(-26, -50), "ladrón", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col, 0.8))
