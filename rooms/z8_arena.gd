extends RoomBase
## Dársena del Timonel: Arena de Kubernetes (Zona 8, Sala 8).

func _init() -> void:
	zone = 8
	display_name = "Dársena del Timonel"

func theme_name() -> String:
	return "k8s_dock"

func music() -> String:
	return "boss"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(8, 14, 15, 14, "=")
	c.fill(42, 14, 49, 14, "=")
	c.fill(24, 10, 33, 10, "=")
	c.door(0, 18, "d")
	c.put(4, 18, "W")    # gate_w
	c.put(53, 18, "E")   # gate_e
	c.put(29, 18, "J")   # BossArena Kubernetes
	c.put(50, 18, "P")   # Portal de regreso
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "z8_hangar_k8s", "to_door": "arr"},
		"W": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"E": {"type": "gate", "id": "gate_e", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"J": {
			"type": "boss",
			"id": "jefe_kubernetes",
			"kind": "kubernetes",
			"half_w": 18,
			"nombre": "Kubernetes, el Gran Timonel",
			"subtitulo": "Orquestador Desbocado del Clúster",
			"musica_zona": "ruins",
			"recompensa": "Máscara de Contenedores",
			"final": "final"
		},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal8", "prompt": "Volver a Qatu"}
	}
