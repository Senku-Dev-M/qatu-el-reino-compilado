extends Node2D
## Banco-Commit: guarda la partida, restaura la vida y permite cambiar
## amuletos mientras el jugador está sentado.

var room: RoomBase
var def: Dictionary
var sitting := false
var player: Player
var t := 0.0
var _sit_time := 0.0
var interactable: Interactable


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	interactable = Interactable.new()
	add_child(interactable)
	interactable.setup(Vector2(180, 110), Vector2(0, -55), "Hacer commit")
	var l := FX.make_light(Color(1.0, 0.8, 0.5), 3.2, 0.9)
	l.position = Vector2(-70, -150)
	add_child(l)


func spawn_position() -> Vector2:
	return global_position + Vector2(0, -2)


func interact(p: Player) -> void:
	if sitting:
		return
	player = p
	sitting = true
	_sit_time = 0.0
	p.lock(true)
	p.global_position = global_position + Vector2(0, -26)
	p.velocity = Vector2.ZERO
	GameState.rest(room.room_id, def.id)
	GameState.at_bench = true
	var hash_text := ("%x" % absi(hash(room.room_id + str(Time.get_ticks_msec())))).substr(0, 7)
	Events.notify.emit("commit %s: «%s»" % [hash_text, room.display_name])
	AudioManager.play_sfx("bench")
	FX.burst(get_parent(), global_position + Vector2(0, -60), Color(2.2, 1.7, 0.8), 24, 240.0, 1.0, 0.35, Vector2(0, -120))
	if RoomRouter.world:
		RoomRouter.world.autosave()
		RoomRouter.world.ui.notify("Pulsa [%s] para cambiar amuletos" % Settings.key_name("codice"))


func can_interact() -> bool:
	return not sitting


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if not sitting:
		return
	_sit_time += delta
	if get_tree().paused or _sit_time < 0.4:
		return
	if Input.is_action_just_pressed("jump") or absf(Input.get_axis("move_left", "move_right")) > 0.5 or Input.is_action_just_pressed("look_down"):
		sitting = false
		GameState.at_bench = false
		if is_instance_valid(player):
			player.lock(false)


func _draw() -> void:
	var stone := Color(0.08, 0.08, 0.09)
	var edge := Color(0.45, 0.42, 0.36)
	# Asiento de piedra con patas escalonadas.
	draw_rect(Rect2(-86, -44, 172, 18), stone)
	draw_line(Vector2(-86, -44), Vector2(86, -44), edge, 3.0)
	for sx in [-70, 50]:
		draw_rect(Rect2(sx, -26, 20, 26), stone)
		draw_rect(Rect2(sx - 6, -8, 32, 8), stone)
	# Respaldo con manta tejida.
	draw_rect(Rect2(-80, -96, 160, 14), stone)
	var palette := [Color(0.45, 0.14, 0.1), Color(0.6, 0.42, 0.12), Color(0.12, 0.25, 0.3)]
	for i in 3:
		draw_rect(Rect2(-54 + i * 36, -82, 34, 36), palette[i])
		draw_line(Vector2(-54 + i * 36, -64), Vector2(-20 + i * 36, -64), Color(palette[i].lightened(0.4), 0.8), 2.0)
	# Farol del commit.
	var lamp := Vector2(-70, -150)
	draw_line(Vector2(-70, -96), lamp + Vector2(0, 14), stone, 5.0)
	var flicker := 0.85 + 0.15 * sin(t * 9.0) * sin(t * 3.3)
	draw_circle(lamp, 26, Color(1.6, 1.0, 0.4, 0.15 * flicker))
	draw_circle(lamp, 9, Color(2.8 * flicker, 1.3 * flicker, 0.4))
	draw_rect(Rect2(lamp.x - 12, lamp.y - 16, 24, 4), stone)
	if sitting:
		draw_arc(Vector2(0, -60), 110 + sin(t * 2.0) * 6.0, 0, TAU, 48, Color(1.8, 1.4, 0.7, 0.18), 3.0)
