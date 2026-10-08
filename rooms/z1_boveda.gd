extends RoomBase
## Bóveda de Sharding (Zona 1, Sala 5). Sello S17.
## Niveles múltiples con ShardPlatform y fosos de partición.

func _init() -> void:
	zone = 1
	display_name = "Bóveda de Sharding"

func theme_name() -> String:
	return "database_abyss"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Fosos
	c.fill(14, 20, 26, 20, "^")
	c.fill(36, 20, 50, 20, "^")
	# Cámaras elevadas de particiones
	c.fill(16, 12, 24, 12)
	c.fill(38, 9, 48, 9)
	# Sello S17 en la cámara superior izquierda
	c.fill(4, 8, 12, 8)
	c.put(8, 7, "S")
	# Plataformas
	c.fill(28, 16, 33, 16, "=")
	c.fill(52, 14, 57, 14, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Tablillas
	c.put(2, 20, "t")    # L128
	c.put(20, 11, "u")   # L129
	c.put(44, 8, "v")    # L130
	# Enemigos
	c.put(20, 19, "f")
	c.put(43, 19, "f")
	c.put(29, 20, "l")
	c.put(55, 13, "e")
	c.put(31, 5, "s")
	c.put(11, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(13, 10, 16, 10, "=")
	c.fill(11, 13, 14, 13, "=")
	c.fill(9, 15, 13, 15, "=")
	c.fill(7, 17, 11, 17, "=")
	c.fill(5, 19, 9, 19, "=")
	c.fill(33, 10, 36, 10, "=")
	c.fill(31, 12, 35, 12, "=")
	c.fill(29, 14, 33, 14, "=")
	c.fill(25, 14, 27, 14, "=")
	c.fill(32, 18, 36, 18, "=")
	c.fill(35, 19, 39, 19, "=")
	c.fill(39, 19, 42, 19, "=")
	c.fill(44, 19, 47, 19, "=")
	c.fill(47, 19, 51, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z1_altar", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_cripta", "to_door": "izq"},
		"S": {"type": "sello", "id": "S17", "h": 4},
		"t": {"type": "tablilla", "id": "L128"},
		"u": {"type": "tablilla", "id": "L129"},
		"v": {"type": "tablilla", "id": "L130"},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"e": {"type": "enemy", "kind": "error_500"},
		"s": {"type": "enemy", "kind": "stateless_drone"}
	}
