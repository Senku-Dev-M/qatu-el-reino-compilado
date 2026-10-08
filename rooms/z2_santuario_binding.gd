extends RoomBase
## Santuario de Inyección de Dependencias (Zona 2, Sala 4).
## Plataformas vinculadas dobles y puente colgante sobre el vacío.

func _init() -> void:
	zone = 2
	display_name = "Santuario de Inyección"

func theme_name() -> String:
	return "clean_arch"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	# Foso
	c.fill(16, 18, 44, 18, "^")
	# Meseta de inyección central
	c.fill(24, 12, 36, 12)
	# Puentes
	c.fill(10, 15, 15, 15, "=")
	c.fill(18, 13, 22, 13, "=")
	c.fill(38, 13, 42, 13, "=")
	c.fill(45, 15, 50, 15, "=")
	# Puertas
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	# Entidades
	c.put(49, 18, "N")   # BindingNode
	c.put(53, 16, "P")   # LinkedPlatform
	c.put(7, 18, "t")    # L146
	c.put(30, 11, "u")   # L147
	c.put(56, 18, "v")   # L148
	c.put(57, 11, "c")   # cofre
	# Enemigos
	c.put(27, 11, "a")
	c.put(13, 14, "r")
	c.put(47, 14, "l")
	c.put(34, 11, "w")
	c.fill(55, 12, 59, 12)
	c.put(10, 18, "A")   # habilidad Data Binding
	c.put(2, 18, "M")   # El Manual
	c.put(24, 11, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(12, 13, 16, 13, "=")
	c.fill(12, 17, 15, 17, "=")
	c.fill(39, 15, 43, 15, "=")
	c.fill(41, 17, 45, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Enlaza el nodo con {binding}: la plataforma (vista) sube", "ancho": 260},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "data_binding", "dialog": "santuario_binding"},
		"d": {"type": "door", "id": "izq", "to": "z2_galeria_spa", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_terraza_mv", "to_door": "izq"},
		"N": {"type": "binding_node", "id": "node1", "targets": ["plat1"]},
		"P": {"type": "linked_platform", "id": "plat1", "w": 3, "dy": -4},
		"t": {"type": "tablilla", "id": "L146"},
		"u": {"type": "tablilla", "id": "L147"},
		"v": {"type": "tablilla", "id": "L148"},
		"c": {"type": "chest", "bits": 55},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
