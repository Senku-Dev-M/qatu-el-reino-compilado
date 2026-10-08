extends RefCounted
## Lógica del refactor (OrderQuiz) y las tres fases de Callback Hell.

var t
var room: RoomBase
var boss: CallbackHell


func test_order_quiz_sets_are_consistent() -> void:
	var q := OrderQuiz.new()
	for i in OrderQuiz.SETS.size():
		q.start(i)
		t.eq(q.lines().size(), 4, "set %d: 4 líneas" % i)
		t.eq(q.options().size(), 6, "set %d: 6 opciones" % i)
		var unique := {}
		for o in q.options():
			unique[o] = true
		t.eq(unique.size(), 6, "set %d: opciones distintas" % i)


func test_order_quiz_logic() -> void:
	var q := OrderQuiz.new()
	q.start(0)
	var lines := q.lines()
	t.eq(q.hit(lines[1]), "wrong", "fuera de orden es error")
	t.eq(q.progress, 0, "el error reinicia")
	t.eq(q.hit(lines[0]), "correct", "primera línea")
	t.eq(q.hit(q.current.distractores[0]), "wrong", "un distractor es error")
	t.eq(q.progress, 0, "reinicia tras distractor")
	for i in 3:
		t.eq(q.hit(lines[i]), "correct", "línea %d" % (i + 1))
	t.eq(q.hit(lines[3]), "complete", "última línea completa")
	t.ok(q.is_complete(), "completo")


func _setup() -> void:
	GameState.new_game()
	room = load("res://rooms/z5_arena.gd").new()
	room.room_id = "z5_arena"
	t.add_child(room)
	room.build()
	var arena: Node2D = room.get_entity("arena")
	boss = CallbackHell.new()
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


func test_phases_and_refactor() -> void:
	await _setup()
	_hit_until(CallbackHell.PHASE2_HP)
	t.eq(boss.phase, 2, "entra en fase 2")
	boss._start_perch()
	t.eq(boss.state, "perch", "se eleva")
	_hit_until(CallbackHell.PHASE3_HP)
	t.eq(boss.phase, 3, "entra en fase 3")
	boss._start_exam()
	t.eq(boss.runes.size(), 6, "seis runas de código")
	t.ok(boss.shield, "escudo durante el refactor")
	var by_line := {}
	for r in boss.runes:
		by_line[r.line] = r
	var lines: Array = boss.quiz.lines()
	by_line[lines[1]].take_hit({})
	t.eq(boss.quiz.progress, 0, "orden incorrecto reinicia")
	t.eq(boss.state, "exam", "sigue el examen")
	for i in lines.size():
		by_line[lines[i]].take_hit({})
	t.eq(boss.state, "exposed", "el refactor completo expone al jefe")
	t.ok(not boss.shield, "sin escudo")
	var got := [false]
	boss.defeated.connect(func(): got[0] = true)
	_hit_until(0)
	t.eq(boss.state, "dead", "muere")
	for i in 30:
		if got[0]:
			break
		await t.get_tree().create_timer(0.25).timeout
	t.ok(got[0], "emite defeated")


func test_nested_brace_splits() -> void:
	await _setup()
	var before := room.entity_layer.get_child_count()
	boss._spawn_brace(boss.global_position + Vector2(0, -200), Vector2.ZERO, 2)
	var saw_children := false
	for i in 180:
		await t.get_tree().physics_frame
		var braces := 0
		for c in room.entity_layer.get_children():
			if c is CallbackHell.NestedBrace:
				braces += 1
		if braces >= 2:
			saw_children = true
			break
	t.ok(saw_children, "la llave anidada se divide en dos al tocar el suelo")
	t.ok(before > 0, "arena construida")
