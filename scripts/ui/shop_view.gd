class_name ShopView
extends Modal
## Tienda de La Depuradora.

signal purchased(item: Dictionary)

var list: VBoxContainer
var desc: Label
var bits: Label
var foot: Label
var shop_id := ""


func _ready() -> void:
	var panel := UITheme.center_panel(Vector2(1200, 640))
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)
	var t := UITheme.label("La Depuradora", 48, UITheme.GOLD, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UITheme.ornament(500))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 30)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	list = VBoxContainer.new()
	list.custom_minimum_size = Vector2(560, 0)
	list.add_theme_constant_override("separation", 12)
	hb.add_child(list)
	desc = UITheme.label("", 30)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(520, 0)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(desc)
	bits = UITheme.label("", 30, UITheme.GOLD, true)
	bits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(bits)
	foot = UITheme.label("", 22, UITheme.DIM)
	vb.add_child(foot)


func show_shop(p_shop: String) -> void:
	shop_id = p_shop
	open_modal()
	_refresh()


func _owned(item: Dictionary) -> bool:
	return bool(GameState.get_flag(item.flag))


func _refresh(focus_index := 0) -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	var items := ContentDB.tienda(shop_id)
	for i in items.size():
		var item: Dictionary = items[i]
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if _owned(item):
			b.text = "%s   —   Vendido" % item.nombre
		else:
			b.text = "%s   —   %d Bits" % [item.nombre, int(item.precio)]
		b.focus_entered.connect(func():
			desc.text = ContentDB.format_text(item.descripcion)
			AudioManager.play_sfx("ui_move"))
		b.pressed.connect(_buy.bind(item, i))
		list.add_child(b)
	bits.text = "Tus Bits: %d" % GameState.data.bits
	foot.text = "[%s] Comprar    [%s] Salir" % [Settings.key_name("jump"), Settings.key_name("attack")]
	await get_tree().process_frame
	if list.get_child_count() > 0:
		(list.get_child(clampi(focus_index, 0, list.get_child_count() - 1)) as Button).grab_focus()


func _buy(item: Dictionary, index: int) -> void:
	if _owned(item):
		AudioManager.play_sfx("sello_bad")
		return
	if not GameState.spend_bits(int(item.precio)):
		desc.text = "No tienes suficientes Bits. Derrota bugs y abre cofres-caché para conseguir más."
		AudioManager.play_sfx("sello_bad")
		return
	GameState.set_flag(item.flag)
	match item.tipo:
		"amuleto":
			GameState.grant_charm(item.id)
		"fragmento":
			GameState.add_shard()
	AudioManager.play_sfx("buy")
	purchased.emit(item)
	_refresh(index)


func _input(event: InputEvent) -> void:
	if visible and (cancel_pressed(event) or event.is_action_pressed("attack")):
		get_viewport().set_input_as_handled()
		close_modal()
