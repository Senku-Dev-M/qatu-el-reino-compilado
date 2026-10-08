class_name ImpostorImplicito
extends Node2D
## Jefe de la Ciudadela IAM. Suplanta identidades aprovechando el flujo
## implícito, que devolvía el token en el fragmento de la URL.
##
## Fase 1: combate (rocía tokens, embestida de redirección, golpe).
## Fase 2: se divide en copias con distinto `state`; solo la que coincide con
## el `state` de la petición recibe daño.
## Fase 3: PKCE; golpear el `code_verifier` que produce el `code_challenge`.

signal defeated
signal health_changed(k: float)

const MAX_HP := 30
const PHASE2_HP := 19
const PHASE3_HP := 8
const ACIERTOS_POR_RONDA := 3

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
var charge_dir := 1.0
var shots_left := 0
var shot_timer := 0.0
var target_pos := Vector2.ZERO

var quiz := AuthQuiz.new()
var clones: Array[Node2D] = []
var runes: Array[CodeRune] = []
var pkce_set := -1
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
	quiz.rng.randomize()
	material = FX.flash_material()
	z_index = 12
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 1 << 4
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var hc := CollisionShape2D.new()
	var hs := RectangleShape2D.new()
	hs.size = Vector2(150, 170)
	hc.shape = hs
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := RectangleShape2D.new()
	cs.size = Vector2(120, 140)
	contact.add_shape(cs)
	add_child(contact)
	var l := FX.make_light(Color(1.6, 1.0, 2.4), 5.0, 0.8)
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
		FX.burst(get_parent(), global_position, Color(1.8, 1.0, 2.4), 8, 300.0, 0.3, 0.3)
		return {"solid": true, "energy": false, "pogo": true}
	return _damage(int(_hit.get("damage", 1)))


