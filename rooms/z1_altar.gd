extends RoomBase
## Altar de las Transacciones ACID (Zona 1, Sala 4).
## Estructura piramidal con doble foso y puente de un solo sentido.

func _init() -> void:
	zone = 1
	display_name = "Altar de las Transacciones"

func theme_name() -> String:
	return "database_abyss"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	# Foso doble
	c.fill(12, 18, 20, 18, "^")
	c.fill(41, 18, 49, 18, "^")
	# Pirámide central escalonada
	c.fill(22, 16, 39, 18)
	c.fill(26, 13, 35, 15)
	c.fill(29, 10, 32, 12)
	# Puentes
	c.fill(14, 15, 18, 15, "=")
	c.fill(43, 15, 47, 15, "=")
	# Puertas
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	# Tablillas
	c.put(6, 18, "t")    # L125
	c.put(29, 9, "u")    # L126 (en la cúspide)
	c.put(55, 18, "v")   # L127
	c.put(32, 9, "c")    # cofre cúspide
	# Enemigos
	c.put(16, 17, "f")
	c.put(45, 17, "f")
	c.put(23, 13, "l")
	c.put(51, 18, "e")
	c.put(2, 18, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(24, 11, 27, 11, "=")
	c.fill(21, 14, 24, 14, "=")
	c.fill(10, 17, 14, 17, "=")
	c.fill(37, 13, 41, 13, "=")
	c.fill(34, 11, 37, 11, "=")
	c.fill(46, 17, 50, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z1_galeria", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z1_boveda", "to_door": "izq"},
		"t": {"type": "tablilla", "id": "L125"},
		"u": {"type": "tablilla", "id": "L126"},
		"v": {"type": "tablilla", "id": "L127"},
		"c": {"type": "chest", "bits": 50},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"e": {"type": "enemy", "kind": "error_500"}
	}
