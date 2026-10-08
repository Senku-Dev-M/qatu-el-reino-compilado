class_name Error500
extends EnemyBase
## Error 500: residuo inestable. Embiste cuando te ve y, cada vez que recibe un
## golpe, suelta fragmentos de stack trace hacia arriba. Al morir detona.

enum S { WALK, WINDUP, CHARGE, REST }

var s := S.WALK
var timer := 0.0


func _setup() -> void:
	enemy_id = "error_500"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(52, 52)


func take_hit(hit: Dictionary) -> Dictionary:
	var r := super.take_hit(hit)
	if not dead:
		_fragments(2)
		EnemyKit.tip("error_500", "Error 500: cada golpe suelta fragmentos del stack trace. Golpea y apártate")
	return r


func _on_death() -> void:
	_fragments(5)


func _fragments(n: int) -> void:
	for i in n:
		var vx := (float(i) - float(n - 1) * 0.5) * 170.0
		BossAttacks.projectile(get_parent(), global_position + Vector2(0, -40), Vector2(vx, -560.0), 1500.0, "at()")
	AudioManager.play_sfx("spit", 0.3)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	timer -= delta
	var tp := to_player()
	match s:
		S.WALK:
			if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
				facing = -facing
			velocity.x = facing * 70.0
			if absf(tp.x) < 400.0 and absf(tp.y) < 110.0 and tp.x != 0.0:
				facing = signf(tp.x)
				s = S.WINDUP
				timer = 0.45
		S.WINDUP:
			velocity.x = 0.0
			if timer <= 0.0:
				s = S.CHARGE
				timer = 0.6
		S.CHARGE:
			velocity.x = facing * 480.0
			if timer <= 0.0 or is_wall_ahead() or (is_on_floor() and is_edge_ahead()):
				s = S.REST
				timer = 0.8
		S.REST:
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			if timer <= 0.0:
				s = S.WALK
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -26)
	var amp := 3.0 if s == S.WINDUP else 0.8
	var shake := Vector2(sin(t * 60.0), cos(t * 53.0)) * amp
	var col := Color(3.0, 1.6, 0.4) if s == S.WINDUP else Color(2.6, 0.5, 0.3)
	draw_circle(c + shake, 30.0, Color(col, 0.12))
	var pts := PackedVector2Array()
	for i in 10:
		var rr := 24.0 if i % 2 == 0 else 16.0
		pts.append(c + shake + Vector2.RIGHT.rotated(i * TAU / 10.0 + t * 0.6) * rr)
	draw_colored_polygon(pts, Color(0.12, 0.03, 0.03))
	pts.append(pts[0])
	draw_polyline(pts, col, 2.0)
	EnemyKit.label(self, c + shake + Vector2(0, 6), "500", 16, col)
	eye(c + shake + Vector2(facing * 10, -10), 3.0, Color(3.0, 1.4, 0.4))
