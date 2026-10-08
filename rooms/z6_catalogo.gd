extends RoomBase
## Sala 3 · Catálogo JSON:API: formato de la especificación y cómo filtra,
## ordena y pagina. Santuario de la Caché y cámara con fragmento tras una
## compuerta que la palanca abre solo 2 segundos.


func _init() -> void:
	zone = 6
	display_name = "Catálogo JSON:API"


func theme_name() -> String:
	return "archive"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(14, 17, 18, 18)           # pedestal del santuario
	c.fill(37, 17, 39, 17, "=")      # subida a la cámara
	c.fill(40, 10, 56, 15)           # bloque de la cámara
	c.fill(40, 12, 55, 14, ".")
	c.fill(1, 1, 12, 4)
	c.fill(20, 1, 36, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(10, 18, "1")
	c.put(16, 16, "A")
	c.put(22, 18, "2")
	c.put(26, 18, "L")
	c.put(43, 14, "G")
	c.put(52, 14, "F")
	c.put(30, 12, "o")
	c.put(48, 18, "l")
	c.put(12, 18, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_estanteria", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_galeria", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L80"},
		"2": {"type": "tablilla", "id": "L81"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "cache", "dialog": "santuario_cache"},
		"L": {"type": "palanca", "id": "palanca_catalogo", "target": "puerta_fragmento", "segundos": 2.0, "etiqueta": "abrir()"},
		"G": {"type": "gate", "id": "puerta_fragmento", "h": 3, "persist": false},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"o": {"type": "enemy", "kind": "cache_obsoleta"},
		"l": {"type": "enemy", "kind": "log_sincrono"},
		"x": {"type": "decor", "kind": "big_tag", "text": "application/vnd.api+json", "size": 56},
	}
