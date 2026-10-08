extends RoomBase
## Sala 5 · Sótano del Rendimiento: logging asíncrono, gzip y connection
## pooling. La palanca abre la compuerta del fondo solo 1,5 s:
## hay que guardar la caché junto a la compuerta y volver. Sello S11.


func _init() -> void:
	zone = 6
	display_name = "Sótano del Rendimiento"


func theme_name() -> String:
	return "archive_vault"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(60, 22).frame(19)
	c.fill(17, 19, 19, 20, ".")
	c.fill(17, 20, 19, 20, "^")
	c.fill(40, 1, 40, 15)            # muro de la compuerta
	c.fill(52, 1, 56, 14)            # techo del sello
	c.fill(1, 1, 12, 4)
	c.fill(22, 1, 38, 2)
	c.door(0, 18, "W")
	c.door(59, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(22, 18, "L")
	c.put(12, 18, "1")
	c.put(26, 18, "2")
	c.put(40, 18, "G")
	c.put(45, 18, "3")
	c.put(54, 18, "S")
	c.put(57, 18, "T")
	c.put(31, 18, "p")
	c.put(36, 18, "l")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_galeria", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_boveda", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L85"},
		"2": {"type": "tablilla", "id": "L86"},
		"3": {"type": "tablilla", "id": "L87"},
		"L": {"type": "palanca", "id": "palanca_sotano", "target": "compuerta_sotano", "segundos": 1.5, "etiqueta": "abrir()"},
		"G": {"type": "gate", "id": "compuerta_sotano", "h": 3, "persist": false},
		"S": {"type": "sello", "id": "S11", "h": 4},
		"T": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "gzip"},
		"p": {"type": "enemy", "kind": "payload_gigante"},
		"l": {"type": "enemy", "kind": "log_sincrono"},
	}
