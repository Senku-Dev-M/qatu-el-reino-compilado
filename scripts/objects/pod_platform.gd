class_name PodPlatform
extends StaticBody2D
## Pod desplegado por la habilidad Contenedor: una plataforma de un sentido que
## existe unos segundos. Pertenece al grupo "pod" para que los nodos de
## despliegue (pod_launcher) lo detecten.

const WIDTH := 128.0
const THICK := 20.0

var ttl := 3.5
var life := 0.0
var shape_node: CollisionShape2D


func _ready() -> void:
	add_to_group("pod")
	collision_layer = 1
	collision_mask = 0
	z_index = 3
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, THICK)
	shape_node.shape = shape
	shape_node.position = Vector2(0, THICK * 0.5)
	shape_node.one_way_collision = true
	add_child(shape_node)
	FX.burst(get_parent(), global_position, Color(0.5, 1.6, 2.6), 14, 260.0, 0.35, 0.3, Vector2.ZERO)


func remaining() -> float:
	return maxf(0.0, ttl - life)


func _physics_process(delta: float) -> void:
	life += delta
	if life >= ttl:
		FX.burst(get_parent(), global_position, Color(0.5, 1.6, 2.6), 10, 200.0, 0.3, 0.3, Vector2.ZERO)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var left := remaining()
	var blink := left < 1.0 and int(life * 12.0) % 2 == 0
	var a := 0.45 if blink else 1.0
	var col := Color(0.5, 1.7, 2.6, a)
	var body := Rect2(-WIDTH * 0.5, 0, WIDTH, 36)
	draw_rect(body, Color(0.05, 0.1, 0.16, 0.92 * a))
	draw_rect(body, col, false, 2.0)
	draw_rect(Rect2(body.position, Vector2(WIDTH, 5)), col)
	for i in 5:
		var x := -WIDTH * 0.5 + 14 + i * 25
		draw_line(Vector2(x, 9), Vector2(x, 32), Color(col, 0.35 * a), 3.0)
	var font := UITheme.mono_font()
	draw_string(font, Vector2(-WIDTH * 0.5, -8), "pod · %.1fs" % left, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col, 0.9 * a))
