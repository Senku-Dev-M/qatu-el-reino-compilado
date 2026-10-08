class_name ScrollInfinito
extends Node2D
## Jefe del Archivo Paginado: una lista que carga elementos sin fin.
## Fase 1: lluvia de tarjetas, hojas sueltas y barrido.
## Fase 2: se eleva y carga sin parar; la memoria crece y lo protege. La
## palanca «paginar» de la arena libera la memoria y lo deja expuesto.
## Fase 3: consulta; golpear los parámetros exactos de los datos pedidos.

signal defeated
signal health_changed(k: float)

const MAX_HP := 28
const PHASE2_HP := 18
const PHASE3_HP := 7
const MAX_MINIONS := 5

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
var sweep_dir := 1.0
var shots_left := 0
var shot_timer := 0.0
var spawn_timer := 0.0
var loaded := 20  # elementos cargados en la lista (se dibujan en la barra)
var memory := 0.0  # 0..1 en la fase 2
var minions: Array = []

var quiz := QueryQuiz.new()
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
	hs.size = Vector2(170, 200)
	hc.shape = hs
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(130, 160)
	contact.add_shape(cs)
	add_child(contact)
	var l := FX.make_light(Color(1.0, 0.8, 0.5), 5.0, 0.8)
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
		FX.burst(get_parent(), global_position, Color(2.2, 1.6, 0.8), 8, 300.0, 0.3, 0.3)
		return {"solid": true, "energy": false, "pogo": true}
	var dmg := maxi(1, int(_hit.get("damage", 1)))
	var floor_hp := PHASE2_HP if phase == 1 else (PHASE3_HP if phase == 2 else 0)
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position, Color(2.2, 1.6, 0.8), 10, 420.0, 0.4, 0.35)
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
	minions = minions.filter(func(e): return is_instance_valid(e) and not e.dead)
	var p := _player()
	match state:
		"intro":
			_move_to(Vector2(center_x, floor_y - 130), delta, 3.0)
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
				_move_to(Vector2(clampf(p.global_position.x, left_x + 180, right_x - 180), floor_y - 130), delta, 1.4)
			if timer <= 0.0:
				_next_attack()
		"rain":
			shot_timer -= delta
			if shot_timer <= 0.0 and shots_left > 0:
				shots_left -= 1
				shot_timer = 0.3
				loaded += 1
				var x := rng.randf_range(left_x + 80, right_x - 80)
				BossAttacks.projectile(get_parent(), Vector2(x, floor_y - 1000), Vector2(0, 100), 1200.0, "item")
			if shots_left <= 0 and timer <= 0.0:
				state = "idle"
				timer = 1.0
		"load_more":
			if timer <= 0.0:
				_spawn_minions(2)
				state = "idle"
				timer = 1.4
		"sweep_windup":
			tremble = 0.3
			if timer <= 0.0:
				state = "sweep"
		"sweep":
			global_position.x += sweep_dir * 820.0 * delta
			if (sweep_dir > 0 and global_position.x >= right_x - 110) or (sweep_dir < 0 and global_position.x <= left_x + 110):
				Events.camera_shake.emit(12.0, 0.3)
				state = "idle"
				timer = 1.2
		"transition":
			_move_to(target_pos, delta, 2.5)
			if timer <= 0.0:
				if phase == 2:
					_start_loading()
				else:
					invulnerable = false
					_start_exam()
		"loading":
			_move_to(Vector2(center_x + sin(t * 0.8) * 200.0, floor_y - 560), delta, 1.5)
			memory = minf(1.0, memory + delta * 0.05)
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				spawn_timer = 3.2
				_spawn_minions(1)
			shot_timer -= delta
			if shot_timer <= 0.0:
				shot_timer = 2.2
				loaded += 5
				for i in 3:
					var x := rng.randf_range(left_x + 80, right_x - 80)
					BossAttacks.projectile(get_parent(), Vector2(x, floor_y - 1000 - i * 160), Vector2(0, 80), 1100.0, "item")
		"exposed":
			_move_to(Vector2(center_x + sin(t * 1.1) * 260.0, floor_y - 130), delta, 3.0)
			if timer <= 0.0:
				if phase == 2:
					_start_loading()
				else:
					shield = true
					_start_exam()
		"exam":
			_move_to(Vector2(center_x, floor_y - 520), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 3.0
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 360.0, 0.0, "item")
	queue_redraw()


