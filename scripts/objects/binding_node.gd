class_name BindingNode
extends Node2D
## Nodo del modelo (zona 2). Con Data Binding se enlaza o desenlaza; mientras
## está enlazado, sus `targets` (plataformas enlazadas y compuertas de la vista)
## reflejan ese estado, igual que una vista refleja el modelo.
##
## Definición: {"type": "binding_node", "id": "node1", "targets": ["plat1", "gate1"]}

const TILE := 64
const RANGE := 2.6 * TILE

var room: RoomBase
var def: Dictionary
var bound := false
var near := false
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	bound = GameState.get_flag(room.flag_key(str(def.get("id", "node"))))
	_apply.call_deferred(false)


func targets() -> Array:
	var ids: Array = def.get("targets", [])
	if def.has("target"):
		ids = ids + [def.target]
	return ids


func set_bound(value: bool, animated := true) -> void:
	bound = value
	GameState.set_flag(room.flag_key(str(def.get("id", "node"))), bound)
	AudioManager.play_sfx("node_on" if bound else "ui_close", 0.1)
	FX.burst(get_parent(), global_position + Vector2(0, -30), Color(0.5, 1.8, 2.6), 14, 300.0, 0.4, 0.35, Vector2.ZERO)
	_apply(animated)


func _apply(animated: bool) -> void:
	for id in targets():
		var e: Node = room.get_entity(str(id))
		if e and e.has_method("set_bound"):
			e.set_bound(bound, animated)


func _process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player") as Player
	near = p != null and p.global_position.distance_to(global_position) < RANGE
	if near and Input.is_action_just_pressed("binding") and GameState.has_ability("data_binding") and p.state == Player.State.NORMAL:
		set_bound(not bound)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, -34)
	var col := Color(0.5, 1.8, 2.6) if bound else Color(1.8, 1.4, 0.5)
	# Líneas de enlace hacia lo que controla.
	if bound:
		for id in targets():
			var e: Node2D = room.get_entity(str(id)) as Node2D
			if e:
				var to := e.global_position - global_position + Vector2(0, -20)
				var steps := 18
				for i in steps:
					if (i + int(t * 8.0)) % 3 == 0:
						continue
					draw_line(c.lerp(to, float(i) / steps), c.lerp(to, float(i + 1) / steps), Color(col, 0.55), 2.0)
	draw_rect(Rect2(-6, -16, 12, 16), Color(0.05, 0.06, 0.08))
	draw_circle(c, 22, Color(0.04, 0.07, 0.1))
	draw_arc(c, 22, 0, TAU, 32, col, 3.0, true)
	draw_arc(c, 13, t * 2.0, t * 2.0 + PI * 1.4, 16, Color(col, 0.8), 2.0, true)
	var font := UITheme.mono_font()
	var state_txt := "modelo ⇄ vista" if bound else "modelo (sin enlazar)"
	var ss := font.get_string_size(state_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(font, Vector2(-ss.x * 0.5, -66), state_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, 0.9))
	if not near:
		return
	var hint: String
	if not GameState.has_ability("data_binding"):
		hint = "(requiere Data Binding)"
	else:
		hint = "[%s] %s" % [Settings.key_name("binding"), "desenlazar" if bound else "enlazar el modelo con la vista"]
	var hs := UITheme.title_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(UITheme.title_font(), Vector2(-hs.x * 0.5, -90), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
