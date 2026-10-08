extends RoomBase
## Sala 6 · Bóveda de la Caché: estrategias, dónde vive la caché, invalidación
## y riesgos, y el patrón Flyweight. La palanca bajo la pasarela abre la compuerta
## de la pasarela alta solo 2,5 s. Cámara oculta con el amuleto CDN.


func _init() -> void:
	zone = 6
	display_name = "Bóveda de la Caché"


func theme_name() -> String:
	return "archive_vault"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	c.fill(1, 11, 8, 17)             # bloque con cámara oculta
	c.fill(2, 14, 8, 16, ".")        # la columna 8 la ocupa la pared falsa
	c.fill(12, 19, 14, 19, "=")      # subida a la cámara
	c.fill(9, 17, 11, 17)
	c.fill(26, 19, 28, 19, "=")      # escalera hacia la pasarela
	c.fill(29, 17, 31, 17, "=")
	c.fill(32, 15, 34, 15, "=")
	c.fill(35, 13, 37, 13, "=")
	c.fill(38, 11, 39, 11, "=")
	c.fill(40, 9, 61, 9)             # pasarela alta
	c.fill(50, 1, 50, 5)             # muro sobre la compuerta
	c.fill(12, 1, 30, 3)
	c.door(0, 20, "W")
	c.door(61, 8, "D")
	c.put(3, 20, "M")
	c.put(8, 16, "f")
	c.put(4, 16, "T")
	c.put(16, 20, "1")
	c.put(41, 20, "L")
	c.put(24, 20, "2")
	c.put(44, 8, "3")
	c.put(50, 8, "G")
	c.put(55, 8, "4")
	c.put(56, 20, "l")
	c.put(30, 8, "o")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_sotano", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_pasillo", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L88"},
		"2": {"type": "tablilla", "id": "L89"},
		"3": {"type": "tablilla", "id": "L90"},
		"4": {"type": "tablilla", "id": "L91"},
		"f": {"type": "fake_wall", "id": "pared_boveda", "w": 1, "h": 3},
		"T": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "cdn"},
		"L": {"type": "palanca", "id": "palanca_boveda", "target": "compuerta_boveda", "segundos": 2.5, "etiqueta": "invalidar()"},
		"G": {"type": "gate", "id": "compuerta_boveda", "h": 3, "persist": false},
		"l": {"type": "enemy", "kind": "log_sincrono"},
		"o": {"type": "enemy", "kind": "cache_obsoleta"},
	}
