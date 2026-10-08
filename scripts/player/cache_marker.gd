class_name CacheMarker
extends Node2D
## Marca de la habilidad Caché: cristal en la posición guardada con el
## tiempo de vida (TTL) restante.

var player: Node
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if player:
		global_position = player.cache_pos
		visible = player.has_cache()
	queue_redraw()


func _draw() -> void:
	if player == null or not player.has_cache():
		return
	var k: float = clampf(player.cache_ttl / maxf(player.cache_ttl_max(), 0.01), 0.0, 1.0)
	var col := Color(1.0, 1.6, 2.6)
	var c := Vector2(0, -44 + sin(t * 3.0) * 4.0)
	# Silueta del jugador guardada.
	draw_rect(Rect2(Vector2(-13, -76), Vector2(26, 76)), Color(0.6, 0.9, 1.6, 0.12))
	# Cristal.
	var pts := PackedVector2Array([c + Vector2(0, -22), c + Vector2(13, 0), c + Vector2(0, 22), c + Vector2(-13, 0)])
	draw_colored_polygon(pts, Color(col, 0.5))
	draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.0, true)
	# Anillo del TTL.
	draw_arc(c, 32, -PI * 0.5, -PI * 0.5 + TAU * k, 40, Color(col, 0.9) if k > 0.25 or int(t * 8.0) % 2 == 0 else Color(2.4, 0.6, 0.5), 3.0, true)
	var font := UITheme.mono_font()
	var text := "max-age=%d" % ceili(player.cache_ttl)
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, Vector2(-ts.x * 0.5, -96), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 1.4, 2.2, 0.9))
