extends RoomBase
## Base de la Torre Hexagonal (Zona 2, Sala 1).
## Columnas cibernéticas, foso de acoplamiento y plataformas elevadas de interfaz.

func _init() -> void:
	zone = 2
	display_name = "Base de la Torre Hexagonal"
	area_title = "Torres de Arquitectura"

func theme_name() -> String:
	return "towers"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	# Foso de acoplamiento rígido
	c.fill(22, 18, 34, 18, "^")
	# Pilares arquitectónicos y cornisas
	c.fill(6, 12, 14, 12)
	c.fill(42, 11, 50, 11)
	# Plataformas de interfaz desacopladas
	c.fill(16, 16, 21, 16, "=")
	c.fill(24, 14, 30, 14, "=")
	c.fill(35, 15, 40, 15, "=")
	# Puertas
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	# Puntos interactivos
	c.put(4, 18, "M")    # Manual
	c.put(8, 18, "B")    # Banco
	c.put(10, 11, "t")   # L137
	c.put(27, 13, "u")   # L138
	c.put(46, 10, "v")   # L139
	c.put(52, 18, "m")   # Mapa
	c.put(48, 10, "c")   # Cofre
	# Enemigos
	c.put(38, 18, "a")   # acoplamiento_rigido
	c.put(27, 17, "r")   # render_bloqueante
	c.put(41, 12, "l")   # logica_en_vista
	c.put(18, 15, "w")   # framework_obsoleto
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(38, 13, 41, 13, "=")
	c.fill(29, 12, 33, 12, "=")
	c.fill(19, 14, 22, 14, "=")
	c.fill(11, 17, 14, 17, "=")
	c.fill(15, 14, 17, 14, "=")
	c.fill(32, 17, 36, 17, "=")
	c.fill(27, 16, 30, 16, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "hub_plaza", "to_door": "portal2"},
		"D": {"type": "door", "id": "der", "to": "z2_sala_flujo", "to_door": "izq"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"t": {"type": "tablilla", "id": "L137"},
		"u": {"type": "tablilla", "id": "L138"},
		"v": {"type": "tablilla", "id": "L139"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"c": {"type": "chest", "bits": 40},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
