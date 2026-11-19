extends Node
## Onboarding, farming interactions and survival use the existing simulation/save slot.
const HOME := Vector3(105, 30, 135)
const PLOT := Rect2(98, 119, 14, 14)
const MISSIONS := [
	["1. Preparar a terra", "Entre na horta junto à placa. Olhe para o chão e prima H.\nO quadrado verde mostra onde a enxada vai actuar."],
	["2. Semear", "Aponte para a terra castanha e prima I.\nCada semente ocupa um quadrado já preparado."],
	["3. Fazer a primeira colheita", "As plantas crescem em 4 minutos reais. Quando aparecer [R], prima R.\nPode descansar junto à casa com T para avançar 4 horas."],
	["4. Alimentar-se", "Prima J para comer uma ração ou produto colhido.\nK bebe água junto ao poço; T descansa junto à casa."],
	["5. Conhecer o tractor", "Procure o tractor ao lado da horta. Aponte para ele e prima F.\nWASD conduz, Espaço trava e F permite sair."],
	["6. Guardar a colheita", "Vá ao armazém a oeste da casa (consulte M).\nAproxime-se e prima L para guardar até 5 alimentos."],
	["7. Carregar a carrinha", "U retira alimentos do armazém. Depois aproxime-se da carrinha e prima L.\nA carrinha transporta até 30 alimentos; F permite conduzir."],
	["8. Estacionar o tractor", "Leve o tractor à garagem a leste da casa. Entre pela frente, trave e saia com F.\nO indicador Estacionado confirma a posição."],
	["9. Conhecer os vizinhos", "Use M para localizar uma fazenda. Aproxime-se de um trabalhador e prima F.\nOs vizinhos oferecem provisões uma vez por dia."],
	["Formação concluída!", "Cultive, armazene e transporte alimentos. Visite as fazendas e cuide das necessidades.\nEsc guarda o progresso; O personaliza o personagem e o tractor."]
]
var missions: Node
var employment: Node
var hand_tools: Node3D
var _employment_worker: Node
var technology: Node3D
var hud: Node
var _active_tool: StringName = &"hoe"
var _hud_cursor := false
var _nearby_prompt := ""
var _dialogue_farm := 0
var player: CharacterBody3D
var data: PlayerData
var farm: FarmData
var canvas: CanvasLayer
var guide_text: Label
var status_text: Label
var hint_text: Label
var message: Label
var map_panel: PanelContainer
var map_view: Control
var menu: PanelContainer
var death_panel: PanelContainer
var marker: MeshInstance3D
var hoe: Node3D
var target := Vector3.ZERO
var target_valid := false
var _terrain_cache: Node
var village: Node3D
var _world: Node3D
var _elapsed := 0.0
var _message_time := 0.0
var _action_cooldown := 0.0
var _swing := 0.0
var _appearance := -1
var _tractor_style := -1
var _tractor_visual: ModernTractor
var _last_vehicle: Node3D
var _ui_ready := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("farm_guide")
	_build_ui()
	EventBus.game_loaded_successfully.connect(_restore_presentation)

func blocks_gameplay() -> bool:
	return _ui_ready and (menu.visible or map_panel.visible or death_panel.visible or _hud_cursor or hud.dialogue.visible or (is_instance_valid(technology) and technology.blocks_player()))

