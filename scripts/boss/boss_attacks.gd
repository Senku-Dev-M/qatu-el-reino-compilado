class_name BossAttacks
extends RefCounted
## Fábrica de ataques del jefe: proyectiles, ondas y zonas corruptas.


static func projectile(parent: Node, pos: Vector2, vel: Vector2, gravity := 0.0, label := "") -> BossProjectile:
	var p := BossProjectile.new()
	p.velocity = vel
	p.fall_gravity = gravity
	p.label = label
	parent.add_child(p)
	p.global_position = pos
	return p


static func shockwave(parent: Node, pos: Vector2, dir: float) -> void:
	var s := Shockwave.new()
	s.dir = dir
	parent.add_child(s)
	s.global_position = pos


static func corrupt_zone(parent: Node, pos: Vector2, width: float) -> void:
	var z := CorruptZone.new()
	z.width = width
	parent.add_child(z)
	z.global_position = pos


## Rayo telegrafiado entre dos puntos: primero una línea fina de aviso y luego
## el rayo activo, que daña durante `active` segundos.
static func beam(parent: Node, a: Vector2, b: Vector2, width := 44.0, warn := 0.8, active := 0.35, tint := Color(2.6, 0.6, 0.4), label := "") -> Node2D:
	var n := Beam.new()
	n.a = a
	n.b = b
	n.width = width
	n.warn = warn
	n.active = active
	n.tint = tint
	n.label = label
	parent.add_child(n)
	return n


## Explosión circular marcada en el suelo o el aire.
static func blast(parent: Node, pos: Vector2, radius := 90.0, warn := 0.9, tint := Color(2.4, 0.5, 1.8), label := "") -> Node2D:
	var n := Blast.new()
	n.radius = radius
	n.warn = warn
	n.tint = tint
	n.label = label
	parent.add_child(n)
	n.global_position = pos
	return n


## Columna que brota del suelo en `x` (se avisa con una marca en el suelo).
static func pillar(parent: Node, x: float, floor_y: float, height := 420.0, warn := 0.8, tint := Color(2.4, 1.2, 0.4), label := "") -> Node2D:
	var n := Pillar.new()
	n.height = height
	n.warn = warn
	n.tint = tint
	n.label = label
	parent.add_child(n)
	n.global_position = Vector2(x, floor_y)
	return n


## Anillo de `count` proyectiles que salen desde `center`.
static func ring(parent: Node, center: Vector2, count: int, speed: float, offset := 0.0, label := "", tint := Color(2.4, 0.5, 1.9)) -> void:
	for i in count:
		var dir := Vector2.RIGHT.rotated(offset + TAU * i / count)
		var p := projectile(parent, center, dir * speed, 0.0, label)
		p.tint = tint


## Proyectil que va y vuelve a `home`.
static func boomerang(parent: Node, pos: Vector2, vel: Vector2, back_after := 0.8, label := "", tint := Color(2.4, 0.5, 1.9)) -> BossProjectile:
	var p := projectile(parent, pos, vel, 0.0, label)
	p.return_after = back_after
	p.home = pos
	p.tint = tint
	return p


