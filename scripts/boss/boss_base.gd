class_name BossBase
extends Node2D
## Base de los jefes de las zonas 1, 2, 8, 9 y la Demo Final.
##
## - Tres fases por vida (`max_hp`, `phase2_hp`, `phase3_hp`); el daño de cada
##   golpe es el del arma equipada y nunca salta una fase entera.
## - Fase 2: el jefe se protege con un escudo y aparecen runas con las opciones
##   de una pregunta (`quiz`). Al golpear todas las correctas el escudo se rompe
##   y el jefe queda aturdido unos segundos; el escudo ya no vuelve.
## - Los ataques son métodos `_atk_<nombre>()` que cada jefe declara en
##   `attacks(phase)`. Las acciones diferidas se programan con `after()` (se
##   cancelan solas si el jefe muere).

signal defeated
signal health_changed(k: float)

const TILE := 64
const STUN_TIME := 4.5

var max_hp := 30
var phase2_hp := 19
var phase3_hp := 9
var boss_kind := ""
var hurt_size := Vector2(110, 170)
var hurt_offset := Vector2(0, -85)
var tint := Color(2.4, 1.4, 0.4)

var arena: Node2D
var floor_y := 0.0
var left_x := 0.0
var right_x := 0.0
var center_x := 0.0

var hp := 30
var phase := 1
var state := "intro"  # intro | idle | busy | transition | stunned | dead
var timer := 0.0
var invulnerable := true
var shield := false
var t := 0.0
var flash := 0.0
var tremble := 0.0
var home := Vector2.ZERO
var move_rate := 2.5
var last_attack := ""
var rng := RandomNumberGenerator.new()

var hurtbox: Area2D
var contact: DamageArea
var quiz: RefCounted
var runes: Array[CodeRune] = []
var quiz_selected: Array[String] = []

var _tasks: Array = []  # [segundos_restantes, Callable]


## Para sobrescribir -------------------------------------------------------------------

func _configure() -> void:
	pass


func attacks(_phase: int) -> Array:
	return []


## Pausa entre ataques (más corta en fase 3).
func idle_time() -> float:
	return [1.5, 1.35, 1.0][clampi(phase - 1, 0, 2)]


func _draw_boss() -> void:
	pass


# --- Montaje ----------------------------------------------------------------------------

func setup_arena(p_arena: Node2D, p_floor_y: float, p_left: float, p_right: float) -> void:
	arena = p_arena
	floor_y = p_floor_y
	left_x = p_left
	right_x = p_right
	center_x = (p_left + p_right) * 0.5


func _ready() -> void:
	rng.randomize()
	_configure()
	hp = max_hp
	material = FX.flash_material()
	z_index = 12
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 1 << 4
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var hc := CollisionShape2D.new()
	var hs := RectangleShape2D.new()
	hs.size = hurt_size
	hc.shape = hs
	hc.position = hurt_offset
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := RectangleShape2D.new()
	cs.size = hurt_size * 0.8
	contact.add_shape(cs, hurt_offset)
	add_child(contact)
	var l := FX.make_light(Color(minf(tint.r, 1.5), minf(tint.g, 1.5), minf(tint.b, 1.5)), 6.0, 0.9)
	l.remove_from_group("light_source")
	add_child(l)
	home = Vector2(center_x, floor_y - 260)
	state = "intro"
	timer = 1.6


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func player_pos() -> Vector2:
	var p := _player()
	return p.global_position if p else Vector2(center_x, floor_y)


## Programa `fn` dentro de `seconds` segundos.
func after(seconds: float, fn: Callable) -> void:
	_tasks.append([seconds, fn])


## Fin de un ataque: vuelve a flotar y espera.
func finish_attack(extra := 0.0) -> void:
	if state == "busy":
		state = "idle"
		timer = idle_time() + extra


# --- Daño y fases -----------------------------------------------------------------------

