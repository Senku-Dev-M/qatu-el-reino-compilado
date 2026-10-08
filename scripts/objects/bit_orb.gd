class_name BitOrb
extends Node2D
## Bit suelto: sale disparado y luego vuela hacia el jugador.

var value := 1
var velocity := Vector2.ZERO
var age := 0.0
var t := 0.0


static func spawn_burst(parent: Node, pos: Vector2, total: int) -> void:
	if parent == null or total <= 0:
		return
	var remaining := total
	while remaining > 0:
		var v := 5 if remaining >= 10 else 1
		remaining -= v
		var orb := BitOrb.new()
		orb.value = v
		orb.velocity = Vector2(randf_range(-320, 320), randf_range(-620, -260))
		parent.add_child(orb)
		orb.global_position = pos


func _ready() -> void:
	z_index = 25
	t = randf() * 3.0


func _physics_process(delta: float) -> void:
	age += delta
	t += delta
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if age < 0.45 or player == null:
		velocity.y += 1800.0 * delta
		velocity *= 0.985
	else:
		var to := player.global_position + Vector2(0, -44) - global_position
		velocity = velocity.lerp(to.normalized() * minf(1700.0, 300.0 + age * 1500.0), 0.18)
		if to.length() < 40.0:
			GameState.add_bits(value)
			AudioManager.play_sfx("bits", 0.2)
			queue_free()
			return
	global_position += velocity * delta
	queue_redraw()


func _draw() -> void:
	var s := 7.0 if value >= 5 else 5.0
	var rot := t * 6.0
	var pts := PackedVector2Array()
	for i in 4:
		var a := rot + TAU * i / 4.0
		pts.append(Vector2(cos(a) * s, sin(a) * s * 1.4))
	draw_colored_polygon(pts, Color(2.4, 1.9, 0.7))
	draw_circle(Vector2.ZERO, s * 2.2, Color(1.8, 1.4, 0.5, 0.12))
