extends RoomBase
## Sala 4 · Manantial de las Promesas: asincronía, callbacks, AJAX, promesas,
## async/await y closures. Santuario de la habilidad Promesa, canal que solo
## se cruza con una promesa cumplida y cornisa encadenada (.then). Sello S8.


func _init() -> void:
	zone = 5
	display_name = "Manantial de las Promesas"


func theme_name() -> String:
	return "river_deep"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(66, 24).frame(21)
	c.fill(17, 19, 21, 20)           # pedestal del santuario
	c.fill(30, 21, 37, 22, ".")      # canal ancho: solo con la promesa
	c.fill(30, 22, 37, 22, "^")
	c.fill(53, 15, 55, 15)           # cornisa del amuleto
	c.fill(56, 1, 60, 16)            # techo sobre el sello
	c.fill(1, 1, 14, 5)
	c.fill(24, 1, 44, 3)
	c.door(0, 20, "W")
	c.door(65, 20, "D")
	c.put(3, 20, "M")
	c.put(8, 20, "1")
	c.put(13, 20, "2")
	c.put(19, 18, "A")
	c.put(24, 20, "3")
	c.put(28, 20, "Q")
	c.put(41, 20, "4")
	c.put(44, 20, "5")
	c.put(47, 20, "c")
	c.put(51, 20, "d")
	c.put(54, 14, "T")
	c.put(58, 20, "S")
	c.put(34, 14, "p")
	c.put(49, 12, "p")
	c.put(10, 20, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_compuerta", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_delta", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L58"},
		"2": {"type": "tablilla", "id": "L59"},
		"3": {"type": "tablilla", "id": "L60"},
		"4": {"type": "tablilla", "id": "L61"},
		"5": {"type": "tablilla", "id": "L62"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "promesa", "dialog": "santuario_promesa"},
		"Q": {"type": "promesa", "id": "manantial", "etiqueta": "cruzar()", "plataformas": [[3, 0, 2], [6, 0, 2]], "retardo": 1.2, "duracion": 5.0},
		"c": {"type": "promesa", "id": "cornisa", "etiqueta": "subir()", "plataformas": [[1, -2, 2]], "retardo": 1.0, "duracion": 5.0, "then": "cornisa_b"},
		"d": {"type": "promesa", "id": "cornisa_b", "etiqueta": ".then(subirMas)", "activable": false, "plataformas": [[0, -4, 2]], "retardo": 1.0, "duracion": 5.0},
		"T": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "timeout"},
		"S": {"type": "sello", "id": "S8", "h": 4},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"x": {"type": "decor", "kind": "big_tag", "text": "await", "size": 120},
	}
