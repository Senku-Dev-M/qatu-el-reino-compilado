class_name LayoutQuiz
extends RefCounted
## Lógica del examen del Guardián del Parcial: hay que elegir el valor de
## cada propiedad que produce el layout objetivo (orden libre).

const SETS := [
	{"justify-content": "space-between", "align-items": "center"},
	{"justify-content": "center", "align-items": "flex-end"},
	{"justify-content": "flex-end", "align-items": "flex-start"},
	{"justify-content": "space-around", "align-items": "center"},
	{"justify-content": "flex-start", "align-items": "stretch"},
]

var target := {}
var solved := {}


func start(p_target: Dictionary) -> void:
	target = p_target.duplicate()
	solved.clear()


func start_random(rng: RandomNumberGenerator, avoid := -1) -> int:
	var idx := rng.randi_range(0, SETS.size() - 1)
	if idx == avoid:
		idx = (idx + 1) % SETS.size()
	start(SETS[idx])
	return idx


func is_complete() -> bool:
	return not target.is_empty() and solved.size() == target.size()


## Devuelve "correct", "wrong" o "complete".
func hit(property: String, value: String) -> String:
	if not target.has(property):
		return "wrong"
	if target[property] != value:
		solved.erase(property)
		return "wrong"
	solved[property] = true
	return "complete" if is_complete() else "correct"


func css_text() -> String:
	var lines := PackedStringArray([".contenedor {", "  display: flex;"])
	for k in target.keys():
		lines.append("  %s: %s;" % [k, target[k]])
	lines.append("}")
	return "\n".join(lines)
