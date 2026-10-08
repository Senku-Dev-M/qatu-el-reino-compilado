extends RefCounted
## Todos los scripts del proyecto deben compilar.

var t


func _collect(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + f)
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with("."):
			continue
		_collect(dir + d + "/", out)


func test_all_scripts_compile() -> void:
	var files := []
	_collect("res://", files)
	t.ok(files.size() > 40, "se encontraron scripts")
	for path in files:
		var s = load(path)
		t.ok(s != null and (s as GDScript).can_instantiate(), "compila: " + path)
