extends RoomBase
## Santuario de Pods y Réplicas (Zona 8, Sala 4).

func _init() -> void:
	zone = 8
	display_name = "Santuario de Pods"

func theme_name() -> String:
	return "k8s_dock"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(16, 18, 42, 18, "^")
	c.fill(22, 12, 36, 12)
	c.fill(8, 15, 14, 15, "=")
	c.fill(44, 15, 50, 15, "=")
	c.door(0, 18, "d")
	c.put(10, 14, "L")
	c.put(34, 11, "c")
	c.put(6, 18, "t")    # L167
	c.put(27, 11, "u")   # L168
	c.put(52, 18, "v")   # L169
	c.put(15, 16, "z")
	c.put(30, 11, "f")
	c.put(45, 14, "o")
	c.put(18, 7, "b")
	c.put(11, 18, "A")   # habilidad Contenedor
	c.put(2, 18, "M")   # El Manual
	c.put(24, 11, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(16, 11, 20, 11, "=")
	c.fill(14, 13, 18, 13, "=")
	c.fill(13, 17, 16, 17, "=")
	c.fill(38, 11, 41, 11, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Salta y pulsa {contenedor}: el Pod te sostiene unos segundos", "ancho": 260},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "contenedor", "dialog": "santuario_pod"},
		"d": {"type": "door", "id": "izq", "to": "z8_astillero_compose", "to_door": "der"},
		"L": {"type": "pod_launcher", "id": "nodo_practica"},
		"t": {"type": "tablilla", "id": "L167"},
		"u": {"type": "tablilla", "id": "L168"},
		"v": {"type": "tablilla", "id": "L169"},
		"c": {"type": "chest", "bits": 55},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
