extends Node2D
## Fuente de promesa (habilidad Promesa). Al activarla pasa a «pending» y,
## tras el retardo, se cumple (aparecen plataformas de agua durante un
## tiempo) o se rechaza. Puede encadenar otra fuente con `then` o `catch`.
##
## Definición:
##   {"type": "promesa", "id": ..., "plataformas": [[dx, dy, ancho], ...] (tiles
##    relativos a la celda de la fuente; dy negativo = arriba),
##    "retardo": s, "duracion": s, "rechaza": bool, "then": id, "catch": id,
##    "activable": bool (false = solo se activa desde otra fuente),
##    "etiqueta": texto de la llamada, p. ej. "fetch('/productos')"}

signal state_changed(state: String)

const TILE := 64
const THICK := 22.0

var room: RoomBase
var def: Dictionary
var state := "idle"  # idle | pending | fulfilled | rejected
var timer := 0.0
var delay := 1.2
var duration := 5.0
var rejects := false
var activable := true
var label := ""
var platforms: Array[StaticBody2D] = []
var rects: Array[Rect2] = []
var player_inside := false
var t := 0.0
var flash := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	add_to_group("promesa")
	delay = float(def.get("retardo", 1.2))
	duration = float(def.get("duracion", 5.0))
	rejects = bool(def.get("rechaza", false))
	activable = bool(def.get("activable", true))
	label = str(def.get("etiqueta", "new Promise(...)"))
	z_index = 3
	for p in def.get("plataformas", []):
		# La posición del nodo es el centro inferior de su celda.
		var r := Rect2(Vector2(float(p[0]) * TILE - TILE * 0.5, float(p[1]) * TILE), Vector2(float(p[2]) * TILE, THICK))
		rects.append(r)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.get_center()
		cs.one_way_collision = true
		cs.disabled = true
		body.add_child(cs)
		add_child(body)
		platforms.append(body)
	if activable:
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 1 << 1
		var acs := CollisionShape2D.new()
		var ashape := RectangleShape2D.new()
		ashape.size = Vector2(TILE * 3, TILE * 3)
		acs.shape = ashape
		acs.position = Vector2(0, -TILE * 1.2)
		area.add_child(acs)
		add_child(area)
		area.body_entered.connect(func(b): if b is Player: player_inside = true)
		area.body_exited.connect(func(b): if b is Player: player_inside = false)


func is_fulfilled() -> bool:
	return state == "fulfilled"


func fulfilled_duration() -> float:
	return duration * (1.6 if GameState.is_charm_equipped("timeout") else 1.0)


## Inicia la promesa. Devuelve false si ya estaba en curso.
func trigger() -> bool:
	if state != "idle":
		return false
	_set_state("pending")
	timer = delay
	AudioManager.play_sfx("node_on", 0.1)
	return true


func _set_state(s: String) -> void:
	state = s
	flash = 1.0
	var solid := s == "fulfilled"
	for body in platforms:
		(body.get_child(0) as CollisionShape2D).set_deferred("disabled", not solid)
	state_changed.emit(s)


func _chain(key: String) -> void:
	if def.has(key):
		var other = room.get_entity(str(def[key]))
		if other and other.has_method("trigger"):
			other.trigger()


func _physics_process(delta: float) -> void:
	if state == "idle":
		return
	timer -= delta
	if timer > 0.0:
		return
	match state:
		"pending":
			if rejects:
				_set_state("rejected")
				timer = 1.6
				AudioManager.play_sfx("sello_bad", 0.1)
				_chain("catch")
			else:
				_set_state("fulfilled")
				timer = fulfilled_duration()
				AudioManager.play_sfx("gate_open", 0.15)
				FX.burst(self, _platforms_center(), Color(0.5, 2.0, 2.2), 18, 320.0, 0.5, 0.35, Vector2.ZERO)
				_chain("then")
		"fulfilled", "rejected":
			_set_state("idle")


func _platforms_center() -> Vector2:
	if rects.is_empty():
		return Vector2(0, -80)
	var sum := Vector2.ZERO
	for r in rects:
		sum += r.get_center()
	return sum / rects.size()


func _nearest_active() -> bool:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var mine := global_position.distance_to(player.global_position)
	for other in get_tree().get_nodes_in_group("promesa"):
		if other != self and other.activable and other.player_inside and other.global_position.distance_to(player.global_position) < mine:
			return false
	return true


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.0)
	if activable and player_inside and not get_tree().paused and Input.is_action_just_pressed("promesa") and _nearest_active():
		if not GameState.has_ability("promesa"):
			Events.notify.emit("La fuente no responde. Necesitas la habilidad Promesa.")
			AudioManager.play_sfx("sello_bad")
		elif not trigger():
			Events.notify.emit("Esta promesa ya está en curso: espera a que se resuelva.")
	queue_redraw()


