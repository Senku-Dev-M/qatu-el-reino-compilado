class_name GuardianParcial
extends Node2D
## Jefe de los Cañones Flexibles. Gólem de rejilla que custodia el Parcial.
## Fase 1: combate. Fase 2: «layout roto», el jefe se sube a lo alto y hay
## que recolocar las plataformas de los contenedores flex con la habilidad
## Flex para alcanzarlo. Fase 3: examen; muestra un layout y hay que golpear
## las runas con los valores de justify-content y align-items que lo producen.

signal defeated
signal health_changed(k: float)

const MAX_HP := 26
const PHASE2_HP := 16
const PHASE3_HP := 7
const TILE := 64
const SPOTS := ["flex-start", "center", "flex-end"]

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
var spot := "center"

var quiz := LayoutQuiz.new()
var quiz_set := -1
var runes: Array[PropertyRune] = []
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
	hs.size = Vector2(150, 150)
	hc.shape = hs
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(120, 120)
	contact.add_shape(cs)
	add_child(contact)
	var l := FX.make_light(Color(1.0, 0.6, 0.3), 5.0, 0.8)
	l.remove_from_group("light_source")
	add_child(l)
	target_pos = global_position
	timer = 1.6


func _flex(id: String) -> Node:
	return arena.room.get_entity(id) if arena and arena.room else null


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func take_hit(_hit: Dictionary) -> Dictionary:
	if state == "dead":
		return {"solid": false}
	if invulnerable or shield:
		AudioManager.play_sfx("sello_bad", 0.2)
		FX.burst(get_parent(), global_position, Color(2.4, 1.6, 0.5), 8, 300.0, 0.3, 0.3)
		return {"solid": true, "energy": false, "pogo": true}
	var dmg := maxi(1, int(_hit.get("damage", 1)))
	var floor_hp := PHASE2_HP if phase == 1 else (PHASE3_HP if phase == 2 else 0)
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position, Color(2.4, 1.2, 0.4), 10, 420.0, 0.4, 0.35)
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
			_move_to(Vector2(center_x, floor_y - 90), delta, 3.0)
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
				_move_to(Vector2(clampf(p.global_position.x, left_x + 160, right_x - 160), floor_y - 90), delta, 1.6)
			if timer <= 0.0:
				_next_attack()
		"slam_rise":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 120, right_x - 120), floor_y - 620), delta, 5.0)
			if timer <= 0.0:
				state = "slam_fall"
		"slam_fall":
			global_position.y += 1600.0 * delta
			if global_position.y >= floor_y - 90:
				global_position.y = floor_y - 90
				Events.camera_shake.emit(20.0, 0.45)
				AudioManager.play_sfx("break_wall")
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 60, floor_y), -1.0)
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 60, floor_y), 1.0)
				state = "idle"
				timer = 1.4
		"columns":
			shot_timer -= delta
			if shot_timer <= 0.0 and shots_left > 0:
				shots_left -= 1
				shot_timer = 0.35
				# Bloques que caen por las columnas de una rejilla de 6 pistas.
				var tracks := FlexLayout.grid_tracks("repeat(6, 1fr)", right_x - left_x)
				var col := rng.randi_range(0, 5)
				var x := left_x + float(tracks[0]) * (col + 0.5)
				BossAttacks.projectile(get_parent(), Vector2(x, floor_y - 1050), Vector2(0, 80), 1100.0, "1fr")
			if shots_left <= 0 and timer <= 0.0:
				state = "idle"
				timer = 1.0
		"charge_windup":
			tremble = 0.3
			if timer <= 0.0:
				state = "charge"
		"charge":
			global_position.x += charge_dir * 900.0 * delta
			if (charge_dir > 0 and global_position.x >= right_x - 100) or (charge_dir < 0 and global_position.x <= left_x + 100):
				Events.camera_shake.emit(12.0, 0.3)
				state = "idle"
				timer = 1.2
		# --- Fase 2: layout roto ---
		"transition":
			_move_to(target_pos, delta, 2.5)
			if timer <= 0.0:
				invulnerable = false
				if phase == 2:
					_start_layout_phase()
				else:
					_start_exam()
		"perch":
			var x := _spot_x(spot)
			_move_to(Vector2(x, floor_y - 520 + sin(t * 1.5) * 10.0), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 1.6
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 480.0)
				AudioManager.play_sfx("spit")
			if timer <= 0.0:
				_break_layout()
		# --- Fase 3: examen ---
		"exam":
			_move_to(Vector2(center_x, floor_y - 470), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 3.0
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 380.0)
		"exposed":
			_move_to(Vector2(center_x + sin(t * 1.2) * 280.0, floor_y - 100), delta, 3.0)
			if timer <= 0.0:
				shield = true
				_start_exam()
	queue_redraw()


