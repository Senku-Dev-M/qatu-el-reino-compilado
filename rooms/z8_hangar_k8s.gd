extends RoomBase
## Hangar de Kubernetes (Zona 8, Sala 6).

func _init() -> void:
	zone = 8
	display_name = "Hangar de Kubernetes"

func theme_name() -> String:
	return "k8s_dock"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	c.fill(26, 5, 31, 5)
	c.fill(16, 18, 44, 18, "^")
	c.fill(22, 12, 34, 12)
	c.fill(10, 15, 15, 15, "=")
	c.fill(40, 15, 46, 15, "=")
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	c.door(28, 4, "A")   # salida superior a arena
	c.put(12, 14, "L")   # PodLauncher
	c.put(60, 18, "G")   # PipelineGate
	c.put(12, 18, "t")    # L173
	c.put(27, 11, "u")   # L174
	c.put(52, 18, "v")   # L175
	c.put(15, 18, "z")
	c.put(31, 11, "f")
	c.put(42, 14, "o")
	c.put(22, 8, "b")
	c.put(2, 18, "M")   # El Manual
	c.put(24, 11, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(20, 5, 24, 5, "=")
	c.fill(18, 7, 22, 7, "=")
	c.fill(16, 9, 20, 9, "=")
	c.fill(14, 11, 18, 11, "=")
	c.fill(14, 13, 17, 13, "=")
	c.fill(6, 17, 10, 17, "=")
	c.fill(34, 10, 38, 10, "=")
	c.fill(17, 15, 20, 15, "=")
	c.fill(35, 14, 38, 14, "=")
	c.fill(35, 15, 38, 15, "=")
	c.fill(41, 17, 45, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Despliega un Pod sobre el nodo del clúster para abrir la compuerta", "ancho": 260},
		"d": {"type": "door", "id": "izq", "to": "z8_gruas_cicd", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z8_faro_swarm", "to_door": "izq"},
		"A": {"type": "door", "id": "arr", "to": "z8_arena", "to_door": "izq"},
		"L": {"type": "pod_launcher", "id": "nodo1", "target": "gate1"},
		"G": {"type": "pipeline_gate", "id": "gate1", "h": 3},
		"t": {"type": "tablilla", "id": "L173"},
		"u": {"type": "tablilla", "id": "L174"},
		"v": {"type": "tablilla", "id": "L175"},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
