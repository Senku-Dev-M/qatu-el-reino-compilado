class_name FlexLayout
extends RefCounted
## Cálculo de posiciones siguiendo las reglas de CSS Flexbox y Grid.
## Lo usan la habilidad Flex del mundo, las vistas previas de las lecciones
## y el examen del Guardián del Parcial, para que todo coincida con CSS real.

const JUSTIFY := ["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]
const ALIGN := ["flex-start", "center", "flex-end", "stretch"]


## Posición inicial de cada elemento en el eje principal (justify-content).
static func justify(container: float, sizes: Array, value: String, gap := 0.0) -> Array:
	var n := sizes.size()
	var out := []
	if n == 0:
		return out
	var used := 0.0
	for s in sizes:
		used += float(s)
	used += gap * (n - 1)
	var free := container - used
	var start := 0.0
	var between := gap
	if free >= 0.0:
		match value:
			"flex-end", "end":
				start = free
			"center":
				start = free * 0.5
			"space-between":
				if n > 1:
					between = gap + free / (n - 1)
			"space-around":
				start = free / n * 0.5
				between = gap + free / n
			"space-evenly":
				start = free / (n + 1)
				between = gap + free / (n + 1)
	var pos := start
	for s in sizes:
		out.append(pos)
		pos += float(s) + between
	return out


## Posición en el eje transversal (align-items) y tamaño resultante.
## Devuelve Vector2(offset, tamaño).
static func align(cross: float, size: float, value: String) -> Vector2:
	match value:
		"flex-end", "end":
			return Vector2(cross - size, size)
		"center":
			return Vector2((cross - size) * 0.5, size)
		"stretch":
			return Vector2(0.0, cross)
	return Vector2(0.0, size)


## Reparte el espacio libre según flex-grow. bases = flex-basis de cada elemento.
static func grow(container: float, bases: Array, grows: Array, gap := 0.0) -> Array:
	var used := gap * (bases.size() - 1)
	var total_grow := 0.0
	for i in bases.size():
		used += float(bases[i])
		total_grow += float(grows[i]) if i < grows.size() else 0.0
	var free := maxf(0.0, container - used)
	var out := []
	for i in bases.size():
		var g := float(grows[i]) if i < grows.size() else 0.0
		out.append(float(bases[i]) + (free * g / total_grow if total_grow > 0.0 else 0.0))
	return out


## Agrupa elementos en líneas con flex-wrap: wrap. Devuelve arrays de índices.
static func wrap_lines(container: float, sizes: Array, gap := 0.0) -> Array:
	var lines := []
	var line := []
	var width := 0.0
	for i in sizes.size():
		var s := float(sizes[i])
		var needed := s if line.is_empty() else width + gap + s
		if not line.is_empty() and needed > container:
			lines.append(line)
			line = [i]
			width = s
		else:
			line.append(i)
			width = needed
	if not line.is_empty():
		lines.append(line)
	return lines


## Expande una definición de pistas de Grid: "repeat(3, 1fr)", "200px 1fr", ["1fr", "2fr"].
static func expand_tracks(defs: Variant) -> Array:
	var parts: Array = []
	if defs is Array:
		for d in defs:
			parts.append_array(expand_tracks(str(d)))
		return parts
	var text := str(defs).strip_edges()
	var re := RegEx.create_from_string("repeat\\(\\s*(\\d+)\\s*,\\s*([^)]+)\\)")
	var m := re.search(text)
	while m:
		var inner := PackedStringArray()
		for k in int(m.get_string(1)):
			inner.append(m.get_string(2).strip_edges())
		text = text.substr(0, m.get_start()) + " ".join(inner) + text.substr(m.get_end())
		m = re.search(text)
	for token in text.split(" ", false):
		parts.append(token)
	return parts


## Tamaño de cada pista de Grid: px fijos y fr repartiendo el espacio restante.
static func grid_tracks(defs: Variant, container: float, gap := 0.0) -> Array:
	var tracks := expand_tracks(defs)
	var fixed := gap * maxi(0, tracks.size() - 1)
	var fr_total := 0.0
	for t in tracks:
		if str(t).ends_with("fr"):
			fr_total += str(t).trim_suffix("fr").to_float()
		else:
			fixed += str(t).trim_suffix("px").to_float()
	var free := maxf(0.0, container - fixed)
	var out := []
	for t in tracks:
		if str(t).ends_with("fr"):
			out.append(free * str(t).trim_suffix("fr").to_float() / fr_total if fr_total > 0.0 else 0.0)
		else:
			out.append(str(t).trim_suffix("px").to_float())
	return out
