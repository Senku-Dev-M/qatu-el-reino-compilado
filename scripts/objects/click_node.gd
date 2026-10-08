extends Area2D
## Nodo *click*: al golpearlo dispara su evento y abre su objetivo.

var room: RoomBase
var def: Dictionary
var active := false
var t := 0.0
var flash := 0.0
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	position.y -= 40
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30
	cs.shape = shape
	add_child(cs)
	light = FX.make_light(Color(1.0, 0.7, 0.4), 1.8, 0.7)
	add_child(light)
	active = bool(GameState.get_flag(room.flag_key(def.id)))


func on_room_ready(_room: RoomBase) -> void:
	if active:
		for target in _targets():
			if target and target.has_method("open"):
				target.open(false)


func _targets() -> Array:
	var out := []
	var ids = def.get("targets", [def.get("target", "")])
	for id in ids:
		out.append(room.get_entity(id))
	return out


func take_hit(_hit: Dictionary) -> Dictionary:
	flash = 1.0
	if not active:
		active = true
		GameState.set_flag(room.flag_key(def.id))
		AudioManager.play_sfx("node_on")
		FX.burst(get_parent(), global_position, Color(2.4, 1.8, 0.8), 20, 380.0, 0.5, 0.35, Vector2.ZERO)
		Events.notify.emit("addEventListener('click') → evento disparado")
		for target in _targets():
			if target and target.has_method("open"):
				target.open(true)
	return {"solid": true, "energy": false, "pogo": true}


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 4.0)
	light.color = Color(1.0, 0.75, 0.4) if active else Color(0.8, 0.5, 1.0)
	queue_redraw()


func _draw() -> void:
	var col := Color(2.4, 1.7, 0.6) if active else Color(1.6, 0.6, 2.0)
	var r := 26.0 + flash * 6.0
	draw_circle(Vector2.ZERO, r + 14, Color(col, 0.08))
	draw_circle(Vector2.ZERO, r, Color(0.03, 0.02, 0.04))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, col, 3.0, true)
	# Icono de puntero (click).
	var p := Vector2(-7, -12)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(0, 24), p + Vector2(6, 18), p + Vector2(11, 27), p + Vector2(15, 25), p + Vector2(10, 16), p + Vector2(18, 16)]), col)
	if not active:
		var k := fmod(t, 1.4) / 1.4
		draw_arc(Vector2.ZERO, r + k * 30, 0, TAU, 32, Color(col, (1.0 - k) * 0.6), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-30, r + 26), "click", HORIZONTAL_ALIGNMENT_CENTER, 60, 18, Color(col, 0.7))
