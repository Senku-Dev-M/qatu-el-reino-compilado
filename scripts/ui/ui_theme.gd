class_name UITheme
extends RefCounted
## Tema visual de la interfaz: fuentes Cinzel (títulos) y EB Garamond
## (texto), paneles oscuros con filete dorado.

const TEXT := Color(0.9, 0.88, 0.82)
const DIM := Color(0.6, 0.6, 0.58)
const GOLD := Color(0.93, 0.78, 0.45)
const CYAN := Color(0.55, 0.95, 0.9)
const RED := Color(0.95, 0.45, 0.45)
const PANEL := Color(0.015, 0.02, 0.03, 0.94)
const BORDER := Color(0.85, 0.75, 0.5, 0.55)

static var _theme: Theme
static var _title_font: FontVariation
static var _body_font: FontVariation
static var _mono_font: SystemFont
static var _bold_font: FontVariation


static func title_font() -> Font:
	if _title_font == null:
		_title_font = FontVariation.new()
		_title_font.base_font = load("res://fonts/Cinzel.ttf")
		_title_font.variation_opentype = {"wght": 600}
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = FontVariation.new()
		_body_font.base_font = load("res://fonts/EBGaramond.ttf")
		_body_font.variation_opentype = {"wght": 450}
	return _body_font


## Negrita del texto de lectura. EB Garamond no es una fuente variable, así que
## `variation_opentype` no engrosa nada: hay que usar el engrosado sintético.
static func bold_font() -> Font:
	if _bold_font == null:
		_bold_font = FontVariation.new()
		_bold_font.base_font = load("res://fonts/EBGaramond.ttf")
		_bold_font.variation_embolden = 0.55
	return _bold_font


static func mono_font() -> Font:
	if _mono_font == null:
		_mono_font = SystemFont.new()
		_mono_font.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "Courier New", "monospace"])
	return _mono_font


static func panel_style(alpha := 0.94, border := BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PANEL, alpha)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(28)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 18
	return sb


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 30
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.7))

	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.05, 0.06, 0.07, 0.85)
	btn.border_color = Color(0.5, 0.48, 0.4, 0.5)
	btn.set_border_width_all(1)
	btn.set_corner_radius_all(3)
	btn.content_margin_left = 22
	btn.content_margin_right = 22
	btn.content_margin_top = 10
	btn.content_margin_bottom = 10
	var btn_focus := btn.duplicate()
	btn_focus.bg_color = Color(0.14, 0.12, 0.07, 0.95)
	btn_focus.border_color = GOLD
	btn_focus.set_border_width_all(2)
	var btn_disabled := btn.duplicate()
	btn_disabled.bg_color = Color(0.03, 0.03, 0.03, 0.6)
	for state in ["normal", "pressed"]:
		t.set_stylebox(state, "Button", btn)
	t.set_stylebox("hover", "Button", btn_focus)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_stylebox("hover_pressed", "Button", btn_focus)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.4))
	t.set_font_size("font_size", "Button", 28)

	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())

	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = Color(0.1, 0.09, 0.06, 0.95)
	tab_sel.border_color = GOLD
	tab_sel.border_width_bottom = 3
	tab_sel.set_content_margin_all(14)
	var tab_un := tab_sel.duplicate()
	tab_un.bg_color = Color(0.03, 0.03, 0.04, 0.9)
	tab_un.border_color = Color(0.4, 0.4, 0.4, 0.4)
	t.set_stylebox("tab_selected", "TabContainer", tab_sel)
	t.set_stylebox("tab_unselected", "TabContainer", tab_un)
	t.set_stylebox("tab_hovered", "TabContainer", tab_sel)
	t.set_stylebox("tab_focus", "TabContainer", tab_sel)
	t.set_stylebox("panel", "TabContainer", panel_style(0.0, Color(0, 0, 0, 0)))
	t.set_font("font", "TabContainer", title_font())
	t.set_font_size("font_size", "TabContainer", 26)
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", DIM)

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.02, 0.025, 0.03, 0.8)
	list_bg.set_content_margin_all(8)
	t.set_stylebox("panel", "ItemList", list_bg)
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	var sel := StyleBoxFlat.new()
	sel.bg_color = Color(0.18, 0.15, 0.08, 0.9)
	sel.border_color = GOLD
	sel.border_width_left = 3
	t.set_stylebox("selected", "ItemList", sel)
	t.set_stylebox("selected_focus", "ItemList", sel)
	t.set_stylebox("cursor", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("cursor_unfocused", "ItemList", StyleBoxEmpty.new())
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", GOLD)
	t.set_font_size("font_size", "ItemList", 28)
	t.set_constant("v_separation", "ItemList", 10)

	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.3, 0.3, 0.3)
	slider.content_margin_top = 4
	slider.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", slider)
	var fill := slider.duplicate()
	fill.bg_color = GOLD
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	_theme = t
	return t


static func label(text: String, size := 30, color := TEXT, title := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", title_font())
	return l


## Separador ornamental estilo grabado.
static func ornament(width := 520.0, color := GOLD) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 24)
	c.draw.connect(func():
		var mid := c.size * 0.5
		var hw := minf(width, c.size.x) * 0.5
		c.draw_line(Vector2(mid.x - hw, mid.y), Vector2(mid.x - 18, mid.y), Color(color, 0.7), 2.0, true)
		c.draw_line(Vector2(mid.x + 18, mid.y), Vector2(mid.x + hw, mid.y), Color(color, 0.7), 2.0, true)
		c.draw_colored_polygon(PackedVector2Array([mid + Vector2(-12, 0), mid + Vector2(0, -9), mid + Vector2(12, 0), mid + Vector2(0, 9)]), color)
		c.draw_circle(Vector2(mid.x - hw, mid.y), 3.0, color)
		c.draw_circle(Vector2(mid.x + hw, mid.y), 3.0, color))
	return c


static func center_panel(min_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	return p
