class_name PodZombi
extends EnemyBase
## Pod Zombi: proceso que terminó pero sigue ocupando recursos. Se abalanza
## cuando estás cerca y, la primera vez que «muere», el controlador lo reinicia
## (CrashLoopBackOff) con menos vida.

enum S { WALK, WINDUP, LUNGE, DOWN }

var s := S.WALK
var timer := 0.0
var restarted := false


func _setup() -> void:
	enemy_id = "pod_zombi"
	max_hp = 4
	bits_drop = 9
	body_size = Vector2(56, 70)
	knock_resist = 0.5


func take_hit(hit: Dictionary) -> Dictionary:
	if s == S.DOWN:
		return {"solid": true, "energy": false, "pogo": true}
	if hp - int(hit.get("damage", 1)) <= 0 and not restarted:
		hp = 0
		flash = 1.0
		AudioManager.play_sfx("enemy_death")
		s = S.DOWN
		timer = 2.0
		contact.set_enabled(false)
		FX.burst(get_parent(), global_position + Vector2(0, -36), Color(0.5, 0.6, 0.7), 14, 300.0, 0.6, 0.4)
		EnemyKit.tip("pod_zombi", "El Pod Zombi se reinicia una vez (CrashLoopBackOff): no te confíes")
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
			velocity.x = facing * 65.0
			if absf(tp.x) < 300.0 and absf(tp.y) < 120.0 and signf(tp.x) == facing:
				s = S.WINDUP
				timer = 0.4
		S.WINDUP:
			velocity.x = 0.0
			if timer <= 0.0:
				s = S.LUNGE
				timer = 0.35
				velocity.y = -380.0
				AudioManager.play_sfx("spit", 0.1)
		S.LUNGE:
			velocity.x = facing * 480.0
			if (timer <= 0.0 and is_on_floor()) or is_wall_ahead():
				s = S.WALK
				velocity.x = 0.0
		S.DOWN:
			velocity.x = 0.0
			if timer <= 0.0:
				restarted = true
				hp = 2
				s = S.WALK
				contact.set_enabled(true)
				flash = 1.0
				FX.burst(get_parent(), global_position + Vector2(0, -36), Color(0.6, 1.8, 2.6), 20, 400.0, 0.6, 0.4)
				AudioManager.play_sfx("boss_roar", 0.3)
	move_and_slide()


func _draw_body() -> void:
	var font := UITheme.mono_font()
	if s == S.DOWN:
		draw_rect(Rect2(-36, -18, 72, 18), Color(0.08, 0.1, 0.12))
		var blink := 0.5 + 0.5 * sin(t * 10.0)
		EnemyKit.label(self, Vector2(0, -30), "Restarting…", 14, Color(0.6, 1.6, 2.4, blink))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.06, 0.08, 0.1)
	var col := Color(0.5, 1.4, 2.2) if not restarted else Color(2.2, 0.6, 0.5)
	var lean := 10.0 if s == S.LUNGE else (5.0 if s == S.WINDUP else 0.0)
	var step := sin(t * 6.0) * 3.0
	draw_line(Vector2(-10, -18), Vector2(-12 + step, 0), dark, 8.0)
	draw_line(Vector2(10, -18), Vector2(8 - step, 0), dark, 8.0)
	# Cuerpo: cubo de contenedor con costuras.
	var body := Rect2(-26 + lean, -70, 52, 52)
	draw_rect(body, dark)
	draw_rect(body, col, false, 2.0)
	for i in 3:
		draw_line(Vector2(-18 + lean + i * 18, -68), Vector2(-18 + lean + i * 18, -20), Color(col, 0.3), 2.0)
	draw_line(Vector2(24 + lean, -56), Vector2(42 + lean * 1.5, -34 + step), dark, 6.0)
	eye(Vector2(10 + lean, -56), 4.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var status := "Terminated" if not restarted else "CrashLoop"
	var w := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(-w * 0.5, -78), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(col, 0.85))
