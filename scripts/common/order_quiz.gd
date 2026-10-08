class_name OrderQuiz
extends RefCounted
## Lógica del refactor de Callback Hell: hay que elegir, en orden, las
## líneas que forman la versión con async/await. Un error reinicia el orden.

const SETS := [
	{
		"titulo": "Pasa estos callbacks a async/await",
		"antes": "obtener(url, function (res) {\n  leerJson(res, function (datos) {\n    mostrar(datos);\n  });\n});",
		"lineas": ["async function cargar() {", "const res = await fetch(url);", "const datos = await res.json();", "mostrar(datos); }"],
		"distractores": ["fetch(url, function (res) {", "res.json(function (datos) {"],
	},
	{
		"titulo": "Gestiona el error con try/catch",
		"antes": "obtener(url, function (error, res) {\n  if (error) { avisar(error); return; }\n  mostrar(res);\n});",
		"lineas": ["try {", "const res = await fetch(url);", "mostrar(await res.json());", "} catch (error) { avisar(error); }"],
		"distractores": ["if (error) callback(error);", "res.then(function () {"],
	},
	{
		"titulo": "Espera dos peticiones en paralelo",
		"antes": "getProductos(function (p) {\n  getUsuarios(function (u) {\n    pintar(p, u);\n  });\n});",
		"lineas": ["const [p, u] = await Promise.all([", "fetch('/productos'),", "fetch('/usuarios') ]);", "pintar(p, u);"],
		"distractores": ["getProductos(function (p) {", "setTimeout(pintar, 1000);"],
	},
]

var current := {}
var progress := 0


func start(index: int) -> void:
	current = SETS[index % SETS.size()]
	progress = 0


func start_random(rng: RandomNumberGenerator, avoid := -1) -> int:
	var idx := rng.randi_range(0, SETS.size() - 1)
	if idx == avoid:
		idx = (idx + 1) % SETS.size()
	start(idx)
	return idx


func lines() -> Array:
	return current.get("lineas", [])


## Todas las opciones (líneas correctas y distractores), sin ordenar.
func options() -> Array:
	var out: Array = lines().duplicate()
	out.append_array(current.get("distractores", []))
	return out


func is_complete() -> bool:
	return not current.is_empty() and progress >= lines().size()


## Devuelve "correct", "wrong" o "complete".
func hit(line: String) -> String:
	if is_complete():
		return "complete"
	if line == str(lines()[progress]):
		progress += 1
		return "complete" if is_complete() else "correct"
	progress = 0
	return "wrong"
