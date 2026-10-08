extends Node
## Carga el contenido educativo desde res://content/<zona>/*.json.
## Nada del texto educativo vive en el código.
##
## Cada archivo pertenece a una tabla según su nombre: "lecciones_raiz.json"
## y "lecciones_claro.json" se cargan en la tabla "lecciones".

const ROOT := "res://content/"
const MAX_PAGE_TEXT := 900
const TABLES := ["zonas", "lecciones", "glosario", "guia", "sellos", "bestiario", "amuletos", "habilidades", "dialogos", "tienda", "armas", "vestimentas"]
const PAGE_TYPES := ["concepto", "sintaxis", "resultado", "errores", "comprueba"]
const RETO_TYPES := ["elegir", "completar", "encontrar_error", "ordenar"]
const BLOCK_TYPES := ["h1", "h2", "p", "a", "img", "img_rota", "ul", "ol", "boton", "texto", "caja", "consola", "arbol", "panel", "nota", "error", "separador", "flex", "grid", "responsive", "flujo", "campo", "fieldset", "peticion", "secuencia", "red", "tabla", "paginacion", "esqueleto"]

var tables := {}  # tabla → { id → Dictionary }
var load_errors: Array[String] = []


func _ready() -> void:
	reload()


func reload() -> void:
	tables.clear()
	load_errors.clear()
	for tb in TABLES:
		tables[tb] = {}
	for dir_name in DirAccess.get_directories_at(ROOT):
		var dir := ROOT + dir_name + "/"
		var files := Array(DirAccess.get_files_at(dir))
		files.sort()
		for f in files:
			if not f.ends_with(".json"):
				continue
			var table: String = f.get_basename().split("_")[0]
			if not tables.has(table):
				continue
			_load_file(dir + f, table)