func _damage(amount := 1) -> Dictionary:
	var dmg := maxi(1, amount)
	var floor_hp := PHASE2_HP if phase == 1 else (PHASE3_HP if phase == 2 else 0)
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position, Color(1.8, 1.0, 2.4), 10, 420.0, 0.4, 0.35)
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
			_move_to(Vector2(center_x, floor_y - 120), delta, 3.0)
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
				_move_to(Vector2(clampf(p.global_position.x, left_x + 170, right_x - 170), floor_y - 120), delta, 1.5)
			if timer <= 0.0:
				_next_attack()
		"spray":
			shot_timer -= delta
			if shot_timer <= 0.0 and shots_left > 0:
				shots_left -= 1
				shot_timer = 0.26
				var a := -PI * 0.85 + shots_left * 0.19
				BossAttacks.projectile(get_parent(), global_position + Vector2(0, -20), Vector2(cos(a), sin(a)) * 480.0, 420.0, "#access_token")
			if shots_left <= 0 and timer <= 0.0:
				state = "idle"
				timer = 1.0
		"redirect_windup":
			tremble = 0.35
			if timer <= 0.0:
				# Desaparece y reaparece en el otro extremo: redirect_uri.
				FX.burst(get_parent(), global_position, Color(1.8, 1.0, 2.4), 22, 420.0, 0.5, 0.4, Vector2.ZERO)
				global_position.x = left_x + 140 if global_position.x > center_x else right_x - 140
				charge_dir = 1.0 if global_position.x < center_x else -1.0
				state = "redirect"
				AudioManager.play_sfx("boss_roar", 0.3)
		"redirect":
			global_position.x += charge_dir * 900.0 * delta
			if (charge_dir > 0 and global_position.x >= right_x - 110) or (charge_dir < 0 and global_position.x <= left_x + 110):
				Events.camera_shake.emit(12.0, 0.3)
				state = "idle"
				timer = 1.2
		"slam_rise":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 140, right_x - 140), floor_y - 600), delta, 5.0)
			if timer <= 0.0:
				state = "slam_fall"
		"slam_fall":
			global_position.y += 1600.0 * delta
			if global_position.y >= floor_y - 120:
				global_position.y = floor_y - 120
				Events.camera_shake.emit(18.0, 0.4)
				AudioManager.play_sfx("break_wall")
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 70, floor_y), -1.0)
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 70, floor_y), 1.0)
				state = "idle"
				timer = 1.3
		"transition":
			_move_to(target_pos, delta, 2.5)
			if timer <= 0.0:
				if phase == 2:
					_start_clones()
				else:
					_start_pkce()
		"clones":
			_move_to(Vector2(center_x, floor_y - 520), delta, 1.6)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 2.4
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 380.0, 0.0, "state?")
		"pkce":
			_move_to(Vector2(center_x, floor_y - 500), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 3.0
				BossAttacks.projectile(get_parent(), global_position, (p.global_position + Vector2(0, -40) - global_position).normalized() * 360.0, 0.0, "code")
		"exposed":
			_move_to(Vector2(center_x + sin(t * 1.2) * 280.0, floor_y - 120), delta, 3.0)
			if timer <= 0.0:
				if phase == 2:
					_start_clones()
				else:
					shield = true
					_start_pkce()
	queue_redraw()


func _next_attack() -> void:
	var options := ["spray", "redirect", "phishing"]
	options.erase(last_attack)
	last_attack = options[rng.randi() % options.size()]
	match last_attack:
		"phishing":
			_special_phishing()
		"spray":
			state = "spray"
			shots_left = 9
			shot_timer = 0.2
			timer = 2.8
			AudioManager.play_sfx("boss_roar", 0.3)
		"redirect":
			state = "redirect_windup"
			timer = 0.6
		"slam":
			state = "slam_rise"
			timer = 0.9


# --- Fase 2: copias con distinto state -------------------------------------------

## Phishing: formularios de «inicia sesión» falsos aparecen alrededor del
## jugador y se cierran de golpe. Un login legítimo nunca te busca a ti.
func _special_phishing() -> void:
	special_pos = Vector2(center_x, floor_y - 460)
	var p := _player()
	var c := p.global_position + Vector2(0, -50) if p else Vector2(center_x, floor_y - 60)
	var spots := [Vector2(-170, 0), Vector2(170, 0), Vector2(0, -170)]
	for i in spots.size():
		BossAttacks.blast(get_parent(), c + spots[i], 78.0, 1.0 + 0.25 * i, Color(1.8, 1.0, 2.4), "Inicia sesión")
	BossAttacks.blast(get_parent(), c, 60.0, 1.9, Color(2.6, 0.6, 0.6), "¿contraseña?")
	AudioManager.play_sfx("boss_roar", 0.3)
	state = "special"
	timer = 2.6


func _enter_phase2() -> void:
	phase = 2
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 520)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	Events.notify.emit("Se multiplica: golpea la copia cuyo state coincide con el de la petición")


func _start_clones() -> void:
	state = "clones"
	invulnerable = true
	shield = true
	shot_timer = 2.0
	quiz.start_states(3)
	_clear_clones()
	var values := quiz.state_options()
	var lane := (right_x - left_x) / values.size()
	for i in values.size():
		var clone := ImpostorClone.new()
		clone.value = str(values[i])
		clone.boss = self
		get_parent().add_child(clone)
		clone.global_position = Vector2(left_x + lane * (i + 0.5), floor_y - 150)
		clones.append(clone)


func _clear_clones() -> void:
	for c in clones:
		if is_instance_valid(c):
			c.queue_free()
	clones.clear()