func _label(parent: Node, text: String, size: int = 17) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _panel(parent: Node, pos: Vector2, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	panel.position = pos
	panel.custom_minimum_size.x = width
	var style := FarmTheme.panel()
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	hud = preload("res://Scripts/ui/farming/ModernFarmHUD.gd").new()
	add_child(hud)
	hud.seed_requested.connect(select_seed)
	hud.tool_requested.connect(select_tool)
	hud.dialogue_action_requested.connect(_on_dialogue_action)
	hud.dialogue_closed.connect(func() -> void: _hud_cursor = false)
	status_text = hud.legacy_status
	guide_text = hud.objective_label
	hint_text = hud.hint_label
	message = hud.toast_label
	EventBus.update_crosshair_prompt.connect(func(text: String) -> void: _nearby_prompt = text)
	EventBus.neighbor_dialogue_requested.connect(_open_dialogue)
	EventBus.hud_visibility_requested.connect(func() -> void: hud.root.visible = not hud.root.visible)
	canvas = CanvasLayer.new()
	canvas.layer = 14
	add_child(canvas)
	var root := Control.new()
	root.theme = FarmTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	_message_time = 12
	var menu_box := _panel(root, Vector2(420, 40), 440)
	menu = menu_box.get_parent()
	_label(menu_box, "PERSONAGEM E GARAGEM", 24)
	_label(menu_box, "Escolhas guardadas com o jogo (Esc → Guardar).", 14)
	var character := OptionButton.new()
	for name_text: String in ["Afonso — roupa verde e chapéu de palha", "Lídia — roupa azul e chapéu de palha", "Rui — roupa terracota e chapéu de palha"]:
		character.add_item(name_text)
	menu_box.add_child(character)
	character.item_selected.connect(func(index: int) -> void:
		data.guide.character = index
		_appearance = -1
		_apply_character())
	character.name = "CharacterChoice"
	var tractor := OptionButton.new()
	for name_text: String in ["Acabamento terracota", "Acabamento floresta", "Acabamento azul"]:
		tractor.add_item(name_text)
	menu_box.add_child(tractor)
	tractor.name = "TractorChoice"
	tractor.item_selected.connect(func(index: int) -> void:
		data.guide.tractor = index
		_tractor_style = -1
		_apply_tractors())
	_label(menu_box, "Escolha o acabamento do seu tractor moderno.\nAs escolhas ficam na sua gravação.", 14)
	var sensitivity := HSlider.new()
	sensitivity.name = "SensitivityChoice"
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = 0.002
	_label(menu_box, "Sensibilidade do rato")
	menu_box.add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float) -> void:
		if is_instance_valid(player):
			player.mouse_sensitivity = value
			player._camera_controller.mouse_sensitivity = value
		data.guide["sensitivity"] = value)
	_button(menu_box, "Voltar ao jogo [O]", func() -> void: _toggle_window(menu))
	menu.hide()
	var map_box := _panel(root, Vector2(420, 30), 530)
	map_panel = map_box.get_parent()
	_label(map_box, "MAPA TÁCTICO — ARREDORES DA FAZENDA", 22)
	map_view = preload("res://Scripts/guided/FarmMap.gd").new()
	map_view.set("guide", self)
	map_view.custom_minimum_size = Vector2(500, 420)
	map_box.add_child(map_view)
	_label(map_box, "▲ Você   ■ Casa / Poço   ▨ Horta   ● Tractor\nL guarda e U retira alimentos no armazém ou carrinha.\nMapa local: o terreno exterior continua acessível.", 15)
	_button(map_box, "Voltar ao jogo [M]", func() -> void: _toggle_window(map_panel))
	map_panel.hide()
	var death_box := _panel(root, Vector2(420, 100), 440)
	death_panel = death_box.get_parent()
	_label(death_box, "FICOU SEM FORÇAS", 26)
	_label(death_box, "A fome ou a sede esgotaram a sua saúde.\nRegresse a casa para recomeçar com provisões.\nAs culturas e missões são mantidas.")
	_button(death_box, "Recomeçar em casa", _respawn)
	death_panel.hide()
	_ui_ready = true

func _input(event: InputEvent) -> void:
	if not _ui_ready or data == null or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if hud.dialogue.visible:
		if key == KEY_F or key == KEY_ESCAPE:
			hud.close_dialogue()
			get_viewport().set_input_as_handled()
		return
	if key == KEY_TAB and not get_tree().paused and not menu.visible and not map_panel.visible and not death_panel.visible:
		_hud_cursor = not _hud_cursor
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _hud_cursor else Input.MOUSE_MODE_CAPTURED
	elif key == KEY_O and not death_panel.visible and not map_panel.visible:
		if get_tree().paused and not menu.visible: return
		_toggle_window(menu)
	elif key == KEY_M and not death_panel.visible and not menu.visible:
		if get_tree().paused and not map_panel.visible: return
		_toggle_window(map_panel)
	elif key == KEY_ESCAPE and (menu.visible or map_panel.visible):
		_toggle_window(menu if menu.visible else map_panel)
	elif key == KEY_Y and not get_tree().paused and not data.active_vehicle_id.is_empty():
		data.guide.headlights = not bool(data.guide.get("headlights",false))
		notify("Faróis ligados." if data.guide.headlights else "Faróis desligados.")
	elif blocks_gameplay() or get_tree().paused or not data.active_vehicle_id.is_empty() or (is_instance_valid(technology) and technology.fences.building):
		return
	else:
		if key >= KEY_7 and key <= KEY_9:
			select_tool([&"hoe",&"saw",&"hammer"][key-KEY_7])
			get_viewport().set_input_as_handled()
			return
		if key == KEY_G and _active_tool == &"hammer":
			hand_tools.build_greenhouse()
			get_viewport().set_input_as_handled()
			return
		if key >= KEY_1 and key <= KEY_6:
			select_seed(CropCatalog.IDS[key-KEY_1])
			get_viewport().set_input_as_handled()
			return
		match key:
			KEY_H: use_action("hoe")
			KEY_I: use_action("seed")
			KEY_R: use_action("harvest")
			KEY_J: eat()
			KEY_K: drink()
			KEY_T: rest()
			KEY_L: village.transfer(true)
			KEY_U: village.transfer(false)
			_: return
	get_viewport().set_input_as_handled()

