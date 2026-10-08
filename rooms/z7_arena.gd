extends RoomBase
## Sala 8 · Salón del Impostor: arena de El Impostor Implícito.


func _init() -> void:
	zone = 7
	display_name = "Salón del Impostor"


func theme_name() -> String:
	return "citadel_vault"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(42, 22).frame(19)
	c.fill(1, 1, 8, 3)
	c.fill(33, 1, 40, 3)
	c.fill(14, 1, 27, 1)
	c.door(0, 18, "W")
	c.put(2, 18, "G")
	c.put(21, 18, "X")
	c.put(38, 18, "P")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_sesiones", "to_door": "este"},
		"G": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"X": {"type": "boss", "id": "arena", "kind": "impostor_implicito", "half_w": 18, "nombre": "El Impostor Implícito", "subtitulo": "Jefe de la Ciudadela IAM", "recompensa": "Máscara de la Identidad", "final": "final_z7"},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal7", "prompt": "Volver a Qatu", "requires_flag": "jefe:impostor_implicito", "week": 7},
	}
