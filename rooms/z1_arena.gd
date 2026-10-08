extends RoomBase
## Arena del Monolito Legado (Zona 1, Sala 8).
## Gran arena de combate con plataformas de desvío elevadas y compuertas de bloqueo.

func _init() -> void:
	zone = 1
	display_name = "Núcleo del Monolito"

func theme_name() -> String:
	return "backend_ruins"

func music() -> String:
	return "boss"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	# Plataformas elevadas para esquivar embestidas y ondas de choque
	c.fill(8, 14, 15, 14, "=")
	c.fill(42, 14, 49, 14, "=")
	c.fill(24, 10, 33, 10, "=")
	# Puerta y compuertas
	c.door(0, 18, "d")
	c.put(4, 18, "W")    # gate_w
	c.put(53, 18, "E")   # gate_e
	# Jefe y portal
	c.put(29, 18, "J")   # BossArena Monolito
	c.put(50, 18, "P")   # Portal de regreso al hub tras vencer
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "z1_bastion", "to_door": "der"},
		"W": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"E": {"type": "gate", "id": "gate_e", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"J": {
			"type": "boss",
			"id": "jefe_monolito",
			"kind": "monolito",
			"half_w": 18,
			"nombre": "El Monolito Legado",
			"subtitulo": "Antiguo Servidor Indivisible",
			"musica_zona": "ruins",
			"recompensa": "Máscara del Backend",
			"final": "final"
		},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal1", "prompt": "Volver a Qatu"}
	}
