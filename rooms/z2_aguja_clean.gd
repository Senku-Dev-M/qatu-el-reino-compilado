extends RoomBase
## Aguja de Clean Architecture (Zona 2, Sala 6).
## Eje vertical de la torre con compuerta de capas y elevador vinculado.

func _init() -> void:
	zone = 2
	display_name = "Aguja de Clean Architecture"

func theme_name() -> String:
	return "clean_arch"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	# Foso
	c.fill(18, 18, 38, 18, "^")
	# Plataforma de desacoplamiento
	c.fill(24, 12, 32, 12)
	c.fill(10, 15, 15, 15, "=")
	c.fill(40, 15, 46, 15, "=")
	c.fill(48, 12, 54, 12, "=")
	# Puertas
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	# Entidades
	c.put(27, 11, "N")   # BindingNode
	c.put(60, 18, "G")   # CleanGate
	c.put(6, 18, "t")    # L152
	c.put(29, 11, "u")   # L153
	c.put(51, 11, "v")   # L154
	# Enemigos
	c.put(36, 16, "a")
	c.put(12, 14, "r")
	c.put(42, 14, "l")
	c.put(13, 18, "w")
	c.put(2, 18, "M")   # El Manual
	c.put(44, 18, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(18, 12, 22, 12, "=")
	c.fill(15, 13, 19, 13, "=")
	c.fill(8, 17, 11, 17, "=")
	c.fill(43, 13, 46, 13, "=")
	c.fill(34, 12, 38, 12, "=")
	c.fill(35, 14, 38, 14, "=")
	c.fill(36, 17, 40, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "La compuerta es la vista: enlaza el nodo del modelo con {binding}", "ancho": 260},
		"d": {"type": "door", "id": "izq", "to": "z2_terraza_mv", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_mirador_frameworks", "to_door": "izq"},
		"N": {"type": "binding_node", "id": "node1", "targets": ["gate1"]},
		"G": {"type": "clean_gate", "id": "gate1", "h": 3},
		"t": {"type": "tablilla", "id": "L152"},
		"u": {"type": "tablilla", "id": "L153"},
		"v": {"type": "tablilla", "id": "L154"},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