func _next_attack() -> void:
	var options := ["slam", "columns", "rejilla"]
	options.erase(last_attack)
	last_attack = options[rng.randi() % options.size()]
	var p := _player()
	match last_attack:
		"rejilla":
			_special_rejilla()
		"slam":
			state = "slam_rise"
			timer = 0.9
		"columns":
			state = "columns"
			shots_left = 7
			shot_timer = 0.5
			timer = 3.0
			AudioManager.play_sfx("boss_roar", 0.3)
		"charge":
			charge_dir = 1.0 if (p and p.global_position.x > global_position.x) else -1.0
			state = "charge_windup"
			timer = 0.6


func _spot_x(which: String) -> float:
	# Sobre la plataforma del contenedor alto cuando tiene ese valor.
	var alto = _flex("flex_alto")
	if alto:
		var rects: Array = alto.compute_rects(which)
		return alto.global_position.x + (rects[0] as Rect2).get_center().x
	var lane := (right_x - left_x) / 3.0
	match which:
		"flex-start": return left_x + lane * 0.5
		"flex-end": return right_x - lane * 0.5
	return center_x


## grid-template-columns: repeat(4, 1fr). Dos columnas de la rejilla se
## iluminan y caen sobre ellas; en las otras dos se está a salvo.
func _special_rejilla() -> void:
	special_pos = Vector2(center_x, floor_y - 620)
	var lane := (right_x - left_x) / 4.0
	var cols := [0, 1, 2, 3]
	cols.shuffle()
	for k in 2:
		var ci: int = cols[k]
		var x := left_x + lane * (ci + 0.5)
		BossAttacks.beam(get_parent(), Vector2(x, floor_y - 900), Vector2(x, floor_y + 10), lane * 0.9, 1.1 + 0.9 * k, 0.4, Color(2.4, 1.6, 0.5), "grid-column: %d" % (ci + 1))
	AudioManager.play_sfx("boss_roar", 0.3)
	state = "special"
	timer = 3.0


func _enter_phase2() -> void:
	phase = 2
	invulnerable = true
	state = "transition"
	timer = 1.5
	target_pos = Vector2(center_x, floor_y - 520)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	Events.notify.emit("¡Layout roto! Recoloca las plataformas con Flex para alcanzar al Guardián")


func _start_layout_phase() -> void:
	state = "perch"
	spot = SPOTS[rng.randi() % SPOTS.size()]
	timer = 9.0
	shot_timer = 1.5
	_scramble()


func _break_layout() -> void:
	# El jefe cambia de lugar y desordena los contenedores.
	var options := SPOTS.duplicate()
	options.erase(spot)
	spot = options[rng.randi() % options.size()]
	timer = 9.0
	_scramble()
	AudioManager.play_sfx("boss_roar", 0.3)
	Events.notify.emit("El Guardián se mueve hacia %s" % spot)


func _scramble() -> void:
	for id in ["flex_bajo", "flex_alto"]:
		var f = _flex(id)
		if f:
			var vals: Array = f.values.duplicate()
			vals.erase(f.value)
			f.set_value(vals[rng.randi() % vals.size()], true, false)


func _enter_phase3() -> void:
	phase = 3
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 470)
	AudioManager.play_sfx("boss_roar")
	Events.notify.emit("El Parcial: observa el layout y golpea los valores que lo producen")


func _start_exam() -> void:
	state = "exam"
	invulnerable = false
	shield = true
	shot_timer = 2.5
	quiz_set = quiz.start_random(rng, quiz_set)
	_clear_runes()
	var justify_opts := [quiz.target["justify-content"]]
	for v in ["flex-start", "center", "flex-end", "space-between", "space-around"]:
		if justify_opts.size() < 3 and not (v in justify_opts):
			justify_opts.append(v)
	var align_opts := [quiz.target["align-items"]]
	for v in ["flex-start", "center", "flex-end", "stretch"]:
		if align_opts.size() < 3 and not (v in align_opts):
			align_opts.append(v)
	justify_opts.shuffle()
	align_opts.shuffle()
	var slots := _rune_slots()
	var k := 0
	for pair in [["justify-content", justify_opts], ["align-items", align_opts]]:
		for v in pair[1]:
			var rune := PropertyRune.new()
			rune.property = pair[0]
			rune.value = v
			get_parent().add_child(rune)
			rune.global_position = global_position
			rune.move_to = slots[k]
			rune.struck.connect(_on_rune)
			runes.append(rune)
			k += 1


