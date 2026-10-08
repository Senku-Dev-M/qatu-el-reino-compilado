class_name LayerGate
extends AbilityGate
## Compuerta de capa (zona 1): responde 401 hasta que un terminal REST recibe
## la petición correcta con el REST Dash.


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	super.setup(p_room, p_def)
	theme_col = Color(2.2, 0.9, 0.5)


func closed_text() -> String:
	return str(def.get("requiere", "401 · envía la petición desde el terminal"))


func open_text() -> String:
	return "200 OK"


func ability_id() -> String:
	return "rest_dash"
