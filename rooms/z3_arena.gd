extends RoomBase
## Sala 8 · Arena del Nodo Huérfano.


func _init() -> void:
	zone = 3
	display_name = "Copa Corrupta"


func theme_name() -> String:
	return "arena"


func music() -> String:
	return "forest"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(40, 22).frame(19)
	c.fill(1, 1, 8, 3)
	c.fill(31, 1, 38, 3)
	c.fill(14, 1, 25, 1)
	c.door(0, 18, "W")
	c.put(2, 18, "G")
	c.put(20, 18, "X")
	c.put(31, 18, "P")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z3_cueva", "to_door": "este"},
		"G": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"X": {"type": "boss", "id": "arena", "kind": "nodo_huerfano", "half_w": 17, "nombre": "El Nodo Huérfano", "subtitulo": "Jefe del Bosque del DOM", "recompensa": "Máscara del Nodo", "final": "final"},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal3", "prompt": "Volver a Qatu", "requires_flag": "jefe:nodo_huerfano", "week": 3},
	}
