extends RoomBase
## Faro del Clúster (Zona 8, Sala 7). Sello S24 y Banco previo al Timonel.

func _init() -> void:
	zone = 8
	display_name = "Faro del Clúster"

func theme_name() -> String:
	return "k8s_dock"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	c.fill(16, 20, 36, 20, "^")
	c.fill(40, 13, 56, 20)
	c.fill(44, 7, 52, 7)
	c.put(48, 6, "S")    # Sello S24
	c.fill(8, 17, 12, 17, "=")
	c.fill(16, 14, 21, 14, "=")
	c.fill(26, 11, 31, 11, "=")
	c.fill(34, 8, 38, 8, "=")
	c.door(0, 20, "d")
	c.put(46, 12, "B")
	c.put(11, 20, "t")    # L176
	c.put(20, 13, "u")   # L177
	c.put(52, 12, "v")   # L178
	c.put(15, 20, "z")
	c.put(10, 16, "f")
	c.put(35, 7, "o")
	c.put(22, 6, "b")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(38, 6, 42, 6, "=")
	c.fill(29, 9, 32, 9, "=")
	c.fill(22, 12, 24, 12, "=")
	c.fill(14, 16, 17, 16, "=")
	c.fill(4, 19, 8, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z8_hangar_k8s", "to_door": "der"},
		"B": {"type": "bench", "id": "banco"},
		"S": {"type": "sello", "id": "S24", "h": 4},
		"t": {"type": "tablilla", "id": "L176"},
		"u": {"type": "tablilla", "id": "L177"},
		"v": {"type": "tablilla", "id": "L178"},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
