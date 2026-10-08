class_name NodoHuerfano
extends Node2D
## Jefe del Bosque del DOM. Fase 1: combate. Fase 2: desprendimiento
## (usar el Event Listener). Fase 3: escudo que se rompe golpeando las
## etiquetas en orden de anidamiento correcto.

signal defeated
signal health_changed(k: float)

const MAX_HP := 24
const PHASE2_HP := 15
const PHASE3_HP := 6
const TILE := 64

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
var shield := false
var invulnerable := true
var t := 0.0
var flash := 0.0
var tremble := 0.0
var dissolve := 0.0

var target_pos := Vector2.ZERO
var move_speed := 6.0
var charge_dir := 1.0
var shots_left := 0
var shot_timer := 0.0
var zone_timer := 0.0

var puzzle := NestingPuzzle.new()
var puzzle_set := -1
var tags: Array[TagTarget] = []
var anchors: Array[Node2D] = []
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
	var hs := CircleShape2D.new()
	hs.radius = 70
	hc.shape = hs
	hurtbox.add_child(hc)
	add_child(hurtbox)
	contact = DamageArea.new()
	var cs := CircleShape2D.new()
	cs.radius = 52
	contact.add_shape(cs)
	add_child(contact)
	var l := FX.make_light(Color(1.0, 0.4, 0.9), 5.0, 0.8)
	l.remove_from_group("light_source")
	add_child(l)
	target_pos = global_position
	state = "intro"
	timer = 1.6


func take_hit(_hit: Dictionary) -> Dictionary:
	if state == "dead":
		return {"solid": false}
	if invulnerable or shield:
		AudioManager.play_sfx("sello_bad", 0.2)
		FX.burst(get_parent(), global_position, Color(0.6, 2.2, 2.4), 8, 300.0, 0.3, 0.3)
		return {"solid": true, "energy": false, "pogo": true}
	var dmg := maxi(1, int(_hit.get("damage", 1)))
	var floor_hp := PHASE2_HP if phase == 1 else (PHASE3_HP if phase == 2 else 0)
	hp = maxi(hp - dmg, floor_hp)
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.04)
	FX.burst(get_parent(), global_position, Color(2.2, 0.5, 1.8), 10, 420.0, 0.4, 0.35)
	health_changed.emit(float(hp) / float(MAX_HP))
	if hp <= 0:
		_die()
	elif phase == 1 and hp <= PHASE2_HP:
		_enter_phase2()
	elif phase == 2 and hp <= PHASE3_HP:
		_enter_phase3()
	return {"solid": true, "energy": true, "pogo": true}


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


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
			_move_to(Vector2(center_x, floor_y - 300), delta, 3.0)
			if timer <= 0.0:
				invulnerable = false
				_next_attack()
		# --- Fase 1 ---
		"special":
			_move_to(special_pos, delta, 3.0)
			if timer <= 0.0:
				state = "idle"
				timer = 1.0
		"idle":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 150, right_x - 150), floor_y - 250 + sin(t * 2.0) * 20.0), delta, 2.0)
			if timer <= 0.0:
				_next_attack()
		"charge_position":
			_move_to(target_pos, delta, 5.0)
			if timer <= 0.0:
				state = "charge_windup"
				timer = 0.55
				tremble = 0.55
				AudioManager.play_sfx("boss_roar", 0.2)
		"charge_windup":
			if timer <= 0.0:
				state = "charge"
		"charge":
			global_position.x += charge_dir * 980.0 * delta
			if (charge_dir > 0 and global_position.x >= right_x - 90) or (charge_dir < 0 and global_position.x <= left_x + 90):
				Events.camera_shake.emit(12.0, 0.3)
				FX.burst(get_parent(), global_position + Vector2(charge_dir * 60, 0), Color(0.2, 0.3, 0.3), 16, 400.0, 0.5, 0.5)
				state = "idle"
				timer = 1.2
		"rain":
			_move_to(Vector2(center_x, floor_y - 640), delta, 3.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and shots_left > 0:
				shots_left -= 1
				shot_timer = 0.22
				var x := rng.randf_range(left_x + 60, right_x - 60)
				BossAttacks.projectile(get_parent(), Vector2(x, floor_y - 1000), Vector2(0, 120), 900.0, ["li", "a", "p", "b"][rng.randi() % 4])
			if shots_left <= 0 and timer <= 0.0:
				state = "idle"
				timer = 1.0
		"slam_rise":
			if p:
				_move_to(Vector2(clampf(p.global_position.x, left_x + 100, right_x - 100), floor_y - 620), delta, 6.0)
			if timer <= 0.0:
				state = "slam_fall"
				tremble = 0.25
		"slam_fall":
			global_position.y += 1500.0 * delta
			if global_position.y >= floor_y - 70:
				global_position.y = floor_y - 70
				Events.camera_shake.emit(20.0, 0.45)
				AudioManager.play_sfx("break_wall")
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 40, floor_y), -1.0)
				BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 40, floor_y), 1.0)
				FX.dust(get_parent(), Vector2(global_position.x, floor_y), 24)
				state = "idle"
				timer = 1.4
		# --- Fase 2 ---
		"transition":
			_move_to(target_pos, delta, 2.5)
			if timer <= 0.0:
				invulnerable = false
				if phase == 2:
					state = "float"
					_pick_float_point()
				else:
					_start_puzzle()
		"float":
			_move_to(target_pos, delta, 1.4)
			shot_timer -= delta
			zone_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 1.25
				var dir := (p.global_position + Vector2(0, -40) - global_position).normalized()
				BossAttacks.projectile(get_parent(), global_position, dir * 520.0)
				AudioManager.play_sfx("spit")
			if zone_timer <= 0.0:
				zone_timer = 3.6
				for i in 2:
					BossAttacks.corrupt_zone(get_parent(), Vector2(rng.randf_range(left_x + 180, right_x - 180), floor_y), 280.0)
			if timer <= 0.0:
				_pick_float_point()
		# --- Fase 3 ---
		"shielded":
			_move_to(Vector2(center_x + sin(t * 0.6) * 120.0, floor_y - 360), delta, 2.0)
			shot_timer -= delta
			if shot_timer <= 0.0 and p:
				shot_timer = 2.8
				var dir := (p.global_position + Vector2(0, -40) - global_position).normalized()
				BossAttacks.projectile(get_parent(), global_position, dir * 420.0)
		"exposed":
			_move_to(Vector2(center_x + sin(t * 1.2) * 260.0, floor_y - 150), delta, 3.0)
			if timer <= 0.0:
				shield = true
				AudioManager.play_sfx("gate_open")
				_start_puzzle()
		"dead":
			tremble = 1.0
	queue_redraw()