func _state_color() -> Color:
	match state:
		"pending": return Color(2.4, 1.7, 0.5)
		"fulfilled": return Color(0.5, 2.2, 2.3)
		"rejected": return Color(2.6, 0.5, 0.45)
	return Color(0.55, 1.3, 1.5)


func _draw() -> void:
	var col := _state_color()
	var stone := Color(0.16, 0.24, 0.28)
	var rim := Color(0.6, 1.4, 1.5, 0.7)
	# Pila de piedra con caño.
	if activable:
		var basin := PackedVector2Array([Vector2(-46, 0), Vector2(46, 0), Vector2(38, -26), Vector2(-38, -26)])
		draw_colored_polygon(basin, stone)
		draw_polyline(basin, rim, 2.0, true)
		draw_rect(Rect2(-54, -40, 108, 16), stone)
		draw_rect(Rect2(-54, -40, 108, 16), rim, false, 2.0)
		draw_circle(Vector2(0, -40), 40, Color(col, 0.06))
		draw_rect(Rect2(-50, -36, 100, 8), Color(col, 0.35 + 0.3 * flash))
		var jet := 30.0 + (40.0 if state == "fulfilled" else 10.0 * sin(t * 4.0))
		draw_line(Vector2(0, -36), Vector2(0, -36 - jet), Color(col, 0.7), 5.0, true)
		draw_circle(Vector2(0, -40 - jet), 7, Color(col, 0.9))
	else:
		# Fuente encadenada: solo un sello en la roca.
		draw_arc(Vector2(0, -30), 18, 0, TAU, 24, Color(col, 0.6), 3.0, true)
	# Anillo de espera.
	if state == "pending":
		var k := 1.0 - clampf(timer / maxf(delay, 0.01), 0.0, 1.0)
		draw_arc(Vector2(0, -110), 22, -PI * 0.5, -PI * 0.5 + TAU * k, 32, col, 4.0, true)
	# Plataformas: fantasmas cuando no están cumplidas.
	for i in rects.size():
		var r := rects[i]
		match state:
			"fulfilled":
				var blink := timer < 1.2 and int(t * 10.0) % 2 == 0
				var a := 0.45 if blink else 1.0
				draw_rect(r, Color(0.12, 0.45, 0.55, a))
				draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(0.8, 2.4, 2.5, a))
				for w in int(r.size.x / 24.0):
					var wx := r.position.x + 12 + w * 24
					draw_line(Vector2(wx - 6, r.position.y + 12 + sin(t * 5.0 + w) * 2.0), Vector2(wx + 6, r.position.y + 12 + sin(t * 5.0 + w) * 2.0), Color(0.6, 1.8, 2.0, 0.5 * a), 2.0)
			"pending":
				draw_rect(r, Color(col, 0.12 + 0.1 * sin(t * 8.0)), false, 2.0)
			_:
				draw_rect(r, Color(0.5, 1.2, 1.4, 0.22), false, 2.0)
	# Texto de estado: sobre la pila, o sobre la plataforma si es una fuente encadenada.
	var font := UITheme.mono_font()
	var text := label
	var status: String = {"idle": "", "pending": "Promise {<pending>}", "fulfilled": "fulfilled", "rejected": "rejected"}.get(state, "")
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var anchor := Vector2(0, -150)
	if not activable and not rects.is_empty():
		anchor = Vector2(_platforms_center().x, rects[0].position.y - 44)
	var y := anchor.y
	draw_rect(Rect2(Vector2(anchor.x - ts.x * 0.5 - 8, y - 20), Vector2(ts.x + 16, 28)), Color(0, 0, 0, 0.5))
	draw_string(font, Vector2(anchor.x - ts.x * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 1.8, 1.9, 0.9))
	if status != "":
		var ss := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2(anchor.x - ss.x * 0.5, y + 26), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col.lerp(Color(3, 3, 3), flash))
	if activable and player_inside and state == "idle":
		var hint := ("[%s] activar promesa" % Settings.key_name("promesa")) if GameState.has_ability("promesa") else "(requiere Promesa)"
		var hs := UITheme.title_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_string(UITheme.title_font(), Vector2(-hs.x * 0.5, y - 30), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
