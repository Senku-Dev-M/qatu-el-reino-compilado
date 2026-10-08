extends RoomBase
## Cripta de Conexiones (Zona 1, Sala 6).
## Pool de conexiones con terminal y compuerta vertical.

func _init() -> void:
	zone = 1
	display_name = "Cripta de Conexiones"

func theme_name() -> String:
	return "backend_ruins"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	# Foso
	c.fill(20, 18, 40, 18, "^")
	# Plataforma de la terminal
	c.fill(26, 12, 34, 12)
	# Plataformas de paso
	c.fill(12, 15, 17, 15, "=")
	c.fill(43, 15, 48, 15, "=")
	c.fill(50, 12, 55, 12, "=")
	# Puertas
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	# Terminal y compuerta
	c.put(31, 11, "T")   # RestTerminal
	c.put(60, 18, "G")   # LayerGate
	# Tablillas
	c.put(6, 18, "t")    # L131
	c.put(27, 11, "u")   # L132
	c.put(52, 11, "v")   # L133
	# Cofre
	c.put(54, 11, "c")
	# Enemigos
	c.put(30, 17, "f")
	c.put(14, 14, "e")
	c.put(10, 16, "l")
	c.put(45, 14, "s")
	c.put(2, 18, "M")   # El Manual
	c.put(47, 18, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(20, 12, 24, 12, "=")
	c.fill(17, 13, 21, 13, "=")
	c.fill(9, 17, 13, 17, "=")
	c.fill(44, 12, 48, 12, "=")
	c.fill(40, 12, 44, 12, "=")
	c.fill(36, 12, 40, 12, "=")
	c.fill(38, 14, 41, 14, "=")
	c.fill(39, 17, 43, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Otra compuerta 401: envía POST desde el terminal con {dash}", "ancho": 260},
		"d": {"type": "door", "id": "izq", "to": "z1_boveda", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_bastion", "to_door": "izq"},
		"T": {"type": "rest_terminal", "id": "term1", "target": "gate1", "peticion": "POST /api/pedidos"},
		"G": {"type": "layer_gate", "id": "gate1", "h": 3},
		"t": {"type": "tablilla", "id": "L131"},
		"u": {"type": "tablilla", "id": "L132"},
		"v": {"type": "tablilla", "id": "L133"},
		"c": {"type": "chest", "bits": 40},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"e": {"type": "enemy", "kind": "error_500"},
		"s": {"type": "enemy", "kind": "stateless_drone"}
	}
