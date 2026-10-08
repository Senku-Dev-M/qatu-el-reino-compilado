class_name AcoplamientoRigido
extends EnemyBase
## Acoplamiento Rígido: la vista atada directamente a la base de datos. Cuando
## te ve carga en línea recta y no sabe frenar ni cambiar de rumbo; si choca con
## una pared queda aturdido (y expuesto) un momento.

enum S { WALK, WINDUP, CHARGE, STUNNED }

var s := S.WALK
var timer := 0.0


func _setup() -> void:
	enemy_id = "acoplamiento_rigido"
	max_hp = 6
	bits_drop = 9
	body_size = Vector2(56, 56)
	knock_resist = 0.8


func take_hit(hit: Dictionary) -> Dictionary:
	if s == S.STUNNED:
		hit = hit.duplicate()
		hit["damage"] = int(hit.get("damage", 1)) * 2
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	timer -= delta
	var tp := to_player()
	match s:
		S.WALK:
			if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
				facing = -facing
			velocity.x = facing * 45.0
			if absf(tp.x) < 520.0 and absf(tp.y) < 100.0 and tp.x != 0.0 and timer <= 0.0:
				facing = signf(tp.x)
				s = S.WINDUP
				timer = 0.7
		S.WINDUP:
			velocity.x = -facing * 20.0
			if timer <= 0.0:
				s = S.CHARGE
				timer = 1.6
				AudioManager.play_sfx("boss_roar", 0.4)
		S.CHARGE:
			velocity.x = facing * 560.0
			if is_wall_ahead():
				s = S.STUNNED
				timer = 1.4
				velocity.x = -facing * 160.0
				Events.camera_shake.emit(6.0, 0.2)
				EnemyKit.tip("acoplamiento", "El acoplamiento rígido no sabe frenar: haz que choque y golpéalo mientras está aturdido")
			elif timer <= 0.0 or (is_on_floor() and is_edge_ahead()):
				s = S.WALK
				timer = 1.0
				velocity.x = 0.0
		S.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if timer <= 0.0:
				s = S.WALK
				timer = 0.8
	move_and_slide()


func _draw_body() -> void:
	var col := Color(2.4, 0.7, 0.3)
	var lean := 0.0
	if s == S.CHARGE:
		lean = 8.0 * facing
	elif s == S.WINDUP:
		lean = -5.0 * facing
	var r := Rect2(-26 + lean, -54, 52, 54)
	draw_rect(r, Color(0.14, 0.08, 0.04))
	draw_rect(r, col, false, 3.0)
	# Cadena rígida que une "vista" y "BD".
	draw_line(Vector2(-18 + lean, -40), Vector2(18 + lean, -14), col, 3.0)
	draw_line(Vector2(18 + lean, -40), Vector2(-18 + lean, -14), col, 3.0)
	EnemyKit.label(self, Vector2(lean, -60), "vista⇔BD", 13, Color(col, 0.9))
	if s == S.STUNNED:
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(lean, -70) + Vector2(cos(a) * 20.0, sin(a) * 6.0), 4.0, Color(2.6, 2.2, 0.6))
	else:
		eye(Vector2(facing * 12 + lean, -44), 3.5, Color(2.6, 0.9, 0.3))
