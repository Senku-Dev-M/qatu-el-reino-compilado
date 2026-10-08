extends RoomBase
## Galería de la Persistencia (Zona 1, Sala 3).
## Sello S16 en santuario vertical con ShardPlatform y foso de datos.

func _init() -> void:
	zone = 1
	display_name = "Galería de la Persistencia"

func theme_name() -> String:
	return "database_abyss"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Foso con pinchos de error
	c.fill(18, 20, 44, 20, "^")
	# Santuario del Sello S16 elevado en la parte superior derecha
	c.fill(48, 8, 58, 8)
	c.fill(48, 1, 48, 7)
	# Plataformas escalonadas
	c.fill(10, 17, 15, 17, "=")
	c.fill(22, 15, 27, 15, "=")
	c.fill(32, 13, 38, 13, "=")
	c.fill(41, 10, 46, 10, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Entidades
	c.put(54, 7, "S")    # Sello S16
	c.put(6, 20, "t")    # L122
	c.put(25, 14, "u")   # L123
	c.put(35, 12, "v")   # L124
	c.put(52, 7, "c")    # cofre
	# Enemigos
	c.put(20, 19, "f")   # over_fetcher
	c.put(35, 19, "f")   # over_fetcher
	c.put(46, 20, "l")   # lock_pesimista
	c.put(45, 9, "e")    # error_500
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(27, 13, 30, 13, "=")
	c.fill(18, 17, 22, 17, "=")
	c.fill(16, 19, 19, 19, "=")
	c.fill(59, 10, 61, 10, "=")
	c.fill(59, 11, 61, 11, "=")
	c.fill(56, 13, 60, 13, "=")
	c.fill(52, 13, 56, 13, "=")
	c.fill(48, 13, 52, 13, "=")
	c.fill(37, 11, 39, 11, "=")
	c.fill(43, 12, 46, 12, "=")
	c.fill(37, 15, 41, 15, "=")
	c.fill(39, 17, 43, 17, "=")
	c.fill(41, 19, 45, 19, "=")
	c.put(58, 7, "W")   # arma de la zona
	return c.rows()

func legend() -> Dictionary:
	return {
		"W": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "lanza_rest"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z1_catacumbas", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_altar", "to_door": "izq"},
		"S": {"type": "sello", "id": "S16", "h": 4},
		"t": {"type": "tablilla", "id": "L122"},
		"u": {"type": "tablilla", "id": "L123"},
		"v": {"type": "tablilla", "id": "L124"},
		"c": {"type": "chest", "bits": 45},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"e": {"type": "enemy", "kind": "error_500"}
	}
