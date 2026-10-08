class_name CallbackHell
extends Node2D
## Jefe de los Ríos Asíncronos: una pirámide de callbacks anidados.
## Fase 1: combate (lluvia de llaves anidadas que se dividen, golpe, embestida).
## Fase 2: se eleva sobre el remolino; hay que encadenar las fuentes de
## promesa (.then) de la arena para subir hasta su núcleo.
## Fase 3: refactor; golpear en orden las líneas de la versión async/await.

signal defeated
signal health_changed(k: float)

const MAX_HP := 28
const PHASE2_HP := 18
const PHASE3_HP := 7
const PERCH_H := 540.0

var arena: Node2D
var floor_y := 0.0
var left_x := 0.0
var right_x := 0.0
var center_x := 0.0

var hp := MAX_HP
var phase := 1
var state := "intro"
var timer := 0.0
var last_attack := ""
var special_pos := Vector2.ZERO
var invulnerable := true
var shield := false
var t := 0.0
var flash := 0.0
var tremble := 0.0
var dissolve := 0.0
var target_pos := Vector2.ZERO
var charge_dir := 1.0
var shots_left := 0
var shot_timer := 0.0
var storm_timer := 0.0

var quiz := OrderQuiz.new()
var quiz_set := -1
var runes: Array[CodeRune] = []
var rng := RandomNumberGenerator.new()
var hurtbox: Area2D
var contact: DamageArea


func setup_arena(p_arena: Node2D, p_floor_y: float, p_left: float, p_right: float) -> void:
	arena = p_arena
	floor_y = p_floor_y
	left_x = p_left
	right_x = p_right
	center_x = (p_left + p_right) * 0.5


func _ready() -> void:
	rng.randomize()
	material = FX.flash_material()
	z_index = 12
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 1 << 4
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var hc := CollisionShape2D.new()
	var hs := RectangleShape2D.new()
	hs.size = Vector2(190, 170)
	hc.shape = hs
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(150, 130)
	contact.add_shape(cs)
	add_child(contact)
	var l := FX.make_light(Color(0.4, 0.9, 1.0), 5.0, 0.8)
	l.remove_from_group("light_source")
	add_child(l)
	target_pos = global_position
	timer = 1.6


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func take_hit(_hit: Dictionary) -> Dictionary:
	if state == "dead":
		return {"solid": false}
	if invulnerable or shield:
		AudioManager.play_sfx("sello_bad", 0.2)
		FX.burst(get_parent(), global_position, Color(0.5, 1.8, 2.4), 8, 300.0, 0.3, 0.3)
		return {"solid": true, "energy": false, "pogo": true}
	var dmg := maxi(1, int(_hit.get("damage", 1)))
	var floor_hp := PHASE2_HP if phase == 1 else (PHASE3_HP if phase == 2 else 0)
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position, Color(0.5, 2.0, 2.4), 10, 420.0, 0.4, 0.35)
	health_changed.emit(float(hp) / float(MAX_HP))
	if hp <= 0:
		_die()
	elif phase == 1 and hp <= PHASE2_HP:
		_enter_phase2()
	elif phase == 2 and hp <= PHASE3_HP:
		_enter_phase3()
	return {"solid": true, "energy": true, "pogo": true}


func _move_to(pos: Vector2, delta: float, speed: float) -> void:
	global_position = global_position.lerp(pos, 1.0 - exp(-speed * delta))


