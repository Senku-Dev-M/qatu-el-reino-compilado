extends RefCounted

var t


func test_correct_order_completes() -> void:
	var p := NestingPuzzle.new()
	p.start(["div", "ul", "li", "a"])
	t.eq(p.expected(), "div", "empieza por fuera")
	t.eq(p.hit("div"), "correct", "div")
	t.eq(p.hit("ul"), "correct", "ul")
	t.eq(p.hit("li"), "correct", "li")
	t.eq(p.hit("a"), "complete", "a completa")
	t.ok(p.is_complete(), "completo")


func test_wrong_resets() -> void:
	var p := NestingPuzzle.new()
	p.start(["div", "ul", "li", "a"])
	p.hit("div")
	t.eq(p.hit("li"), "wrong", "orden incorrecto")
	t.eq(p.expected(), "div", "vuelve al inicio")


func test_texts() -> void:
	var p := NestingPuzzle.new()
	p.start(["nav", "ul", "li", "a"])
	t.eq(p.structure_text(), "nav > ul > li > a", "estructura")
	t.eq(p.html_text(), "<nav><ul><li><a></a></li></ul></nav>", "html bien anidado")


func test_all_sets_have_four_tags() -> void:
	for s in NestingPuzzle.SETS:
		t.eq(s.size(), 4, "cuatro etiquetas")
