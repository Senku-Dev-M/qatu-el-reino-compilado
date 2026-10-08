extends RoomBase
## Sala 5 · Delta de las APIs: frontend y backend, REST, GraphQL, gRPC,
## WebSockets y SSE. Subida obligatoria encadenando cuatro promesas (.then).


func _init() -> void:
	zone = 5
	display_name = "Delta de las APIs"


func theme_name() -> String:
	return "river"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(60, 26).frame(23)
	c.fill(30, 13, 59, 22)           # meseta alta del delta
	c.fill(33, 11, 35, 11, "=")      # subida al fragmento
	c.fill(37, 9, 39, 9, "=")
	c.fill(41, 7, 44, 7)
	c.fill(1, 1, 16, 4)
	c.fill(48, 1, 58, 3)
	c.door(0, 22, "W")
	c.door(59, 12, "D")
	c.put(3, 22, "M")
	c.put(6, 22, "B")
	c.put(10, 22, "1")
	c.put(16, 22, "2")
	c.put(22, 22, "Q")
	c.put(20, 22, "a")
	c.put(24, 22, "b")
	c.put(28, 22, "c")
	c.put(37, 12, "3")
	c.put(49, 12, "4")
	c.put(42, 6, "F")
	c.put(44, 12, "p")
	c.put(54, 12, "k")
	c.put(12, 22, "t")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_manantial", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_aduana", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L63"},
		"2": {"type": "tablilla", "id": "L64"},
		"3": {"type": "tablilla", "id": "L65"},
		"4": {"type": "tablilla", "id": "L66"},
		"Q": {"type": "promesa", "id": "api1", "etiqueta": "fetch('/api/rios')", "plataformas": [[2, -2, 3]], "retardo": 1.2, "duracion": 8.0, "then": "api2"},
		"a": {"type": "promesa", "id": "api2", "etiqueta": ".then(res => res.json())", "activable": false, "plataformas": [[1, -4, 3]], "retardo": 1.0, "duracion": 8.0, "then": "api3"},
		"b": {"type": "promesa", "id": "api3", "etiqueta": ".then(pintar)", "activable": false, "plataformas": [[0, -6, 3]], "retardo": 1.0, "duracion": 8.0, "then": "api4"},
		"c": {"type": "promesa", "id": "api4", "etiqueta": ".finally(listo)", "activable": false, "plataformas": [[-1, -8, 3]], "retardo": 1.0, "duracion": 8.0},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"k": {"type": "enemy", "kind": "csrf_impostor"},
		"t": {"type": "pipe", "largo": 16, "alto": 8, "peticion": "GET /api/productos", "respuesta": "200 OK · JSON"},
	}