class Beam extends DamageArea:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var width := 44.0
	var warn := 0.8
	var active := 0.35
	var tint := Color(2.6, 0.6, 0.4)
	var label := ""
	var age := 0.0

	func _ready() -> void:
		var r := RectangleShape2D.new()
		r.size = Vector2(a.distance_to(b), width * 0.7)
		global_position = (a + b) * 0.5
		rotation = (b - a).angle()
		add_shape(r)
		set_enabled(false)
		z_index = 18

	func _physics_process(delta: float) -> void:
		var before := age
		age += delta
		if before < warn and age >= warn:
			set_enabled(true)
			AudioManager.play_sfx("spit", 0.2)
			Events.camera_shake.emit(5.0, 0.15)
		if age >= warn + active:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var hl := a.distance_to(b) * 0.5
		if age < warn:
			var k := age / warn
			draw_line(Vector2(-hl, 0), Vector2(hl, 0), Color(tint, 0.25 + 0.45 * k * absf(sin(age * 18.0))), 3.0)
			draw_rect(Rect2(-hl, -width * 0.5 * k, hl * 2.0, width * k), Color(tint, 0.06))
		else:
			var f := 1.0 - (age - warn) / active
			draw_rect(Rect2(-hl, -width * 0.5, hl * 2.0, width), Color(tint, 0.35 * f))
			draw_rect(Rect2(-hl, -width * 0.18, hl * 2.0, width * 0.36), Color(tint.lerp(Color(3, 3, 3), 0.5), 0.9 * f))
		if label != "":
			draw_string(UITheme.mono_font(), Vector2(-hl + 12, -width * 0.5 - 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(tint, 0.9))


class Blast extends DamageArea:
	var radius := 90.0
	var warn := 0.9
	var tint := Color(2.4, 0.5, 1.8)
	var label := ""
	var age := 0.0
	const ACTIVE := 0.25

	func _ready() -> void:
		var c := CircleShape2D.new()
		c.radius = radius
		add_shape(c)
		set_enabled(false)
		z_index = 17

	func _physics_process(delta: float) -> void:
		var before := age
		age += delta
		if before < warn and age >= warn:
			set_enabled(true)
			AudioManager.play_sfx("break_wall", 0.3)
			FX.burst(get_parent(), global_position, tint, 18, 420.0, 0.45, 0.4, Vector2.ZERO)
		if age >= warn + ACTIVE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if age < warn:
			var k := age / warn
			draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(tint, 0.5 + 0.4 * absf(sin(age * 14.0))), 3.0)
			draw_circle(Vector2.ZERO, radius * k, Color(tint, 0.12))
			if label != "":
				var w := UITheme.mono_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
				draw_string(UITheme.mono_font(), Vector2(-w * 0.5, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(tint, 0.95))
		else:
			draw_circle(Vector2.ZERO, radius, Color(tint, 0.45 * (1.0 - (age - warn) / ACTIVE)))


class Pillar extends DamageArea:
	var height := 420.0
	var warn := 0.8
	var tint := Color(2.4, 1.2, 0.4)
	var label := ""
	var age := 0.0
	const ACTIVE := 0.55
	const W := 70.0

	func _ready() -> void:
		var r := RectangleShape2D.new()
		r.size = Vector2(W * 0.8, height)
		add_shape(r, Vector2(0, -height * 0.5))
		set_enabled(false)
		z_index = 16

	func _physics_process(delta: float) -> void:
		var before := age
		age += delta
		if before < warn and age >= warn:
			set_enabled(true)
			AudioManager.play_sfx("break_wall", 0.3)
		if age >= warn + ACTIVE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if age < warn:
			var k := age / warn
			draw_rect(Rect2(-W * 0.5, -8, W, 8), Color(tint, 0.3 + 0.6 * absf(sin(age * 16.0))))
			draw_rect(Rect2(-W * 0.5, -height * k * 0.15, W, height * k * 0.15), Color(tint, 0.08))
		else:
			var grow := clampf((age - warn) / 0.1, 0.0, 1.0)
			var fade := 1.0 - clampf((age - warn - 0.35) / 0.2, 0.0, 1.0)
			var h := height * grow
			draw_rect(Rect2(-W * 0.5, -h, W, h), Color(0.06, 0.04, 0.03, 0.9 * fade))
			draw_rect(Rect2(-W * 0.5, -h, W, h), Color(tint, fade), false, 3.0)
		if label != "":
			var w := UITheme.mono_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(UITheme.mono_font(), Vector2(-w * 0.5, -18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(tint, 0.9))


class BossProjectile extends DamageArea:
	var velocity := Vector2.ZERO
	var fall_gravity := 0.0
	var label := ""
	var age := 0.0
	var tint := Color(2.4, 0.5, 1.9)
	## Bumerán: pasado este tiempo vuelve hacia `home` (0 = no vuelve).
	var return_after := 0.0
	var home := Vector2.ZERO

	func _ready() -> void:
		var c := CircleShape2D.new()
		c.radius = 16
		add_shape(c)
		monitoring = true
		collision_mask = 1
		body_entered.connect(func(_b):
			if age > 0.05:
				FX.burst(get_parent(), global_position, Color(2.2, 0.5, 1.8), 8, 200.0, 0.3, 0.3)
				queue_free())
		z_index = 20

	func _physics_process(delta: float) -> void:
		age += delta
		velocity.y += fall_gravity * delta
		if return_after > 0.0 and age > return_after:
			var back := (home - global_position)
			velocity = velocity.move_toward(back.normalized() * 620.0, 1400.0 * delta)
			if back.length() < 40.0:
				queue_free()
		global_position += velocity * delta
		if age > 6.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 26, Color(tint, 0.15))
		draw_circle(Vector2.ZERO, 14, Color(0.08, 0.02, 0.08))
		draw_arc(Vector2.ZERO, 14, 0, TAU, 20, tint, 3.0)
		if label != "":
			draw_string(ThemeDB.fallback_font, Vector2(-18, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 36, 14, tint.lerp(Color(2.4, 2.4, 2.4), 0.4))


class Shockwave extends DamageArea:
	var dir := 1.0
	var age := 0.0

	func _ready() -> void:
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 46)
		add_shape(r, Vector2(0, -23))
		z_index = 20

	func _physics_process(delta: float) -> void:
		age += delta
		global_position.x += dir * 760.0 * delta
		if age > 2.2:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for i in 4:
			var x := -dir * i * 18.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 14, 0), Vector2(x, -46 + i * 8), Vector2(x + 14, 0)]), Color(2.4, 0.5, 1.8, 0.9 - i * 0.2))


