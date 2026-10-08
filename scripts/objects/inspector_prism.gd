class_name InspectorPrism
extends Area2D
## Prisma Inspector: Dispositivo interactivo que activa el modo de aserción y revela elementos ocultos.

@export var pulse_speed := 3.0
var active := false
var t := 0.0

func setup(_room: RoomBase, _def: Dictionary) -> void:
	pass

func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	cs.shape = rect
	cs.position = Vector2(0, -24)
	add_child(cs)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	t += delta * pulse_speed
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not active:
		active = true
		AudioManager.play_sfx("laser", 0.5)
		Events.camera_shake.emit(3.0, 0.2)

func _draw() -> void:
	var col := Color(0.3, 0.9, 1.2) if not active else Color(0.4, 1.4, 0.6)
	var glow := (sin(t) * 0.5 + 0.5) * 6.0
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -8), Vector2(0, -38), Vector2(16, -8), Vector2(0, 0)]), Color(0.06, 0.1, 0.18, 0.8))
	draw_polyline(PackedVector2Array([Vector2(-16, -8), Vector2(0, -38), Vector2(16, -8), Vector2(0, 0), Vector2(-16, -8)]), col, 2.0)
	draw_circle(Vector2(0, -18), 6.0 + glow, Color(col.r, col.g, col.b, 0.35))
