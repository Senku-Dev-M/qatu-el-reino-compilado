extends Node2D
## Tablilla de conocimiento: losa de piedra con glifo luminoso.

var room: RoomBase
var def: Dictionary
var t := 0.0
var light: PointLight2D
var reading := false


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	t = randf() * 10.0
	var it := Interactable.new()
	add_child(it)
	it.setup(Vector2(150, 130), Vector2(0, -65), "Estudiar la lección")
	light = FX.make_light(Color(1.0, 0.8, 0.45), 2.6, 0.9)
	light.position = Vector2(0, -110)
	add_child(light)


func is_read() -> bool:
	return def.id in GameState.data.tablillas


func interact(_p: Player) -> void:
	if reading or RoomRouter.world == null:
		return
	reading = true
	var is_new := GameState.read_tablilla(def.id)
	await RoomRouter.world.ui.show_tablilla(def.id, is_new)
	reading = false


func _process(delta: float) -> void:
	t += delta
	light.energy = (0.9 if not is_read() else 0.45) + sin(t * 2.0) * 0.08
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.09, 0.085, 0.08)
	var edge := Color(0.5, 0.45, 0.35)
	var read := is_read()
	# Base escalonada.
	draw_rect(Rect2(-54, -18, 108, 18), stone)
	draw_rect(Rect2(-42, -30, 84, 14), stone)
	# Losa con remate trapezoidal.
	var slab := PackedVector2Array([Vector2(-36, -30), Vector2(36, -30), Vector2(32, -150), Vector2(18, -170), Vector2(-18, -170), Vector2(-32, -150)])
	draw_colored_polygon(slab, stone)
	slab.append(slab[0])
	draw_polyline(slab, Color(edge, 0.6), 2.0, true)
	# Glifo </> y líneas de texto grabado.
	var glow_k := 0.55 + 0.45 * sin(t * 2.2)
	var col := Color(2.2, 1.6, 0.6) if not read else Color(0.9, 0.75, 0.45)
	col = Color(col.r * (0.7 + 0.3 * glow_k), col.g * (0.7 + 0.3 * glow_k), col.b, 1.0)
	var c := Vector2(0, -130)
	draw_polyline(PackedVector2Array([c + Vector2(-8, -12), c + Vector2(-18, 0), c + Vector2(-8, 12)]), col, 3.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(8, -12), c + Vector2(18, 0), c + Vector2(8, 12)]), col, 3.0, true)
	draw_line(c + Vector2(4, -14), c + Vector2(-4, 14), col, 3.0, true)
	for i in 4:
		var y := -100 + i * 16
		draw_line(Vector2(-22, y), Vector2(22 - (i * 7) % 18, y), Color(col, 0.45), 2.0)
	if not read:
		for i in 3:
			var a := t * 0.8 + TAU * i / 3.0
			draw_circle(c + Vector2(cos(a) * 46, sin(a) * 20 - 10), 2.5, Color(2.0, 1.5, 0.6, 0.8))