func _physics_process(delta: float) -> void:
	t += delta
	timer -= delta
	flash = maxf(0.0, flash - delta * 5.0)
	tremble = maxf(0.0, tremble - delta)
	var m := material as ShaderMaterial
	m.set_shader_parameter("flash", flash)
	m.set_shader_parameter("dissolve", dissolve)
	var p := _player()
	match state:
		"intro":
			_move_to(Vector2(center_x, floor_y - 110), delta, 3.0)
			if timer <= 0.0:
				invulnerable = false
				_next_attack()
		"special":
			_move_to(special_pos, delta, 3.0)
			if timer <= 0.0:
				state = "idle"
				timer = 1.0
		"idle":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 180, right_x - 180), floor_y - 110), delta, 1.4)
			if timer <= 0.0:
				_next_attack()
		"rain":
			shot_timer -= delta
			if shot_timer <= 0.0 and shots_left > 0:
				shots_left -= 1
				shot_timer = 0.55
				var x := rng.randf_range(left_x + 120, right_x - 120)
				if p and shots_left % 2 == 0:
					x = clampf(p.global_position.x + rng.randf_range(-80, 80), left_x + 80, right_x - 80)
				_spawn_brace(Vector2(x, floor_y - 1000), Vector2(0, 60), 2)
			if shots_left <= 0 and timer <= 0.0:
				state = "idle"
				timer = 1.1
		"slam_rise":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 140, right_x - 140), floor_y - 600), delta, 5.0)
			if timer <= 0.0:
				state = "slam_fall"
		"slam_fall":
			global_position.y += 1600.0 * delta
			if global_position.y >= floor_y - 110:
				global_position.y = floor_y - 110
				Events.camera_shake.emit(18.0, 0.4)
				AudioManager.play_sfx("break_wall")
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 70, floor_y), -1.0)
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 70, floor_y), 1.0)
				state = "idle"
				timer = 1.3
		"charge_windup":
			tremble = 0.3
			if timer <= 0.0:
				state = "charge"
		"charge":
			global_position.x += charge_dir * 850.0 * delta
			if (charge_dir > 0 and global_position.x >= right_x - 110) or (charge_dir < 0 and global_position.x <= left_x + 110):
				Events.camera_shake.emit(12.0, 0.3)
				state = "idle"
				timer = 1.2
		"transition":
			_move_to(target_pos, delta, 2.5)
			if timer <= 0.0:
				invulnerable = false
				if phase == 2:
					_start_perch()
				else:
					_start_exam()
		"perch":
			_move_to(Vector2(center_x + sin(t * 0.7) * 30.0, floor_y - PERCH_H + sin(t * 1.5) * 10.0), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 2.0
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 420.0, 0.0, "cb")
				AudioManager.play_sfx("spit")
			storm_timer -= delta
			if storm_timer <= 0.0:
				storm_timer = 9.0
				for i in 3:
					_spawn_brace(Vector2(rng.randf_range(left_x + 100, right_x - 100), floor_y - 1000 - i * 200), Vector2(0, 40), 1)
		"exam":
			_move_to(Vector2(center_x, floor_y - 500), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 3.2
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 360.0, 0.0, "cb")
		"exposed":
			_move_to(Vector2(center_x + sin(t * 1.1) * 300.0, floor_y - 120), delta, 3.0)
			if timer <= 0.0:
				shield = true
				_start_exam()
	queue_redraw()


func _spawn_brace(pos: Vector2, vel: Vector2, depth: int) -> void:
	var b := NestedBrace.new()
	b.depth = depth
	b.floor_y = floor_y
	b.velocity = vel
	get_parent().add_child(b)
	b.global_position = pos


func _next_attack() -> void:
	var options := ["rain", "slam", "set_timeout"]
	options.erase(last_attack)
	last_attack = options[rng.randi() % options.size()]
	var p := _player()
	match last_attack:
		"set_timeout":
			_special_set_timeout()
		"rain":
			state = "rain"
			shots_left = 5
			shot_timer = 0.4
			timer = 3.4
			AudioManager.play_sfx("boss_roar", 0.3)
		"slam":
			state = "slam_rise"
			timer = 0.9
		"charge":
			charge_dir = 1.0 if (p and p.global_position.x > global_position.x) else -1.0
			state = "charge_windup"
			timer = 0.6