func _toggle_window(window: Control) -> void:
	_hud_cursor = false
	window.visible = not window.visible
	get_tree().paused = window.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if window.visible else Input.MOUSE_MODE_CAPTURED
	if window == map_panel and window.visible: map_view.queue_redraw()
	if window == menu and window.visible:
		menu.find_child("CharacterChoice", true, false).select(int(data.guide.character))
		menu.find_child("TractorChoice", true, false).select(int(data.guide.tractor))
		menu.find_child("SensitivityChoice", true, false).value = float(data.guide.get("sensitivity", 0.002))

func _process(delta: float) -> void:
	if GameManager.session == null: return
	var current_data: PlayerData = GameManager.session.entities.get_player()
	if current_data != data:
		data = current_data
		_appearance = -1
		_tractor_style = -1
	var current_farm: FarmData = GameManager.session.farm
	if current_farm != farm:
		farm = current_farm
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if player != null:
			_appearance = -1
			_build_world()
	if not is_instance_valid(player): return
	var selected := StringName(data.guide.get("selected_seed","tomato"))
	if hud._selected != selected: EventBus.seed_selection_changed.emit(CropCatalog.normalize_id(selected))
	_active_tool = StringName(data.guide.get("tool","hoe"))
	if get_tree().paused: return
	_action_cooldown = maxf(0.0, _action_cooldown - delta)
	_message_time -= delta
	message.visible = _message_time > 0
	_swing = maxf(0, _swing - delta * 4)
	if is_instance_valid(hoe):
		hoe.rotation.x = -sin(_swing * PI) * 1.1
		hoe.visible = _active_tool in [&"hoe",&"saw",&"hammer"]
	_animate_presentation(delta)
	_elapsed += delta
	if _elapsed < 0.15: return
	var elapsed := _elapsed
	_elapsed = 0
	_update_target()
	# SoilFurrows renders all worked tiles, including tractor passes.
	_apply_character()
	_apply_tractors()
	_update_survival(elapsed)
	_update_ui()
	if map_panel.visible: map_view.queue_redraw()

func _update_survival(delta: float) -> void:
	var health: float = float(data.guide.health)
	if data.calories <= 0 or data.hydration <= 0:
		health = maxf(0, health - delta * 2)
	elif data.calories > 200 and data.hydration > 20:
		health = minf(100, health + delta * 0.3)
	data.guide.health = health
	player.walk_speed = 3.0 if data.energy < 10 else 5.0
	player.sprint_speed = 4.0 if data.energy < 10 or health < 25 else 8.0
	if health <= 0:
		if is_instance_valid(technology) and technology.drone.flying: technology.drone.land()
		if not data.active_vehicle_id.is_empty():
			for vehicle: Node in get_tree().get_nodes_in_group("vehicle"):
				if vehicle.has_method("exit_vehicle"): vehicle.call("exit_vehicle")
		death_panel.show()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if int(data.guide.mission) == 4 and not data.active_vehicle_id.is_empty():
		data.guide.mission = 5
		notify("Tractor conhecido! Próximo objectivo: guardar a colheita no armazém.")

func _update_ui() -> void:
	var stage: int = clampi(int(data.guide.mission),0,MISSIONS.size()-1)
	var hint := "Olhe para o chão a menos de 3 metros."
	if target_valid:
		var grid := farm.world_to_grid(target)
		var tile: FarmTileData = farm.get_tile_data(grid)
		match tile.state:
			FarmData.SoilState.GRASS: hint = "H · Preparar esta terra" if farm.can_plow_at(target) else "Terra não cultivável. Procure a horta sinalizada."
			FarmData.SoilState.PLOWED: hint = "I · Plantar %s
1–6 escolhem a semente. Humidade: %.0f%%" % [CropCatalog.get_crop(StringName(data.guide.get("selected_seed","tomato"))).name,tile.moisture]
			FarmData.SoilState.SEEDED:
				var progress := farm.get_tile_growth_progress(grid)
				hint = "%s · %s · %d%%
