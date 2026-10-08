extends RefCounted
## Pruebas de Espagueti y ArchQuiz.

var t

func test_arch_quiz_progression() -> void:
	var quiz := ArchQuiz.new()
	t.eq(quiz.is_complete(), false, "quiz empieza incompleto")
	t.eq(quiz.submit_choice("Presentación"), false, "opción incorrecta no avanza")
	t.eq(quiz.submit_choice("Dominio"), true, "opción correcta avanza pregunta 1")
	t.eq(quiz.current_idx, 1, "avanzó a pregunta 2")

func test_espagueti_hp_thresholds() -> void:
	t.eq(Espagueti.MAX_HP, 30, "HP máximo de Espagueti")
	t.eq(Espagueti.PHASE2_HP, 19, "Umbral fase 2")
	t.eq(Espagueti.PHASE3_HP, 9, "Umbral fase 3")
