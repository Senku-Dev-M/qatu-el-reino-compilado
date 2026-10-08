extends RoomBase
## Cúspide de la Torre: Arena de El Espagueti Arquitectónico (Zona 2, Sala 8).

func _init() -> void:
	zone = 2
	display_name = "Cúspide de la Torre"

func theme_name() -> String:
	return "clean_arch"

func music() -> String:
	return "boss"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	# Plataformas elevadas de interfaz
	c.fill(8, 14, 15, 14, "=")
	c.fill(42, 14, 49, 14, "=")
	c.fill(24, 10, 33, 10, "=")
	# Puerta y compuertas
	c.door(0, 18, "d")
	c.put(4, 18, "W")    # gate_w
	c.put(53, 18, "E")   # gate_e
	# Jefe y portal
	c.put(29, 18, "J")   # BossArena Espagueti
	c.put(50, 18, "P")   # Portal de regreso

	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "z2_mirador_frameworks", "to_door": "der"},
		"W": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"E": {"type": "gate", "id": "gate_e", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"J": {
			"type": "boss",
			"id": "jefe_espagueti",
			"kind": "espagueti",
			"half_w": 18,
			"nombre": "El Espagueti Arquitectónico",
			"subtitulo": "Enredo de Acoplamiento Rígido",
			"musica_zona": "canyon",
			"recompensa": "Máscara de Arquitectura",
			"final": "final"
		},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal2", "prompt": "Volver a Qatu"}
	}
