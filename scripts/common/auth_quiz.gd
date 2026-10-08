class_name AuthQuiz
extends RefCounted
## Lógica del Impostor Implícito.
##
## Fase 2 · `state`: la petición de autorización llevaba un `state`; solo la
## respuesta que devuelve ese mismo valor es legítima (las demás son copias).
## Fase 3 · PKCE: se muestra el `code_challenge` y hay que elegir el
## `code_verifier` que lo produce con S256.

const STATES := ["a91f2c", "7d4e08", "b3c5aa", "12f9de", "e04b71", "6c8a35"]

const PKCE := [
	{"verifier": "qatu-verifier-1", "challenge": "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"},
	{"verifier": "poncho-de-alpaca", "challenge": "Kx7pQ2mWv9LbTnA4ZyR6Cs1DfGh0JkUeYwXiOpMnQaE"},
	{"verifier": "mercado-de-qatu", "challenge": "R4tYu7Io9PaSdF2gHjKl5ZxCvBnM8QwErTyUiOp3AsD"},
	{"verifier": "telar-del-valle", "challenge": "Zq8WsX3eDcVfR5tGbNhY7uJmI2kOl9pA6sD4fG1hJ0K"},
]

var rng := RandomNumberGenerator.new()

## Fase 2
var expected_state := ""
var decoy_states: Array = []
var aciertos := 0

## Fase 3
var pkce_index := -1


func start_states(count := 3) -> void:
	var pool := STATES.duplicate()
	pool.shuffle()
	expected_state = str(pool.pop_back())
	decoy_states = []
	for i in maxi(0, count - 1):
		decoy_states.append(str(pool.pop_back()))


## Valores que mostrarán las copias, ya mezclados.
func state_options() -> Array:
	var out := decoy_states.duplicate()
	out.append(expected_state)
	out.shuffle()
	return out


## Devuelve "correct" (era la legítima) o "wrong" (una copia).
func hit_state(value: String) -> String:
	if value == expected_state:
		aciertos += 1
		return "correct"
	return "wrong"


func start_pkce(avoid := -1) -> int:
	var idx := rng.randi_range(0, PKCE.size() - 1)
	if idx == avoid:
		idx = (idx + 1) % PKCE.size()
	pkce_index = idx
	return idx


func challenge() -> String:
	return str(PKCE[pkce_index].challenge)


func verifier() -> String:
	return str(PKCE[pkce_index].verifier)


## Opciones de verifier (el correcto y dos señuelos), mezcladas.
func verifier_options() -> Array:
	var out := [verifier()]
	for i in PKCE.size():
		if i != pkce_index and out.size() < 3:
			out.append(str(PKCE[i].verifier))
	out.shuffle()
	return out


func hit_verifier(value: String) -> String:
	return "correct" if value == verifier() else "wrong"
