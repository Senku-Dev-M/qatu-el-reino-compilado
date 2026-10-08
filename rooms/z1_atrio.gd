extends RoomBase
## Atrio de la Integración (Zona 1, Sala 1).
## Servidores escalonados, foso de sockets caídos y cornisas de racks.

func _init() -> void:
	zone = 1
	display_name = "Atrio de la Integración"
	area_title = "Ruinas del Backend"

func theme_name() -> String:
	return "backend_ruins"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	# Foso de sockets desconectados en el centro
	c.fill(24, 18, 33, 18, "^")
	# Racks de servidores escalonados (plataformas de un solo sentido)
	c.fill(12, 16, 17, 16, "=")
	c.fill(19, 14, 23, 14, "=")
	c.fill(26, 12, 31, 12, "=")
	c.fill(34, 14, 38, 14, "=")
	c.fill(40, 16, 45, 16, "=")
	# Cornisa superior secreta del manual y servidor maestro
	c.fill(6, 10, 14, 10)
	c.fill(44, 9, 52, 9)
	# Puertas laterales a ras de suelo
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	# Puntos interactivos y tablillas
	c.put(4, 18, "M")    # El Manual
	c.put(8, 18, "B")    # Banco
	c.put(10, 9, "t")    # L116 en la cornisa superior
	c.put(28, 11, "u")   # L117 en plataforma central flotante
	c.put(48, 8, "v")    # L118 en cornisa este
	c.put(52, 18, "m")   # Mapa pickup
	c.put(50, 8, "c")    # Cofre en cornisa este
	# Enemigos patrullando
	c.put(28, 17, "f")   # over_fetcher volando sobre los pinchos
	c.put(41, 15, "e")   # error_500 en rack intermedio
	c.put(40, 18, "l")   # lock_pesimista en el suelo derecho
	c.put(15, 7, "s")    # stateless_drone vigilando desde arriba
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(39, 10, 42, 10, "=")
	c.fill(37, 12, 41, 12, "=")
	c.fill(20, 12, 24, 12, "=")
	c.fill(19, 17, 22, 17, "=")
	c.fill(15, 12, 18, 12, "=")
	c.fill(35, 17, 38, 17, "=")
	c.fill(28, 14, 32, 14, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "hub_plaza", "to_door": "portal1"},
		"D": {"type": "door", "id": "der", "to": "z1_catacumbas", "to_door": "izq"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"t": {"type": "tablilla", "id": "L116"},
		"u": {"type": "tablilla", "id": "L117"},
		"v": {"type": "tablilla", "id": "L118"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"c": {"type": "chest", "bits": 35},
		"f": {"type": "enemy", "kind": "over_fetcher"},
		"e": {"type": "enemy", "kind": "error_500"},
		"l": {"type": "enemy", "kind": "lock_pesimista"},
		"s": {"type": "enemy", "kind": "stateless_drone"}
	}
