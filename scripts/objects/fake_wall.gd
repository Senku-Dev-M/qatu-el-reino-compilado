extends StaticBody2D
## Pared falsa: parece roca, pero se rompe tras varios golpes.
## La celda es la esquina inferior izquierda; ocupa w × h tiles.

const TILE := 64

var room: RoomBase
var def: Dictionary
var w := 2
var h := 3
var hp := 4
var shake := 0.0
var hit_area: Area2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	w = int(def.get("w", 2))
	h = int(def.get("h", 3))
	if GameState.get_flag(room.flag_key(def.id)):
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	position += Vector2(-TILE * 0.5, 0)
	var size := Vector2(w * TILE, h * TILE)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
	add_child(cs)
	hit_area = Area2D.new()
	hit_area.collision_layer = 1 << 4
	hit_area.collision_mask = 0
	hit_area.monitoring = false
	var hcs := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = size + Vector2(24, 0)
	hcs.shape = hshape
	hcs.position = cs.position
	hit_area.add_child(hcs)
	add_child(hit_area)
	z_index = 2


func take_hit(_hit: Dictionary) -> Dictionary:
	hp -= 1
	shake = 1.0
	AudioManager.play_sfx("hit")
	FX.burst(get_parent(), global_position + Vector2(w * TILE * 0.5, -h * TILE * 0.5), Color(0.3, 0.4, 0.4), 10, 300.0, 0.5, 0.5)
	if hp <= 0:
		GameState.set_flag(room.flag_key(def.id))
		AudioManager.play_sfx("break_wall")
		Events.camera_shake.emit(10.0, 0.4)
		FX.burst(get_parent(), global_position + Vector2(w * TILE * 0.5, -h * TILE * 0.5), Color(0.15, 0.2, 0.2), 40, 600.0, 1.0, 0.8)
		Events.notify.emit("¡Un pasaje oculto!")
		queue_free()
	queue_redraw()
	return {"solid": true, "energy": false, "pogo": true}


func _process(delta: float) -> void:
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 5.0)
		queue_redraw()


func _draw() -> void:
	var th := room.theme() if room else Themes.get_theme("forest")
	var off := Vector2(randf_range(-3, 3) * shake, 0)
	var rect := Rect2(Vector2(0, -h * TILE) + off, Vector2(w * TILE, h * TILE))
	draw_rect(rect.grow(2), th.rock)
	# Grietas sutiles que delatan la pared (más visibles al dañarla).
	var crack := Color(th.rim, 0.12 + (4 - hp) * 0.12)
	var c := rect.get_center()
	draw_polyline(PackedVector2Array([c + Vector2(-30, -60), c + Vector2(-8, -20), c + Vector2(-20, 10), c + Vector2(6, 50)]), crack, 2.0)
	draw_polyline(PackedVector2Array([c + Vector2(-8, -20), c + Vector2(24, -8), c + Vector2(34, 30)]), crack, 2.0)
