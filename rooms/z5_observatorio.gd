extends RoomBase
## Sala 7 · Observatorio de Red: pestaña Network, waterfall y diagnóstico.
## Cámara del amuleto tras una compuerta Promise.all. Sello S9.


func _init() -> void:
	zone = 5
	display_name = "Observatorio de Red"


func theme_name() -> String:
	return "river"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(16, 17, 22, 18)           # mirador de la cascada
	c.fill(34, 17, 36, 17, "=")      # subida a la cámara
	c.fill(38, 9, 50, 15)            # bloque con la cámara del amuleto
	c.fill(38, 12, 49, 14, ".")
	c.fill(53, 1, 57, 14)            # techo sobre el sello
	c.fill(1, 1, 12, 4)
	c.fill(20, 1, 34, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(11, 18, "1")
	c.put(19, 16, "2")
	c.put(28, 18, "3")
	c.put(31, 18, "a")
	c.put(51, 18, "b")
	c.put(40, 14, "G")
	c.put(46, 14, "T")
	c.put(55, 18, "S")
	c.put(25, 12, "p")
	c.put(45, 18, "g")
	c.put(8, 18, "w")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_aduana", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_arena", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L71"},
		"2": {"type": "tablilla", "id": "L72"},
		"3": {"type": "tablilla", "id": "L73"},
		"a": {"type": "promesa", "id": "peticion_a", "etiqueta": "fetch('/productos')", "retardo": 1.2, "duracion": 7.0},
		"b": {"type": "promesa", "id": "peticion_b", "etiqueta": "fetch('/usuarios')", "retardo": 1.2, "duracion": 7.0},
		"G": {"type": "promise_all", "id": "compuerta_all", "h": 3, "fuentes": ["peticion_a", "peticion_b"]},
		"T": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "async_await"},
		"S": {"type": "sello", "id": "S9", "h": 4},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"g": {"type": "enemy", "kind": "guardia_cors"},
		"w": {"type": "decor", "kind": "waterfall"},
	}
