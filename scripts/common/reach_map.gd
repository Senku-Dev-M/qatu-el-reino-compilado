class_name ReachMap
extends RefCounted
## Mapa de alcanzabilidad de una sala con los limites reales del jugador:
## capsula de 76 px (cabe en 2 filas), salto de 185 px (2 filas como maximo) y
## hueco horizontal de 4 tiles. Sirve para comprobar que todo lo obligatorio se
## puede alcanzar solo caminando y saltando, sin habilidades ni trucos.

const MAX_UP := 2
const MAX_GAP := 4
## Cuanto se avanza segun las filas que se suben, medido ejecutando los saltos
## con la fisica real (test_new_zone_routes): a plena carrera el salto llega a
## ~3,8 tiles si sube 2 filas, asi que 4 se queda corto por poco. Aqui se
## describe lo que SE PUEDE hacer; el reparador de salas (tools/fix_reach.py)
## usa una envolvente mas estrecha para que los saltos no queden al milimetro.
## Indice = filas que se suben.
const REACH := [4, 4, 3]
## Envolvente comoda con la que se disenan las salas (tools/fix_reach.py): deja
## margen para que ningun salto obligatorio quede al milimetro.
const REACH_COMODA := [4, 3, 2]
const HOOK_TILES := 6.0

## Entidades que el jugador tiene que poder alcanzar si o si.
const REQUIRED := ["door", "tablilla", "sello", "bench", "npc", "pickup", "portal", "boss", "shop"]

## Envolvente en uso. Por defecto la fisica real; ponla en REACH_COMODA para
## trazar rutas con margen.
var reach: Array = REACH

var rows: PackedStringArray
var legend: Dictionary
var w := 0
var h := 0


func load_room(room) -> ReachMap:
	rows = room.layout()
	legend = room.legend()
	h = rows.size()
	w = rows[0].length() if h > 0 else 0
	return self