func _rune_slots() -> Array:
	var out := []
	var lane := (right_x - left_x) / 3.0
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 140))
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 280))
	return out


func _clear_runes() -> void:
	for r in runes:
		if is_instance_valid(r):
			r.queue_free()
	runes.clear()


func _on_rune(rune: PropertyRune) -> void:
	if state != "exam":
		return
	var result := quiz.hit(rune.property, rune.value)
	match result:
		"correct":
			for r in runes:
				if r.property == rune.property:
					r.state = "idle"
			rune.state = "correct"
			AudioManager.play_sfx("node_on")
		"complete":
			rune.state = "correct"
			AudioManager.play_sfx("sello_ok")
			Events.camera_shake.emit(10.0, 0.5)
			Events.notify.emit("Correcto: justify-content: %s; align-items: %s;" % [quiz.target["justify-content"], quiz.target["align-items"]])
			shield = false
			state = "exposed"
			timer = 5.5
			await get_tree().create_timer(0.5).timeout
			_clear_runes()
		"wrong":
			rune.state = "wrong"
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
		FX.burst(get_parent(), global_position + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)), Color(2.4, 1.4, 0.4) if i % 2 == 0 else Color(0.6, 2.2, 2.2), 26, 600.0, 0.8, 0.5, Vector2.ZERO)
		await get_tree().create_timer(0.22).timeout
	var tw := create_tween()
	tw.tween_property(self, "dissolve", 1.0, 1.0)
	await tw.finished
	FX.burst(get_parent(), global_position, Color(2.6, 2.4, 2.0), 60, 900.0, 1.2, 0.6, Vector2.ZERO)
	defeated.emit()
	queue_free()


func _draw() -> void:
	var shake := Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * tremble
	var stone := Color(0.18, 0.11, 0.07)
	var line := Color(2.2, 1.3, 0.4)
	# Cuerpo: rejilla de 3 × 3 bloques.
	var cell := 48.0
	var origin := shake + Vector2(-cell * 1.5, -cell * 1.5)
	for gy in 3:
		for gx in 3:
			var wob := Vector2(sin(t * 2.0 + gx) * 2.0, cos(t * 1.7 + gy) * 2.0) * (1.0 if phase > 1 else 0.3)
			var r := Rect2(origin + Vector2(gx, gy) * cell + wob, Vector2(cell - 4, cell - 4))
			draw_rect(r, stone)
			draw_rect(r, Color(line, 0.6), false, 2.0)
	# Brazos.
	for side in [-1.0, 1.0]:
		var arm := shake + Vector2(side * cell * 1.9, sin(t * 2.5) * 6.0)
		draw_rect(Rect2(arm - Vector2(18, 40), Vector2(36, 80)), stone)
		draw_rect(Rect2(arm - Vector2(18, 40), Vector2(36, 80)), Color(line, 0.5), false, 2.0)
	# Visor con { }.
	var visor := Rect2(shake + Vector2(-40, -cell * 1.5 - 30), Vector2(80, 30))
	draw_rect(visor, Color(0.05, 0.03, 0.02))
	draw_string(UITheme.mono_font(), visor.position + Vector2(14, 23), "{ ▪▪ }", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(2.6, 1.2, 0.4) if phase < 3 else Color(0.6, 2.4, 2.4))
	if shield and state != "dead":
		draw_arc(shake, 125, 0, TAU, 64, Color(2.2, 1.6, 0.6, 0.8), 4.0, true)
		draw_circle(shake, 125, Color(2.0, 1.4, 0.4, 0.05))
	if state == "exam":
		_draw_exam_target(shake + Vector2(-190, -330))


## Dibuja el layout que el jugador debe reproducir.
func _draw_exam_target(pos: Vector2) -> void:
	var w := 380.0
	var h := 120.0
	var box := Rect2(pos, Vector2(w, h))
	draw_rect(box.grow(10), Color(0, 0, 0, 0.75))
	draw_rect(box, Color(0.95, 0.93, 0.88))
	var sizes := [70.0, 70.0, 70.0]
	var heights := [50.0, 36.0, 64.0]
	var offs := FlexLayout.justify(w, sizes, str(quiz.target.get("justify-content", "")))
	for i in 3:
		var a := FlexLayout.align(h, heights[i], str(quiz.target.get("align-items", "")))
		var r := Rect2(pos + Vector2(offs[i], a.x), Vector2(sizes[i], a.y))
		draw_rect(r, [Color(0.36, 0.62, 0.92), Color(0.95, 0.62, 0.3), Color(0.45, 0.78, 0.5)][i])
	var font := UITheme.title_font()
	draw_string(font, pos + Vector2(0, -18), "¿Qué valores producen este layout?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.95, 0.85))
