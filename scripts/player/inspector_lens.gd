class_name InspectorLens
extends Node2D
## Anillo visible mientras la habilidad Inspector está activa: marca el alcance
## dentro del cual las aserciones se revelan.

var player: Player
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	visible = player != null and player.inspecting()
	if visible:
		queue_redraw()


func _draw() -> void:
	var c := Vector2(0, -40)
	var r := Player.INSPECT_RANGE
	var k := clampf(player.inspect_t / Player.INSPECT_TIME, 0.0, 1.0)
	var col := Color(0.6, 1.8, 2.4)
	draw_circle(c, r, Color(0.3, 0.9, 1.2, 0.05))
	draw_arc(c, r, 0.0, TAU, 96, Color(col, 0.45), 2.0, true)
	draw_arc(c, r - 10.0, -PI * 0.5, -PI * 0.5 + TAU * k, 64, Color(col, 0.8), 4.0, true)
	for i in 3:
		var a := t * 2.0 + TAU * i / 3.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r, 5.0, Color(col, 0.7))
