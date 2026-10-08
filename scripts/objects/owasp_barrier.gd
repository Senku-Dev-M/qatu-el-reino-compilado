class_name OwaspBarrier
extends AbilityGate
## Barrera WAF (zona 9): bloquea el paso hasta que el Inspector verifica la
## aserción de seguridad que la controla.


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	super.setup(p_room, p_def)
	theme_col = Color(2.4, 0.6, 0.6)


func closed_text() -> String:
	return str(def.get("requiere", "WAF · verifica la aserción con el Inspector"))


func open_text() -> String:
	return "aserción verificada · paso permitido"


func ability_id() -> String:
	return "inspector"


func unlock() -> void:
	open()
