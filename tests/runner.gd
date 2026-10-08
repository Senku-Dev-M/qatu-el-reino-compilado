extends Node
## Runner de pruebas ligero. Ejecutar:
##   godot --headless --path qatu res://tests/runner.tscn

const TEST_DIR := "res://tests/"

var failures: Array[String] = []
var checks := 0
var current := ""


func _ready() -> void:
	var files := DirAccess.get_files_at(TEST_DIR)
	var ran := 0
	# QATU_TEST=<texto> ejecuta solo los archivos cuyo nombre lo contiene.
	var only := OS.get_environment("QATU_TEST")
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		if only != "" and not f.contains(only):
			continue
		var script: GDScript = load(TEST_DIR + f)
		if script == null or not script.can_instantiate():
			failures.append("%s → no compila" % f)
			continue
		var suite = script.new()
		suite.set("t", self)
		for m in suite.get_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			current = "%s::%s" % [f.get_basename(), name]
			if suite.has_method("before_each"):
				suite.before_each()
			var before_checks := checks
			var before_failures := failures.size()
			await suite.call(name)
			if suite.has_method("after_each"):
				suite.after_each()
			# Un error de script aborta la función sin lanzar excepción:
			# una prueba sin verificaciones se considera fallida.
			if checks == before_checks and failures.size() == before_failures:
				failures.append("%s → terminó sin verificaciones (¿error de script?)" % current)
			ran += 1
		if suite is Node:
			suite.free()
	print("")
	print("Pruebas: %d · Verificaciones: %d · Fallos: %d" % [ran, checks, failures.size()])
	for fail in failures:
		printerr("  FALLO " + fail)
	if failures.is_empty():
		print("ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		print("TESTS FAILED")
		get_tree().quit(1)


func ok(cond: bool, msg := "") -> void:
	checks += 1
	if not cond:
		failures.append("%s → %s" % [current, msg])


func eq(actual: Variant, expected: Variant, msg := "") -> void:
	checks += 1
	if typeof(actual) != typeof(expected) and not (_is_num(actual) and _is_num(expected)):
		failures.append("%s → %s (tipo: esperado %s, obtenido %s)" % [current, msg, str(expected), str(actual)])
	elif actual != expected:
		failures.append("%s → %s (esperado %s, obtenido %s)" % [current, msg, str(expected), str(actual)])


func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
