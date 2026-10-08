class_name RestQuiz
extends RefCounted
## Desafío interactivo de diseño REST para la fase 3 de El Monolito.
## El jugador debe golpear los glifos correctos de Verbo + URI correspondientes
## a la operación solicitada del marketplace Qatu.

const QUESTIONS := [
	{
		"prompt": "Crear un nuevo producto en el catálogo de Qatu",
		"correct": ["POST", "/api/v1/productos"],
		"options": ["GET", "POST", "DELETE", "/api/v1/productos", "/api/v1/crear_prod", "/api/v1/productos/10"]
	},
	{
		"prompt": "Obtener el detalle del producto #42",
		"correct": ["GET", "/api/v1/productos/42"],
		"options": ["GET", "POST", "PUT", "/api/v1/productos/42", "/api/v1/consultar?id=42", "/api/v1/productos"]
	},
	{
		"prompt": "Eliminar la orden #100 sin dejar rastro",
		"correct": ["DELETE", "/api/v1/ordenes/100"],
		"options": ["GET", "POST", "DELETE", "/api/v1/ordenes/100", "/api/v1/borrar_orden", "/api/v1/ordenes"]
	}
]

var current_idx := 0
var selected: Array[String] = []

func current_question() -> Dictionary:
	return QUESTIONS[current_idx % QUESTIONS.size()]

func submit_choice(choice: String) -> bool:
	var q := current_question()
	var needed: Array = q.correct
	if choice in needed and not (choice in selected):
		selected.append(choice)
		if selected.size() == needed.size():
			current_idx += 1
			selected.clear()
			return true
	return false

func is_complete() -> bool:
	return current_idx >= QUESTIONS.size()