class CorruptZone extends DamageArea:
	var width := 200.0
	var age := 0.0
	const WARN := 0.9
	const ACTIVE := 1.4

	func _ready() -> void:
		var r := RectangleShape2D.new()
		r.size = Vector2(width, 30)
		add_shape(r, Vector2(0, -15))
		set_enabled(false)
		z_index = 3

	func _physics_process(delta: float) -> void:
		var before := age
		age += delta
		if before < WARN and age >= WARN:
			set_enabled(true)
			AudioManager.play_sfx("spit", 0.2)
		if age >= WARN + ACTIVE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var hw := width * 0.5
		if age < WARN:
			var k := age / WARN
			draw_rect(Rect2(-hw, -6, width, 6), Color(2.0, 0.3, 1.5, 0.25 + 0.5 * k * absf(sin(age * 20.0))))
		else:
			for i in int(width / 20.0):
				var x := -hw + 10 + i * 20
				var h := 20.0 + sin(age * 18.0 + i) * 10.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 0), Vector2(x, -h), Vector2(x + 9, 0)]), Color(2.4, 0.4, 1.8, 0.85))


## Sombra que repite el recorrido del jugador con `DELAY` segundos de retraso
## (la regresión vuelve a hacer lo que ya se había corregido).
class ReplayGhost extends DamageArea:
	const DELAY := 1.2
	var lifetime := 5.0
	var tint := Color(2.4, 0.5, 0.9)
	var label := ""
	var age := 0.0
	var trail: Array = []  # [tiempo, posición]

	func _ready() -> void:
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 70)
		add_shape(r, Vector2(0, -38))
		set_enabled(false)
		z_index = 14

	func _physics_process(delta: float) -> void:
		age += delta
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p:
			trail.append([age, p.global_position])
		while trail.size() > 1 and float(trail[1][0]) <= age - DELAY:
			trail.pop_front()
		if age >= DELAY and not trail.is_empty():
			global_position = trail[0][1]
			if age - delta < DELAY:
				set_enabled(true)
		if age >= DELAY + lifetime:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if age < DELAY:
			draw_arc(Vector2(0, -38), 40.0 * (age / DELAY), 0, TAU, 20, Color(tint, 0.6), 2.0)
			return
		var fade := clampf((DELAY + lifetime - age) / 0.5, 0.0, 1.0)
		draw_circle(Vector2(0, -60), 16, Color(tint, 0.45 * fade))
		draw_colored_polygon(PackedVector2Array([Vector2(-16, -48), Vector2(16, -48), Vector2(22, 0), Vector2(-22, 0)]), Color(tint, 0.35 * fade))
		draw_arc(Vector2(0, -38), 34, 0, TAU, 20, Color(tint, 0.7 * fade), 2.0)
		if label != "":
			draw_string(UITheme.mono_font(), Vector2(-24, -88), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(tint, 0.9 * fade))
