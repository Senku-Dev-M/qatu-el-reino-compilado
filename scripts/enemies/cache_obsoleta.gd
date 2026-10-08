extends EnemyBase
## Caché Obsoleta: un reflejo que ocupa la posición donde estabas hace un
## momento. Sirve datos viejos: si te quedas quieto, te alcanza.

const DELAY := 1.2

var trail: Array = []  # [tiempo, posición]


func _setup() -> void:
	enemy_id = "cache_obsoleta"
	max_hp = 3
	bits_drop = 7
	body_size = Vector2(40, 72)
	uses_gravity = false
	collision_mask = 0


func _after_setup() -> void:
	position.y -= 60


func _ai(delta: float) -> void:
	var p := player()
	if p == null:
		return
	trail.append([t, p.global_position])
	while trail.size() > 2 and t - float(trail[1][0]) > DELAY:
		trail.pop_front()
	var target: Vector2 = p.global_position
	var active := p.global_position.distance_to(global_position) < 760.0
	if active and t - float(trail[0][0]) >= DELAY * 0.8:
		target = trail[0][1]
	elif not active:
		target = global_position
	global_position = global_position.lerp(target, 1.0 - exp(-5.0 * delta))
	facing = signf(p.global_position.x - global_position.x) if absf(p.global_position.x - global_position.x) > 5.0 else facing


func _draw_body() -> void:
	var col := Color(0.8, 1.2, 2.0, 0.35 + 0.1 * sin(t * 6.0))
	# Silueta del aprendiz con estática.
	draw_rect(Rect2(-14, -70, 28, 50), col)
	draw_circle(Vector2(0, -80), 16, col)
	for i in 6:
		var y := -90 + fmod(t * 120.0 + i * 20.0, 100.0)
		draw_line(Vector2(-18, y), Vector2(18, y), Color(1.2, 1.6, 2.4, 0.25), 2.0)
	eye(Vector2(-6, -82), 2.5, Color(2.6, 0.6, 0.6))
	eye(Vector2(6, -82), 2.5, Color(2.6, 0.6, 0.6))
	draw_string(UITheme.mono_font(), Vector2(-26, -108), "stale", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.4, 1.6, 2.4, 0.8))
