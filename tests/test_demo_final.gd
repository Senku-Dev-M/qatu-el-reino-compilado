extends RefCounted
## Pruebas de la máquina de estados del jefe final El Tribunal de la Demo en Vivo.

var t

func test_demo_final_hp_thresholds() -> void:
	t.eq(DemoFinal.MAX_HP, 36, "HP máximo de la Demo Final")
	t.eq(DemoFinal.PHASE2_HP, 24, "Umbral fase 2")
	t.eq(DemoFinal.PHASE3_HP, 11, "Umbral fase 3")

func test_hub_sanctum_compiles_and_loads() -> void:
	var script: GDScript = load("res://rooms/hub_sanctum.gd")
	t.ok(script != null, "hub_sanctum compila")
	var inst: RoomBase = script.new()
	inst.room_id = "hub_sanctum"
	var rows := inst.layout()
	t.ok(rows.size() >= 17, "hub_sanctum tiene al menos 17 filas")
	t.ok(rows[0].length() >= 30, "hub_sanctum tiene al menos 30 columnas")
	inst.free()