func take_hit(hit: Dictionary) -> Dictionary:
	if state == "dead":
		return {"solid": false}
	if invulnerable or shield:
		AudioManager.play_sfx("sello_bad", 0.3)
		FX.burst(get_parent(), global_position + hurt_offset, Color(0.8, 1.8, 2.5), 10, 320.0, 0.3, 0.3)
		if shield:
			EnemyKit.tip("escudo_jefe", "El escudo no cede a golpes: golpea las runas con la respuesta correcta")
		return {"solid": true, "energy": false, "pogo": true}
	var dmg := maxi(1, int(hit.get("damage", 1)))
	if state == "stunned":
		dmg += 1  # aturdido: golpes más efectivos
	var floor_hp := 0
	if phase == 1:
		floor_hp = phase2_hp
	elif phase == 2:
		floor_hp = phase3_hp
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position + hurt_offset, tint, 12, 450.0, 0.4, 0.35)
	health_changed.emit(float(hp) / float(max_hp))
	if hp <= 0:
		_die()
	elif phase == 1 and hp <= phase2_hp:
		_enter_phase2()
	elif phase == 2 and hp <= phase3_hp:
		_enter_phase3()
	return {"solid": true, "energy": true, "pogo": true}


func _enter_phase2() -> void:
	phase = 2
	_tasks.clear()
	state = "transition"
	timer = 1.6
	AudioManager.play_sfx("boss_roar", 0.4)
	Events.camera_shake.emit(10.0, 0.8)
	FX.burst(get_parent(), global_position + hurt_offset, Color(0.6, 1.8, 2.6), 24, 500.0, 0.8, 0.5)
	if quiz != null:
		shield = true
		_spawn_runes()
		Events.notify.emit("¡Escudo! Golpea las runas con la respuesta correcta para romperlo")


func _enter_phase3() -> void:
	phase = 3
	_tasks.clear()
	shield = false
	_clear_runes()
	state = "transition"
	timer = 1.4
	AudioManager.play_sfx("boss_roar", 0.5)
	Events.camera_shake.emit(14.0, 1.0)
	FX.burst(get_parent(), global_position + hurt_offset, Color(2.8, 0.5, 0.3), 30, 600.0, 1.0, 0.6)


func _die() -> void:
	invulnerable = true
	state = "dead"
	_tasks.clear()
	_clear_runes()
	_kill_minions()
	contact.set_enabled(false)
	AudioManager.play_sfx("boss_roar", 0.6)
	Events.camera_shake.emit(16.0, 1.4)
	for i in 6:
		FX.burst(get_parent(), global_position + hurt_offset + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)), tint, 26, 700.0, 1.0, 0.6, Vector2.ZERO)
	if boss_kind != "":
		GameState.set_flag("jefe:" + boss_kind, true)
	defeated.emit()
	queue_free()


# --- Runas del quiz (fase 2) --------------------------------------------------------------

func question() -> Dictionary:
	return quiz.call("current_question") if quiz != null else {}


func _rune_slots() -> Array:
	var out := []
	var lane := (right_x - left_x) / 3.0
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 130))
	for i in 3:
		out.append(Vector2(left_x + lane * (i + 0.5), floor_y - 290))
	return out