func _move_to(pos: Vector2, delta: float, speed: float) -> void:
	global_position = global_position.lerp(pos, 1.0 - exp(-speed * delta))


func _next_attack() -> void:
	var options := ["burbujeo", "rain", "slam"]
	options.erase(last_attack)
	var pick: String = options[rng.randi() % options.size()]
	last_attack = pick
	var p := _player()
	match pick:
		"burbujeo":
			_special_burbujeo()
		"charge":
			var px := p.global_position.x if p else center_x
			var from_left := px > center_x
			target_pos = Vector2((left_x + 110) if from_left else (right_x - 110), floor_y - 72)
			charge_dir = 1.0 if from_left else -1.0
			state = "charge_position"
			timer = 0.9
		"rain":
			state = "rain"
			shots_left = 8
			shot_timer = 0.6
			timer = 2.6
			AudioManager.play_sfx("boss_roar", 0.3)
		"slam":
			state = "slam_rise"
			timer = 0.9


## Propagación de eventos (bubbling): el evento nace en el elemento donde está
## el jugador y sube por sus ancestros: click → div → body → html.
func _special_burbujeo() -> void:
	special_pos = Vector2(center_x, floor_y - 560)
	var x := clampf(_player().global_position.x if _player() else center_x, left_x + 90, right_x - 90)
	var names := ["click", "<div>", "<body>", "<html>"]
	for i in 4:
		BossAttacks.blast(get_parent(), Vector2(x, floor_y - 45 - 110 * i), 62.0, 0.75 + 0.3 * i, Color(0.6, 2.2, 2.4), names[i])
	# Segundo evento en el otro lado de la arena.
	var x2 := right_x - 160 if x < center_x else left_x + 160
	for i in 4:
		BossAttacks.blast(get_parent(), Vector2(x2, floor_y - 45 - 110 * i), 62.0, 1.5 + 0.3 * i, Color(2.2, 0.6, 1.8), names[i])
	AudioManager.play_sfx("boss_roar", 0.3)
	state = "special"
	timer = 2.8


