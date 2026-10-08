extends RefCounted
## Pruebas de la máquina de estados y OwaspQuiz del jefe La Regresión.

var t

func test_owasp_quiz_progression() -> void:
	var quiz := OwaspQuiz.new()
	t.eq(quiz.is_complete(), false, "quiz empieza incompleto")
	var q1 := quiz.current_question()
	t.ok(q1.has("prompt"), "pregunta 1 tiene prompt")
	t.eq(quiz.submit_choice("eval()"), false, "elección errónea no avanza")
	t.eq(quiz.submit_choice("Prepared Statement"), false, "primera correcta no completa")
	t.eq(quiz.submit_choice("Parametrizar"), false, "segunda correcta no completa")
	t.eq(quiz.submit_choice("ORM"), true, "tercera correcta completa pregunta 1")
	t.eq(quiz.current_idx, 1, "avanzó a pregunta 2")

func test_regresion_hp_thresholds() -> void:
	t.eq(Regresion.MAX_HP, 32, "HP máximo de La Regresión")
	t.eq(Regresion.PHASE2_HP, 20, "Umbral fase 2")
	t.eq(Regresion.PHASE3_HP, 9, "Umbral fase 3")
