extends RefCounted
## Recorre las tres fases del Guardián del Parcial sin jugador.

var t
var room: RoomBase
var boss: GuardianParcial


func _setup() -> void:
	GameState.new_game()
	room = load("res://rooms/z4_arena.gd").new()
	room.room_id = "z4_arena"
	t.add_child(room)
	room.build()
	var arena: Node2D = room.get_entity("arena")
	boss = GuardianParcial.new()
	boss.setup_arena(arena, arena.global_position.y, arena.global_position.x - 17 * 64, arena.global_position.x + 17 * 64)
	room.entity_layer.add_child(boss)
	boss.global_position = arena.global_position + Vector2(0, -300)
	await t.get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _hit_until(hp: int) -> void:
	var guard := 0
	while boss.hp > hp and guard < 100:
		boss.invulnerable = false
		boss.shield = false
		boss.take_hit({})
		guard += 1


func test_phase_two_moves_platforms_and_perch() -> void:
	await _setup()
	t.ok(boss._flex("flex_alto") != null and boss._flex("flex_bajo") != null, "el jefe encuentra los contenedores flex")
	_hit_until(GuardianParcial.PHASE2_HP)
	t.eq(boss.phase, 2, "entra en fase 2")
	t.ok(boss.invulnerable, "invulnerable durante la transición")
	var bajo_before: String = boss._flex("flex_bajo").value
	var alto_before: String = boss._flex("flex_alto").value
	boss._start_layout_phase()
	t.eq(boss.state, "perch", "estado perch")
	t.ok(boss._flex("flex_bajo").value != bajo_before, "desordena flex_bajo")
	t.ok(boss._flex("flex_alto").value != alto_before, "desordena flex_alto")
	var alto = boss._flex("flex_alto")
	for spot in GuardianParcial.SPOTS:
		alto.set_value(spot, false, false)
		for i in 3:
			await t.get_tree().physics_frame
		var plat_x: float = alto.platforms[0].global_position.x
		print("    spot ", spot, " jefe ", boss._spot_x(spot), " plataforma ", plat_x)
		t.ok(absf(boss._spot_x(spot) - plat_x) < 1.0, "el jefe se coloca sobre la plataforma con %s" % spot)
	t.ok(not GameState.get_flag(room.flag_key("flex_alto")), "los contenedores de la arena no se guardan")


func test_phase_three_exam_and_death() -> void:
	await _setup()
	_hit_until(GuardianParcial.PHASE2_HP)
	boss._start_layout_phase()
	_hit_until(GuardianParcial.PHASE3_HP)
	t.eq(boss.phase, 3, "entra en fase 3")
	boss._start_exam()
	t.eq(boss.runes.size(), 6, "seis runas")
	t.ok(boss.shield, "escudo activo durante el examen")
	var props := {}
	for r in boss.runes:
		props[r.property + ":" + r.value] = true
	t.eq(props.size(), 6, "runas distintas")
	for p in ["justify-content", "align-items"]:
		t.ok(props.has(p + ":" + boss.quiz.target[p]), "hay una runa con el valor correcto de %s" % p)
	# Golpe equivocado: no expone.
	var wrong: PropertyRune = null
	for r in boss.runes:
		if r.value != boss.quiz.target[r.property]:
			wrong = r
			break
	wrong.take_hit({})
	t.eq(boss.state, "exam", "un valor equivocado no expone al jefe")
	t.eq(boss.take_hit({}).get("energy"), false, "el escudo bloquea los golpes")
	for r in boss.runes.duplicate():
		if r.value == boss.quiz.target[r.property]:
			r.take_hit({})
	t.eq(boss.state, "exposed", "los dos valores correctos exponen al jefe")
	t.ok(not boss.shield, "sin escudo")
	var got_defeated := [false]
	boss.defeated.connect(func(): got_defeated[0] = true)
	_hit_until(0)
	t.eq(boss.state, "dead", "muere al llegar a 0")
	for i in 30:
		if got_defeated[0]:
			break
		await t.get_tree().create_timer(0.25).timeout
	t.ok(got_defeated[0], "emite defeated")
