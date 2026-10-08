extends RefCounted

var t


func _db():
	return t.get_node("/root/ContentDB")


func test_validate_has_no_errors() -> void:
	var errors: Array = _db().validate()
	for e in errors:
		t.ok(false, e)
	t.ok(errors.is_empty(), "contenido válido")


func test_slice_counts() -> void:
	t.eq(_db().lecciones_de_zona(1).size(), 21, "21 lecciones en zona 1")
	t.eq(_db().sellos_de_zona(1).size(), 3, "3 sellos en zona 1")
	t.eq(_db().enemigos_de_zona(1).size(), 5, "5 fichas de bestiario en zona 1")
	t.eq(_db().amuletos_de_zona(1).size(), 2, "2 amuletos en zona 1")

	t.eq(_db().lecciones_de_zona(2).size(), 21, "21 lecciones en zona 2")
	t.eq(_db().sellos_de_zona(2).size(), 3, "3 sellos en zona 2")
	t.eq(_db().enemigos_de_zona(2).size(), 5, "5 fichas de bestiario en zona 2")
	t.eq(_db().amuletos_de_zona(2).size(), 2, "2 amuletos en zona 2")

	t.eq(_db().lecciones_de_zona(3).size(), 28, "28 lecciones en zona 3")
	t.eq(_db().sellos_de_zona(3).size(), 3, "3 sellos en zona 3")
	t.eq(_db().enemigos_de_zona(3).size(), 6, "6 fichas de bestiario en zona 3")
	t.eq(_db().amuletos_de_zona(3).size(), 3, "3 amuletos en zona 3")

	t.eq(_db().lecciones_de_zona(4).size(), 20, "20 lecciones en zona 4")
	t.eq(_db().sellos_de_zona(4).size(), 3, "3 sellos en zona 4")
	t.eq(_db().enemigos_de_zona(4).size(), 5, "5 fichas de bestiario en zona 4")
	t.eq(_db().amuletos_de_zona(4).size(), 2, "2 amuletos en zona 4")

	t.eq(_db().lecciones_de_zona(5).size(), 25, "25 lecciones en zona 5")
	t.eq(_db().sellos_de_zona(5).size(), 3, "3 sellos en zona 5")
	t.eq(_db().enemigos_de_zona(5).size(), 5, "5 fichas de bestiario en zona 5")
	t.eq(_db().amuletos_de_zona(5).size(), 2, "2 amuletos en zona 5")

	t.eq(_db().lecciones_de_zona(6).size(), 21, "21 lecciones en zona 6")
	t.eq(_db().sellos_de_zona(6).size(), 3, "3 sellos en zona 6")
	t.eq(_db().enemigos_de_zona(6).size(), 5, "5 fichas de bestiario en zona 6")
	t.eq(_db().amuletos_de_zona(6).size(), 2, "2 amuletos en zona 6")

	t.eq(_db().lecciones_de_zona(7).size(), 21, "21 lecciones en zona 7")
	t.eq(_db().sellos_de_zona(7).size(), 3, "3 sellos en zona 7")
	t.eq(_db().enemigos_de_zona(7).size(), 5, "5 fichas de bestiario en zona 7")
	t.eq(_db().amuletos_de_zona(7).size(), 2, "2 amuletos en zona 7")

	t.eq(_db().lecciones_de_zona(8).size(), 21, "21 lecciones en zona 8")
	t.eq(_db().sellos_de_zona(8).size(), 3, "3 sellos en zona 8")
	t.eq(_db().enemigos_de_zona(8).size(), 5, "5 fichas de bestiario en zona 8")
	t.eq(_db().amuletos_de_zona(8).size(), 2, "2 amuletos en zona 8")

	t.eq(_db().lecciones_de_zona(9).size(), 21, "21 lecciones en zona 9")
	t.eq(_db().sellos_de_zona(9).size(), 3, "3 sellos en zona 9")
	t.eq(_db().enemigos_de_zona(9).size(), 5, "5 fichas de bestiario en zona 9")
	t.eq(_db().amuletos_de_zona(9).size(), 2, "2 amuletos en zona 9")

	t.eq(_db().lecciones_de_zona(10).size(), 6, "6 lecciones en zona 10")
	t.eq(_db().sellos_de_zona(10).size(), 1, "1 sello en zona 10")
	t.eq(_db().enemigos_de_zona(10).size(), 1, "1 ficha de bestiario en zona 10")
	t.eq(_db().amuletos_de_zona(10).size(), 1, "1 amuleto en zona 10")


