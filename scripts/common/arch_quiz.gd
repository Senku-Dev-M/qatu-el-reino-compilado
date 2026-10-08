class_name ArchQuiz
extends RefCounted
## Desafío interactivo de Clean Architecture para la fase 3 de Espagueti.
## El jugador debe clasificar componentes en su capa correcta (Dominio, Casos de Uso, Presentación).

const QUESTIONS := [
	{
		"prompt": "¿A qué capa pertenece la entidad 'Producto' y sus reglas de negocio?",
		"correct": ["Dominio"],
		"options": ["Dominio", "Presentación", "Infraestructura", "Controlador"]
	},
	{
		"prompt": "¿A qué capa pertenece el componente 'PublicarProductoUseCase'?",
		"correct": ["Aplicación"],
		"options": ["Aplicación", "Base de Datos", "HTML", "UI"]
	},
	{
		"prompt": "¿A qué capa pertenece 'ProductosViewModel' y el Data Binding?",
		"correct": ["Presentación"],
		"options": ["Presentación", "Dominio", "Infraestructura", "Núcleo"]
	}
]

var current_idx := 0

func current_question() -> Dictionary:
	return QUESTIONS[current_idx % QUESTIONS.size()]

func submit_choice(choice: String) -> bool:
	var q := current_question()
	if choice in q.correct:
		current_idx += 1
		return true
	return false

func is_complete() -> bool:
	return current_idx >= QUESTIONS.size()