Espere ou descanse junto à casa [T]." % [CropCatalog.get_crop(tile.crop_type).name,CropCatalog.stage_name(CropCatalog.stage(progress)),int(progress*100)]
			FarmData.SoilState.HARVESTABLE: hint = "R · Colher %s" % CropCatalog.get_crop(tile.crop_type).plural
	if target_valid:
		hint += "\n"+farm.rotation_recommendation(farm.world_to_grid(target))
	if not _nearby_prompt.is_empty(): hint = _nearby_prompt
	var driving := not data.active_vehicle_id.is_empty()
	var vehicle_text := ""
	var tractor_driving := false
	if driving:
		hint = "WASD · Conduzir    Espaço · Travar
F · Sair    Y · Faróis"
		marker.visible = false
		var view: Node = null
		for candidate: Node in get_tree().get_nodes_in_group("vehicle"):
			if candidate.entity_data != null and candidate.entity_data.runtime_id == data.active_vehicle_id: view = candidate; break
		if view != null:
			tractor_driving = view.entity_data.definition_id == &"vehicle.truck"
			var kind := "CARRINHA" if view.entity_data.definition_id == &"vehicle.van" else "TRACTOR"
			var fuel: VehicleComponent = view.entity_data.get_component(&"vehicle") as VehicleComponent
			vehicle_text = "%s · %d km/h · Mudança %d
Combustível %.0f%%" % [kind,int(view.linear_velocity.length()*3.6),int(view.current_gear),fuel.fuel_level if fuel else 100.0]
	if is_instance_valid(technology):
		var tech_hint: String = technology.contextual_hint()
		if not tech_hint.is_empty():
			hint = tech_hint
			marker.visible = false
		if driving and is_instance_valid(technology.equipment) and technology.equipment.vehicle.entity_data.runtime_id == data.active_vehicle_id:
			vehicle_text += "\n"+technology.equipment.status()
	if is_instance_valid(technology) and technology.drone.flying:
		vehicle_text = technology.drone.status()
		hint = "OPERAÇÃO AÉREA · Rega de precisão"
	var tm: TimeManager = GameManager.session.time
	var location := "A SUA FAZENDA"
	for i: int in range(3):
		if Vector2(player.global_position.x-_farm_centers()[i].x,player.global_position.z-_farm_centers()[i].z).length()<25:
			location = ["FAZENDA AURORA","FAZENDA VALE VERDE","FAZENDA BOA COLHEITA"][i]
	EventBus.farm_hud_updated.emit({"health":float(data.guide.health),"hunger":100*data.calories/data.max_calories,"water":100*data.hydration/data.max_hydration,"energy":100*data.energy/data.max_energy,"day":tm.current_day,"hour":tm.current_hour,"minute":tm.current_minute,"money":int(data.guide.get("money",0)),"wood":int(data.guide.get("wood",0)),"employees":data.guide.get("employees",{}).size(),"seeds":int(data.guide.seeds),"food":int(data.guide.food),"stored":int(data.guide.get("warehouse_food",0)),"cargo":int(data.guide.get("van_food",0)),"parked":bool(data.guide.get("tractor_parked",false)),"produce":data.guide.get("produce",{}),"objective":"%s\n%s" % [MISSIONS[stage][0],str(MISSIONS[stage][1]).split("\n")[0]],"mission":stage,"quest":NeighborOrders.summary(data),"production":missions.summary(),"hint":hint,"tool":String(_active_tool),"driving":driving,"tractor":tractor_driving,"flying":is_instance_valid(technology) and technology.drone.flying,"vehicle":vehicle_text,"position":player.global_position,"location":location})

func _farm_centers() -> Array[Vector3]:
	return [Vector3(38,0,75),Vector3(210,0,60),Vector3(212,0,208)]

func select_seed(crop_id: StringName) -> void:
	if data == null or get_tree().paused or hud.dialogue.visible: return
	var id := CropCatalog.normalize_id(crop_id)
	data.guide.selected_seed = String(id)
	select_tool(&"seed")
	EventBus.seed_selection_changed.emit(id)

func select_tool(tool_id: StringName) -> void:
	if data == null or get_tree().paused or hud.dialogue.visible: return
	_active_tool = tool_id
	data.guide.tool = String(tool_id)
	if tool_id != &"hammer" and is_instance_valid(technology): technology.fences.building = false
	_update_hand_tool()
	if is_instance_valid(player):
		player._tool_inventory.equip_slot({&"hoe":1,&"seed":2,&"saw":3,&"hammer":4}.get(tool_id,1))
		player._refresh_tool_ui()

