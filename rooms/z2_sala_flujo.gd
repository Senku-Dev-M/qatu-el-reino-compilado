extends RoomBase
## Sala del Flujo Unidireccional (Zona 2, Sala 2).
## Mecánica de BindingNode que activa LinkedPlatform y desbloquea CleanGate.

func _init() -> void:
	zone = 2
	display_name = "Sala del Flujo Unidireccional"

func theme_name() -> String:
	return "towers"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	# Foso con pinchos
	c.fill(16, 20, 38, 20, "^")
	# Meseta superior de inyección
	c.fill(20, 12, 30, 12)
	# Plataformas escalonadas
	c.fill(8, 17, 13, 17, "=")
	c.fill(33, 15, 38, 15, "=")
	c.fill(42, 17, 47, 17, "=")
	c.fill(50, 14, 58, 14)
	# Puertas
	c.door(0, 20, "d")
	c.door(61, 20, "D")
	# Nodos y compuertas
	# Tablillas
	c.put(12, 20, "t")    # L140
	c.put(27, 11, "u")   # L141
	c.put(54, 13, "v")   # L142
	c.put(56, 13, "c")   # Cofre
	# Enemigos
	c.put(38, 18, "a")
	c.put(10, 16, "r")
	c.put(44, 20, "l")
	c.put(49, 20, "w")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(15, 13, 18, 13, "=")
	c.fill(13, 15, 17, 15, "=")
	c.fill(5, 19, 9, 19, "=")
	c.fill(45, 15, 48, 15, "=")
	c.fill(32, 13, 35, 13, "=")
	c.fill(33, 17, 37, 17, "=")
	c.fill(35, 19, 39, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z2_torre_base", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_galeria_spa", "to_door": "izq"},
		"t": {"type": "tablilla", "id": "L140"},
		"u": {"type": "tablilla", "id": "L141"},
		"v": {"type": "tablilla", "id": "L142"},
		"c": {"type": "chest", "bits": 45},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
