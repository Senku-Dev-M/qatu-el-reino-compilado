extends Node2D
## Palanca: abre una compuerta durante `segundos` (0 = para siempre) o avisa a
## otra entidad que tenga `on_lever()` (por ejemplo, la arena de un jefe).
## Definición: {"type": "palanca", "target": id, "segundos": s,
##              "enfriamiento": s, "etiqueta": texto}

var room: RoomBase
var def: Dictionary
var t := 0.0
var timer := 0.0
var cooldown := 0.0
var pulled := false
var it: Interactable


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	it = Interactable.new()
	add_child(it)
	it.setup(Vector2(120, 150), Vector2(0, -70), "Tirar de la palanca")
	var seconds := float(def.get("segundos", 0.0))
	if seconds <= 0.0 and GameState.get_flag(room.flag_key(def.id)):
		pulled = true


func can_interact() -> bool:
	return cooldown <= 0.0 and timer <= 0.0 and not (pulled and float(def.get("segundos", 0.0)) <= 0.0)


func interact(_p: Player) -> void:
	pull()


func pull() -> void:
	if not can_interact():
		return
	var target = room.get_entity(str(def.get("target", "")))
	var seconds := float(def.get("segundos", 0.0))
	AudioManager.play_sfx("gate_open", 0.1)
	Events.camera_shake.emit(4.0, 0.2)
	pulled = true
	cooldown = float(def.get("enfriamiento", 0.0))
	if target and target.has_method("on_lever"):
		target.on_lever()
	elif target and target.has_method("open"):
		target.open()
		if seconds > 0.0:
			timer = seconds
		else:
			GameState.set_flag(room.flag_key(def.id))


func _process(delta: float) -> void:
	t += delta
	cooldown = maxf(0.0, cooldown - delta)
	if timer > 0.0:
		timer -= delta
		if timer <= 0.0:
			timer = 0.0
			pulled = false
			var target = room.get_entity(str(def.get("target", "")))
			if target and target.has_method("close"):
				target.close()
	elif cooldown <= 0.0 and float(def.get("segundos", 0.0)) > 0.0:
		pulled = false
	queue_redraw()


func _draw() -> void:
	var metal := Color(0.42, 0.38, 0.36)
	draw_rect(Rect2(-26, -18, 52, 18), metal)
	draw_rect(Rect2(-26, -18, 52, 18), Color(1.2, 0.9, 0.6, 0.6), false, 1.5)
	var angle := -0.6 if not pulled else 0.6
	var tip := Vector2(sin(angle), -cos(angle)) * 60 + Vector2(0, -14)
	draw_line(Vector2(0, -14), tip, Color(0.6, 0.52, 0.46), 7.0, true)
	var col := Color(2.4, 1.6, 0.5) if not pulled else Color(0.5, 2.2, 1.4)
	draw_circle(tip, 9, col)
	var font := UITheme.mono_font()
	var text := str(def.get("etiqueta", ""))
	if timer > 0.0:
		text = "abierta · %.1f s" % timer
		draw_arc(Vector2(0, -40), 40, -PI * 0.5, -PI * 0.5 + TAU * timer / maxf(float(def.get("segundos", 1.0)), 0.01), 32, Color(0.5, 2.2, 1.4), 3.0, true)
	elif cooldown > 0.0:
		text = "espera · %.1f s" % cooldown
	if text != "":
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_string(font, Vector2(-ts.x * 0.5, -104), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.0, 1.6, 0.8, 0.9))