func _open_dialogue(farm_index: int) -> void:
	if data == null or death_panel.visible or get_tree().paused: return
	_dialogue_farm = farm_index
	_hud_cursor = false
	hud.show_dialogue(NeighborOrders.offer(data,farm_index))

func _on_dialogue_action(action: String) -> void:
	if action == "hire":
		employment.hire(_dialogue_farm)
		hud.close_dialogue()
		return
	if action == "assign_worker" and is_instance_valid(_employment_worker):
		employment.reassign(_employment_worker)
		employment.manage(_employment_worker)
		return
	if action == "dismiss_worker" and is_instance_valid(_employment_worker):
		employment.dismiss(_employment_worker)
		hud.close_dialogue()
		return
	if NeighborOrders.act(data,_dialogue_farm,action):
		notify("Encomenda aceite. Cultive os produtos e volte para entregar." if action == "accept" else "Entrega concluída! Recebeu a recompensa em MT.")
	hud.show_dialogue(NeighborOrders.offer(data,_dialogue_farm))

func notify(text: String) -> void:
	message.text = text
	message.visible = true
	_message_time = 7

func _update_target() -> void:
	target_valid = false
	if not data.active_vehicle_id.is_empty() or (is_instance_valid(technology) and technology.blocks_player()): return
	var camera: Camera3D = player.camera
	var center := camera.get_viewport().get_visible_rect().size * 0.5
	var ray := PhysicsRayQueryParameters3D.create(camera.project_ray_origin(center), camera.project_ray_origin(center) + camera.project_ray_normal(center) * 12)
	ray.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		target = hit.position
		var distance := Vector2(target.x - player.global_position.x, target.z - player.global_position.z).length()
		target_valid = distance <= 3.5 and hit.normal.y > 0.5
	if is_instance_valid(marker):
		marker.visible = target_valid
		if target_valid:
			var grid := farm.world_to_grid(target)
			marker.global_position = Vector3(grid.x + 0.5, target.y + 0.04, grid.y + 0.5)
			marker.material_override.albedo_color = Color(0.38, 0.94, 0.6, 0.45) if farm.can_plow_at(target) else Color(0.93, 0.44, 0.36, 0.45)

func use_selected(_seed: bool) -> void:
	if is_instance_valid(technology) and technology.fences.building: return
	use_action(String(_active_tool))

func use_action(action: String) -> bool:
	if data == null or blocks_gameplay() or get_tree().paused or not data.active_vehicle_id.is_empty() or (is_instance_valid(technology) and technology.fences.building): return false
	if _action_cooldown > 0: return false
	_action_cooldown = 0.25
	select_tool(StringName(action))
	if action == "saw": return hand_tools.cut_tree()
	if action == "hammer":
		technology.fences.building = true
		technology.fences.anchor = Vector3.INF
		notify("Martelo · clique marca postes; N termina. G constrói estufa fora do modo cercas.")
		return true
	_update_target()
	if not target_valid:
		notify("Olhe para o chão perto dos seus pés (alcance: 3 metros).")
		return false
	var grid := farm.world_to_grid(target)
	var tile: FarmTileData = farm.get_tile_data(grid)
	if action == "hoe" or action == "seed":
		player._tool_inventory.equip_slot(1 if action == "hoe" else 2)
		player._refresh_tool_ui()
	match action:
		"hoe":
			if not farm.can_plow_at(target):
				notify("Não é possível cultivar aqui. Use a horta sinalizada."); return false
			if tile.state != FarmData.SoilState.GRASS:
				notify("A terra já está preparada. I semeia; R colhe plantas maduras."); return false
			farm.set_tile_state(grid, FarmData.SoilState.PLOWED, target.y)
			missions.record("plow")
			_swing = 1.0
			EventBus.farm_action_feedback.emit(&"hoe",target,&"tomato",0)
			data.energy = maxf(0, data.energy - 0.5)
			if int(data.guide.mission) == 0: data.guide.mission = 1
			notify("Terra preparada! Aponte para este quadrado e prima I.")
		"seed":
			if tile.state != FarmData.SoilState.PLOWED:
				notify("Primeiro prepare a terra com H." if tile.state == 0 else "Já existe uma plantação neste quadrado."); return false
			if int(data.guide.seeds) <= 0:
				notify("Sem sementes. Reponha-as no armazém junto à casa [T]."); return false
			var selected := StringName(data.guide.get("selected_seed","tomato"))
			if not farm.plant_crop(grid, selected, int(CropCatalog.get_crop(selected).minutes), target.y): return false
			missions.record("plant")
			data.guide.seeds = int(data.guide.seeds) - 1
			if int(data.guide.mission) <= 1: data.guide.mission = 2
			EventBus.farm_action_feedback.emit(&"plant",target,selected,1)
			notify("%s plantado! 4 minutos até à colheita." % CropCatalog.get_crop(selected).name)
		"harvest":
			var harvest: Dictionary = farm.harvest_crop(grid)
			if harvest.is_empty():
				notify("Ainda está a crescer: %d%%." % int(farm.get_tile_growth_progress(grid) * 100) if tile.state == 2 else "Aponte para uma planta madura (amarela)."); return false
			missions.record("harvest")
			data.guide.harvests = int(data.guide.harvests) + 1
			var crop_id := StringName(harvest.crop_type)
			var amount: int = int(harvest.get("yield",1))
			ProduceInventory.add_harvest(data,crop_id,amount)
			data.guide.seeds = int(data.guide.seeds) + 2
			if int(data.guide.mission) <= 2: data.guide.mission = 3
			EventBus.farm_action_feedback.emit(&"harvest",target,crop_id,amount)
			notify("+%d %s · +2 sementes" % [amount,CropCatalog.get_crop(crop_id).plural])
	return true

