class_name CleanGate
extends AbilityGate
## Compuerta de la vista (zona 2): refleja el estado del modelo. Se abre
## mientras su nodo de Data Binding está enlazado y se cierra si se desenlaza.


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	super.setup(p_room, p_def)
	theme_col = Color(0.5, 1.6, 2.4)
	persist = false   # su estado lo decide el nodo enlazado


func closed_text() -> String:
	return str(def.get("requiere", "vista sin enlazar · enlaza el nodo del modelo"))


func open_text() -> String:
	return "vista sincronizada"


func ability_id() -> String:
	return "data_binding"


func set_bound(bound: bool, animated := true) -> void:
	if bound and not is_open():
		open(animated)
	elif not bound and open_k > 0.0:
		close(animated)