func _spawn_minions(n: int) -> void:
	for i in n:
		if minions.size() >= MAX_MINIONS:
			return
		var e: EnemyBase = load("res://scripts/enemies/pagina_suelta.gd").new()
		e.position = get_parent().to_local(global_position) + Vector2(rng.randf_range(-80, 80), 40)
		get_parent().add_child(e)
		minions.append(e)
	AudioManager.play_sfx("spit", 0.2)


func _next_attack() -> void:
	var options := ["carga_diferida", "load_more", "sweep"]
	options.erase(last_attack)
	last_attack = options[rng.randi() % options.size()]
	var p := _player()
	match last_attack:
		"carga_diferida":
			_special_carga_diferida()
		"rain":
			state = "rain"
			shots_left = 8
			shot_timer = 0.3
			timer = 3.0
			AudioManager.play_sfx("boss_roar", 0.3)
		"load_more":
			state = "load_more"
			timer = 0.5
			tremble = 0.5
		"sweep":
			sweep_dir = 1.0 if (p and p.global_position.x > global_position.x) else -1.0
			state = "sweep_windup"
			timer = 0.6


## Carga diferida (lazy loading): las filas de contenido aparecen de arriba
## abajo conforme «se hace scroll»; la última barre el suelo y hay que saltarla.
func _special_carga_diferida() -> void:
	special_pos = Vector2(center_x, floor_y - 600)
	var heights := [300.0, 170.0, 40.0]
	for i in 3:
		BossAttacks.beam(get_parent(), Vector2(left_x - 40, floor_y - heights[i]), Vector2(right_x + 40, floor_y - heights[i]), 40.0, 0.9 + 0.7 * i, 0.3, Color(1.8, 1.4, 0.7), "cargando página %d…" % (i + 2))
	AudioManager.play_sfx("boss_roar", 0.3)
	state = "special"
	timer = 3.0


func _enter_phase2() -> void:
	phase = 2
	invulnerable = true
	state = "transition"
	timer = 1.5
	target_pos = Vector2(center_x, floor_y - 560)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	Events.notify.emit("¡Carga sin fin! Tira de la palanca para paginar y liberar la memoria")


func _start_loading() -> void:
	state = "loading"
	invulnerable = true
	spawn_timer = 1.0
	shot_timer = 1.5


## La palanca «paginar» de la arena.
func on_lever() -> void:
	if state != "loading":
		return
	for e in minions:
		if is_instance_valid(e):
			e.die()
	minions.clear()
	memory = 0.0
	loaded = 20
	invulnerable = false
	state = "exposed"
	timer = 5.5
	Events.camera_shake.emit(12.0, 0.5)
	AudioManager.play_sfx("sello_ok")
	Events.notify.emit("Paginado: solo se cargan 20 elementos. ¡Está expuesto!")


