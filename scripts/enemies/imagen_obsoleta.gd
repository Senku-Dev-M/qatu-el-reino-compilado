class_name ImagenObsoleta
extends EnemyBase
## Imagen Pesada sin Limpiar: gigante hecho de capas. Cada capa que le quitas
## cae al suelo (así se adelgaza una imagen). Cuando estás cerca salta y, al
## aterrizar, lanza ondas de choque a ambos lados: sáltalas.

const LAYER_HP := 3
const LAYERS := 3

var stomp_cd := 1.5
var jumping := false


func _setup() -> void:
	enemy_id = "imagen_obsoleta"
	max_hp = LAYER_HP * LAYERS
	bits_drop = 14
	body_size = Vector2(80, 100)
	knock_resist = 0.9


func layers_left() -> int:
	return int(ceil(float(hp) / LAYER_HP))


func take_hit(hit: Dictionary) -> Dictionary:
	var before := layers_left()
	var r := super.take_hit(hit)
	if not dead and layers_left() < before:
		AudioManager.play_sfx("break_wall", 0.2)
		Events.camera_shake.emit(6.0, 0.2)
		FX.burst(get_parent(), global_position + Vector2(0, -30 * before), Color(0.6, 1.2, 1.8), 18, 380.0, 0.6, 0.45)
		EnemyKit.tip("imagen", "Cada capa que eliminas hace la imagen más ligera... y más rápida")
	return r


func _ai(delta: float) -> void:
	apply_gravity(delta)
	var tp := to_player()
	var speed := 30.0 + 25.0 * (LAYERS - layers_left())
	if jumping:
		if is_on_floor() and velocity.y >= 0.0:
			jumping = false
			BossAttacks.shockwave(get_parent(), global_position, 1.0)
			BossAttacks.shockwave(get_parent(), global_position, -1.0)
			Events.camera_shake.emit(10.0, 0.25)
			AudioManager.play_sfx("break_wall", 0.3)
			stomp_cd = 3.0
	else:
		stomp_cd -= delta
		if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
			facing = -facing
		velocity.x = facing * speed
		if is_on_floor() and stomp_cd <= 0.0 and absf(tp.x) < 420.0 and absf(tp.y) < 160.0:
			velocity = Vector2(0.0, -720.0)
			jumping = true
	move_and_slide()


func _draw_body() -> void:
	var n := layers_left()
	var cols: Array[Color] = [Color(0.4, 0.9, 1.4), Color(0.5, 1.2, 1.8), Color(0.7, 1.6, 2.4)]
	var names: Array[String] = ["FROM node:14", "RUN npm i", "COPY . ."]
	var font := UITheme.mono_font()
	var y := 0.0
	var step := sin(t * 3.0) * 2.0
	for i in n:
		var w := 84.0 - i * 12.0
		var h := 30.0
		var r := Rect2(-w * 0.5, y - h - 4.0 - step * i, w, h)
		draw_rect(r, Color(0.05, 0.08, 0.12))
		draw_rect(r, cols[i], false, 2.0)
		draw_string(font, r.position + Vector2(6, 20), names[i], HORIZONTAL_ALIGNMENT_LEFT, w - 8.0, 12, Color(cols[i], 0.85))
		y -= h + 2.0
	eye(Vector2(facing * 14, y + 16), 4.0, Color(2.4, 0.8, 0.5))
	EnemyKit.label(self, Vector2(0, y - 10), "%d MB" % (400 * n), 13, Color(0.8, 1.4, 2.0, 0.9))
