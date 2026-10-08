extends Area2D
## Cofre-caché: se rompe a golpes y suelta Bits.

var room: RoomBase
var def: Dictionary
var hp := 3
var broken := false
var shake := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, 70)
	cs.shape = shape
	cs.position = Vector2(0, -35)
	add_child(cs)
	broken = bool(GameState.get_flag(room.flag_key(def.id)))


func take_hit(_hit: Dictionary) -> Dictionary:
	if broken:
		return {"solid": false}
	hp -= 1
	shake = 1.0
	AudioManager.play_sfx("hit")
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(1.6, 1.3, 0.6), 8, 300.0, 0.4, 0.3)
	if hp <= 0:
		broken = true
		GameState.set_flag(room.flag_key(def.id))
		AudioManager.play_sfx("break_wall")
		BitOrb.spawn_burst(get_parent(), global_position + Vector2(0, -50), int(def.get("bits", 40)))
		Events.notify.emit("Caché liberada")
	queue_redraw()
	return {"solid": true, "energy": false, "pogo": true}


func _process(delta: float) -> void:
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 6.0)
		queue_redraw()


func _draw() -> void:
	var off := Vector2(randf_range(-4, 4) * shake, 0)
	var dark := Color(0.08, 0.06, 0.04)
	var rim := Color(0.7, 0.5, 0.2)
	if broken:
		draw_colored_polygon(PackedVector2Array([Vector2(-46, 0), Vector2(-30, -22), Vector2(-4, -8), Vector2(20, -26), Vector2(46, 0)]), dark)
		return
	draw_rect(Rect2(Vector2(-45, -64) + off, Vector2(90, 64)), dark)
	draw_rect(Rect2(Vector2(-45, -64) + off, Vector2(90, 64)), rim, false, 3.0)
	draw_line(Vector2(-45, -40) + off, Vector2(45, -40) + off, rim, 3.0)
	# Glifo de caché (disco).
	var c := Vector2(0, -26) + off
	draw_arc(c, 12, 0, TAU, 20, Color(2.2, 1.6, 0.6), 3.0)
	draw_circle(c, 4, Color(2.2, 1.6, 0.6))
	for i in hp:
		draw_circle(Vector2(-30 + i * 12, -52) + off, 3, Color(2.0, 1.5, 0.5))
