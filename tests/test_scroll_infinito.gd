extends RefCounted
## Examen de consultas (QueryQuiz) y fases del Scroll Infinito.

var t
var room: RoomBase
var boss: ScrollInfinito


func test_query_quiz_sets() -> void:
	var q := QueryQuiz.new()
	for i in QueryQuiz.SETS.size():
		q.start(i)
		t.eq(q.correct_params().size(), 4, "set %d: 4 parámetros correctos" % i)
		t.eq(q.options().size(), 6, "set %d: 6 opciones" % i)
		var unique := {}
		for o in q.options():
			unique[o] = true
		t.eq(unique.size(), 6, "set %d: opciones distintas" % i)


func test_query_quiz_logic() -> void:
	var q := QueryQuiz.new()
	q.start(0)
	var ok := q.correct_params()
	t.eq(q.hit(ok[2]), "correct", "orden libre: tercer parámetro primero")
	t.eq(q.hit(ok[2]), "repeat", "repetir no suma")
	t.eq(q.hit(q.current.distractores[0]), "wrong", "distractor")
	t.eq(q.solved.size(), 0, "un error reinicia")
	for i in 3:
		t.eq(q.hit(ok[i]), "correct", "parámetro %d" % i)
	t.eq(q.hit(ok[3]), "complete", "completo")
	t.ok(q.url().contains("$top=10"), "url con los parámetros")


func _setup() -> void:
	GameState.new_game()
	room = load("res://rooms/z6_arena.gd").new()
	room.room_id = "z6_arena"
	t.add_child(room)
	room.build()
	var arena: Node2D = room.get_entity("arena")
	boss = ScrollInfinito.new()
	boss.setup_arena(arena, arena.global_position.y, arena.global_position.x - 17 * 64, arena.global_position.x + 17 * 64)
	room.entity_layer.add_child(boss)
	boss.global_position = arena.global_position + Vector2(0, -300)
	arena.boss = boss
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


func test_phases_lever_and_query() -> void:
	await _setup()
	_hit_until(ScrollInfinito.PHASE2_HP)
	t.eq(boss.phase, 2, "fase 2")
	boss._start_loading()
	t.eq(boss.state, "loading", "carga sin fin")
	t.eq(boss.take_hit({}).get("energy"), false, "invulnerable mientras carga")
	boss._spawn_minions(3)
	t.ok(boss.minions.size() >= 3, "invoca hojas sueltas")
	room.get_entity("paginar").pull()
	t.eq(boss.state, "exposed", "la palanca paginar lo expone")
	t.eq(boss.minions.size(), 0, "libera la memoria (hojas eliminadas)")
	t.ok(not room.get_entity("paginar").can_interact(), "la palanca tiene enfriamiento")
	_hit_until(ScrollInfinito.PHASE3_HP)
	t.eq(boss.phase, 3, "fase 3")
	boss._start_exam()
	t.eq(boss.runes.size(), 6, "seis runas de parámetros")
	var by_text := {}
	for r in boss.runes:
		by_text[r.line] = r
	by_text[boss.quiz.current.distractores[0]].take_hit({})
	t.eq(boss.state, "exam", "un parámetro incorrecto no expone")
	var params: Array = boss.quiz.correct_params().duplicate()
	params.reverse()
	for p in params:
		by_text[p].take_hit({})
	t.eq(boss.state, "exposed", "todos los parámetros (en cualquier orden) lo exponen")
	var got := [false]
	boss.defeated.connect(func(): got[0] = true)
	_hit_until(0)
	for i in 30:
		if got[0]:
			break
		await t.get_tree().create_timer(0.25).timeout
	t.ok(got[0], "emite defeated")