## setTimeout: programa tres callbacks que se ejecutan a los 1, 2 y 3 segundos
## donde estaba el jugador al programarlos.
func _special_set_timeout() -> void:
	special_pos = Vector2(center_x, floor_y - 520)
	var p := _player()
	var base_x := p.global_position.x if p else center_x
	var offsets := [0.0, -240.0, 240.0]
	offsets.shuffle()
	for i in 3:
		var x := clampf(base_x + offsets[i], left_x + 90, right_x - 90)
		BossAttacks.blast(get_parent(), Vector2(x, floor_y - 70), 100.0, 1.0 + i * 0.9, Color(2.4, 1.2, 0.4), "setTimeout(%dms)" % ((i + 1) * 1000))
	AudioManager.play_sfx("boss_roar", 0.3)
	state = "special"
	timer = 3.4


func _enter_phase2() -> void:
	phase = 2
	invulnerable = true
	state = "transition"
	timer = 1.5
	target_pos = Vector2(center_x, floor_y - PERCH_H)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	Events.notify.emit("¡Se elevó! Activa la fuente y encadena las promesas (.then) para alcanzarlo")


func _start_perch() -> void:
	state = "perch"
	shot_timer = 1.5
	storm_timer = 5.0


func _enter_phase3() -> void:
	phase = 3
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 500)
	AudioManager.play_sfx("boss_roar")
	Events.notify.emit("Refactor: golpea en orden las líneas de la versión async/await")


func _start_exam() -> void:
	state = "exam"
	invulnerable = false
	shield = true
	shot_timer = 2.5
	quiz_set = quiz.start_random(rng, quiz_set)
	_clear_runes()
	var opts := quiz.options()
	opts.shuffle()
	var slots := _rune_slots()
	for i in opts.size():
		var rune := CodeRune.new()
		rune.line = str(opts[i])
		get_parent().add_child(rune)
		rune.global_position = global_position
		rune.move_to = slots[i % slots.size()]
		rune.struck.connect(_on_rune)
		runes.append(rune)


func _rune_slots() -> Array:
	var out := []
	var lane := (right_x - left_x) / 3.0
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 130))
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 270))
	return out


func _clear_runes() -> void:
	for r in runes:
		if is_instance_valid(r):
			r.queue_free()
	runes.clear()


func _on_rune(rune: CodeRune) -> void:
	if state != "exam":
		return
	var result := quiz.hit(rune.line)
	match result:
		"correct":
			rune.state = "correct"
			rune.order = quiz.progress
			AudioManager.play_sfx("node_on")
		"complete":
			rune.state = "correct"
			rune.order = quiz.progress
			AudioManager.play_sfx("sello_ok")
			Events.camera_shake.emit(10.0, 0.5)
			Events.notify.emit("Refactor correcto: sin callbacks anidados")
			shield = false
			state = "exposed"
			timer = 6.0
			await get_tree().create_timer(0.6).timeout
			_clear_runes()
		"wrong":
			rune.state = "wrong"
			for r in runes:
				if r != rune:
					r.state = "idle"
					r.order = 0
			AudioManager.play_sfx("sello_bad")
			BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 60, floor_y), -1.0)
			BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 60, floor_y), 1.0)
			await get_tree().create_timer(0.6).timeout
			if is_instance_valid(rune) and rune.state == "wrong":
				rune.state = "idle"


func _die() -> void:
	state = "dead"
	invulnerable = true
	contact.set_enabled(false)
	_clear_runes()
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(26.0, 2.0)
	for i in 8:
		FX.burst(get_parent(), global_position + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80)), Color(0.5, 2.0, 2.4) if i % 2 == 0 else Color(2.4, 1.6, 0.5), 26, 600.0, 0.8, 0.5, Vector2.ZERO)
		await get_tree().create_timer(0.22).timeout
	var tw := create_tween()
	tw.tween_property(self, "dissolve", 1.0, 1.0)
	await tw.finished
	FX.burst(get_parent(), global_position, Color(2.6, 2.4, 2.0), 60, 900.0, 1.2, 0.6, Vector2.ZERO)
	defeated.emit()
	queue_free()


