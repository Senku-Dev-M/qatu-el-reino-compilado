extends RoomBase
## Sala 7 · Pasillo de los Middlewares: qué es un middleware, tipos, ventajas
## y casos de uso. Tres compuertas en cadena como un pipeline: autenticar,
## registrar (next()) y el controlador, cuya palanca solo la abre 1,2 s. Sello S12.


func _init() -> void:
	zone = 6
	display_name = "Pasillo de los Middlewares"


func theme_name() -> String:
	return "archive"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	c.fill(16, 1, 16, 15)
	c.fill(28, 1, 28, 15)
	c.fill(50, 1, 50, 15)
	c.fill(53, 1, 57, 14)            # techo del sello
	c.door(0, 18, "W")
	c.door(61, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(10, 18, "1")
	c.put(13, 18, "a")
	c.put(16, 18, "A")
	c.put(19, 18, "2")
	c.put(25, 18, "r")
	c.put(28, 18, "R")
	c.put(33, 18, "3")
	c.put(36, 18, "c")
	c.put(50, 18, "C")
	c.put(55, 18, "S")
	c.put(58, 18, "n")
	c.put(21, 18, "p")
	c.put(58, 10, "o")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_boveda", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_arena", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L92"},
		"2": {"type": "tablilla", "id": "L93"},
		"3": {"type": "tablilla", "id": "L94"},
		"a": {"type": "palanca", "id": "palanca_auth", "target": "compuerta_auth", "segundos": 0, "etiqueta": "autenticar(req, res, next)"},
		"A": {"type": "gate", "id": "compuerta_auth", "h": 3},
		"r": {"type": "palanca", "id": "palanca_log", "target": "compuerta_log", "segundos": 0, "etiqueta": "registrar(req, res, next)"},
		"R": {"type": "gate", "id": "compuerta_log", "h": 3},
		"c": {"type": "palanca", "id": "palanca_ctrl", "target": "compuerta_ctrl", "segundos": 1.2, "etiqueta": "controlador(req, res)"},
		"C": {"type": "gate", "id": "compuerta_ctrl", "h": 3, "persist": false},
		"S": {"type": "sello", "id": "S12", "h": 4},
		"n": {"type": "enemy", "kind": "consulta_n1"},
		"p": {"type": "enemy", "kind": "payload_gigante"},
		"o": {"type": "enemy", "kind": "cache_obsoleta"},
	}
