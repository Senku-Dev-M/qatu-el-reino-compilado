extends RoomBase
## Bastión de Microservicios (Zona 1, Sala 7). Sello S18 y Banco previo al Jefe.

func _init() -> void:
	zone = 1
	display_name = "Bastión de Microservicios"

func theme_name() -> String:
	return "backend_ruins"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Foso de caída
	c.fill(14, 20, 32, 20, "^")
	# Bastión elevado
	c.fill(36, 14, 52, 20)
	c.fill(40, 7, 50, 7)
	# Sello S18 en la torre alta del bastión
	c.put(45, 6, "S")
	# Plataformas de escalada
	c.fill(8, 17, 12, 17, "=")
	c.fill(16, 14, 21, 14, "=")
	c.fill(24, 11, 29, 11, "=")
	c.fill(32, 8, 37, 8, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Banco en la meseta segura del bastión
	c.put(42, 13, "B")
	# Tablillas
	c.put(11, 20, "t")    # L134
	c.put(20, 13, "u")   # L135
	c.put(48, 13, "v")   # L136
	# Enemigos
	c.put(23, 19, "f")
	c.put(9, 16, "e")
	c.put(58, 20, "l")
	c.put(34, 7, "s")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(27, 9, 30, 9, "=")
	c.fill(23, 13, 26, 13, "=")
	c.fill(14, 16, 17, 16, "=")
	c.fill(4, 19, 8, 19, "=")
	c.fill(26, 15, 30, 15, "=")
	c.fill(30, 14, 34, 14, "=")
	c.fill(54, 15, 57, 15, "=")
	c.fill(54, 17, 57, 17, "=")
	c.fill(54, 19, 57, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z1_cripta", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_arena", "to_door": "izq"},
		"B": {"type": "bench", "id": "banco"},
		"S": {"type": "sello", "id": "S18", "h": 4},
		"t": {"type": "tablilla", "id": "L134"},
		"u": {"type": "tablilla", "id": "L135"},
		"v": {"type": "tablilla", "id": "L136"},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"e": {"type": "enemy", "kind": "error_500"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"s": {"type": "enemy", "kind": "stateless_drone"}
	}
