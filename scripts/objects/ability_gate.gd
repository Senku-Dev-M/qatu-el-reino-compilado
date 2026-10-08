class_name AbilityGate
extends "res://scripts/objects/gate.gd"
## Compuerta de las zonas 1, 2, 8 y 9. Se abre con la habilidad de la zona y
## muestra siempre qué hace falta para abrirla, para que el jugador nunca se
## quede sin saber qué hacer.
##
## Definición: {"type": "...", "id": "...", "h": 3, "requiere": "texto opcional"}

var theme_col := Color(0.5, 1.6, 2.4)
var near := false


## Para sobrescribir: texto mientras está cerrada y al abrirse.
func closed_text() -> String:
	return str(def.get("requiere", "Cerrada"))


func open_text() -> String:
	return "Abierta"


## Para sobrescribir: habilidad que la abre (para indicar si falta).
func ability_id() -> String:
	return ""


func _process(delta: float) -> void:
	super._process(delta)
	var p := get_tree().get_first_node_in_group("player") as Node2D
	near = p != null and p.global_position.distance_to(global_position) < 9.0 * TILE


func _draw() -> void:
	var height := h * TILE * (1.0 - open_k)
	var top := -h * TILE
	# Marco.
	draw_rect(Rect2(-34, top - 12, 68, 14), Color(0.04, 0.05, 0.07))
	draw_rect(Rect2(-34, top - 12, 68, 14), Color(theme_col, 0.5), false, 2.0)
	if height > 4.0:
		var body := Rect2(-22, top, 44, height)
		draw_rect(body, Color(0.05, 0.07, 0.11))
		draw_rect(body, Color(theme_col, 0.8), false, 2.0)
		var lines := int(height / 18.0)
		for i in lines:
			var y := top + 9 + i * 18
			var a := 0.25 + 0.2 * sin(t * 4.0 + i * 0.7)
			draw_line(Vector2(-16, y), Vector2(16, y), Color(theme_col, a), 2.0)
	# Rótulo: qué hace falta, o que ya está abierta.
	if not near:
		return
	var font := UITheme.mono_font()
	var text := open_text() if is_open() else closed_text()
	if not is_open() and ability_id() != "" and not GameState.has_ability(ability_id()):
		var hab: Dictionary = ContentDB.habilidad(ability_id())
		text += "  (requiere %s)" % hab.get("nombre", ability_id())
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	var pos := Vector2(-ts.x * 0.5, top - 30)
	var col := Color(0.5, 2.0, 0.9) if is_open() else Color(2.2, 1.6, 0.6)
	draw_rect(Rect2(pos + Vector2(-8, -18), Vector2(ts.x + 16, 26)), Color(0, 0, 0, 0.65))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
