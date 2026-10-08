class_name OwaspQuiz
extends RefCounted
## Desafío interactivo de seguridad OWASP y testing para la fase 3 de La Regresión.
## El jugador debe activar las directivas y controles correctos para purificar el código.

const QUESTIONS := [
	{
		"prompt": "Inyección SQL detectada en endpoint de búsqueda: aplicar defensa canónica",
		"correct": ["Prepared Statement", "Parametrizar", "ORM"],
		"options": ["Prepared Statement", "Parametrizar", "ORM", "Concatenar Strings", "eval()", "Quitar espacios"]
	},
	{
		"prompt": "Vulnerabilidad XSS: bloquear ejecución de scripts inline en el navegador",
		"correct": ["Content-Security-Policy", "Sanitizar HTML", "Escape Contextual"],
		"options": ["Content-Security-Policy", "Sanitizar HTML", "Escape Contextual", "innerHTML directo", "document.write", "Desactivar HTTPS"]
	},
	{
		"prompt": "Blindar cookies de sesión contra accesos no autorizados y CSRF",
		"correct": ["HttpOnly", "SameSite=Strict", "Secure"],
		"options": ["HttpOnly", "SameSite=Strict", "Secure", "document.cookie", "LocalStorage", "Sin expiración"]
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
