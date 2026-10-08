class_name DemoQuiz
extends RefCounted
## Pregunta de la Demo Final: una de cada semana con jefe propio (REST,
## arquitectura, contenedores y seguridad), en el formato de los otros quizzes.

var current_idx := 0
var questions: Array = []


func _init() -> void:
	for source: Array in [RestQuiz.QUESTIONS, ArchQuiz.QUESTIONS, PipelineQuiz.QUESTIONS, OwaspQuiz.QUESTIONS]:
		questions.append(source[randi() % source.size()])
	questions.shuffle()


func current_question() -> Dictionary:
	return questions[current_idx % questions.size()]


func submit_choice(choice: String) -> bool:
	if choice in current_question().correct:
		return true
	return false


func is_complete() -> bool:
	return current_idx >= questions.size()
