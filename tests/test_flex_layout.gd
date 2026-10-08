extends RefCounted
## Las posiciones deben coincidir con lo que calcula un navegador.

var t


func _approx(a: Array, b: Array, msg: String) -> void:
	var same := a.size() == b.size()
	for i in mini(a.size(), b.size()):
		same = same and absf(float(a[i]) - float(b[i])) < 0.01
	t.ok(same, "%s (esperado %s, obtenido %s)" % [msg, str(b), str(a)])


func test_justify_values() -> void:
	# Contenedor de 300 px con tres elementos de 50 px: sobran 150 px.
	var s := [50, 50, 50]
	_approx(FlexLayout.justify(300, s, "flex-start"), [0, 50, 100], "flex-start")
	_approx(FlexLayout.justify(300, s, "flex-end"), [150, 200, 250], "flex-end")
	_approx(FlexLayout.justify(300, s, "center"), [75, 125, 175], "center")
	_approx(FlexLayout.justify(300, s, "space-between"), [0, 125, 250], "space-between")
	_approx(FlexLayout.justify(300, s, "space-around"), [25, 125, 225], "space-around")
	_approx(FlexLayout.justify(300, s, "space-evenly"), [37.5, 125, 212.5], "space-evenly")


func test_justify_with_gap() -> void:
	_approx(FlexLayout.justify(300, [50, 50], "flex-start", 20), [0, 70], "gap separa elementos")
	_approx(FlexLayout.justify(300, [50, 50], "center", 20), [90, 160], "gap cuenta en el centrado")


func test_space_between_single_item() -> void:
	_approx(FlexLayout.justify(300, [50], "space-between"), [0], "un elemento se comporta como flex-start")


func test_align_items() -> void:
	t.eq(FlexLayout.align(100, 40, "flex-start"), Vector2(0, 40), "flex-start")
	t.eq(FlexLayout.align(100, 40, "center"), Vector2(30, 40), "center")
	t.eq(FlexLayout.align(100, 40, "flex-end"), Vector2(60, 40), "flex-end")
	t.eq(FlexLayout.align(100, 40, "stretch"), Vector2(0, 100), "stretch ocupa todo")


func test_flex_grow() -> void:
	_approx(FlexLayout.grow(400, [100, 100], [1, 1]), [200, 200], "reparto igual")
	_approx(FlexLayout.grow(400, [100, 100], [1, 3]), [150, 250], "reparto 1:3")
	_approx(FlexLayout.grow(400, [100, 100], [0, 1]), [100, 300], "solo crece el segundo")


func test_wrap() -> void:
	t.eq(FlexLayout.wrap_lines(250, [100, 100, 100], 10), [[0, 1], [2]], "salta de línea al no caber")
	t.eq(FlexLayout.wrap_lines(400, [100, 100, 100], 10), [[0, 1, 2]], "caben en una línea")


func test_grid_tracks() -> void:
	t.eq(FlexLayout.expand_tracks("repeat(3, 1fr)"), ["1fr", "1fr", "1fr"], "repeat")
	_approx(FlexLayout.grid_tracks("repeat(3, 1fr)", 300), [100, 100, 100], "tres fr iguales")
	_approx(FlexLayout.grid_tracks("200px 1fr", 600), [200, 400], "px + fr")
	_approx(FlexLayout.grid_tracks("1fr 2fr", 320, 20), [100, 200], "fr descontando gap")


func test_layout_quiz() -> void:
	var q := LayoutQuiz.new()
	q.start({"justify-content": "space-between", "align-items": "center"})
	t.eq(q.hit("align-items", "flex-end"), "wrong", "valor incorrecto")
	t.eq(q.hit("align-items", "center"), "correct", "primera propiedad")
	t.eq(q.hit("justify-content", "space-between"), "complete", "completo")
	t.ok(q.css_text().contains("justify-content: space-between;"), "CSS del objetivo")
