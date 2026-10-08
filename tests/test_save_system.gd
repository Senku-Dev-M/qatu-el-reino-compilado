extends RefCounted

var t
var ss


func before_each() -> void:
	ss = load("res://autoload/save_system.gd").new()
	ss.base_dir = "user://test_saves/"
	DirAccess.make_dir_recursive_absolute(ss.base_dir)
	for f in DirAccess.get_files_at(ss.base_dir):
		DirAccess.remove_absolute(ss.base_dir + f)


func after_each() -> void:
	ss.free()


func test_roundtrip() -> void:
	t.ok(not ss.has_slot(1), "vacía")
	t.ok(ss.save_slot(1, {"bits": 7, "room": "z3_raiz"}), "guarda")
	t.ok(ss.has_slot(1), "existe")
	var d: Dictionary = ss.load_slot(1)
	t.eq(d.get("room"), "z3_raiz", "carga sala")


func test_corrupt_uses_backup() -> void:
	ss.save_slot(2, {"bits": 1})
	ss.save_slot(2, {"bits": 2})
	var f := FileAccess.open(ss.slot_path(2), FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	var d: Dictionary = ss.load_slot(2)
	t.eq(int(d.get("bits", -1)), 1, "usa respaldo")


func test_missing_returns_empty() -> void:
	t.eq(ss.load_slot(3), {}, "vacío")


func test_delete() -> void:
	ss.save_slot(1, {"a": 1})
	ss.delete_slot(1)
	t.ok(not ss.has_slot(1), "borrada")