func _enter_phase3() -> void:
	phase = 3
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 520)
	for e in minions:
		if is_instance_valid(e):
			e.die()
	minions.clear()
	AudioManager.play_sfx("boss_roar")
	Events.notify.emit("Consulta: golpea todos los parámetros que devuelven los datos pedidos")


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
	match quiz.hit(rune.line):
		"correct":
			rune.state = "correct"
			rune.order = quiz.solved.size()
			AudioManager.play_sfx("node_on")
		"complete":
			rune.state = "correct"
			rune.order = quiz.solved.size()
			AudioManager.play_sfx("sello_ok")
			Events.camera_shake.emit(10.0, 0.5)
			Events.notify.emit(quiz.url())
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
	for e in minions:
		if is_instance_valid(e):
			e.die()
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(26.0, 2.0)
	for i in 8:
		FX.burst(get_parent(), global_position + Vector2(rng.randf_range(-80, 80), rng.randf_range(-90, 90)), Color(2.4, 1.8, 0.8) if i % 2 == 0 else Color(0.9, 0.85, 0.7), 26, 600.0, 0.8, 0.5, Vector2.ZERO)
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
	# Marco de la lista con tarjetas que suben sin fin.
	var frame := Rect2(shake + Vector2(-90, -110), Vector2(180, 220))
	draw_rect(frame, Color(0.08, 0.06, 0.05))
	var scroll := fmod(t * (60.0 if state != "exam" else 20.0), 56.0)
	for i in 5:
		var y := frame.position.y + 8 + i * 56 - scroll
		if y < frame.position.y - 10 or y > frame.end.y - 40:
			continue
		var card := Rect2(Vector2(frame.position.x + 10, y), Vector2(frame.size.x - 34, 46))
		draw_rect(card, Color(0.9, 0.84, 0.7))
		draw_rect(Rect2(card.position + Vector2(6, 6), Vector2(34, 34)), Color(0.6, 0.4, 0.25))
		draw_line(card.position + Vector2(48, 14), card.position + Vector2(card.size.x - 8, 14), Color(0.35, 0.3, 0.25), 3.0)
		draw_line(card.position + Vector2(48, 28), card.position + Vector2(card.size.x - 30, 28), Color(0.55, 0.45, 0.35), 3.0)
	draw_rect(frame, Color(2.2, 1.6, 0.7, 0.8), false, 3.0)
	# Barra de desplazamiento: el pulgar se encoge a medida que carga más.
	var bar := Rect2(Vector2(frame.end.x - 18, frame.position.y + 6), Vector2(10, frame.size.y - 12))
	draw_rect(bar, Color(0.2, 0.16, 0.12))
	var thumb_h := maxf(8.0, bar.size.y * 20.0 / float(maxi(loaded, 20)))
	draw_rect(Rect2(bar.position + Vector2(0, bar.size.y - thumb_h), Vector2(10, thumb_h)), Color(2.2, 1.6, 0.7))
	# Ojo centinela (IntersectionObserver) en el borde inferior.
	var eye_pos := shake + Vector2(0, 124)
	var eye_col := Color(2.4, 1.6, 0.5) if phase < 3 else Color(0.6, 2.4, 1.4)
	draw_circle(eye_pos, 20, Color(0.05, 0.04, 0.03))
	draw_circle(eye_pos, 9, eye_col)
	draw_string(font, shake + Vector2(-60, -126), "cargados: %d" % loaded, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.0, 1.6, 0.9, 0.85))
	if phase == 2 and state == "loading":
		var mem := Rect2(shake + Vector2(-90, -150), Vector2(180, 10))
		draw_rect(mem, Color(0.15, 0.1, 0.08))
		draw_rect(Rect2(mem.position, Vector2(mem.size.x * memory, mem.size.y)), Color(2.4, 0.6 + 1.0 * (1.0 - memory), 0.4))
		draw_string(font, mem.position + Vector2(0, -8), "memoria", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(2.2, 1.2, 0.8, 0.8))
	if shield and state != "dead":
		draw_arc(shake, 160, 0, TAU, 64, Color(2.2, 1.7, 0.8, 0.8), 4.0, true)
		draw_circle(shake, 160, Color(2.0, 1.5, 0.6, 0.05))
	if state == "exam":
		_draw_exam(shake + Vector2(-260, -330))


func _draw_exam(pos: Vector2) -> void:
	var font := UITheme.title_font()
	var text := "%s · %s" % [quiz.current.get("estilo", ""), quiz.current.get("pedido", "")]
	var w := 520.0
	draw_rect(Rect2(pos - Vector2(10, 34), Vector2(w + 20, 92)), Color(0, 0, 0, 0.8))
	draw_string(font, pos, "Consulta pedida:", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.95, 0.85))
	draw_multiline_string(font, pos + Vector2(0, 26), text, HORIZONTAL_ALIGNMENT_LEFT, w, 18, 2, Color(2.0, 1.6, 0.8))
	draw_string(UITheme.mono_font(), pos + Vector2(0, 76), "Parámetros: %d de %d" % [quiz.solved.size(), quiz.correct_params().size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 2.0, 1.4))