func eat() -> void:
	if int(data.guide.food) <= 0:
		notify("Sem alimentos. Colha uma planta madura com R."); return
	ProduceInventory.take(data,"food",1)
	data.calories = minf(data.max_calories, data.calories + 350)
	data.energy = minf(data.max_energy, data.energy + 15)
	if int(data.guide.mission) == 3: data.guide.mission = 4
	notify("Comeu uma porção. Comida e energia recuperadas.")

func drink() -> void:
	if player.global_position.distance_to(Vector3(113, _ground(Vector3(113, 0, 139)), 139)) > 5:
		notify("Aproxime-se do poço azul junto à casa; depois prima K."); return
	data.hydration = data.max_hydration
	notify("Bebeu água do poço. Hidratação recuperada.")

func rest() -> void:
	if Vector2(player.global_position.x - HOME.x, player.global_position.z - HOME.z).length() > 18:
		notify("Aproxime-se da casa inicial para descansar [T]."); return
	GameManager.session.time.fast_forward_minutes(240, true)
	data.energy = data.max_energy
	data.guide.seeds = maxi(10, int(data.guide.seeds))
	notify("Descansou 4 horas. Energia recuperada e sementes repostas até 10.")

func _respawn() -> void:
	data.guide.health = 100.0
	data.calories = data.max_calories * 0.7
	data.hydration = data.max_hydration
	data.energy = data.max_energy
	data.guide.food = maxi(3, int(data.guide.food))
	data.guide.seeds = maxi(10, int(data.guide.seeds))
	player.global_position = Vector3(HOME.x, _ground(HOME) + 2, HOME.z)
	player.velocity = Vector3.ZERO
	death_panel.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	notify("Regressou a casa. Cuide da comida e da água.")

func _ground(pos: Vector3) -> float:
	if not is_instance_valid(_terrain_cache):
		_terrain_cache = get_tree().root.find_child("Terrain3D", true, false)
	if _terrain_cache != null:
		var terrain_data: Object = _terrain_cache.get("data")
		if terrain_data != null and terrain_data.has_method("get_height"):
			var height: float = terrain_data.call("get_height", pos)
			if is_finite(height): return height
	return 29.0

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
		mesh.add_child(body)
	return mesh

