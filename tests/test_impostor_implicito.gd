extends RefCounted
## Lógica de state y PKCE (AuthQuiz) y fases de El Impostor Implícito.

var t
var room: RoomBase
var boss: ImpostorImplicito


func test_auth_quiz_states() -> void:
	var q := AuthQuiz.new()
	q.rng.seed = 7
	q.start_states(3)
	t.eq(q.state_options().size(), 3, "tres copias")
	t.ok(q.expected_state in q.state_options(), "una de ellas es la legítima")
	t.ok(not (q.expected_state in q.decoy_states), "los señuelos son distintos")
	t.eq(q.hit_state(q.decoy_states[0]), "wrong", "una copia no vale")
	t.eq(q.hit_state(q.expected_state), "correct", "la del state esperado sí")
	t.eq(q.aciertos, 1, "cuenta los aciertos")


func test_auth_quiz_pkce() -> void:
	var q := AuthQuiz.new()
	q.rng.seed = 3
	var idx := q.start_pkce()
	t.eq(q.challenge(), AuthQuiz.PKCE[idx].challenge, "muestra el challenge del par elegido")
	var opciones := q.verifier_options()
	t.eq(opciones.size(), 3, "tres verifiers")
	t.ok(q.verifier() in opciones, "el correcto está entre ellos")
	for v in opciones:
		if v != q.verifier():
			t.eq(q.hit_verifier(v), "wrong", "otro verifier no produce ese challenge")
	t.eq(q.hit_verifier(q.verifier()), "correct", "el verifier correcto sí")
	t.ok(q.start_pkce(idx) != idx, "la siguiente ronda cambia de par")


func _setup() -> void:
	GameState.new_game()
	room = load("res://rooms/z7_arena.gd").new()
	room.room_id = "z7_arena"
	t.add_child(room)
	room.build()
	var arena: Node2D = room.get_entity("arena")
	boss = ImpostorImplicito.new()
	boss.setup_arena(arena, arena.global_position.y, arena.global_position.x - 18 * 64, arena.global_position.x + 18 * 64)
	room.entity_layer.add_child(boss)
	boss.global_position = arena.global_position + Vector2(0, -300)
	await t.get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _hit_until(hp: int) -> void:
	var guard := 0
	while boss.hp > hp and guard < 120:
		boss.invulnerable = false
		boss.shield = false
		boss.take_hit({})
		guard += 1


func test_phases_clones_and_pkce() -> void:
	await _setup()
	_hit_until(ImpostorImplicito.PHASE2_HP)
	t.eq(boss.phase, 2, "entra en fase 2")
	boss._start_clones()
	t.eq(boss.state, "clones", "se multiplica")
	t.eq(boss.clones.size(), 3, "tres copias")
	t.eq(boss.take_hit({}).get("energy"), false, "el original está protegido")
	var hp_antes := boss.hp
	var falsa: Node2D = null
	for c in boss.clones:
		if c.value != boss.quiz.expected_state:
			falsa = c
			break
	falsa.take_hit({})
	t.eq(boss.hp, hp_antes, "golpear una copia no le hace daño")
	for c in boss.clones:
		if c.value == boss.quiz.expected_state:
			c.take_hit({})
			break
	t.eq(boss.hp, hp_antes - 1, "la copia con el state correcto sí le hace daño")
	_hit_until(ImpostorImplicito.PHASE3_HP)
	t.eq(boss.phase, 3, "entra en fase 3")
	boss._start_pkce()
	t.eq(boss.runes.size(), 3, "tres runas de code_verifier")
	t.ok(boss.shield, "escudo durante PKCE")
	var correcta: CodeRune = null
	var incorrecta: CodeRune = null
	for r in boss.runes:
		if r.line == "code_verifier=" + boss.quiz.verifier():
			correcta = r
		else:
			incorrecta = r
	incorrecta.take_hit({})
	t.eq(boss.state, "pkce", "un verifier que no encaja no lo expone")
	correcta.take_hit({})
	t.eq(boss.state, "exposed", "el verifier correcto lo deja expuesto")
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
