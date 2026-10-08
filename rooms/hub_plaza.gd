extends RoomBase
## Plaza de Qatu: hub central con los nueve portales de las semanas y la entrada al Sanctum Capstone.


func _init() -> void:
	zone = 0
	display_name = "Plaza de Qatu"
	area_title = "Qatu"


func theme_name() -> String:
	return "hub"


func music() -> String:
	return "hub"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(68, 18).frame(15)
	c.fill(24, 14, 66, 14)  # estrado de los portales
	c.fill(1, 1, 3, 3)
	c.fill(64, 1, 66, 2)
	c.put(3, 14, "S")
	c.put(6, 14, "L")
	c.put(9, 14, "M")
	c.put(15, 14, "B")
	c.put(18, 14, "q")
	c.put(12, 14, "r")
	c.put(1, 14, "u")
	c.put(14, 14, "w")
	c.put(21, 14, "E")
	c.put(23, 14, "k")
	var digits := "123456789"
	for i in 9:
		c.put(26 + i * 4, 13, digits[i])
	c.put(62, 13, "C")  # Portal al Sanctum Capstone
	c.put(65, 13, "L")
	return c.rows()


func legend() -> Dictionary:
	return {
		"S": {"type": "sign", "id": "inicio", "text": "Plaza de Qatu"},
		"L": {"type": "lamp"},
		"k": {"type": "lamp", "id": "farol_semana3", "flag": "jefe:nodo_huerfano"},
		"q": {"type": "lamp", "id": "farol_semana4", "flag": "jefe:guardian_parcial"},
		"M": {"type": "npc", "id": "mentora", "who": "mentora"},
		"B": {"type": "bench", "id": "banco"},
		"E": {"type": "npc", "id": "estatua", "who": "estatua"},
		"1": {"type": "portal", "id": "portal1", "week": 1, "label": "Ruinas del Backend", "to": "z1_atrio", "to_door": "izq", "prompt": "Entrar a las Ruinas del Backend", "restored_flag": "jefe:monolito"},
		"2": {"type": "portal", "id": "portal2", "week": 2, "label": "Torres de Arquitectura", "to": "z2_torre_base", "to_door": "izq", "prompt": "Entrar a las Torres de Arquitectura", "restored_flag": "jefe:espagueti"},
		"3": {"type": "portal", "id": "portal3", "week": 3, "label": "Bosque del DOM", "to": "z3_raiz", "to_door": "portal", "prompt": "Entrar al Bosque del DOM", "restored_flag": "jefe:nodo_huerfano"},
		"4": {"type": "portal", "id": "portal4", "week": 4, "label": "Cañones Flexibles", "to": "z4_mirador", "to_door": "portal", "prompt": "Entrar a los Cañones Flexibles", "restored_flag": "jefe:guardian_parcial"},
		"5": {"type": "portal", "id": "portal5", "week": 5, "label": "Ríos Asíncronos", "to": "z5_embarcadero", "to_door": "portal", "prompt": "Entrar a los Ríos Asíncronos", "restored_flag": "jefe:callback_hell"},
		"r": {"type": "lamp", "id": "farol_semana5", "flag": "jefe:callback_hell"},
		"6": {"type": "portal", "id": "portal6", "week": 6, "label": "Archivo Paginado", "to": "z6_vestibulo", "to_door": "portal", "prompt": "Entrar al Archivo Paginado", "restored_flag": "jefe:scroll_infinito"},
		"u": {"type": "lamp", "id": "farol_semana6", "flag": "jefe:scroll_infinito"},
		"7": {"type": "portal", "id": "portal7", "week": 7, "label": "Ciudadela IAM", "to": "z7_puesto", "to_door": "portal", "prompt": "Entrar a la Ciudadela IAM", "restored_flag": "jefe:impostor_implicito"},
		"w": {"type": "lamp", "id": "farol_semana7", "flag": "jefe:impostor_implicito"},
		"8": {"type": "portal", "id": "portal8", "week": 8, "label": "Puerto de Contenedores", "to": "z8_muelle", "to_door": "izq", "prompt": "Entrar al Puerto de Contenedores", "restored_flag": "jefe:kubernetes"},
		"9": {"type": "portal", "id": "portal9", "week": 9, "label": "Laboratorio de Pruebas", "to": "z9_vestibulo_qa", "to_door": "izq", "prompt": "Entrar al Laboratorio de Pruebas", "restored_flag": "jefe:regresion"},
		"C": {"type": "portal", "id": "portal_sanctum", "to": "hub_sanctum", "to_door": "izq", "prompt": "Entrar al Sanctum de Qatu"}
	}
