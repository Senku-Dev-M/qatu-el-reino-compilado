class_name RichFormat
extends RefCounted
## Convierte el texto de las lecciones a BBCode y colorea código.
##
## Marcas en el contenido:
##   [[término]] o [[texto visible|id]]  → término del glosario resaltado
##   **negrita**                          → negrita
##   `código`                             → código en línea

const TERM_COLOR := "#f2c46b"
const CODE_COLOR := "#8fe3d6"

const C_TAG := "#7fd3ff"
const C_ATTR := "#f2c46b"
const C_STRING := "#a8e07a"
const C_PUNCT := "#9aa4ad"
const C_COMMENT := "#6f7a80"
const C_KEYWORD := "#d8a2ff"
const C_NUMBER := "#ffb27a"
const C_PROP := "#7fd3ff"
const C_TEXT := "#e8e4da"

const JS_KEYWORDS := ["const", "let", "var", "function", "return", "if", "else", "for", "while", "new", "true", "false", "null", "undefined", "this", "document", "console", "window", "event"]

static var _term_re: RegEx
static var _bold_re: RegEx
static var _code_re: RegEx


static func _init_regex() -> void:
	if _term_re != null:
		return
	_term_re = RegEx.create_from_string("\\[\\[([^\\]|]+)(?:\\|([^\\]]+))?\\]\\]")
	_bold_re = RegEx.create_from_string("\\*\\*(.+?)\\*\\*")
	_code_re = RegEx.create_from_string("`([^`]+)`")


static func escape(s: String) -> String:
	return s.replace("[", "[lb]")


## Identificador normalizado de un término del glosario.
static func term_id(text: String) -> String:
	var t := text.strip_edges().to_lower()
	var map := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u", "ñ": "n"}
	for k in map.keys():
		t = t.replace(k, map[k])
	return t.replace(" ", "_").replace("-", "_")


static func glossary_ids(text: String) -> Array:
	_init_regex()
	var out := []
	for m in _term_re.search_all(text):
		var id: String = term_id(m.get_string(2) if m.get_string(2) != "" else m.get_string(1))
		if not (id in out):
			out.append(id)
	return out


## Texto de lección → BBCode.
static func lesson_text(text: String) -> String:
	_init_regex()
	var terms := []
	var codes := []
	# Extraer marcas antes de escapar corchetes.
	var result := ""
	var last := 0
	for m in _term_re.search_all(text):
		result += text.substr(last, m.get_start() - last)
		terms.append(m.get_string(1))
		result += "%d" % (terms.size() - 1)
		last = m.get_end()
	result += text.substr(last)
	var tmp := ""
	last = 0
	for m in _code_re.search_all(result):
		tmp += result.substr(last, m.get_start() - last)
		codes.append(m.get_string(1))
		tmp += "%d" % (codes.size() - 1)
		last = m.get_end()
	tmp += result.substr(last)
	result = escape(tmp)
	result = _bold_re.sub(result, "[b]$1[/b]", true)
	for i in codes.size():
		result = result.replace("%d" % i, "[color=%s][code]%s[/code][/color]" % [CODE_COLOR, escape(codes[i])])
	for i in terms.size():
		result = result.replace("%d" % i, "[color=%s][u]%s[/u][/color]" % [TERM_COLOR, escape(terms[i])])
	return result


## Código coloreado con números de línea.
static func code(src: String, lang: String, line_numbers := true, highlight_line := -1) -> String:
	var lines := src.split("\n")
	var out := PackedStringArray()
	var in_comment := false
	for i in lines.size():
		var colored := ""
		match lang:
			"html": colored = _html_line(lines[i])
			"css": colored = _css_line(lines[i])
			"js": colored = _js_line(lines[i])
			_: colored = "[color=%s]%s[/color]" % [C_TEXT, escape(lines[i])]
		var prefix := ("[color=%s]%2d  [/color]" % [C_COMMENT, i + 1]) if line_numbers else ""
		if i == highlight_line:
			colored = "[bgcolor=#4a1f25]" + colored + "[/bgcolor]"
		out.append(prefix + colored)
	return "\n".join(out)


## Panel de código listo para añadir a la interfaz.
static func code_panel(src: String, lang: String, highlight := -1, font_size := 23) -> PanelContainer:
	var pc := PanelContainer.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.03, 0.04, 0.05, 0.98)
	csb.border_color = Color(0.3, 0.8, 0.75, 0.45)
	csb.border_width_left = 4
	csb.set_corner_radius_all(4)
	csb.set_content_margin_all(18)
	pc.add_theme_stylebox_override("panel", csb)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	# Las líneas largas se ajustan al ancho disponible en vez de ensanchar la
	# ventana (antes desbordaban la lección por la derecha). La numeración va
	# en su propia columna para que la continuación quede alineada con el código.
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_override("normal_font", UITheme.mono_font())
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_constant_override("table_h_separation", 0)
	r.add_theme_constant_override("table_v_separation", 2)
	r.text = code_table(src, lang, highlight)
	pc.add_child(r)
	return pc


