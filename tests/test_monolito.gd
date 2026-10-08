extends RefCounted
## Pruebas de la máquina de estados y RestQuiz del jefe El Monolito.

var t

func test_rest_quiz_progression() -> void:
	var quiz := RestQuiz.new()
	t.eq(quiz.is_complete(), false, "quiz empieza incompleto")
	var q1 := quiz.current_question()
	t.ok(q1.has("prompt"), "pregunta 1 tiene prompt")
	t.eq(quiz.submit_choice("GET"), false, "elección errónea o incompleta no avanza")
	t.eq(quiz.submit_choice("POST"), false, "primera correcta no completa")
	t.eq(quiz.submit_choice("/api/v1/productos"), true, "segunda correcta completa pregunta 1")
	t.eq(quiz.current_idx, 1, "avanzó a pregunta 2")

func test_monolito_hp_thresholds() -> void:
	t.eq(Monolito.MAX_HP, 28, "HP máximo de El Monolito")
	t.eq(Monolito.PHASE2_HP, 18, "Umbral fase 2")
	t.eq(Monolito.PHASE3_HP, 8, "Umbral fase 3")
