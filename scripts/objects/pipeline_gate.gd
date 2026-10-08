class_name PipelineGate
extends AbilityGate
## Compuerta del Deployment (zona 8): se abre cuando se despliega un Pod sobre
## el nodo del clúster que la controla.


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	super.setup(p_room, p_def)
	theme_col = Color(0.5, 1.8, 2.6)


func closed_text() -> String:
	return str(def.get("requiere", "Deployment 0/1 · despliega un Pod en el nodo"))


func open_text() -> String:
	return "Deployment 1/1 listo"


func ability_id() -> String:
	return "contenedor"
