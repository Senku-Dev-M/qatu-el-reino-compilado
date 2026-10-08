class_name FX
extends RefCounted
## Utilidades visuales compartidas: texturas de luz, partículas y efectos.

const TILE := 64

static var _dot: GradientTexture2D
static var _light: GradientTexture2D
static var _flash_shader: Shader


static func dot_texture() -> GradientTexture2D:
	if _dot == null:
		_dot = _radial(32, [0.0, 0.45, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	return _dot


static func light_texture() -> GradientTexture2D:
	if _light == null:
		_light = _radial(256, [0.0, 0.35, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	return _light


static func _radial(size: int, offsets: Array, colors: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = load("res://shaders/flash.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	return m


static func make_light(color: Color, scale: float, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = color
	l.texture_scale = scale
	l.energy = energy
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.add_to_group("light_source")
	return l


static func fade_gradient() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	return g


## Estallido de partículas de un solo uso.
static func burst(parent: Node, pos: Vector2, color: Color, amount := 16, speed := 380.0, lifetime := 0.5, size := 0.35, gravity := Vector2(0, 700), direction := Vector2.ZERO, spread := 180.0) -> CPUParticles2D:
	if parent == null or not parent.is_inside_tree():
		return null
	var p := CPUParticles2D.new()
	p.texture = dot_texture()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.direction = direction if direction != Vector2.ZERO else Vector2.UP
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.damping_min = 80.0
	p.damping_max = 200.0
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	p.color = color
	p.color_ramp = fade_gradient()
	p.z_index = 30
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func dust(parent: Node, pos: Vector2, amount := 8) -> void:
	burst(parent, pos, Color(0.75, 0.8, 0.8, 0.5), amount, 160.0, 0.45, 0.5, Vector2(0, -60), Vector2.UP, 70.0)


## Texto flotante (p. ej. "+12").
static func popup_text(parent: Node, pos: Vector2, text: String, color := Color(1.6, 1.4, 0.7)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	l.z_index = 60
	parent.add_child(l)
	l.global_position = pos - Vector2(40, 20)
	var tw := l.create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)


static func hdr(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)
