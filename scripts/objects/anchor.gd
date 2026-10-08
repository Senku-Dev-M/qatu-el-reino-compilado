extends Node2D
## Nodo ancla del DOM: el Event Listener se "suscribe" a él.

var room: RoomBase
var def: Dictionary
var t := 0.0
var targeted := false
var pulse := 0.0
var link_to: Node2D  # jugador mientras está enganchado
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	position.y -= 32
	add_to_group("anchor")
	t = randf() * 5.0
	light = FX.make_light(Color(0.4, 1.0, 0.95), 1.6, 0.8)
	add_child(light)


var _released_at := -10000


func can_grapple() -> bool:
	# Tras soltarse, el nodo descansa un instante para poder encadenar el siguiente.
	return Time.get_ticks_msec() - _released_at > 450


func set_targeted(on: bool) -> void:
	targeted = on


func on_grapple(player: Node2D) -> void:
	link_to = player
	pulse = 1.0
	AudioManager.play_sfx("node_on", 0.1)


func on_release() -> void:
	link_to = null
	_released_at = Time.get_ticks_msec()
	FX.burst(get_parent(), global_position, Color(0.6, 2.4, 2.2), 10, 260.0, 0.4, 0.3, Vector2.ZERO)


func _process(delta: float) -> void:
	t += delta
	pulse = maxf(0.0, pulse - delta * 2.0)
	var has := GameState.has_ability("event_listener")
	light.energy = (0.5 if has else 0.25) + (0.6 if targeted else 0.0) + pulse
	queue_redraw()


func _draw() -> void:
	var has := GameState.has_ability("event_listener")
	var base := Color(0.5, 2.2, 2.0) if has else Color(0.3, 0.6, 0.6)
	var r := 13.0 + sin(t * 3.0) * 1.5 + pulse * 6.0
	draw_circle(Vector2.ZERO, r * 2.4, Color(base, 0.08))
	draw_circle(Vector2.ZERO, r, Color(0.02, 0.05, 0.05))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, base, 3.0, true)
	draw_circle(Vector2.ZERO, r * 0.42, base)
	# Ramitas que lo sujetan.
	for i in 3:
		var a := -PI * 0.5 + (i - 1) * 0.7
		draw_line(Vector2(cos(a), sin(a)) * r, Vector2(cos(a), sin(a)) * (r + 26), Color(0.1, 0.2, 0.2), 3.0, true)
	if targeted:
		var k := 0.5 + 0.5 * sin(t * 10.0)
		draw_arc(Vector2.ZERO, r + 12 + k * 4, 0, TAU, 32, Color(2.4, 2.4, 2.4, 0.9), 2.0, true)
		for i in 4:
			var a := t * 2.0 + TAU * i / 4.0
			draw_line(Vector2(cos(a), sin(a)) * (r + 20), Vector2(cos(a), sin(a)) * (r + 30), Color(2.4, 2.4, 2.4), 3.0)
	if is_instance_valid(link_to):
		var to := link_to.global_position + Vector2(0, -44) - global_position
		var pts := PackedVector2Array()
		for i in 13:
			var k := i / 12.0
			pts.append(to * k + to.orthogonal().normalized() * sin(k * PI * 3.0 + t * 30.0) * 6.0 * (1.0 - k) * k * 4.0)
		draw_polyline(pts, Color(1.0, 2.6, 2.4), 3.0, true)
