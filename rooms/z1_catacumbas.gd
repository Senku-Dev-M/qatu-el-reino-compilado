extends RoomBase
## Catacumbas de Endpoints (Zona 1, Sala 2).
## Mecánica de terminal REST que desactiva compuerta de capas en el abismo.

func _init() -> void:
	zone = 1
	display_name = "Catacumbas de Endpoints"

func theme_name() -> String:
	return "backend_ruins"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	# Gran foso con pinchos
	c.fill(16, 20, 36, 20, "^")
	# Meseta superior con terminal REST
	c.fill(18, 13, 28, 13)
	# Plataformas de datos flotantes
	c.fill(8, 17, 13, 17, "=")
	c.fill(32, 15, 37, 15, "=")
	c.fill(40, 17, 46, 17, "=")
	# Cornisa de salida
	c.fill(50, 14, 60, 14)
	c.door(0, 20, "d")
	c.door(61, 20, "D")
	# Terminal y compuerta
	c.put(24, 12, "T")   # RestTerminal
	c.put(60, 20, "G")   # LayerGate
	# Tablillas
	c.put(6, 20, "t")    # L119
	c.put(19, 12, "u")   # L120
	c.put(54, 13, "v")   # L121
	# Cofre y anclas
	c.put(58, 13, "c")
	# Enemigos
	c.put(25, 18, "f")   # over_fetcher
	c.put(41, 20, "l")   # lock_pesimista
	c.put(9, 16, "e")   # error_500
	c.put(44, 11, "s")   # stateless_drone
	c.put(11, 20, "A")   # habilidad REST Dash
	c.put(2, 20, "M")   # El Manual
	c.put(44, 20, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(12, 13, 16, 13, "=")
	c.fill(10, 15, 14, 15, "=")
	c.fill(13, 19, 16, 19, "=")
	c.fill(45, 15, 48, 15, "=")
	c.fill(30, 13, 33, 13, "=")
	c.fill(31, 17, 35, 17, "=")
	c.fill(33, 19, 37, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Compuerta 401: atraviesa el terminal REST con REST Dash {dash}", "ancho": 260},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "rest_dash", "dialog": "santuario_rest_dash"},
		"d": {"type": "door", "id": "izq", "to": "z1_atrio", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_galeria", "to_door": "izq"},
		"T": {"type": "rest_terminal", "id": "term1", "target": "gate1", "peticion": "GET /api/productos"},
		"G": {"type": "layer_gate", "id": "gate1", "h": 3},
		"t": {"type": "tablilla", "id": "L119"},
		"u": {"type": "tablilla", "id": "L120"},
		"v": {"type": "tablilla", "id": "L121"},
		"c": {"type": "chest", "bits": 40},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"e": {"type": "enemy", "kind": "error_500"},
		"s": {"type": "enemy", "kind": "stateless_drone"}
	}
