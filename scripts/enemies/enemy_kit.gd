class_name EnemyKit
extends RefCounted
## Utilidades compartidas por los enemigos de las zonas 1, 2, 8 y 9: disparos
## apuntados, abanicos, vuelo suave y avisos de una sola vez.


## Dispara un proyectil desde `from` hacia `target` a `speed` px/s.
static func shoot_at(e: Node2D, from: Vector2, target: Vector2, speed: float, label := "", gravity := 0.0) -> Node2D:
	var dir := (target - from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	AudioManager.play_sfx("spit", 0.2)
	return BossAttacks.projectile(e.get_parent(), from, dir * speed, gravity, label)


## Abanico de `count` proyectiles separados `spread` radianes.
static func fan(e: Node2D, from: Vector2, target: Vector2, speed: float, count: int, spread: float, label := "") -> void:
	var base := (target - from).angle()
	AudioManager.play_sfx("spit", 0.2)
	for i in count:
		var a := base + (float(i) - float(count - 1) * 0.5) * spread
		BossAttacks.projectile(e.get_parent(), from, Vector2.RIGHT.rotated(a) * speed, 0.0, label)


## Velocidad para volar hacia `goal` con aceleración limitada.
static func steer(vel: Vector2, from: Vector2, goal: Vector2, max_speed: float, accel: float, delta: float) -> Vector2:
	var want := (goal - from).limit_length(max_speed)
	return vel.move_toward(want, accel * delta)


## Muestra una pista la primera vez que se da una situación.
static func tip(flag: String, text: String) -> void:
	if GameState.get_flag("tip:" + flag):
		return
	GameState.set_flag("tip:" + flag)
	Events.notify.emit(text)


## Etiqueta de texto centrada sobre el enemigo.
static func label(ci: CanvasItem, pos: Vector2, text: String, size: int, col: Color) -> void:
	var font := UITheme.mono_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, pos - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Ajusta el tamaño de todas las formas rectangulares del enemigo (crecer).
static func resize(e: EnemyBase, size: Vector2) -> void:
	e.body_size = size
	(e.body_shape.shape as RectangleShape2D).size = size
	e.body_shape.position = Vector2(0, -size.y * 0.5)
	for area: Area2D in [e.hurtbox, e.contact]:
		for c in area.get_children():
			var cs := c as CollisionShape2D
			if cs and cs.shape is RectangleShape2D:
				var extra := Vector2(14, 14) if area == e.hurtbox else Vector2.ZERO
				var k := 1.0 if area == e.hurtbox else 0.85
				(cs.shape as RectangleShape2D).size = size * k + extra
				cs.position = Vector2(0, -size.y * 0.5)