func _draw() -> void:
	var shake := Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * tremble
	var font := UITheme.mono_font()
	# Pirámide de callbacks: cada nivel más indentado y más estrecho.
	var levels := ["cargar(function () {", "leer(function () {", "parsear(function () {", "mostrar(function () {", "});"]
	for i in levels.size():
		var w := 220.0 - i * 30.0
		var y := -90.0 + i * 36.0
		var sway := sin(t * 2.0 + i * 0.8) * (4.0 + phase * 2.0)
		var r := Rect2(shake + Vector2(-w * 0.5 + i * 8.0 + sway, y), Vector2(w, 32))
		draw_rect(r, Color(0.03, 0.06, 0.08))
		draw_rect(r, Color(0.5, 1.6, 2.0, 0.6), false, 2.0)
		draw_string(font, r.position + Vector2(8, 22), levels[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, 15, Color(0.7, 1.8, 2.2, 0.9))
	# Núcleo: ojo del remolino.
	var core := shake + Vector2(0, -130)
	var eye_col := Color(2.4, 1.6, 0.5) if phase < 3 else Color(0.6, 2.4, 1.4)
	for k in 3:
		draw_arc(core, 30.0 + k * 12.0, t * (2.0 + k), t * (2.0 + k) + PI * 1.3, 24, Color(0.5, 1.8, 2.2, 0.5 - k * 0.12), 3.0, true)
	draw_circle(core, 18, Color(0.02, 0.04, 0.05))
	draw_circle(core, 8, eye_col)
	if shield and state != "dead":
		draw_arc(shake + Vector2(0, -20), 150, 0, TAU, 64, Color(0.5, 1.8, 2.4, 0.8), 4.0, true)
		draw_circle(shake + Vector2(0, -20), 150, Color(0.4, 1.4, 2.0, 0.05))
	if state == "exam":
		_draw_exam_code(shake + Vector2(-230, -420))


func _draw_exam_code(pos: Vector2) -> void:
	var font := UITheme.mono_font()
	var text := str(quiz.current.get("antes", ""))
	var lines := text.split("\n")
	var box := Rect2(pos, Vector2(460, 30 + lines.size() * 24))
	draw_rect(box.grow(10), Color(0, 0, 0, 0.8))
	draw_rect(box, Color(0.03, 0.05, 0.07))
	draw_string(UITheme.title_font(), pos + Vector2(0, -18), str(quiz.current.get("titulo", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.95, 0.85))
	for i in lines.size():
		draw_string(font, pos + Vector2(12, 26 + i * 24), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1.6, 1.2, 0.6, 0.9))
	draw_string(font, pos + Vector2(0, box.size.y + 26), "Línea %d de %d" % [quiz.progress + 1, quiz.lines().size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 2.0, 2.2))


## Llave anidada: cae y, si tiene profundidad, se divide en dos al tocar el suelo.
class NestedBrace extends DamageArea:
	var velocity := Vector2.ZERO
	var depth := 2
	var floor_y := 0.0
	var age := 0.0

	func _ready() -> void:
		var c := CircleShape2D.new()
		c.radius = 14.0 + depth * 4.0
		add_shape(c)
		z_index = 20

	func _physics_process(delta: float) -> void:
		age += delta
		velocity.y += 1300.0 * delta
		global_position += velocity * delta
		if global_position.y >= floor_y - 14.0 and velocity.y > 0.0:
			FX.burst(get_parent(), global_position, Color(0.5, 2.0, 2.4), 10, 260.0, 0.3, 0.3)
			if depth > 1:
				for side in [-1.0, 1.0]:
					var child := NestedBrace.new()
					child.depth = depth - 1
					child.floor_y = floor_y
					child.velocity = Vector2(side * 300.0, -620.0)
					get_parent().add_child(child)
					child.global_position = global_position + Vector2(side * 20.0, -20.0)
			queue_free()
		elif age > 6.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := 14.0 + depth * 4.0
		draw_circle(Vector2.ZERO, r + 10.0, Color(0.4, 1.6, 2.2, 0.15))
		draw_circle(Vector2.ZERO, r, Color(0.02, 0.05, 0.07))
		draw_arc(Vector2.ZERO, r, 0, TAU, 20, Color(0.6, 2.0, 2.4), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-10, 7), "{ }" if depth > 1 else "{}", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 2.2, 2.6))
