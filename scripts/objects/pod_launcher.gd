class_name PodLauncher
extends Node2D
## Nodo del clúster (zona 8). Cuando se despliega un Pod (habilidad Contenedor)
## justo encima, el Deployment queda listo y abre su `target`.
##
## Definición: {"type": "pod_launcher", "id": "nodo1", "target": "gate1"}

const TILE := 64

var room: RoomBase
var def: Dictionary
var deployed := false
var near := false
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	deployed = GameState.get_flag(room.flag_key(str(def.get("id", "nodo"))))
	if deployed:
		_open_target.call_deferred(false)


func _open_target(animated: bool) -> void:
	if room == null or not def.has("target"):
		return
	var gate: Node = room.get_entity(str(def.target))
	if gate and gate.has_method("open"):
		gate.open(animated)


func _physics_process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	near = p != null and p.global_position.distance_to(global_position) < 5.0 * TILE
	if not deployed:
		for pod in get_tree().get_nodes_in_group("pod"):
			var d: Vector2 = (pod as Node2D).global_position - global_position
			if absf(d.x) < 1.6 * TILE and d.y > -4.0 * TILE and d.y < 0.5 * TILE:
				_deploy()
				break
	queue_redraw()


func _deploy() -> void:
	deployed = true
	GameState.set_flag(room.flag_key(str(def.get("id", "nodo"))))
	AudioManager.play_sfx("node_on")
	Events.camera_shake.emit(4.0, 0.25)
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.5, 1.8, 2.6), 24, 400.0, 0.5, 0.4, Vector2.ZERO)
	_open_target(true)


func _draw() -> void:
	var col := Color(0.5, 2.2, 1.1) if deployed else Color(0.5, 1.6, 2.6)
	var pad := Rect2(-56, -14, 112, 14)
	draw_rect(pad, Color(0.05, 0.08, 0.12))
	draw_rect(pad, col, false, 2.0)
	for i in 3:
		var x := -40 + i * 40
		draw_circle(Vector2(x, -7), 3.0, Color(col, 0.5 + 0.5 * sin(t * 4.0 + i)))
	# Columna de luz que marca dónde desplegar.
	if not deployed:
		draw_rect(Rect2(-56, -190, 112, 176), Color(col, 0.05 + 0.03 * sin(t * 3.0)))
	var font := UITheme.mono_font()
	var status := "kubectl apply · 1/1 Running" if deployed else "nodo libre · 0/1 pods"
	var ss := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(font, Vector2(-ss.x * 0.5, -24), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, 0.9))
	if not near or deployed:
		return
	var hint := ("Salta sobre el nodo y pulsa [%s] para desplegar un Pod" % Settings.key_name("contenedor")) if GameState.has_ability("contenedor") else "(requiere Contenedor)"
	var hs := UITheme.title_font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(UITheme.title_font(), Vector2(-hs.x * 0.5, -206), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
