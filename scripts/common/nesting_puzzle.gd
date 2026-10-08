class_name NestingPuzzle
extends RefCounted
## Lógica de la fase 3 del jefe: golpear etiquetas en orden de anidamiento
## (de fuera hacia dentro).

const SETS := [
	["div", "ul", "li", "a"],
	["html", "body", "main", "p"],
	["nav", "ul", "li", "a"],
	["form", "fieldset", "label", "input"],
	["section", "article", "p", "strong"],
]

var sequence: PackedStringArray = []
var progress := 0


func start(seq: Array) -> void:
	sequence = PackedStringArray(seq)
	progress = 0


func start_random(rng: RandomNumberGenerator, avoid := -1) -> int:
	var idx := rng.randi_range(0, SETS.size() - 1)
	if idx == avoid:
		idx = (idx + 1) % SETS.size()
	start(SETS[idx])
	return idx


func expected() -> String:
	return sequence[progress] if progress < sequence.size() else ""


func is_complete() -> bool:
	return sequence.size() > 0 and progress >= sequence.size()


## Devuelve "correct", "wrong" o "complete".
func hit(tag: String) -> String:
	if is_complete():
		return "complete"
	if tag == sequence[progress]:
		progress += 1
		return "complete" if progress >= sequence.size() else "correct"
	progress = 0
	return "wrong"


func structure_text() -> String:
	return " > ".join(sequence)


## Representación en HTML anidado, útil para mostrar al jugador.
func html_text() -> String:
	var open := ""
	var close := ""
	for tag in sequence:
		open += "<%s>" % tag
	for i in range(sequence.size() - 1, -1, -1):
		close += "</%s>" % sequence[i]
	return open + close