func _spawn_runes() -> void:
	_clear_runes()
	quiz_selected.clear()
	var opts: Array = question().get("options", []).duplicate()
	# Mezcla estable para que la respuesta no esté siempre en el mismo sitio.
	for i in range(opts.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = opts[i]
		opts[i] = opts[j]
		opts[j] = tmp
	var slots := _rune_slots()
	for i in opts.size():
		var rune := CodeRune.new()
		rune.line = str(opts[i])
		get_parent().add_child(rune)
		rune.global_position = global_position
		rune.move_to = slots[i % slots.size()]
		rune.struck.connect(_on_rune)
		runes.append(rune)


func _clear_runes() -> void:
	for r in runes:
		if is_instance_valid(r):
			r.queue_free()
	runes.clear()


func _on_rune(rune: CodeRune) -> void:
	if not shield or quiz == null:
		return
	var correct: Array = question().get("correct", [])
	if rune.line in correct and not (rune.line in quiz_selected):
		quiz_selected.append(rune.line)
		rune.state = "correct"
		rune.order = quiz_selected.size()
		AudioManager.play_sfx("node_on")
		if quiz_selected.size() >= correct.size():
			for c in correct:
				quiz.call("submit_choice", str(c))
			_break_shield()
	elif not (rune.line in correct):
		rune.state = "wrong"
		quiz_selected.clear()
		for r in runes:
			if r != rune and is_instance_valid(r):
				r.state = "idle"
				r.order = 0
		AudioManager.play_sfx("sello_bad")
		var p := player_pos()
		BossAttacks.blast(get_parent(), p + Vector2(0, -40), 70.0, 0.8, Color(2.6, 0.5, 0.4), "✗")
		after(0.8, func() -> void:
			if is_instance_valid(rune) and rune.state == "wrong":
				rune.state = "idle")


func _break_shield() -> void:
	shield = false
	_tasks.clear()
	AudioManager.play_sfx("sello_ok")
	Events.camera_shake.emit(12.0, 0.6)
	Events.notify.emit("¡Respuesta correcta! El escudo se rompe: aprovecha el aturdimiento")
	FX.burst(get_parent(), global_position + hurt_offset, Color(0.6, 2.4, 2.6), 40, 700.0, 0.9, 0.5, Vector2.ZERO)
	after(0.6, _clear_runes)
	state = "stunned"
	timer = STUN_TIME
	contact.set_enabled(false)


# --- Bucle --------------------------------------------------------------------------------

func _move_to(target: Vector2, delta: float, speed := 3.0) -> void:
	global_position = global_position.lerp(target, clampf(delta * speed, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	t += delta
	timer -= delta
	flash = maxf(0.0, flash - delta * 5.0)
	tremble = maxf(0.0, tremble - delta)
	var m := material as ShaderMaterial
	if m:
		m.set_shader_parameter("flash", flash)
	if state == "dead":
		return
	var pending := _tasks
	_tasks = []
	for task: Array in pending:
		task[0] = float(task[0]) - delta
		if float(task[0]) <= 0.0:
			(task[1] as Callable).call()
		else:
			_tasks.append(task)
	if state == "dead":
		return
	match state:
		"intro":
			_move_to(Vector2(center_x, floor_y - 260), delta, 2.5)
			if timer <= 0.0:
				invulnerable = false
				state = "idle"
				timer = 0.8
		"transition":
			_move_to(Vector2(center_x, floor_y - 320), delta, 3.0)
			tremble = 0.4
			if timer <= 0.0:
				state = "idle"
				timer = 0.8
		"stunned":
			_move_to(Vector2(global_position.x, floor_y - hurt_offset.y - hurt_size.y * 0.5), delta, 4.0)
			if timer <= 0.0:
				contact.set_enabled(true)
				state = "idle"
				timer = 0.6
		"idle":
			var track_x := clampf(player_pos().x, left_x + 160, right_x - 160)
			_move_to(Vector2(track_x, floor_y - 260 + sin(t * 2.6) * 22.0), delta, 1.8 if phase == 1 else 2.6)
			if timer <= 0.0:
				_next_attack()
		"busy":
			_move_to(home, delta, move_rate)
	queue_redraw()


func _next_attack() -> void:
	var options: Array = attacks(phase).duplicate()
	if options.is_empty():
		timer = 1.0
		return
	if options.size() > 1:
		options.erase(last_attack)
	var chosen: String = options[rng.randi() % options.size()]
	last_attack = chosen
	state = "busy"
	home = global_position
	move_rate = 3.0
	call("_atk_" + chosen)


func _draw() -> void:
	_draw_boss()
	var c := hurt_offset
	if shield:
		var pts := PackedVector2Array()
		for i in 13:
			var a := t * 2.0 + TAU * i / 12.0
			pts.append(c + Vector2(cos(a) * hurt_size.x * 0.85, sin(a) * hurt_size.y * 0.65))
		draw_polyline(pts, Color(0.6, 2.2, 2.8, 0.9), 4.0, true)
		draw_circle(c, hurt_size.x * 0.9, Color(0.4, 1.8, 2.6, 0.08))
		_draw_question()
	elif state == "stunned":
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_circle(c + Vector2(cos(a) * 60.0, -hurt_size.y * 0.55 + sin(a) * 14.0), 6.0, Color(2.6, 2.2, 0.6))


func _draw_question() -> void:
	var q := question()
	if q.is_empty():
		return
	var font := UITheme.title_font()
	var text := str(q.get("prompt", ""))
	var fs := 24
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2(center_x - w * 0.5, floor_y - 560) - global_position
	draw_rect(Rect2(pos + Vector2(-18, -34), Vector2(w + 36, 50)), Color(0.02, 0.03, 0.05, 0.85))
	draw_rect(Rect2(pos + Vector2(-18, -34), Vector2(w + 36, 50)), Color(0.6, 2.0, 2.4, 0.7), false, 2.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.85))
	var need: int = q.get("correct", []).size()
	var hint := "Golpea %d runa%s correcta%s  (%d/%d)" % [need, "" if need == 1 else "s", "" if need == 1 else "s", quiz_selected.size(), need]
	var hw := UITheme.mono_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(UITheme.mono_font(), Vector2(center_x - hw * 0.5, floor_y - 500) - global_position, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 2.0, 2.2))


# --- Patrones de ataque reutilizables -----------------------------------------------------
# Cada jefe los combina con sus etiquetas y colores; todos avisan antes de dañar.

var minions: Array[Node] = []


func _hover(pos: Vector2, rate := 3.0) -> void:
	home = pos
	move_rate = rate


## Rayos horizontales a varias alturas sobre el suelo (en px), uno tras otro.
func pattern_beams(heights: Array, label: String, gap := 0.9) -> void:
	_hover(Vector2(center_x, floor_y - 460))
	for i in heights.size():
		var h: float = heights[i]
		after(0.3 + gap * i, func() -> void:
			BossAttacks.beam(get_parent(), Vector2(left_x - 40, floor_y - h), Vector2(right_x + 40, floor_y - h), 44.0, 0.85, 0.35, tint, label))
	after(0.3 + gap * heights.size() + 0.9, finish_attack)


## Columnas que brotan del suelo, repartidas por la arena y con un hueco seguro.
func pattern_pillars(count: int, label: String, waves := 1) -> void:
	_hover(Vector2(center_x, floor_y - 480))
	var span := right_x - left_x - 160.0
	for w in waves:
		var gap := rng.randi_range(0, count - 1)
		var shift := 0.5 if w % 2 == 1 else 0.0
		for i in count:
			if i == gap:
				continue
			var x := left_x + 80.0 + span * (float(i) + 0.25 + shift * 0.5) / count
			after(0.4 + 1.3 * w, func() -> void:
				BossAttacks.pillar(get_parent(), x, floor_y, 460.0, 0.9, tint, label))
	after(0.4 + 1.3 * waves + 0.8, finish_attack)


## Salta sobre el jugador, cae y lanza ondas por el suelo.
func pattern_slam() -> void:
	var px := clampf(player_pos().x, left_x + 120, right_x - 120)
	_hover(Vector2(px, floor_y - 620), 6.0)
	after(0.75, func() -> void:
		tremble = 0.4)
	after(0.95, func() -> void:
		_hover(Vector2(global_position.x, floor_y - hurt_offset.y - hurt_size.y * 0.5), 16.0))
	after(1.15, func() -> void:
		Events.camera_shake.emit(16.0, 0.4)
		AudioManager.play_sfx("break_wall")
		BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 60, floor_y), -1.0)
		BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 60, floor_y), 1.0)
		FX.dust(get_parent(), Vector2(global_position.x, floor_y), 24))
	after(1.9, finish_attack)


