class_name FrameworkObsoleto
extends EnemyBase
## Framework Abandonado: armadura oxidada que dispara avisos «deprecated».
## Al perder la mitad de la vida se le cae la armadura (ya nadie la mantiene):
## queda sin disparos, pero corre y salta mucho más rápido.

var shoot_cd := 1.8
var broken := false
var hop_cd := 0.8


func _setup() -> void:
	enemy_id = "framework_obsoleto"
	max_hp = 6
	bits_drop = 10
	body_size = Vector2(54, 74)
	knock_resist = 0.5


func take_hit(hit: Dictionary) -> Dictionary:
	var r := super.take_hit(hit)
	if not dead and not broken and hp * 2 <= max_hp:
		broken = true
		knock_resist = 0.0
		AudioManager.play_sfx("break_wall", 0.2)
		FX.burst(get_parent(), global_position + Vector2(0, -40), Color(1.2, 0.7, 0.3), 26, 460.0, 0.7, 0.5)
		EnemyKit.tip("framework", "Sin armadura, el framework abandonado es frágil pero muy rápido")
	return r


func _ai(delta: float) -> void:
	apply_gravity(delta)
	var tp := to_player()
	var near := absf(tp.x) < 600.0 and absf(tp.y) < 160.0
	if not broken:
		shoot_cd -= delta
		if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
			facing = -facing
		velocity.x = facing * 40.0
		if near and shoot_cd <= 0.0 and tp.x != 0.0:
			facing = signf(tp.x)
			velocity.x = 0.0
			BossAttacks.projectile(get_parent(), global_position + Vector2(facing * 34, -46), Vector2(facing * 380.0, 0.0), 0.0, "@deprecated")
			AudioManager.play_sfx("spit", 0.2)
			shoot_cd = 2.2
	else:
		hop_cd -= delta
		if near and tp.x != 0.0:
			facing = signf(tp.x)
		if is_on_floor():
			if is_wall_ahead() or (is_edge_ahead() and not near):
				facing = -facing
			velocity.x = facing * 230.0
			if is_edge_ahead():
				velocity.x = 0.0
			if hop_cd <= 0.0:
				velocity.y = -640.0
				hop_cd = 1.1
	move_and_slide()


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var rust := Color(1.2, 0.6, 0.25)
	var dark := Color(0.1, 0.07, 0.05)
	var step := sin(t * (14.0 if broken else 5.0)) * 4.0
	draw_line(Vector2(-10, -24), Vector2(-12 + step, 0), dark, 8.0)
	draw_line(Vector2(10, -24), Vector2(8 - step, 0), dark, 8.0)
	if broken:
		draw_rect(Rect2(-14, -60, 28, 38), Color(0.2, 0.18, 0.2))
		draw_rect(Rect2(-14, -60, 28, 38), Color(1.8, 1.8, 2.2), false, 2.0)
		eye(Vector2(6, -50), 3.5, Color(2.6, 2.4, 0.6))
	else:
		draw_rect(Rect2(-26, -74, 52, 52), dark)
		draw_rect(Rect2(-26, -74, 52, 52), rust, false, 3.0)
		for i in 4:
			draw_circle(Vector2(-18 + i * 12, -30), 2.5, Color(rust, 0.7))
		draw_rect(Rect2(-10, -66, 30, 10), Color(0.02, 0.02, 0.02))
		eye(Vector2(10, -61), 3.0, Color(2.4, 0.8, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var txt := "v0.9 · sin soporte" if not broken else "v0.9"
	EnemyKit.label(self, Vector2(0, -84), txt, 12, Color(rust, 0.85))
