extends CanvasLayer
## View only: receives snapshots and emits selection/quest commands.
signal seed_requested(crop_id: StringName)
signal tool_requested(tool_id: StringName)
signal dialogue_action_requested(action: String)
signal dialogue_closed
var root: Control
var seed_buttons: Dictionary = {}
var bars: Dictionary = {}
var bar_labels: Dictionary = {}
var objective_label: Label
var hint_label: Label
var toast_label: Label
var legacy_status: Label
var resource_label: Label
var time_label: Label
var tool_label: Label
var inventory_label: Label
var vehicle_label: Label
var controls_panel: PanelContainer
var controls_label: Label
var _right_scroll: ScrollContainer
var location_label: Label
var location_panel: Control
var objective_progress: ProgressBar
var quest_label: Label
var dialogue: PanelContainer
var dialogue_title: Label
var dialogue_body: Label
var dialogue_button: Button
var hire_button: Button
var _staff_dialogue := false
var _dialogue_command := "accept"
var _selected: StringName = &"tomato"
var _preview: SubViewport
var _preview_mesh: MeshInstance3D
var _mini_map: Control
var _vehicle_hints := ""
var _tool_buttons: Dictionary = {}
var _last_tool := ""
func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.theme = FarmTheme.build()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_build_top()
	_build_left()
	_build_right()
	_build_controls()
	_build_footer()
	_build_dialogue()
	EventBus.farm_hud_updated.connect(_update_snapshot)
	EventBus.seed_selection_changed.connect(select_seed)
	EventBus.update_crosshair_prompt.connect(func(text: String) -> void:
		if not text.is_empty(): hint_label.text = text)
	EventBus.update_vehicle_hints.connect(func(show_hud: bool, hints: Array) -> void:
		_vehicle_hints = "\n".join(hints) if show_hud else "")
	legacy_status = Label.new()
	legacy_status.hide()
	root.add_child(legacy_status)
	select_seed(&"tomato")
