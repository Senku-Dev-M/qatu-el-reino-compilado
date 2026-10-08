extends RoomBase
## Sala 8 · Pozo del Scroll Infinito: arena del jefe con la palanca «paginar».


func _init() -> void:
	zone = 6
	display_name = "Pozo del Scroll Infinito"


func theme_name() -> String:
	return "archive_vault"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(40, 22).frame(19)
	c.fill(1, 1, 8, 3)
	c.fill(31, 1, 38, 3)
	c.fill(14, 1, 25, 1)
	c.fill(3, 17, 6, 17)             # repisa de la palanca
	c.door(0, 18, "W")
	c.put(2, 18, "G")
	c.put(5, 16, "L")
	c.put(20, 18, "X")
	c.put(36, 18, "P")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_pasillo", "to_door": "este"},
		"G": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"L": {"type": "palanca", "id": "paginar", "target": "arena", "enfriamiento": 4.0, "etiqueta": "paginar()"},
		"X": {"type": "boss", "id": "arena", "kind": "scroll_infinito", "half_w": 17, "nombre": "Scroll Infinito", "subtitulo": "Jefe del Archivo Paginado", "recompensa": "Máscara del Índice", "final": "final_z6"},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal6", "prompt": "Volver a Qatu", "requires_flag": "jefe:scroll_infinito", "week": 6},
	}
