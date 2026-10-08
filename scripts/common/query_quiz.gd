class_name QueryQuiz
extends RefCounted
## Examen del Scroll Infinito: golpear, en cualquier orden, todos los
## parámetros de consulta que producen los datos pedidos. Un parámetro
## incorrecto reinicia lo acertado.

const SETS := [
	{
		"estilo": "OData",
		"pedido": "Textiles de menos de 100, del más barato al más caro, 10 por página: página 3",
		"correctas": ["$filter=categoria eq 'textil' and precio lt 100", "$orderby=precio asc", "$top=10", "$skip=20"],
		"distractores": ["$orderby=precio desc", "$skip=30"],
	},
	{
		"estilo": "JSON:API",
		"pedido": "Pedidos con su cliente incluido, los más recientes primero, de 25 en 25: página 2",
		"correctas": ["include=cliente", "sort=-fecha", "page[number]=2", "page[size]=25"],
		"distractores": ["sort=fecha", "page[number]=3"],
	},
	{
		"estilo": "OData",
		"pedido": "Solo nombre y precio de los productos en oferta, con el total de resultados: los 5 primeros",
		"correctas": ["$select=nombre,precio", "$filter=oferta eq true", "$count=true", "$top=5"],
		"distractores": ["$expand=nombre,precio", "$skip=5"],
	},
]

var current := {}
var solved := {}


func start(index: int) -> void:
	current = SETS[index % SETS.size()]
	solved.clear()


func start_random(rng: RandomNumberGenerator, avoid := -1) -> int:
	var idx := rng.randi_range(0, SETS.size() - 1)
	if idx == avoid:
		idx = (idx + 1) % SETS.size()
	start(idx)
	return idx


func correct_params() -> Array:
	return current.get("correctas", [])


func options() -> Array:
	var out: Array = correct_params().duplicate()
	out.append_array(current.get("distractores", []))
	return out


func is_complete() -> bool:
	return not current.is_empty() and solved.size() == correct_params().size()


## Devuelve "correct", "repeat", "wrong" o "complete".
func hit(param: String) -> String:
	if not (param in correct_params()):
		solved.clear()
		return "wrong"
	if solved.has(param):
		return "repeat"
	solved[param] = true
	return "complete" if is_complete() else "correct"


## URL completa con los parámetros correctos, para mostrarla al acertar.
func url() -> String:
	return "GET /api/recurso?" + "&".join(PackedStringArray(correct_params()))