func ch(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return rows[y][x]


func solid(x: int, y: int) -> bool:
	return ch(x, y) == "#"


func hazard(x: int, y: int) -> bool:
	return ch(x, y) == "^"


## Se puede estar de pie con los pies en la fila y.
func stand(x: int, y: int) -> bool:
	if y <= 1 or y >= h:
		return false
	if not (solid(x, y) or ch(x, y) == "="):
		return false
	for dy in [1, 2]:
		if solid(x, y - dy) or hazard(x, y - dy):
			return false
	return true


func body_free(x: int, y: int) -> bool:
	return not (solid(x, y - 1) or solid(x, y - 2))


func fall_to(cx: int, from_y: int) -> int:
	for yy in range(from_y, h):
		if stand(cx, yy):
			return yy
		if solid(cx, yy):
			return -1
	return -1


func neighbours(x: int, y: int) -> Array:
	var out := []
	for dx in [-1, 1]:
		for dy in [0, -1, 1]:
			if stand(x + dx, y + dy) and body_free(x + dx, y + dy):
				out.append(Vector2i(x + dx, y + dy))
	for dy in range(1, MAX_UP + 1):
		var span: int = reach[dy]
		for dx in range(-span, span + 1):
			var tx := x + dx
			var ty := y - dy
			if not (stand(tx, ty) and body_free(tx, ty)):
				continue
			# Para subirse a una cornisa solida hace falta separacion: pegado a
			# su pared el salto choca de lado en vez de coronarla.
			if solid(tx, ty) and absi(dx) < 2:
				continue
			var clear := true
			for xi in range(mini(x, tx), maxi(x, tx) + 1):
				if solid(xi, ty - 1) or solid(xi, ty - 2):
					clear = false
					break
			# Las columnas intermedias tienen que estar libres entre las dos
			# alturas: si no, el jugador choca de lado con la cornisa en vez de
			# subirse encima.
			for xi in range(mini(x, tx) + 1, maxi(x, tx)):
				for yy in range(ty, y):
					if solid(xi, yy):
						clear = false
						break
				if not clear:
					break
			if clear:
				out.append(Vector2i(tx, ty))
	for dx in range(-MAX_GAP, MAX_GAP + 1):
		if dx == 0:
			continue
		var tx := x + dx
		var clear := true
		for xi in range(mini(x, tx), maxi(x, tx) + 1):
			if not body_free(xi, y):
				clear = false
				break
		if not clear:
			continue
		var land := fall_to(tx, y)
		if land >= 0:
			out.append(Vector2i(tx, land))
	return out


## Todas las entidades de la sala como [{"type", "id", "x", "y"}].
func entities() -> Array:
	var out := []
	for y in h:
		for x in w:
			var c := ch(x, y)
			if legend.has(c):
				var d: Dictionary = legend[c]
				out.append({
					"type": str(d.get("type", "")),
					"id": str(d.get("id", d.get("kind", ""))),
					"x": x, "y": y,
				})
	return out


## Origenes agrupados por puerta: cada entrada se comprueba por separado,
## porque una sala puede ser transitable solo en un sentido.
func door_entries() -> Array:
	var groups := []
	for e in entities():
		if e.type != "door":
			continue
		var g := []
		for dx in [0, 1, -1, 2, -2]:
			var y: int = fall_to(int(e.x) + dx, int(e.y))
			if y >= 0:
				g.append(Vector2i(int(e.x) + dx, y))
		if not g.is_empty():
			groups.append({"id": e.id, "spots": g})
	if groups.is_empty():
		groups.append({"id": "suelo", "spots": _entry_spots()})
	return groups


func _entry_spots() -> Array:
	var out := []
	for e in entities():
		if e.type == "door":
			for dx in [0, 1, -1, 2, -2]:
				var y: int = fall_to(int(e.x) + dx, int(e.y))
				if y >= 0:
					out.append(Vector2i(int(e.x) + dx, y))
	if out.is_empty():
		# Salas sin puertas (el hub): se parte del suelo principal.
		var ground := -1
		for x in w:
			var y := fall_to(x, 1)
			if y > ground:
				ground = y
		for x in w:
			if stand(x, ground):
				out.append(Vector2i(x, ground))
	return out


## Posiciones alcanzables desde las puertas, como diccionario {y*1000+x: true}.
func reachable(origins := []) -> Dictionary:
	var seen := {}
	var queue := []
	for s in (origins if not origins.is_empty() else _entry_spots()):
		if stand(s.x, s.y):
			seen[s.y * 1000 + s.x] = true
			queue.append(s)
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for n in neighbours(cur.x, cur.y):
			var k: int = n.y * 1000 + n.x
			if not seen.has(k):
				seen[k] = true
				queue.append(n)
	return seen


## Entidades obligatorias a las que no se puede llegar. Devuelve etiquetas.
func unreachable_required(origins := []) -> Array:
	var seen := reachable(origins)
	var bad := []
	for e in entities():
		if not (e.type in REQUIRED):
			continue
		var ok := false
		for dy in [1, 2, 0]:
			if seen.has((int(e.y) + dy) * 1000 + int(e.x)):
				ok = true
				break
		if not ok:
			bad.append("%s %s (%d,%d)" % [e.type, e.id, e.x, e.y])
	return bad


## Camino de posiciones de pie entre dos puntos, o [] si no existe.
func path(from: Vector2i, to: Vector2i) -> Array:
	if not stand(from.x, from.y):
		return []
	var prev := {}
	var seen := {from.y * 1000 + from.x: true}
	var queue := [from]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == to:
			var out := [cur]
			while prev.has(out[0].y * 1000 + out[0].x):
				out.push_front(prev[out[0].y * 1000 + out[0].x])
			return out
		for n in neighbours(cur.x, cur.y):
			var k: int = n.y * 1000 + n.x
			if not seen.has(k):
				seen[k] = true
				prev[k] = cur
				queue.append(n)
	return []


## Posicion de pie mas cercana a un tile dado (para fijar destinos).
func nearest_stand(x: int, y: int) -> Vector2i:
	for dy in [1, 2, 0, 3]:
		if stand(x, y + dy):
			return Vector2i(x, y + dy)
	return Vector2i(x, -1)
