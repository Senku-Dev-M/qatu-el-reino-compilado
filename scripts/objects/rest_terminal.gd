class_name RestTerminal
extends Area2D
## Terminal REST (zona 1). Recibe la petición cuando el jugador lo atraviesa con
## el REST Dash, y entonces abre la compuerta de su `target`.
##
## Definición: {"type": "rest_terminal", "id": "term1", "target": "gate1",
##              "peticion": "GET /api/pedidos"}

const TILE := 64

var room: RoomBase
var def: Dictionary
var sent := false
var near := false
var t := 0.0
var flash := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	sent = GameState.get_flag(room.flag_key(str(def.get("id", "term"))))
	if sent:
		_open_target.call_deferred(false)


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	monitoring = true
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 96)
	cs.shape = rect
	cs.position = Vector2(0, -48)
	add_child(cs)


func peticion() -> String:
	return str(def.get("peticion", "GET /api/pedidos"))


## Envía la petición (lo llama el propio terminal al detectar el REST Dash).
func send() -> void:
	if sent:
		return
	sent = true
	flash = 1.0
	GameState.set_flag(room.flag_key(str(def.get("id", "term"))))
	AudioManager.play_sfx("node_on")
	Events.camera_shake.emit(4.0, 0.25)
	FX.burst(get_parent(), global_position + Vector2(0, -50), Color(0.5, 2.2, 1.2), 22, 380.0, 0.5, 0.4, Vector2.ZERO)
	_open_target(true)


func _open_target(animated: bool) -> void:
	if room == null or not def.has("target"):
		return
	var gate: Node = room.get_entity(str(def.target))
	if gate and gate.has_method("open"):
		gate.open(animated)


func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.0)
	var p := get_tree().get_first_node_in_group("player") as Player
	near = p != null and p.global_position.distance_to(global_position) < 5.0 * TILE
	if not sent and p != null and p.is_dashing():
		# Basta con que el impulso pase por el terminal (o lo roce).
		var d := p.global_position - global_position
		if overlaps_body(p) or (absf(d.x) < 72.0 and absf(d.y) < 110.0):
			send()
	queue_redraw()


func _draw() -> void:
	var col := Color(0.4, 2.2, 1.1) if sent else Color(2.4, 1.6, 0.4)
	var screen := Rect2(-34, -92, 68, 58)
	draw_rect(Rect2(-8, -34, 16, 34), Color(0.06, 0.06, 0.09))
	draw_rect(screen, Color(0.05, 0.06, 0.09))
	draw_rect(screen, col.lerp(Color(3, 3, 3), flash), false, 2.5)
	var font := UITheme.mono_font()
	var parts := peticion().split(" ", false, 1)
	draw_string(font, Vector2(-30, -70), parts[0], HORIZONTAL_ALIGNMENT_LEFT, 60, 15, col)
	draw_string(font, Vector2(-30, -48), "200 OK" if sent else "...", HORIZONTAL_ALIGNMENT_LEFT, 60, 13, Color(col, 0.8))
	if not near:
		return
	var label := peticion() + ("  →  200 OK" if sent else "")
	var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_rect(Rect2(Vector2(-ls.x * 0.5 - 8, -126), Vector2(ls.x + 16, 24)), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(-ls.x * 0.5, -108), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
	if sent:
		return
	var hint := ("[%s] REST Dash a través del terminal para enviar la petición" % Settings.key_name("dash")) if GameState.has_ability("rest_dash") else "(requiere REST Dash)"
	var hs := UITheme.title_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(UITheme.title_font(), Vector2(-hs.x * 0.5, -140), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