func _load_file(path: String, table: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		_error("%s: JSON inválido en línea %d (%s)" % [path, json.get_error_line(), json.get_error_message()])
		return
	if not json.data is Array:
		_error("%s: se esperaba una lista" % path)
		return
	for entry in json.data:
		if not entry is Dictionary or not entry.has("id"):
			_error("%s: entrada sin id" % path)
			continue
		if tables[table].has(entry.id):
			_error("%s: id duplicado '%s'" % [path, entry.id])
		tables[table][entry.id] = entry


func _error(msg: String) -> void:
	load_errors.append(msg)
	push_error("[ContentDB] " + msg)


func _lookup(table: String, id: String) -> Dictionary:
	var entry: Dictionary = tables.get(table, {}).get(id, {})
	if entry.is_empty() and id != "" and not Engine.is_editor_hint():
		push_warning("[ContentDB] Contenido no encontrado: %s/%s" % [table, id])
	return entry


func zona(zone: int) -> Dictionary: return _lookup("zonas", "z%d" % zone)
func leccion(id: String) -> Dictionary: return _lookup("lecciones", id)
func tablilla(id: String) -> Dictionary: return _lookup("lecciones", id)
func termino(id: String) -> Dictionary: return _lookup("glosario", id)
func guia(room_id: String) -> Dictionary: return _lookup("guia", room_id)
func sello(id: String) -> Dictionary: return _lookup("sellos", id)
func enemy(id: String) -> Dictionary: return _lookup("bestiario", id)
func amuleto(id: String) -> Dictionary: return _lookup("amuletos", id)
func habilidad(id: String) -> Dictionary: return _lookup("habilidades", id)
func arma(id: String) -> Dictionary: return _lookup("armas", id)
func vestimenta(id: String) -> Dictionary: return _lookup("vestimentas", id)


## Vestimentas en orden de zona (la base primero).
func vestimentas_ordenadas() -> Array:
	var out: Array = tables.vestimentas.values()
	out.sort_custom(func(a, b): return int(a.get("orden", 0)) < int(b.get("orden", 0)))
	return out


## Armas en orden de zona (el Cursor primero).
func armas_ordenadas() -> Array:
	var out: Array = tables.armas.values()
	out.sort_custom(func(a, b): return int(a.get("orden", 0)) < int(b.get("orden", 0)))
	return out
func tienda_item(id: String) -> Dictionary: return _lookup("tienda", id)


func dialogo(id: String) -> Array:
	var d := _lookup("dialogos", id)
	if d.is_empty():
		return ["[Diálogo no encontrado: %s]" % id]
	return d.lineas


func dialogo_speaker(id: String) -> String:
	return str(_lookup("dialogos", id).get("speaker", ""))


func _by_zone(table: String, zone: int) -> Array:
	var out := []
	for e in tables.get(table, {}).values():
		if int(e.get("zona", -1)) == zone:
			out.append(e)
	out.sort_custom(func(a, b): return str(a.id) < str(b.id))
	return out


## Lecciones de la zona en el orden del currículo.
func lecciones_de_zona(zone: int) -> Array:
	var out := _by_zone("lecciones", zone)
	out.sort_custom(func(a, b): return int(a.orden) < int(b.orden))
	return out


func lecciones_de_sala(room_id: String) -> Array:
	var out := []
	for l in tables.lecciones.values():
		if l.get("sala") == room_id:
			out.append(l)
	out.sort_custom(func(a, b): return int(a.orden) < int(b.orden))
	return out


func tablillas_de_zona(zone: int) -> Array: return lecciones_de_zona(zone)
func sellos_de_zona(zone: int) -> Array: return _by_zone("sellos", zone)
func enemigos_de_zona(zone: int) -> Array: return _by_zone("bestiario", zone)
func amuletos_de_zona(zone: int) -> Array: return _by_zone("amuletos", zone)


## Zonas con contenido, en orden de semana.
func zonas_ordenadas() -> Array:
	var out: Array = tables.zonas.values()
	out.sort_custom(func(a, b): return int(a.semana) < int(b.semana))
	return out


## Salas de una zona en el orden del currículo.
func salas_de_zona(zone: int) -> Array:
	return zona(zone).get("salas", [])


func glosario_ordenado() -> Array:
	var out: Array = tables.glosario.values()
	out.sort_custom(func(a, b): return str(a.termino).to_lower() < str(b.termino).to_lower())
	return out


## Índice (1..N) de la lección dentro de su sala y total de la sala.
func posicion_en_sala(id: String) -> Vector2i:
	var l := leccion(id)
	var list := lecciones_de_sala(str(l.get("sala", "")))
	for i in list.size():
		if list[i].id == id:
			return Vector2i(i + 1, list.size())
	return Vector2i(0, list.size())


func nombre_sala(room_id: String) -> String:
	return str(guia(room_id).get("nombre", room_id))


func tienda(shop: String) -> Array:
	var out := []
	for e in tables.tienda.values():
		if e.get("tienda") == shop:
			out.append(e)
	out.sort_custom(func(a, b): return int(a.precio) < int(b.precio))
	return out


func all_bestiary() -> Array:
	var out: Array = tables.bestiario.values()
	out.sort_custom(func(a, b): return int(a.get("zona", 0)) > int(b.get("zona", 0)) if a.get("zona") != b.get("zona") else str(a.id) < str(b.id))
	return out


## Términos del glosario citados en una lección ([[término]] o [[texto|id]]).
func terminos_de_leccion(id: String) -> Array:
	var found := []
	var l := leccion(id)
	for page in l.get("paginas", []):
		for t in RichFormat.glossary_ids(str(page.get("texto", ""))):
			if not (t in found):
				found.append(t)
	return found


## Reemplaza {accion} por la tecla configurada.
func format_text(text: String) -> String:
	var settings := get_node_or_null("/root/Settings")
	if settings == null:
		return text
	for action in settings.ACTIONS.keys():
		text = text.replace("{%s}" % action, "[%s]" % settings.key_name(action))
	return text


# --- Validación ------------------------------------------------------------------

func validate() -> Array[String]:
	var errors: Array[String] = load_errors.duplicate()
	_validate_lecciones(errors)
	_validate_glosario(errors)
	_validate_sellos(errors)
	for g in tables.guia.values():
		for field in ["nombre", "intro", "cierre"]:
			if not g.has(field):
				errors.append("guía %s: falta %s" % [g.id, field])
	for e in tables.bestiario.values():
		for field in ["nombre", "descripcion", "leccion"]:
			if str(e.get(field, "")) == "":
				errors.append("bestiario %s: falta %s" % [e.id, field])
		if int(e.get("derrotas_requeridas", 0)) < 1:
			errors.append("bestiario %s: derrotas_requeridas debe ser ≥ 1" % e.id)
	for a in tables.amuletos.values():
		if int(a.get("coste", 0)) < 1:
			errors.append("amuleto %s: coste inválido" % a.id)
	for item in tables.tienda.values():
		if item.get("tipo") == "amuleto" and not tables.amuletos.has(item.id):
			errors.append("tienda %s: amuleto inexistente" % item.id)
	for d in tables.dialogos.values():
		if not d.get("lineas") is Array or d.lineas.is_empty():
			errors.append("diálogo %s: sin líneas" % d.id)
	return errors


func _validate_lecciones(errors: Array[String]) -> void:
	var orders := {}
	for l in tables.lecciones.values():
		var id: String = l.id
		for field in ["titulo", "sala", "nivel", "resumen"]:
			if str(l.get(field, "")) == "":
				errors.append("lección %s: falta %s" % [id, field])
		if not (str(l.get("nivel", "")) in ["inicial", "intermedio"]):
			errors.append("lección %s: nivel debe ser inicial o intermedio" % id)
		if not tables.guia.has(str(l.get("sala", ""))):
			errors.append("lección %s: sala sin guía '%s'" % [id, l.get("sala", "")])
		var o := int(l.get("orden", -1))
		if orders.has(o):
			errors.append("lección %s: orden %d repetido con %s" % [id, o, orders[o]])
		orders[o] = id
		var pages: Array = l.get("paginas", [])
		if pages.size() < 3:
			errors.append("lección %s: necesita al menos 3 páginas" % id)
		var has_check := false
		for i in pages.size():
			var p: Dictionary = pages[i]
			var where := "lección %s página %d" % [id, i + 1]
			if not (str(p.get("tipo", "")) in PAGE_TYPES):
				errors.append("%s: tipo inválido '%s'" % [where, p.get("tipo", "")])
			if str(p.get("titulo", "")) == "":
				errors.append("%s: falta título" % where)
			if str(p.get("texto", "")).length() > MAX_PAGE_TEXT:
				errors.append("%s: texto de %d caracteres (máx %d)" % [where, str(p.texto).length(), MAX_PAGE_TEXT])
			if p.has("vista"):
				_validate_vista(p.vista, where, errors)
			for er in p.get("errores", []):
				if not (er.has("mal") and er.has("bien") and er.has("explicacion")):
					errors.append("%s: cada error necesita mal, bien y explicacion" % where)
			if p.get("tipo") == "comprueba":
				has_check = true
				_validate_question(p.get("pregunta", {}), where, errors)
		if not has_check:
			errors.append("lección %s: falta página de comprobación" % id)
		for t in terminos_de_leccion(id):
			if not tables.glosario.has(t):
				errors.append("lección %s: término de glosario inexistente '%s'" % [id, t])


func _validate_question(q: Dictionary, where: String, errors: Array[String]) -> void:
	var opts: Array = q.get("opciones", [])
	if str(q.get("enunciado", "")) == "":
		errors.append("%s: pregunta sin enunciado" % where)
	if opts.size() < 2 or opts.size() > 4:
		errors.append("%s: la pregunta necesita de 2 a 4 opciones" % where)
	var c := int(q.get("correcta", -1))
	if c < 0 or c >= opts.size():
		errors.append("%s: índice correcto fuera de rango" % where)
	if str(q.get("explicacion", "")) == "":
		errors.append("%s: la pregunta necesita explicación" % where)


func _validate_vista(v: Variant, where: String, errors: Array[String]) -> void:
	if not v is Dictionary or not v.get("bloques") is Array:
		errors.append("%s: vista sin bloques" % where)
		return
	for b in v.bloques:
		if not b is Dictionary or b.size() != 1 or not (b.keys()[0] in BLOCK_TYPES):
			errors.append("%s: bloque de vista inválido %s" % [where, str(b)])


func _validate_glosario(errors: Array[String]) -> void:
	for g in tables.glosario.values():
		for field in ["termino", "definicion", "leccion"]:
			if str(g.get(field, "")) == "":
				errors.append("glosario %s: falta %s" % [g.id, field])
		if not tables.lecciones.has(str(g.get("leccion", ""))):
			errors.append("glosario %s: lección inexistente %s" % [g.id, g.get("leccion", "")])


func _validate_sellos(errors: Array[String]) -> void:
	for s in tables.sellos.values():
		for lid in s.get("lecciones", []):
			if not tables.lecciones.has(lid):
				errors.append("sello %s: lección inexistente %s" % [s.id, lid])
		if str(s.get("pista", "")) == "":
			errors.append("sello %s: falta pista" % s.id)
		var retos: Array = s.get("retos", [])
		if retos.size() < 2:
			errors.append("sello %s: necesita al menos 2 retos" % s.id)
		for i in retos.size():
			var r: Dictionary = retos[i]
			var where := "sello %s reto %d" % [s.id, i + 1]
			var tipo := str(r.get("tipo", ""))
			if not (tipo in RETO_TYPES):
				errors.append("%s: tipo inválido '%s'" % [where, tipo])
				continue
			if str(r.get("enunciado", "")) == "" or str(r.get("explicacion", "")) == "":
				errors.append("%s: falta enunciado o explicación" % where)
			match tipo:
				"elegir":
					_validate_question(r, where, errors)
				"completar":
					if not str(r.get("codigo", "")).contains("___"):
						errors.append("%s: el código debe contener ___" % where)
					_validate_question(r, where, errors)
				"encontrar_error":
					var lines: Array = r.get("lineas", [])
					var c := int(r.get("correcta", -1))
					if lines.size() < 3 or c < 0 or c >= lines.size():
						errors.append("%s: necesita ≥3 líneas y un índice de línea con error válido" % where)
					if str(r.get("corregida", "")) == "":
						errors.append("%s: falta la línea corregida" % where)
				"ordenar":
					if r.get("lineas", []).size() < 3:
						errors.append("%s: necesita al menos 3 líneas para ordenar" % where)
			if r.has("vista"):
				_validate_vista(r.vista, where, errors)
