extends RoomBase
## Sala 6 · Aduana de Fetch: fetch y la respuesta, body y headers, CORS y
## credenciales. La petición a otro origen se rechaza; su .catch abre la ruta.


func _init() -> void:
	zone = 5
	display_name = "Aduana de Fetch"


func theme_name() -> String:
	return "river_deep"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	c.fill(27, 19, 36, 20, ".")      # canal de la aduana
	c.fill(27, 20, 36, 20, "^")
	c.fill(1, 1, 14, 4)
	c.fill(18, 1, 44, 3)
	c.fill(50, 1, 60, 5)
	c.door(0, 18, "W")
	c.door(61, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(14, 18, "2")
	c.put(20, 18, "g")
	c.put(25, 18, "Q")
	c.put(38, 18, "R")
	c.put(41, 18, "3")
	c.put(47, 18, "4")
	c.put(54, 18, "k")
	c.put(31, 12, "p")
	c.put(10, 18, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_delta", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_observatorio", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L67"},
		"2": {"type": "tablilla", "id": "L68"},
		"3": {"type": "tablilla", "id": "L69"},
		"4": {"type": "tablilla", "id": "L70"},
		"Q": {"type": "promesa", "id": "otro_origen", "etiqueta": "fetch('https://otro-origen.com/api')", "rechaza": true, "retardo": 1.2, "catch": "respaldo"},
		"R": {"type": "promesa", "id": "respaldo", "etiqueta": ".catch(() => fetch('/api/respaldo'))", "activable": false, "plataformas": [[-10, 0, 2], [-7, 0, 2], [-4, 0, 2]], "retardo": 0.8, "duracion": 6.0},
		"g": {"type": "enemy", "kind": "guardia_cors"},
		"k": {"type": "enemy", "kind": "csrf_impostor"},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"x": {"type": "decor", "kind": "big_tag", "text": "fetch()", "size": 110},
	}