func _enter_phase2() -> void:
	phase = 2
	invulnerable = true
	state = "transition"
	timer = 1.6
	target_pos = Vector2(center_x, floor_y - 560)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	Events.notify.emit("¡El nodo se desprende! Suscríbete a los nodos con el Event Listener")
	var anchor_script: GDScript = load("res://scripts/objects/anchor.gd")
	var positions := [
		Vector2(left_x + 260, floor_y - 300), Vector2(center_x - 300, floor_y - 470),
		Vector2(center_x + 300, floor_y - 470), Vector2(right_x - 260, floor_y - 300),
		Vector2(center_x, floor_y - 260)]
	for pos in positions:
		var a: Node2D = anchor_script.new()
		get_parent().add_child(a)
		a.global_position = pos + Vector2(0, 32)
		a.setup(arena.room, {"type": "anchor"})
		anchors.append(a)
		FX.burst(get_parent(), pos, Color(0.6, 2.4, 2.2), 20, 300.0, 0.6, 0.4, Vector2.ZERO)


func _pick_float_point() -> void:
	var a: Node2D = anchors[rng.randi() % anchors.size()]
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	target_pos = a.global_position + Vector2(side * 150, -40)
	target_pos.x = clampf(target_pos.x, left_x + 100, right_x - 100)
	timer = 3.2
	shot_timer = 0.8


func _enter_phase3() -> void:
	phase = 3
	invulnerable = true
	shield = true
	state = "transition"
	timer = 1.4
	target_pos = Vector2(center_x, floor_y - 360)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(16.0, 1.0)
	for a in anchors:
		if is_instance_valid(a):
			a.queue_free()
	anchors.clear()
	Events.notify.emit("Un escudo lo protege: golpea las etiquetas de fuera hacia dentro")


func _start_puzzle() -> void:
	state = "shielded"
	invulnerable = false
	shield = true
	shot_timer = 2.0
	puzzle_set = puzzle.start_random(rng, puzzle_set)
	_clear_tags()
	var slots := _tag_slots()
	var order := range(4)
	order.shuffle()
	for i in 4:
		var tag := TagTarget.new()
		tag.tag = puzzle.sequence[i]
		get_parent().add_child(tag)
		tag.global_position = global_position
		tag.move_to = slots[order[i]]
		tag.struck.connect(_on_tag_struck)
		tags.append(tag)


func _tag_slots() -> Array:
	return [
		Vector2(left_x + 220, floor_y - 150), Vector2(center_x - 230, floor_y - 250),
		Vector2(center_x + 230, floor_y - 250), Vector2(right_x - 220, floor_y - 150)]


func _clear_tags() -> void:
	for tag in tags:
		if is_instance_valid(tag):
			tag.queue_free()
	tags.clear()


func _on_tag_struck(tag: TagTarget) -> void:
	if state != "shielded":
		return
	var result := puzzle.hit(tag.tag)
	match result:
		"correct":
			tag.state = "correct"
			AudioManager.play_sfx("node_on")
		"complete":
			tag.state = "correct"
			AudioManager.play_sfx("sello_ok")
			Events.camera_shake.emit(10.0, 0.5)
			FX.burst(get_parent(), global_position, Color(2.4, 1.9, 0.7), 40, 700.0, 0.8, 0.5, Vector2.ZERO)
			Events.notify.emit("Estructura correcta: %s" % puzzle.html_text())
			shield = false
			state = "exposed"
			timer = 5.0
			await get_tree().create_timer(0.4).timeout
			_clear_tags()
		"wrong":
			AudioManager.play_sfx("sello_bad")
			Events.notify.emit("Anidamiento incorrecto. Empieza por <%s>" % puzzle.expected())
			var slots := _tag_slots()
			var order := range(4)
			order.shuffle()
			for i in tags.size():
				tags[i].state = "idle"
				tags[i].move_to = slots[order[i]]
			tag.state = "wrong"
			BossAttacks.shockwave(get_parent(), Vector2(global_position.x - 40, floor_y), -1.0)
			BossAttacks.shockwave(get_parent(), Vector2(global_position.x + 40, floor_y), 1.0)
			await get_tree().create_timer(0.5).timeout
			if is_instance_valid(tag):
				tag.state = "idle"


