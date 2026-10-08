extends RefCounted
## Pruebas de la máquina de estados y PipelineQuiz del jefe Kubernetes, el Timonel.

var t

func test_pipeline_quiz_progression() -> void:
	var quiz := PipelineQuiz.new()
	t.eq(quiz.is_complete(), false, "quiz empieza incompleto")
	var q1 := quiz.current_question()
	t.ok(q1.has("prompt"), "pregunta 1 tiene prompt")
	t.eq(quiz.submit_choice("docker rm"), false, "elección errónea no avanza")
	t.eq(quiz.submit_choice("docker build"), false, "primera correcta no completa")
	t.eq(quiz.submit_choice("docker push"), false, "segunda correcta no completa")
	t.eq(quiz.submit_choice("kubectl apply"), true, "tercera correcta completa pregunta 1")
	t.eq(quiz.current_idx, 1, "avanzó a pregunta 2")

func test_kubernetes_hp_thresholds() -> void:
	t.eq(Kubernetes.MAX_HP, 30, "HP máximo de Kubernetes")
	t.eq(Kubernetes.PHASE2_HP, 19, "Umbral fase 2")
	t.eq(Kubernetes.PHASE3_HP, 9, "Umbral fase 3")
