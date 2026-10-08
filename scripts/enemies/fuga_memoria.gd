class_name FugaMemoria
extends EnemyBase
## Fuga de Memoria: nube que te sigue despacio y crece cada pocos segundos
## (memoria reservada que nunca se libera). Suelta burbujas que flotan hacia ti;
## cuanto más grande, más burbujas. Hay que eliminarla pronto.

const MAX_GROWTH := 3

var growth := 0
var grow_timer := 5.0
var bubble_cd := 2.2


func _setup() -> void:
	enemy_id = "fuga_memoria"
	max_hp = 4
	bits_drop = 9
	body_size = Vector2(56, 48)
	uses_gravity = false


func _ai(delta: float) -> void:
	var tp := to_player()
	var near := tp.length() < 700.0
	if near:
		grow_timer -= delta
		bubble_cd -= delta
	if grow_timer <= 0.0 and growth < MAX_GROWTH:
		growth += 1
		grow_timer = 5.0
		max_hp += 2
		hp += 2
		EnemyKit.resize(self, Vector2(56, 48) * (1.0 + 0.3 * growth))
		AudioManager.play_sfx("heal_charge", 0.2)
		EnemyKit.tip("fuga", "La fuga de memoria crece con el tiempo: destrúyela antes de que ocupe el pasillo")
	if bubble_cd <= 0.0:
		bubble_cd = 2.6
		var n := 1 + growth
		for i in n:
			var off := Vector2((float(i) - float(n - 1) * 0.5) * 40.0, 0)
			var from := global_position + Vector2(0, -body_size.y * 0.5) + off
			EnemyKit.shoot_at(self, from, global_position + tp + Vector2(0, -40) + off, 130.0 + 20.0 * i, "0x")
	var goal := global_position + tp + Vector2(0, -150)
	velocity = EnemyKit.steer(velocity, global_position, goal, 50.0 if near else 0.0, 200.0, delta)
	move_and_slide()


func _draw_body() -> void:
	var k := 1.0 + 0.3 * growth
	var c := Vector2(0, -24 * k)
	var col := Color(0.8, 2.2, 0.6)
	for i in 6:
		var a := i * TAU / 6.0 + t * 0.4
		var r := (16.0 + 4.0 * sin(t * 2.0 + i)) * k
		draw_circle(c + Vector2(cos(a) * 16.0, sin(a) * 10.0) * k, r, Color(0.08, 0.14, 0.06, 0.85))
	draw_circle(c, 22.0 * k, Color(col, 0.08))
	for i in 6:
		var a := i * TAU / 6.0 + t * 0.4
		draw_arc(c + Vector2(cos(a) * 16.0, sin(a) * 10.0) * k, (16.0 + 4.0 * sin(t * 2.0 + i)) * k, 0, TAU, 14, Color(col, 0.35), 1.5)
	eye(c + Vector2(-8, -4) * k, 3.0, col)
	eye(c + Vector2(9, -2) * k, 3.0, col)
	EnemyKit.label(self, c + Vector2(0, -30 * k), "%d MB" % (64 << growth), 13, Color(col, 0.9))