## Llamado por una copia al recibir un golpe.
func on_clone_hit(clone: Node2D) -> void:
	if state != "clones":
		return
	if quiz.hit_state(str(clone.value)) == "correct":
		AudioManager.play_sfx("sello_ok")
		Events.camera_shake.emit(8.0, 0.4)
		invulnerable = false
		shield = false
		_damage()
		invulnerable = true
		shield = true
		if hp > PHASE3_HP:
			if quiz.aciertos % ACIERTOS_POR_RONDA == 0:
				Events.notify.emit("state verificado. La petición era legítima")
				shield = false
				invulnerable = false
				state = "exposed"
				timer = 5.0
				_clear_clones()
			else:
				_shuffle_clones()
	else:
		AudioManager.play_sfx("sello_bad")
		clone.wrong = 1.0
		BossAttacks.shockwave(get_parent(), Vector2(clone.global_position.x - 40, floor_y), -1.0)
		BossAttacks.shockwave(get_parent(), Vector2(clone.global_position.x + 40, floor_y), 1.0)


func _shuffle_clones() -> void:
	var values := quiz.state_options()
	for i in clones.size():
		if is_instance_valid(clones[i]):
			clones[i].value = str(values[i % values.size()])
			clones[i].flash = 1.0


# --- Fase 3: PKCE --------------------------------------------------------------------

func _enter_phase3() -> void:
	phase = 3
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 500)
	_clear_clones()
	AudioManager.play_sfx("boss_roar")
	Events.notify.emit("PKCE: golpea el code_verifier que produce el code_challenge")


func _start_pkce() -> void:
	state = "pkce"
	invulnerable = false
	shield = true
	shot_timer = 2.5
	pkce_set = quiz.start_pkce(pkce_set)
	_clear_runes()
	var opts := quiz.verifier_options()
	var lane := (right_x - left_x) / opts.size()
	for i in opts.size():
		var rune := CodeRune.new()
		rune.line = "code_verifier=" + str(opts[i])
		get_parent().add_child(rune)
		rune.global_position = global_position
		rune.move_to = Vector2(left_x + lane * (i + 0.5), floor_y - (150 if i % 2 == 0 else 280))
		rune.struck.connect(_on_rune)
		runes.append(rune)


func _clear_runes() -> void:
	for r in runes:
		if is_instance_valid(r):
			r.queue_free()
	runes.clear()


func _on_rune(rune: CodeRune) -> void:
	if state != "pkce":
		return
	var value := rune.line.replace("code_verifier=", "")
	if quiz.hit_verifier(value) == "correct":
		rune.state = "correct"
		AudioManager.play_sfx("sello_ok")
		Events.camera_shake.emit(10.0, 0.5)
		Events.notify.emit("S256(code_verifier) coincide con el code_challenge")
		shield = false
		state = "exposed"
		timer = 6.0
		await get_tree().create_timer(0.6).timeout
		_clear_runes()
	else:
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
	_clear_clones()
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(26.0, 2.0)
	for i in 8:
		FX.burst(get_parent(), global_position + Vector2(rng.randf_range(-80, 80), rng.randf_range(-90, 90)), Color(1.8, 1.0, 2.4) if i % 2 == 0 else Color(2.4, 1.9, 0.8), 26, 600.0, 0.8, 0.5, Vector2.ZERO)
		await get_tree().create_timer(0.22).timeout
	var tw := create_tween()
	tw.tween_property(self, "dissolve", 1.0, 1.0)
	await tw.finished
	FX.burst(get_parent(), global_position, Color(2.6, 2.4, 2.4), 60, 900.0, 1.2, 0.6, Vector2.ZERO)
	defeated.emit()
	queue_free()