func _label(parent: Node, text: String, size: int = 15, color: Color = FarmTheme.TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
func _card(parent: Node, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",9)
	panel.add_child(box)
	return box
func _build_top() -> void:
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 22
	panel.offset_right = -22
	panel.offset_top = 18
	panel.offset_bottom = 96
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	panel.add_child(row)
	var brand := VBoxContainer.new()
	row.add_child(brand)
	_label(brand,"MOZCOLHEITA",18,FarmTheme.ACCENT)
	_label(brand,"TECNOLOGIA NA MACHAMBA",10,FarmTheme.MUTED)
	for entry: Array in [["health","Saúde"],["hunger","Alimentação"],["energy","Energia"],["water","Água"]]:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation",6)
		box.custom_minimum_size.x = 94
		box.tooltip_text = entry[1]
		row.add_child(box)
		var icon := preload("res://Scripts/ui/farming/VitalIcon.gd").new()
		icon.kind = entry[0]
		box.add_child(icon)
		bars[entry[0]] = icon
		bar_labels[entry[0]] = _label(box,"100",14)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var resources := VBoxContainer.new()
	resources.custom_minimum_size.x = 215
	row.add_child(resources)
	time_label = _label(resources,"DIA 01   /   06:00",17)
	resource_label = _label(resources,"0 MT   ·   30 sementes",13,FarmTheme.GOLD)
func _build_left() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	# Side columns scroll within the viewport instead of covering the footer.
	var scroll := ScrollContainer.new()
	root.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	scroll.offset_left = 22
	scroll.offset_right = 262
	scroll.offset_top = 114
	scroll.offset_bottom = -55
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(column)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var seeds := _card(column,224)
	_label(seeds,"SEMENTES",12,FarmTheme.MUTED)
	_label(seeds,"O que vamos plantar?",18)
	for i: int in range(CropCatalog.IDS.size()):
		var id: StringName = CropCatalog.IDS[i]
		var button := Button.new()
		button.custom_minimum_size.y = 33
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		seeds.add_child(button)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 9
		row.offset_right = -7
		var icon := CropIcon.new()
		icon.crop_id = id
		icon.custom_minimum_size = Vector2(27,27)
		row.add_child(icon)
		var name_label := _label(row,str(CropCatalog.get_crop(id).name),14)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row,str(i+1),13,FarmTheme.MUTED)
		button.pressed.connect(func() -> void: seed_requested.emit(id))
		button.tooltip_text = "%d · %s — cresce em 4 minutos" % [i+1,CropCatalog.get_crop(id).name]
		seed_buttons[id] = button
	var preview_row := HBoxContainer.new()
	seeds.add_child(preview_row)
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(90,94)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_row.add_child(container)
	_preview = SubViewport.new()
	_preview.size = Vector2i(90,94)
	_preview.transparent_bg = true
	_preview.own_world_3d = true
	_preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	container.add_child(_preview)
	var camera := Camera3D.new()
	camera.position = Vector3(1.8,1.45,2.4)
	_preview.add_child(camera)
	camera.look_at(Vector3(0,0.68,0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-35,0)
	light.light_energy = 1.5
	_preview.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,145,0)
	fill.light_energy = 0.7
	_preview.add_child(fill)
	_preview_mesh = MeshInstance3D.new()
	_preview.add_child(_preview_mesh)
	_label(preview_row,"I · PLANTAR\n4 min de cultivo\nTab · usar cursor",11,FarmTheme.MUTED)
	var tools := _card(column,224)
	_label(tools,"FERRAMENTA ACTIVA",11,FarmTheme.MUTED)
	tool_label = _label(tools,"Enxada",17)
	var tool_row := HBoxContainer.new()
	tools.add_child(tool_row)
	for entry: Array in [[&"hoe","7 Enxada"],[&"saw","8 Serrote"],[&"hammer","9 Martelo"]]:
		var button := Button.new()
		button.text = entry[1]
		button.add_theme_font_size_override("font_size",11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for state: String in ["normal","hover","pressed"]: button.add_theme_stylebox_override(state,FarmTheme.compact_button(Color("20323a")))
		tool_row.add_child(button)
		var id: StringName = entry[0]
		button.pressed.connect(func() -> void: tool_requested.emit(id))
		_tool_buttons[id] = button
	_label(tools,"Roda · Trocar | I Semear | R Colher",10,FarmTheme.MUTED)
	inventory_label = _label(tools,"Bolso: 3 alimentos",12,FarmTheme.MUTED)
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.custom_minimum_size.x = 192
func _build_right() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	_right_scroll = ScrollContainer.new()
	root.add_child(_right_scroll)
	_right_scroll.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_right_scroll.offset_left = -312
	_right_scroll.offset_right = -22
	_right_scroll.offset_top = 114
	_right_scroll.offset_bottom = -55
	_right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right_scroll.add_child(column)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var objective := _card(column,274)
	_label(objective,"O SEU PRÓXIMO PASSO",11,FarmTheme.ACCENT)
	objective_progress = ProgressBar.new()
	objective_progress.show_percentage = false
	objective_progress.custom_minimum_size.y = 4
	objective_progress.max_value = 9
	objective.add_child(objective_progress)
	objective_label = _label(objective,"A carregar objectivos…",15)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 242
	quest_label = _label(objective,"",13,FarmTheme.GOLD)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.custom_minimum_size.x = 242
	var context := _card(column,274)
	_label(context,"À SUA VOLTA",11,FarmTheme.MUTED)
	hint_label = _label(context,"Olhe para a horta para começar.",14)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.x = 242
	vehicle_label = _label(context,"",12,FarmTheme.ACCENT)
	vehicle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vehicle_label.custom_minimum_size.x = 242
	var location := _card(column,274)
	location_panel = location.get_parent()
	location_label = _label(location,"A SUA FAZENDA",12,FarmTheme.MUTED)
	_mini_map = preload("res://Scripts/ui/farming/LocalCompass.gd").new()
	_mini_map.custom_minimum_size = Vector2(240,86)
	location.add_child(_mini_map)
	_label(location,"C Casa · A Armazém · G Garagem\nM · Mapa completo    F · Interagir",11,FarmTheme.MUTED)
func _build_controls() -> void:
	controls_panel = PanelContainer.new()
	root.add_child(controls_panel)
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls_panel.offset_left = -296
	controls_panel.offset_right = -22
	controls_panel.offset_top = -232
	controls_panel.offset_bottom = -55
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	controls_panel.add_child(box)
	_label(box,"COMANDOS DE OPERAÇÃO",11,FarmTheme.ACCENT)
	controls_label = _label(box,"",12)
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.custom_minimum_size.x = 242
	controls_panel.hide()
func _build_footer() -> void:
	var footer_panel := PanelContainer.new()
	root.add_child(footer_panel)
	footer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_left = 22
	footer_panel.offset_right = -22
	footer_panel.offset_top = -43
	footer_panel.offset_bottom = -12
	var footer_style := FarmTheme.compact_button(FarmTheme.INK)
	footer_panel.add_theme_stylebox_override("panel",footer_style)
	var footer := _label(footer_panel,"MOZCOLHEITA   ·   WASD Andar   J Comer   K Água   T Descansar   L/U Carga   O Visual   F8 Drone   N Cercas   F1 Ajuda",12,FarmTheme.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label = _label(root,"Bem-vindo à sua fazenda.",18)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.offset_left = 280
	toast_label.offset_right = -310
	toast_label.offset_top = -88
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_outline_color",Color("102126"))
	toast_label.add_theme_constant_override("outline_size",4)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
func _build_dialogue() -> void:
	var shade := PanelContainer.new()
	dialogue = shade
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	shade.offset_left = -305
	shade.offset_right = 305
	shade.offset_top = -255
	shade.offset_bottom = -48
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	shade.add_child(box)
	dialogue_title = _label(box,"",20,FarmTheme.ACCENT)
	dialogue_body = _label(box,"",15)
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_body.custom_minimum_size.x = 575
	var row := HBoxContainer.new()
	box.add_child(row)
	dialogue_button = Button.new()
	dialogue_button.text = "Aceitar encomenda"
	row.add_child(dialogue_button)
	dialogue_button.pressed.connect(func() -> void: dialogue_action_requested.emit(_dialogue_command))
	var hire := Button.new()
	hire_button = hire
	hire.text = "Contratar · 8 MT/tarefa"
	row.add_child(hire)
	hire.pressed.connect(func() -> void: dialogue_action_requested.emit("dismiss_worker" if _staff_dialogue else "hire"))
	var close := Button.new()
	close.text = "Até já [F / Esc]"
	row.add_child(close)
	close.pressed.connect(close_dialogue)
	dialogue.hide()
func show_dialogue(payload: Dictionary) -> void:
	_staff_dialogue = payload.get("action","") == "assign_worker"
	hire_button.text = "Dispensar trabalhador" if _staff_dialogue else "Contratar · 8 MT/tarefa"
	dialogue_title.text = payload.get("name", "Vizinho")
	dialogue_body.text = payload.get("text", "")
	_dialogue_command = payload.get("action","accept")
	dialogue_button.text = payload.get("button","Aceitar encomenda")
	dialogue_button.disabled = not payload.get("enabled",true)
	dialogue.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func close_dialogue() -> void:
	dialogue.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dialogue_closed.emit()
func select_seed(id: StringName) -> void:
	_selected = CropCatalog.normalize_id(id)
	for key: StringName in seed_buttons:
		var style := FarmTheme.panel(Color("2b4e45") if key == _selected else Color("1b2c34"),8)
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		style.border_color = CropCatalog.get_crop(key).color if key == _selected else Color("2b3d44")
		seed_buttons[key].add_theme_stylebox_override("normal",style)
		seed_buttons[key].add_theme_stylebox_override("hover",style)
		seed_buttons[key].add_theme_stylebox_override("pressed",style)
	if _preview_mesh != null:
		_preview_mesh.mesh = CropVisualFactory.mesh_for(_selected,4)
		_preview_mesh.scale = Vector3.ONE*(0.8 if _selected == &"corn" else 1.0)
		_preview.render_target_update_mode = SubViewport.UPDATE_ONCE
func _update_snapshot(state: Dictionary) -> void:
	for key: String in bars:
		var value: float = float(state.get(key,100))
		bars[key].value = value
		bar_labels[key].text = str(roundi(value))
	time_label.text = "DIA %02d   /   %02d:%02d" % [state.get("day",1),state.get("hour",6),state.get("minute",0)]
	resource_label.text = "%s   ·   %d sementes" % [FarmTheme.money(int(state.get("money",0))),state.get("seeds",0)]
	objective_label.text = state.get("objective","")
	objective_progress.value = mini(9,int(state.get("mission",0)))
	quest_label.text = state.get("quest","") + "\n" + state.get("production","")
	quest_label.visible = not quest_label.text.is_empty()
	hint_label.text = state.get("hint","")
	tool_label.text = {"hoe":"Enxada", "seed":"Sementes · " + str(CropCatalog.get_crop(_selected).name), "harvest":"Colheita", "saw":"Serrote · clique corta árvore", "hammer":"Martelo · clique cerca / G estufa"}.get(state.get("tool","hoe"),"Enxada")
	var active_tool: String = str(state.get("tool","hoe"))
	if active_tool != _last_tool:
		_last_tool = active_tool
		for id: StringName in _tool_buttons:
			_tool_buttons[id].add_theme_stylebox_override("normal",FarmTheme.compact_button(Color("34594f") if String(id)==active_tool else Color("20323a")))
	for id: StringName in seed_buttons:
		seed_buttons[id].get_child(0).get_child(0).active = int(state.get("seeds",0))>0
	inventory_label.text = "%d madeira · %d funcionários\n" % [state.get("wood",0),state.get("employees",0)]
	inventory_label.text += "%d alimentos · Armazém %d · Carrinha %d" % [state.get("food",0),state.get("stored",0),state.get("cargo",0)]
	if state.get("parked",false): inventory_label.text += "\nGaragem · estacionado"
	var produce: Dictionary = state.get("produce",{})
	var rows: PackedStringArray = []
	for id: StringName in CropCatalog.IDS:
		if int(produce.get(String(id),0)) > 0: rows.append("%s %d" % [CropCatalog.get_crop(id).name,int(produce[String(id)])])
	if not rows.is_empty(): inventory_label.text += "\n" + " · ".join(rows)
	vehicle_label.visible = not str(state.get("vehicle", "")).is_empty()
	location_panel.visible = not vehicle_label.visible
	vehicle_label.text = state.get("vehicle","")
	var flying: bool = state.get("flying",false)
	var driving: bool = state.get("driving",false)
	controls_panel.visible = flying or driving
	_right_scroll.offset_bottom = -250 if controls_panel.visible else -55
	if flying:
		controls_label.text = "W A S D · Deslocar   Rato · Câmara\nQ / E · Descer / subir\nEspaço · Iniciar / parar rega\nF8 / Esc · Regressar à fazenda"
	elif driving:
		controls_label.text = "W / S · Acelerar / recuar\nA / D · Virar   Espaço · Travar\nF · Sair   Y · Faróis\n" + ("7 / 8 / 9 · Charrua / sementes / rega\nP · Acoplar   V · Baixar   B · Ligar" if state.get("tractor",false) else _vehicle_hints)
	location_label.text = state.get("location","A SUA FAZENDA")
	_mini_map.set("world_position", state.get("position",Vector3.ZERO))
	_mini_map.queue_redraw()