func _sign(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	_world.add_child(label)
	label.position = pos
	label.text = text
	label.font_size = 32
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10

func _build_world() -> void:
	if is_instance_valid(_world): return
	_world = Node3D.new()
	_world.name = "FazendasEVizinhanca"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	marker = _box(_world, Vector3.ZERO, Vector3(0.98, 0.018, 0.98), Color("61ef98"))
	marker.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override.albedo_color.a = 0.55
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i: int in range(4):
		var centers := [Vector3(104, 0, 145), Vector3(38, 0, 75), Vector3(210, 0, 60), Vector3(212, 0, 208)]
		var names := ["A SUA CASA\nT · Descansar / Repor sementes", "FAZENDA AURORA", "FAZENDA VALE VERDE", "FAZENDA BOA COLHEITA"]
		var pos: Vector3 = centers[i]
		pos.y = _ground(pos)
		_box(_world, pos + Vector3(0, 1.7, 0), Vector3(8, 3.4, 6), Color("c7946d") if i == 0 else Color("b5c69b"), true)
		var roof := _box(_world, pos + Vector3(0, 3.7, 0), Vector3(9, 0.5, 7), Color("793e36"))
		roof.rotation.z = 0.08
		_box(_world, pos + Vector3(0, 1, -3.04), Vector3(1.3, 2, 0.1), Color("48372d"))
		for x: float in [-2.4, 2.4]:
			_box(_world, pos + Vector3(x, 2, -3.06), Vector3(1.3, 1.1, 0.12), Color("98d9de"))
		_sign(pos + Vector3(0, 5.3, 0), names[i])
		if i > 0:
			for row: int in range(5):
				for col: int in range(8):
					var crop_pos := pos + Vector3(col * 1.2 - 4, 0, -7 - row * 1.5)
					crop_pos.y = _ground(crop_pos)
					_box(_world, crop_pos + Vector3(0, 0.02, 0), Vector3(1.1, 0.04, 1.2), Color("6e4d30"))
					var crop := MeshInstance3D.new()
					crop.mesh = CropVisualFactory.mesh_for([&"tomato",&"lettuce",&"carrot"][i-1],4)
					_world.add_child(crop)
					crop.position = crop_pos
			for x: int in range(-6, 7, 2):
				_box(_world, pos + Vector3(x, 0.7, -16), Vector3(0.15, 1.4, 0.15), Color("c4a275"))
			_box(_world, pos + Vector3(0, 0.85, -16), Vector3(12, 0.15, 0.12), Color("c4a275"))
	var well := Vector3(113, 0, 139)
	well.y = _ground(well)
	_box(_world, well + Vector3(0, 0.6, 0), Vector3(2, 1.2, 2), Color("748b9c"), true)
	_box(_world, well + Vector3(0, 1.22, 0), Vector3(1.6, 0.03, 1.6), Color("50bce3"))
	_sign(well + Vector3(0, 3, 0), "POÇO\nK · Beber água")
	_sign(Vector3(101, _ground(Vector3(101, 0, 119)) + 1.5, 119), "HORTA DE APRENDIZAGEM\nH · Preparar | I · Semear | R · Colher")
	for x: int in range(98, 113):
		for z: int in [119, 133]:
			var pos := Vector3(x, 0, z)
			pos.y = _ground(pos) + 0.05
			_box(_world, pos, Vector3(0.9, 0.08, 0.18), Color("e5d5a0"))
	missions = preload("res://Scripts/farm/ProductionMissions.gd").new()
	missions.guide = self
	_world.add_child(missions)
	employment = preload("res://Scripts/farm/WorkerEmployment.gd").new()
	employment.guide = self
	_world.add_child(employment)
	hand_tools = preload("res://Scripts/farm/HandToolActions.gd").new()
	hand_tools.guide = self
	_world.add_child(hand_tools)
	_world.add_child(preload("res://Scripts/presentation/RuralAmbience.gd").new())
	village = preload("res://Scripts/guided/FarmVillage.gd").new()
	village.guide = self
	_world.add_child(village)
	_world.add_child(preload("res://Scripts/presentation/FarmFeedback.gd").new())
	technology = preload("res://Scripts/technology/FarmTechnology.gd").new()
	technology.guide = self
	_world.add_child(technology)
	_world.add_child(preload("res://Scripts/presentation/SoilFurrows.gd").new())
	# A visible hoe is attached to the character, with a short swing on use.
	hoe = Node3D.new()
	hoe.name = "EnxadaVisivel"
	player.hero_mesh.add_child(hoe)
	hoe.position = Vector3(0.45, 0.9, 0.1)
	_update_hand_tool()

func cycle_tool(direction: int) -> void:
	var tools: Array[StringName] = [&"hoe",&"saw",&"hammer"]
	select_tool(tools[posmod(tools.find(_active_tool)+direction,tools.size())])

func _update_hand_tool() -> void:
	if not is_instance_valid(hoe): return
	for child: Node in hoe.get_children():
		hoe.remove_child(child)
		child.queue_free()
	var kit := MeshWorkshop.new()
	match _active_tool:
		&"saw":
			kit.box(Vector3(0,-0.15,0),Vector3(0.035,0.58,0.16),Color("aeb9b7"))
			kit.box(Vector3(0,0.22,0),Vector3(0.07,0.18,0.14),Color("b58a51"))
			for tooth: int in range(12): kit.box(Vector3(0,-0.4+tooth*0.04,-0.09),Vector3(0.035,0.025,0.03),Color("9da9a6"))
		&"hammer":
			kit.rod(Vector3(0,-0.35,0),Vector3(0,0.13,0),0.025,Color("ac855b"))
			kit.box(Vector3(0,0.16,0),Vector3(0.09,0.11,0.28),Color("79898d"))
		_:
			kit.rod(Vector3(0,-0.72,0),Vector3(0,0.55,0),0.023,Color("a87c4d"))
			kit.box(Vector3(0,-0.74,-0.08),Vector3(0.3,0.035,0.24),Color("737e83"))
	var view := MeshInstance3D.new()
	view.mesh = kit.finish()
	hoe.add_child(view)

func _apply_character() -> void:
	var choice: int = int(data.guide.character)
	player._camera_controller.mouse_sensitivity = float(data.guide.get("sensitivity", 0.002))
	if choice == _appearance: return
	_appearance = choice
	if is_instance_valid(hoe) and hoe.get_parent() != player.hero_mesh: hoe.reparent(player.hero_mesh)
	var old: Node = player.hero_mesh.get_node_or_null("PersonagemAlternativo")
	if old != null:
		old.get_parent().remove_child(old)
		old.queue_free()
	for child: Node in player.hero_mesh.get_children():
		if child is Node3D and child.name not in ["EnxadaVisivel", "PersonagemAlternativo"]: child.visible = false
	var character := ModularHuman.new()
	character.name = "PersonagemAlternativo"
	character.variant = choice
	character.show_work_tool = false
	character.rotation.y = PI
	player.hero_mesh.add_child(character)
	if is_instance_valid(hoe):
		hoe.reparent(character._elbows[1])
		hoe.position = Vector3(0,-0.26,0)
		hoe.rotation = Vector3.ZERO
	for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
		if vehicle.is_driven: vehicle.refresh_driver_visual(true)

func _apply_tractors() -> void:
	var vehicle: Node3D = null
	for candidate: Node3D in get_tree().get_nodes_in_group("vehicle"):
		if candidate.entity_data != null and candidate.entity_data.definition_id == &"vehicle.truck":
			vehicle = candidate
			break
	if vehicle == null: return
	var choice: int = int(data.guide.tractor)
	if choice == _tractor_style and vehicle == _last_vehicle: return
	_tractor_style = choice
	_last_vehicle = vehicle
	var original: Node3D = vehicle.get_node_or_null("Main_tractor")
	if original != null: original.hide()
	var old: Node3D = vehicle.get_node_or_null("ModernTractor")
	if old != null:
		vehicle.remove_child(old)
		old.queue_free()
	var old_roof: Node3D = vehicle.get_node_or_null("CoberturaPersonalizada")
	if old_roof != null:
		vehicle.remove_child(old_roof)
		old_roof.queue_free()
	_tractor_visual = ModernTractor.new()
	_tractor_visual.name = "ModernTractor"
	_tractor_visual.paint = [Color("bd7c66"),Color("719b87"),Color("638caa")][choice]
	vehicle.add_child(_tractor_visual)
	if vehicle.is_driven: vehicle.refresh_driver_visual(true)

func _animate_presentation(delta: float) -> void:
	var character: Node = player.hero_mesh.get_node_or_null("PersonagemAlternativo")
	if character is ModularHuman:
		character.movement_speed = Vector2(player.velocity.x,player.velocity.z).length()
		character.activity = _active_tool if _swing>0 else &"walk" if character.movement_speed>0.1 else &"idle"
	if is_instance_valid(_tractor_visual) and is_instance_valid(_last_vehicle):
		var speed: float = _last_vehicle.linear_velocity.dot(-_last_vehicle.global_transform.basis.z)
		_tractor_visual.animate_wheels(delta,speed,float(_last_vehicle._steering_target))
		var hour: int = GameManager.session.time.current_hour
		_tractor_visual.set_headlights(bool(data.guide.get("headlights",hour>=18 or hour<6)))


func _restore_presentation() -> void:
	_appearance = -1
	_tractor_style = -1
	_hud_cursor = false
	hud.dialogue.hide()
	if data != null:
		_active_tool = StringName(data.guide.get("tool","hoe"))
		_update_hand_tool()
		if is_instance_valid(player):
			player._tool_inventory.equip_slot({&"hoe":1,&"seed":2,&"saw":3,&"hammer":4}.get(_active_tool,1))
			player._refresh_tool_ui()