func _die() -> void:
	state = "dead"
	invulnerable = true
	contact.set_enabled(false)
	_clear_tags()
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(26.0, 2.0)
	for i in 8:
		FX.burst(get_parent(), global_position + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)), Color(2.4, 0.6, 2.0) if i % 2 == 0 else Color(0.6, 2.4, 2.2), 26, 600.0, 0.8, 0.5, Vector2.ZERO)
		await get_tree().create_timer(0.22).timeout
	var tw := create_tween()
	tw.tween_property(self, "dissolve", 1.0, 1.0)
	await tw.finished
	FX.burst(get_parent(), global_position, Color(2.6, 2.6, 2.8), 60, 900.0, 1.2, 0.6, Vector2.ZERO)
	defeated.emit()
	queue_free()


func _draw() -> void:
	var shake := Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)) * tremble
	var c := shake
	var core := Color(0.03, 0.02, 0.04)
	var rim := Color(0.5, 2.0, 2.2)
	var vein := Color(2.4, 0.4, 1.9)
	# Rama cortada y cable colgante.
	var stub := c + Vector2(0, -60)
	draw_line(stub, stub + Vector2(10, -70), Color(0.08, 0.1, 0.1), 16.0, true)
	var cable := PackedVector2Array()
	for i in 12:
		var k := i / 11.0
		cable.append(stub + Vector2(10, -70) + Vector2(sin(t * 2.0 + k * 4.0) * 30.0 * k, -k * 160.0))
	draw_polyline(cable, Color(0.2, 0.25, 0.25, 0.8), 3.0, true)
	draw_circle(cable[11], 5, vein)
	# Hojas-etiqueta orbitando.
	var font := ThemeDB.fallback_font
	var leaves := ["<li>", "<a>", "<ul>", "<p>", "<div>"]
	for i in leaves.size():
		var a := t * (0.8 if phase == 1 else 1.6) + TAU * i / leaves.size()
		var lp := c + Vector2(cos(a) * 118, sin(a) * 58)
		draw_string(font, lp + Vector2(-18, 5), leaves[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(rim, 0.7))
	# Cuerpo del nodo.
	draw_circle(c, 92, Color(vein, 0.08))
	draw_circle(c, 66, core)
	draw_arc(c, 66, 0, TAU, 64, rim, 4.0, true)
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		var v := PackedVector2Array([c + Vector2(cos(a), sin(a)) * 20, c + Vector2(cos(a + 0.2), sin(a + 0.2)) * 44, c + Vector2(cos(a - 0.1), sin(a - 0.1)) * 66])
		draw_polyline(v, Color(vein, 0.8), 2.5, true)
	# Ojos.
	var glare := 1.0 + tremble
	draw_circle(c + Vector2(-20, -8), 9, Color(vein.r * glare, vein.g, vein.b * glare))
	draw_circle(c + Vector2(20, -8), 9, Color(vein.r * glare, vein.g, vein.b * glare))
	draw_line(c + Vector2(-30, -22), c + Vector2(-10, -16), rim, 3.0)
	draw_line(c + Vector2(30, -22), c + Vector2(10, -16), rim, 3.0)
	# Escudo.
	if shield and state != "dead":
		var pts := PackedVector2Array()
		for i in 7:
			var a := t * 0.8 + TAU * i / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * 104)
		draw_polyline(pts, Color(0.8, 2.4, 2.6, 0.9), 4.0, true)
		draw_circle(c, 104, Color(0.5, 1.8, 2.0, 0.06))
	if state == "shielded" or state == "exposed":
		var ui_font := UITheme.mono_font()
		var text := "Anida:  " + puzzle.html_text()
		var size := ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
		var top := c + Vector2(-size.x * 0.5, -170)
		draw_rect(Rect2(top + Vector2(-16, -34), Vector2(size.x + 32, 48)), Color(0, 0, 0, 0.7))
		draw_string(ui_font, top, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(2.2, 1.8, 0.8) if state == "shielded" else Color(0.8, 2.2, 1.2))
		if state == "shielded":
			var next := "Siguiente: <%s>" % puzzle.expected()
			draw_string(font, c + Vector2(-70, -118), next, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 2.0, 2.2))
