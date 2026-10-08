extends RefCounted
## Pruebas de rutas y navegabilidad física para las salas de Zona 9.

var t

func test_z9_rooms_exist_and_compile() -> void:
	var rooms := [
		"z9_vestibulo_qa", "z9_sala_piramide", "z9_camara_selenium", "z9_santuario_inspector",
		"z9_bunker_owasp", "z9_torre_monitoreo", "z9_galeria_metricas", "z9_arena"
	]
	for r in rooms:
		var script: GDScript = load("res://rooms/%s.gd" % r)
		t.ok(script != null, "Sala %s compila" % r)
		var inst: RoomBase = script.new()
		inst.room_id = r
		var rows := inst.layout()
		t.ok(rows.size() >= 17, "%s tiene al menos 17 filas" % r)
		t.ok(rows[0].length() >= 30, "%s tiene al menos 30 columnas" % r)
		inst.free()