## Código coloreado como tabla de dos columnas (número | línea) para que las
## líneas largas se ajusten con sangría colgante.
static func code_table(src: String, lang: String, highlight_line := -1) -> String:
	var lines := src.split(char(10))
	var out := PackedStringArray(["[table=2]"])
	for i in lines.size():
		var colored := ""
		match lang:
			"html": colored = _html_line(lines[i])
			"css": colored = _css_line(lines[i])
			"js": colored = _js_line(lines[i])
			_: colored = "[color=%s]%s[/color]" % [C_TEXT, escape(lines[i])]
		if lines[i].strip_edges() == "":
			colored = " "
		if i == highlight_line:
			colored = "[bgcolor=#4a1f25]" + colored + "[/bgcolor]"
		out.append("[cell][color=%s]%2d  [/color][/cell][cell expand=1]%s[/cell]" % [C_COMMENT, i + 1, colored])
	out.append("[/table]")
	return "".join(out)


## Texto de lección listo para añadir a la interfaz.
static func text_label(bbcode: String, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_override("normal_font", UITheme.body_font())
	r.add_theme_font_override("bold_font", UITheme.bold_font())
	r.add_theme_font_override("mono_font", UITheme.mono_font())
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("mono_font_size", size - 6)
	r.add_theme_color_override("default_color", UITheme.TEXT)
	r.add_theme_constant_override("line_separation", 6)
	r.text = bbcode
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


static func _span(text: String, color: String) -> String:
	if text == "":
		return ""
	return "[color=%s]%s[/color]" % [color, escape(text)]


static func _html_line(line: String) -> String:
	var out := ""
	var i := 0
	var n := line.length()
	while i < n:
		if line.substr(i, 4) == "<!--":
			var end := line.find("-->", i)
			end = n if end == -1 else end + 3
			out += _span(line.substr(i, end - i), C_COMMENT)
			i = end
		elif line[i] == "<":
			var end := line.find(">", i)
			if end == -1:
				end = n - 1
			var tag := line.substr(i, end - i + 1)
			out += _html_tag(tag)
			i = end + 1
		else:
			var next := line.find("<", i)
			if next == -1:
				next = n
			out += _span(line.substr(i, next - i), C_TEXT)
			i = next
	return out


static func _html_tag(tag: String) -> String:
	var out := ""
	var re := RegEx.create_from_string("^(</?!?)([A-Za-z0-9]*)(.*?)(/?>?)$")
	var m := re.search(tag)
	if m == null:
		return _span(tag, C_TAG)
	out += _span(m.get_string(1), C_PUNCT)
	out += _span(m.get_string(2), C_TAG)
	var attrs := m.get_string(3)
	var attr_re := RegEx.create_from_string("(\\s+)([A-Za-z_:-]+)(=)?(\"[^\"]*\"|'[^']*')?")
	var last := 0
	for a in attr_re.search_all(attrs):
		out += _span(attrs.substr(last, a.get_start() - last), C_TEXT)
		out += escape(a.get_string(1))
		out += _span(a.get_string(2), C_ATTR)
		out += _span(a.get_string(3), C_PUNCT)
		out += _span(a.get_string(4), C_STRING)
		last = a.get_end()
	out += _span(attrs.substr(last), C_TEXT)
	out += _span(m.get_string(4), C_PUNCT)
	return out


static func _css_line(line: String) -> String:
	var trimmed := line.strip_edges()
	if trimmed.begins_with("/*"):
		return _span(line, C_COMMENT)
	var colon := line.find(":")
	if line.contains("{") or line.strip_edges() == "}" or colon == -1:
		# Selector o llave.
		var out := ""
		for ch in line:
			out += _span(ch, C_PUNCT if ch in "{}" else C_ATTR)
		return out
	var prop := line.substr(0, colon)
	var value := line.substr(colon + 1)
	var semi := value.find(";")
	var tail := ""
	if semi != -1:
		tail = value.substr(semi)
		value = value.substr(0, semi)
	return _span(prop, C_PROP) + _span(":", C_PUNCT) + _span(value, C_STRING) + _span(tail, C_PUNCT)


## Posición de un comentario // que no esté dentro de una cadena, o -1.
static func _js_comment_start(line: String) -> int:
	var quote := ""
	var i := 0
	while i < line.length() - 1:
		var ch := line[i]
		if quote != "":
			if ch == "\\":
				i += 1
			elif ch == quote:
				quote = ""
		elif ch == "'" or ch == "\"" or ch == "`":
			quote = ch
		elif ch == "/" and line[i + 1] == "/":
			return i
		i += 1
	return -1


static func _js_line(line: String) -> String:
	var comment := _js_comment_start(line)
	var code_part := line if comment == -1 else line.substr(0, comment)
	var out := ""
	var re := RegEx.create_from_string("('[^']*'|\"[^\"]*\"|`[^`]*`|\\b\\d+(?:\\.\\d+)?\\b|\\b[A-Za-z_$][A-Za-z0-9_$]*\\b|\\s+|.)")
	for m in re.search_all(code_part):
		var tok := m.get_string()
		if tok.begins_with("'") or tok.begins_with("\"") or tok.begins_with("`"):
			out += _span(tok, C_STRING)
		elif tok.is_valid_float():
			out += _span(tok, C_NUMBER)
		elif tok in JS_KEYWORDS:
			out += _span(tok, C_KEYWORD)
		elif tok.strip_edges() == "":
			out += tok
		elif tok.length() == 1 and not tok.is_valid_identifier():
			out += _span(tok, C_PUNCT)
		else:
			out += _span(tok, C_TEXT if not code_part.substr(m.get_end(), 1) == "(" else C_TAG)
	if comment != -1:
		out += _span(line.substr(comment), C_COMMENT)
	return out
