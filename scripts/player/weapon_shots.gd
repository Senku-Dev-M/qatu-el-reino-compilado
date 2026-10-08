class_name WeaponShots
extends RefCounted
## Proyectiles que lanzan algunas armas del jugador: la flecha del Arco de
## Promesas y la onda del Mazo MVC. Golpean a cualquier cosa con `take_hit`
## (enemigos, jefes, runas) una sola vez.


static func bolt(parent: Node, pos: Vector2, dir: float, damage: int, tint: Color) -> Node2D:
	var b := Shot.new()
	b.velocity = Vector2(dir * 980.0, 0)
	b.max_distance = 780.0
	b.damage = damage
	b.tint = tint
	b.kind = "flecha"
	parent.add_child(b)
	b.global_position = pos
	return b


static func wave(parent: Node, pos: Vector2, dir: float, damage: int, tint: Color) -> Node2D:
	var w := Shot.new()
	w.velocity = Vector2(dir * 620.0, 0)
	w.max_distance = 420.0
	w.damage = damage
	w.tint = tint
	w.kind = "onda"
	w.size = Vector2(46, 56)
	w.pierce = true
	parent.add_child(w)
	w.global_position = pos
	return w


class Shot extends Area2D:
	var velocity := Vector2.ZERO
	var max_distance := 700.0
	var damage := 1
	var tint := Color(2.4, 2.4, 2.6)
	var kind := "flecha"
	var size := Vector2(40, 14)
	var pierce := false
	var travelled := 0.0
	var hits: Array = []

	func _ready() -> void:
		collision_layer = 0
		collision_mask = (1 << 4) if kind == "onda" else ((1 << 4) | 1)
		monitoring = true
		monitorable = false
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		cs.shape = r
		cs.position = Vector2(0, -size.y * 0.5) if kind == "onda" else Vector2.ZERO
		add_child(cs)
		body_entered.connect(func(_b: Node) -> void:
			FX.burst(get_parent(), global_position, tint, 8, 260.0, 0.3, 0.3)
			queue_free())
		z_index = 19

	func _physics_process(delta: float) -> void:
		var step := velocity * delta
		global_position += step
		travelled += step.length()
		for area in get_overlapping_areas():
			var target: Object = area if area.has_method("take_hit") else area.get_parent()
			if target == null or not target.has_method("take_hit") or target in hits:
				continue
			hits.append(target)
			var res: Dictionary = target.take_hit({"damage": damage, "dir": Vector2(signf(velocity.x), 0), "position": global_position - velocity.normalized() * 60.0})
			if res.get("energy", false):
				GameState.add_energy(0.5 * 0.11)
			FX.burst(get_parent(), global_position, tint, 10, 380.0, 0.3, 0.3)
			if not pierce and res.get("solid", false):
				queue_free()
				return
		if travelled >= max_distance:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var dir := signf(velocity.x)
		if kind == "flecha":
			draw_line(Vector2(-22 * dir, 0), Vector2(18 * dir, 0), tint, 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(26 * dir, 0), Vector2(14 * dir, -7), Vector2(14 * dir, 7)]), tint)
			draw_circle(Vector2(-18 * dir, 0), 8.0, Color(tint, 0.2))
		else:
			var fade := 1.0 - travelled / max_distance
			for i in 3:
				var x := -dir * i * 16.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 0), Vector2(x + 6 * dir, -50 + i * 10), Vector2(x + 14, 0)]), Color(tint, (0.85 - i * 0.25) * fade))
