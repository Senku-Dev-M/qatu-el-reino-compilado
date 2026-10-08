extends Area2D
## Nodo *hover*: mientras el jugador está cerca, activa sus plataformas.

const LINGER := 3.5

var room: RoomBase
var def: Dictionary
var near := false
var linger := 0.0
var t := 0.0
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	position.y -= 40
	collision_layer = 0
	collision_mask = 1 << 1
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(def.get("radius", 190))
	cs.shape = shape
	add_child(cs)
	body_entered.connect(func(b): if b is Player: _set_near(true))
	body_exited.connect(func(b): if b is Player: near = false)
	light = FX.make_light(Color(0.6, 0.8, 1.0), 2.0, 0.5)
	add_child(light)


func _set_near(on: bool) -> void:
	if on and not near and linger <= 0.0:
		AudioManager.play_sfx("node_on", 0.2)
		if not GameState.get_flag("tip:hover"):
			Events.notify.emit("addEventListener('mouseover') → evento disparado")
			GameState.set_flag("tip:hover")
	near = on


func _process(delta: float) -> void:
	t += delta
	if near:
		linger = LINGER
	else:
		linger = maxf(0.0, linger - delta)
	var active := near or linger > 0.0
	var fading := not near and linger < 0.8 and linger > 0.0
	for id in def.get("targets", []):
		var p = room.get_entity(id)
		if p and p.has_method("set_active"):
			p.set_active(active, fading)
	light.energy = 1.2 if active else 0.5
	queue_redraw()


func _draw() -> void:
	var active := near or linger > 0.0
	var col := Color(0.8, 1.4, 2.6) if active else Color(0.5, 0.7, 1.2)
	var r := 20.0 + sin(t * 2.0) * 2.0
	draw_circle(Vector2.ZERO, r + 16, Color(col, 0.07))
	draw_circle(Vector2.ZERO, r, Color(0.02, 0.03, 0.06))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, col, 3.0, true)
	draw_arc(Vector2.ZERO, float(def.get("radius", 190)), 0, TAU, 64, Color(col, 0.08 if not active else 0.16), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, r + 26), "hover", HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color(col, 0.7))
	if linger > 0.0 and not near:
		draw_arc(Vector2.ZERO, r + 8, -PI * 0.5, -PI * 0.5 + TAU * linger / LINGER, 32, Color(2.0, 2.0, 2.2), 3.0, true)