## Anillos de proyectiles desde el jefe, cada uno girado.
func pattern_rings(volleys: int, count: int, speed: float, label: String, gap := 0.5) -> void:
	_hover(Vector2(center_x, floor_y - 330))
	for v in volleys:
		after(0.6 + gap * v, func() -> void:
			AudioManager.play_sfx("spit", 0.2)
			BossAttacks.ring(get_parent(), global_position + hurt_offset, count, speed, t + v * 0.35, label, tint))
	after(0.6 + gap * volleys + 0.6, finish_attack)


## Latigazos: rayos desde el jefe hacia donde está el jugador en ese momento.
func pattern_whips(count: int, label: String) -> void:
	_hover(global_position, 1.0)
	for i in count:
		after(0.2 + 0.75 * i, func() -> void:
			var from := global_position + hurt_offset
			var dir := (player_pos() + Vector2(0, -40) - from).normalized()
			BossAttacks.beam(get_parent(), from, from + dir * 1500.0, 34.0, 0.6, 0.3, tint, label))
	after(0.2 + 0.75 * count + 0.7, finish_attack)


## Explota donde está, reaparece junto al jugador y explota otra vez.
func pattern_teleport(label: String) -> void:
	_hover(global_position, 1.0)
	BossAttacks.blast(get_parent(), global_position + hurt_offset, 120.0, 0.55, tint, label)
	after(0.55, func() -> void:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x := clampf(player_pos().x + side * 280.0, left_x + 120, right_x - 120)
		global_position = Vector2(x, floor_y - 240)
		home = global_position
		flash = 1.0
		FX.burst(get_parent(), global_position + hurt_offset, tint, 24, 500.0, 0.5, 0.4, Vector2.ZERO)
		BossAttacks.blast(get_parent(), global_position + hurt_offset, 130.0, 0.75, tint, label))
	after(1.7, finish_attack)