func test_lookup() -> void:
	t.eq(_db().leccion("L14").titulo, "El modelo de cajas", "búsqueda por id")
	t.eq(_db().leccion("NO_EXISTE"), {}, "id inexistente devuelve vacío")
	t.ok(_db().dialogo("mentora_inicio").size() > 0, "diálogo")
	t.ok(_db().habilidad("event_listener").has("nombre"), "habilidad")


func test_sellos_have_practical_retos() -> void:
	for s in _db().tables.sellos.values():
		var tipos := {}
		for r in s.retos:
			tipos[r.tipo] = true
		t.ok(s.retos.size() >= 3, "%s tiene al menos 3 retos" % s.id)
		t.ok(tipos.size() >= 3, "%s mezcla al menos 3 tipos de reto" % s.id)


func test_lessons_follow_room_order() -> void:
	for z in _db().zonas_ordenadas():
		var salas: Array = z.salas
		var last_room_index := -1
		for l in _db().lecciones_de_zona(int(z.zona)):
			var idx: int = salas.find(l.sala)
			t.ok(idx >= 0, "%s pertenece a una sala de su zona" % l.id)
			t.ok(idx >= last_room_index, "%s respeta el orden de salas" % l.id)
			last_room_index = idx


func test_every_room_has_a_guide() -> void:
	for z in _db().zonas_ordenadas():
		for room in z.salas:
			t.ok(not _db().guia(room).is_empty(), "guía para %s" % room)
			t.ok(_db().lecciones_de_sala(room).size() >= 2, "%s tiene al menos 2 lecciones" % room)


func test_lesson_order_is_global_and_consecutive() -> void:
	var orders := []
	for l in _db().tables.lecciones.values():
		orders.append(int(l.orden))
	orders.sort()
	for i in orders.size():
		t.eq(orders[i], i + 1, "orden consecutivo %d" % (i + 1))


func test_rich_format() -> void:
	var bb: String = RichFormat.lesson_text("Un [[elemento]] con **negrita**, `<p>` y [[etiquetas|etiqueta]] [x]")
	t.ok(bb.contains("[u]elemento[/u]"), "término resaltado")
	t.ok(bb.contains("[b]negrita[/b]"), "negrita")
	t.ok(bb.contains("[code]<p>[/code]"), "código en línea")
	t.ok(bb.contains("[lb]x]"), "corchetes escapados")
	t.eq(RichFormat.glossary_ids("[[Elemento vacío|elemento_vacio]] y [[etiqueta]]"), ["elemento_vacio", "etiqueta"], "ids de glosario")
	t.ok(RichFormat.code("<a href=\"x\">Hola</a>", "html").contains("href"), "resaltado html")
	t.eq(RichFormat._js_comment_start("fetch('https://qatu.com'); // pide"), 27, "// dentro de una cadena no es comentario")
	t.eq(RichFormat._js_comment_start("const url = 'a//b';"), -1, "sin comentario")


func test_bold_is_visible() -> void:
	var f := UITheme.bold_font() as FontVariation
	t.ok(f != null, "hay fuente negrita")
	t.ok(f.variation_embolden > 0.0, "la negrita usa engrosado sintético")
	var label := RichFormat.text_label("[b]x[/b]", 30)
	t.ok(label.has_theme_font_override("bold_font"), "el texto de lección define bold_font")
	label.free()


func test_no_unrendered_bold_markers() -> void:
	for l in _db().tables.lecciones.values():
		for p in l.paginas:
			for field in [str(p.get("texto", ""))]:
				t.ok(not RichFormat.lesson_text(field).contains("**"), "%s convierte toda la negrita" % l.id)
			for er in p.get("errores", []):
				t.ok(not RichFormat.lesson_text(str(er.get("explicacion", ""))).contains("**"), "%s error con negrita válida" % l.id)
			if p.has("pregunta"):
				t.ok(not RichFormat.lesson_text(str(p.pregunta.get("explicacion", ""))).contains("**"), "%s pregunta con negrita válida" % l.id)
	for s in _db().tables.sellos.values():
		for r in s.retos:
			t.ok(not RichFormat.lesson_text(str(r.get("explicacion", ""))).contains("**"), "%s reto con negrita válida" % s.id)
