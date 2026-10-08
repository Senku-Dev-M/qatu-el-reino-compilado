class_name AssertNode
extends Node2D
## Aserción oculta (zona 9). Solo se ve con el Inspector activo y a su alcance;
## al revelarla queda verificada y desbloquea su `target` (una barrera WAF).
##
## Definición: {"type": "assert_node", "id": "assert1", "target": "barrier1",
##              "texto": "assert(entrada.saneada)"}

const TILE := 64

var room: RoomBase
var def: Dictionary
var verified := false
var near := false
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	verified = GameState.get_flag(room.flag_key(str(def.get("id", "assert"))))
	if verified:
		_open_target.call_deferred(false)


func texto() -> String:
	return str(def.get("texto", "assert(entrada.saneada)"))


func _open_target(animated: bool) -> void:
	if room == null or not def.has("target"):
		return
	var gate: Node = room.get_entity(str(def.target))
	if gate and gate.has_method("open"):
		gate.open(animated)


func _physics_process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player") as Player
	var dist := p.global_position.distance_to(global_position) if p else INF
	near = dist < 6.0 * TILE
	if not verified and p != null and p.inspecting() and dist <= Player.INSPECT_RANGE:
		verified = true
		GameState.set_flag(room.flag_key(str(def.get("id", "assert"))))
		AudioManager.play_sfx("sello_ok")
		FX.burst(get_parent(), global_position + Vector2(0, -30), Color(0.5, 2.2, 1.1), 24, 380.0, 0.5, 0.4, Vector2.ZERO)
		_open_target(true)
	queue_redraw()


func _draw() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	var revealed := verified or (p != null and p.inspecting())
	var c := Vector2(0, -34)
	var font := UITheme.mono_font()
	if not revealed:
		# Casi invisible: solo un destello que delata que ahí hay algo.
		draw_arc(c, 18, 0, TAU, 24, Color(0.6, 1.2, 1.6, 0.12 + 0.08 * sin(t * 2.0)), 2.0, true)
		draw_string(font, Vector2(-5, -28), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 1.2, 1.6, 0.25))
	else:
		var col := Color(0.5, 2.2, 1.1) if verified else Color(2.2, 1.6, 0.6)
		draw_circle(c, 20, Color(0.04, 0.07, 0.08))
		draw_arc(c, 20, 0, TAU, 32, col, 3.0, true)
		draw_string(font, Vector2(-9, -27), "✓" if verified else "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
		var label := texto() + ("  → true" if verified else "")
		var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_rect(Rect2(Vector2(-ls.x * 0.5 - 8, -86), Vector2(ls.x + 16, 24)), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(-ls.x * 0.5, -68), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
	if not near or verified:
		return
	var hint := ("[%s] Inspector: revela la aserción oculta" % Settings.key_name("inspector")) if GameState.has_ability("inspector") else "(requiere Inspector)"
	var hs := UITheme.title_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(UITheme.title_font(), Vector2(-hs.x * 0.5, -104), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