## Ola de columnas que recorre la arena de un lado a otro, con un hueco de dos.
func pattern_rolling(label: String) -> void:
	_hover(Vector2(center_x, floor_y - 500))
	var n := int((right_x - left_x) / 130.0)
	var gap := rng.randi_range(2, maxi(2, n - 4))
	var from_left := rng.randf() < 0.5
	for i in n:
		if i == gap or i == gap + 1:
			continue
		var idx := i if from_left else n - 1 - i
		var x := left_x + 65.0 + 130.0 * idx
		after(0.3 + 0.12 * i, func() -> void:
			BossAttacks.pillar(get_parent(), x, floor_y, 380.0, 0.7, tint, label))
	after(0.3 + 0.12 * n + 1.2, finish_attack)


## Abanico de bumeranes hacia el jugador.
func pattern_boomerangs(count: int, label: String) -> void:
	_hover(global_position, 1.0)
	after(0.45, func() -> void:
		var from := global_position + hurt_offset
		var base := (player_pos() + Vector2(0, -40) - from).angle()
		AudioManager.play_sfx("spit", 0.2)
		for i in count:
			var a := base + (float(i) - float(count - 1) * 0.5) * 0.3
			BossAttacks.boomerang(get_parent(), from, Vector2.RIGHT.rotated(a) * 560.0, 0.85, label, tint))
	after(2.4, finish_attack)


## Explosiones en el suelo: una bajo el jugador y otras al azar.
func pattern_floor_blasts(waves: int, per_wave: int, label: String) -> void:
	_hover(Vector2(center_x, floor_y - 420))
	for w in waves:
		after(0.3 + 1.05 * w, func() -> void:
			BossAttacks.blast(get_parent(), Vector2(player_pos().x, floor_y - 40), 85.0, 0.9, tint, label)
			for i in per_wave - 1:
				var x := rng.randf_range(left_x + 80, right_x - 80)
				BossAttacks.blast(get_parent(), Vector2(x, floor_y - 40), 85.0, 0.9, tint, label))
	after(0.3 + 1.05 * waves + 0.8, finish_attack)


## Lluvia de proyectiles desde lo alto.
func pattern_rain(count: int, labels: Array) -> void:
	_hover(Vector2(center_x, floor_y - 580))
	for i in count:
		after(0.4 + 0.2 * i, func() -> void:
			var x := rng.randf_range(left_x + 80, right_x - 80)
			var p := BossAttacks.projectile(get_parent(), Vector2(x, floor_y - 950), Vector2(0, 160), 800.0, str(labels[rng.randi() % labels.size()]))
			p.tint = tint)
	after(0.4 + 0.2 * count + 1.0, finish_attack)


## Sombra que repite el recorrido del jugador con retraso.
func pattern_replay(label: String, seconds := 5.0) -> void:
	_hover(Vector2(center_x, floor_y - 420))
	var ghost := BossAttacks.ReplayGhost.new()
	ghost.lifetime = seconds
	ghost.tint = tint
	ghost.label = label
	get_parent().add_child(ghost)
	ghost.global_position = player_pos()
	after(1.6, finish_attack)


## Invoca enemigos normales (máximo `cap` vivos a la vez).
func pattern_minions(kind: String, count: int, cap: int) -> void:
	_hover(Vector2(center_x, floor_y - 380))
	minions = minions.filter(func(m: Node) -> bool: return is_instance_valid(m) and not (m as EnemyBase).dead)
	for i in mini(count, cap - minions.size()):
		var x := left_x + 140.0 if i % 2 == 0 else right_x - 140.0
		BossAttacks.blast(get_parent(), Vector2(x, floor_y - 50), 60.0, 0.7, tint, "")
		after(0.7, func() -> void:
			var e: EnemyBase = load("res://scripts/enemies/%s.gd" % kind).new()
			e.bits_drop = 1
			e.position = get_parent().to_local(Vector2(x, floor_y - 4))
			get_parent().add_child(e)
			minions.append(e))
	after(1.3, finish_attack)


func _kill_minions() -> void:
	for m in minions:
		if is_instance_valid(m):
			(m as EnemyBase).die()
	minions.clear()
