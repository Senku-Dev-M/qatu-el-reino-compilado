extends Node
## Guardado en JSON con copia de respaldo del guardado anterior.

var base_dir := "user://saves/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(base_dir)


func slot_path(slot: int) -> String:
	return base_dir + "partida_%d.json" % slot


func backup_path(slot: int) -> String:
	return base_dir + "partida_%d.bak.json" % slot


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(backup_path(slot))


func save_slot(slot: int, d: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(base_dir)
	var path := slot_path(slot)
	if FileAccess.file_exists(path) and _read(path) != null:
		DirAccess.copy_absolute(path, backup_path(slot))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar en %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.close()
	return true


func load_slot(slot: int) -> Dictionary:
	var d = _read(slot_path(slot))
	if d == null:
		d = _read(backup_path(slot))
		if d != null:
			push_warning("Partida %d dañada: se usó el respaldo" % slot)
	return d if d is Dictionary else {}


func delete_slot(slot: int) -> void:
	for p in [slot_path(slot), backup_path(slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Resumen para el menú: {} si vacía, {"corrupt": true} si ilegible.
func slot_summary(slot: int) -> Dictionary:
	if not has_slot(slot):
		return {}
	var d := load_slot(slot)
	if d.is_empty():
		return {"corrupt": true}
	return d


func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data if json.data is Dictionary else null