func _draw() -> void:
	var shake := Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * tremble
	_draw_figure(self, shake, Color(1.8, 1.0, 2.4), phase)
	var font := UITheme.mono_font()
	if shield and state != "dead":
		draw_arc(shake + Vector2(0, -60), 150, 0, TAU, 64, Color(1.8, 1.1, 2.4, 0.8), 4.0, true)
		draw_circle(shake + Vector2(0, -60), 150, Color(1.6, 0.9, 2.2, 0.05))
	if state == "clones":
		var text := "GET /authorize?…&state=" + quiz.expected_state
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		var pos := shake + Vector2(-ts.x * 0.5, -300)
		draw_rect(Rect2(pos + Vector2(-12, -26), Vector2(ts.x + 24, 38)), Color(0, 0, 0, 0.8))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(2.4, 1.9, 0.8))
		draw_string(UITheme.title_font(), pos + Vector2(0, 26), "Solo la respuesta con ese state es legítima", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.95, 0.9, 0.8))
	elif state == "pkce":
		var lines := ["code_challenge_method = S256", "code_challenge = " + quiz.challenge().substr(0, 24) + "…"]
		var pos := shake + Vector2(-260, -320)
		draw_rect(Rect2(pos + Vector2(-12, -26), Vector2(540, 68)), Color(0, 0, 0, 0.8))
		for i in lines.size():
			draw_string(font, pos + Vector2(0, i * 26), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.7, 2.2, 2.2) if i == 0 else Color(2.4, 1.9, 0.8))


## Dibuja la figura del impostor (la usan también las copias).
static func _draw_figure(c: CanvasItem, at: Vector2, col: Color, fase: int) -> void:
	var dark := Color(0.08, 0.05, 0.12)
	var body := PackedVector2Array([
		at + Vector2(-46, 0), at + Vector2(-34, -96), at + Vector2(-16, -128),
		at + Vector2(16, -128), at + Vector2(34, -96), at + Vector2(46, 0)])
	c.draw_colored_polygon(body, dark)
	c.draw_polyline(body, Color(col, 0.7), 2.5, true)
	# Capucha vacía con una máscara de identidad prestada.
	c.draw_circle(at + Vector2(0, -132), 26, dark)
	c.draw_arc(at + Vector2(0, -132), 26, 0, TAU, 28, Color(col, 0.8), 2.0, true)
	var mask := PackedVector2Array([
		at + Vector2(-16, -140), at + Vector2(16, -140), at + Vector2(12, -120), at + Vector2(-12, -120)])
	c.draw_colored_polygon(mask, Color(col, 0.25))
	c.draw_circle(at + Vector2(-7, -134), 3.0, col)
	c.draw_circle(at + Vector2(7, -134), 3.0, col)
	if fase >= 2:
		for i in 3:
			var a := float(i) * TAU / 3.0
			c.draw_circle(at + Vector2(cos(a), sin(a)) * 60 + Vector2(0, -60), 5.0, Color(col, 0.5))


## Copia del impostor: muestra un `state` y solo una es la legítima.
class ImpostorClone extends Area2D:
	var value := ""
	var boss: Node2D
	var flash := 0.0
	var wrong := 0.0
	var t := 0.0

	func _ready() -> void:
		collision_layer = 1 << 4
		collision_mask = 0
		monitoring = false
		var shape := RectangleShape2D.new()
		shape.size = Vector2(110, 150)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(0, -75)
		add_child(cs)
		z_index = 11
		t = randf() * 4.0

	func take_hit(_hit: Dictionary) -> Dictionary:
		flash = 1.0
		if boss and boss.has_method("on_clone_hit"):
			boss.on_clone_hit(self)
		return {"solid": true, "energy": true, "pogo": true}

	func _process(delta: float) -> void:
		t += delta
		flash = maxf(0.0, flash - delta * 3.0)
		wrong = maxf(0.0, wrong - delta)
		position.y += sin(t * 2.0) * 6.0 * delta
		queue_redraw()

	func _draw() -> void:
		var col := Color(1.4, 0.9, 2.2).lerp(Color(3, 3, 3), flash)
		if wrong > 0.0:
			col = Color(2.6, 0.5, 0.5)
		ImpostorImplicito._draw_figure(self, Vector2.ZERO, col, 2)
		var font := UITheme.mono_font()
		var text := "state=" + value
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_rect(Rect2(Vector2(-ts.x * 0.5 - 8, -190), Vector2(ts.x + 16, 26)), Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(-ts.x * 0.5, -172), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
