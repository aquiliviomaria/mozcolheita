extends Node
var failures: Array[String] = []
func check(condition: bool, text: String) -> void:
	print("OVERHAUL: ",text," — ",condition)
	if not condition: failures.append(text)
func wait_frames(count: int) -> void:
	for i: int in range(count): await get_tree().process_frame
func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_frames(2)
	var release: InputEventKey = event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await wait_frames(2)
func shot(name_text: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/openacre-overhaul-"+name_text+".png")
func _ready() -> void:
	var game: Node = load("res://Scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await wait_frames(2)
	get_tree().current_scene = game
	await get_tree().create_timer(3.5).timeout
	var guide: Node = get_tree().get_first_node_in_group("farm_guide")
	var player: CharacterBody3D = guide.player
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var farm: FarmData = guide.farm
	var data: PlayerData = guide.data
	check(guide.hud.seed_buttons.size()==6,"Seis escolhas de sementes no HUD")
	check(guide.hud.bars.size()==4,"Saúde, fome, energia e água no topo")
	var planted: Array[Vector2i] = []
	for i: int in range(6):
		player.global_position = Vector3(99.5+i*2,guide._ground(Vector3(99.5+i*2,0,128.5))+0.1,128.5)
		player._camera_controller.pitch = -0.9
		player._camera_controller.yaw_global = 0
		await get_tree().create_timer(0.35).timeout
		guide._update_target()
		var grid: Vector2i = farm.world_to_grid(guide.target)
		farm.reset_tile(grid)
		farm.set_tile_state(grid,FarmData.SoilState.PLOWED,guide.target.y)
		await press(KEY_1+i)
		check(data.guide.selected_seed==String(CropCatalog.IDS[i]),"Tecla %d selecciona %s" % [i+1,CropCatalog.get_crop(CropCatalog.IDS[i]).name])
		check(guide.hud._selected==CropCatalog.IDS[i],"HUD acompanha a selecção")
		await get_tree().create_timer(0.3).timeout
		await press(KEY_I)
		check(farm.get_tile_data(grid).crop_type==CropCatalog.IDS[i],"I planta o tipo escolhido")
		planted.append(grid)
		for stage: int in range(5):
			var mesh: ArrayMesh = CropVisualFactory.mesh_for(CropCatalog.IDS[i],stage)
			check(mesh.get_surface_count()>0,"Modelo %s fase %d" % [CropCatalog.IDS[i],stage])
			check(mesh==CropVisualFactory.mesh_for(CropCatalog.IDS[i],stage),"Malha partilhada em cache")
	# Buttons use the same selection path as keyboard input.
	guide.hud.seed_buttons[&"tomato"].pressed.emit()
	check(data.guide.selected_seed=="tomato","Escolha de sementes por botão")
	GameManager.session.time.fast_forward_minutes(240,true)
	for grid: Vector2i in planted: check(farm.get_tile_data(grid).state==FarmData.SoilState.HARVESTABLE,"Cultura pronta ao fim de 4 horas de jogo")
	for i: int in range(planted.size()):
		var harvest: Dictionary = farm.harvest_crop(planted[i])
		check(int(harvest.get("yield",0))==int(CropCatalog.get_crop(CropCatalog.IDS[i]).get("yield")),"Colheita produz o rendimento correcto")
		ProduceInventory.add_harvest(data,CropCatalog.IDS[i],int(harvest.get("yield",0)))
	# Verify conservation across storage and a real quest delivery (no duplication).
	var starting_money: int = int(data.guide.money)
	var before_total: int = int(data.guide.food)
	var before_tomatoes: int = int(data.guide.produce.tomato)
	ProduceInventory.transfer(data,"food","warehouse_food",before_total)
	check(int(data.guide.food)==0 and int(data.guide.produce.get("tomato",0))==0,"Guardar retira os produtos do bolso")
	ProduceInventory.transfer(data,"warehouse_food","food",before_total)
	check(int(data.guide.food)==before_total and int(data.guide.produce.tomato)==before_tomatoes,"Retirar devolve os tipos de produtos sem duplicar")
	check(NeighborOrders.act(data,0,"accept"),"NPC aceita encomenda")
	check(NeighborOrders.act(data,0,"deliver"),"Produtos entregues ao NPC")
	check(int(data.guide.money)==starting_money+24,"Entrega paga moedas reais do jogo")
	check(not NeighborOrders.act(data,0,"deliver"),"A mesma entrega não paga duas vezes")
	EventBus.neighbor_dialogue_requested.emit(1)
	check(guide.hud.dialogue.visible and guide.blocks_gameplay(),"Diálogo abre e bloqueia as acções da fazenda")
	await shot("dialogo")
	guide.hud.close_dialogue()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Plant a small six-crop showcase near the player for visual QA.
	for i: int in range(6):
		var grid := Vector2i(100+i*2,125)
		var pos := Vector3(grid.x+0.5,0,grid.y+0.5)
		farm.set_tile_state(grid,FarmData.SoilState.PLOWED,guide._ground(pos))
		farm.plant_crop(grid,CropCatalog.IDS[i],240,guide._ground(pos))
	GameManager.session.time.fast_forward_minutes(240,true)
	player.global_position = Vector3(105.5,guide._ground(Vector3(105.5,0,132))+0.1,132)
	player._camera_controller.pitch = -0.62
	player._camera_controller.yaw_global = 0
	await get_tree().create_timer(1).timeout
	guide._update_ui()
	await shot("hud")
	var tractor: Node
	for vehicle: Node in get_tree().get_nodes_in_group("vehicle"):
		if vehicle.entity_data.definition_id==&"vehicle.truck": tractor=vehicle
	check(tractor!=null and tractor.has_node("ModernTractor"),"Tractor tem carroçaria profissional modular")
	if tractor!=null:
		var model: ModernTractor = tractor.get_node("ModernTractor")
		model.set_headlights(true)
		check(model._lamps.size()==2 and model._lamps[0].visible,"Faróis funcionais")
	var npc: Node = get_tree().get_nodes_in_group("farm_workers")[0]
	check(npc._human is ModularHuman and npc._human._arms.size()==2,"NPC articulado com membros humanos")
	check(npc._human._head!=null,"NPC tem cabeça orientável")
	# Dense planting explicitly exercises the MultiMesh path.
	for x: int in range(95,109):
		for z: int in range(110,124):
			var grid := Vector2i(x,z)
			var pos := Vector3(x+0.5,0,z+0.5)
			if farm.get_tile_data(grid).state!=FarmData.SoilState.SEEDED and farm.get_tile_data(grid).state!=FarmData.SoilState.HARVESTABLE:
				farm.set_tile_state(grid,FarmData.SoilState.PLOWED,guide._ground(pos))
				farm.plant_crop(grid,&"wheat",240,guide._ground(pos))
	await get_tree().create_timer(1.4).timeout
	var manager: Node = get_tree().get_first_node_in_group("grid_manager")
	check(manager._batch_mode and manager._batch_renderer._groups.size()>0,"Campos densos usam MultiMesh")
	if not SaveManager.slot_exists(9877):
		check(SaveManager.save_slot(9877),"Guardar escolha, culturas e encomendas")
		data.guide.selected_seed="carrot"
		data.guide.money=0
		var loaded: bool = await SaveManager.load_slot(9877)
		check(loaded and data.guide.selected_seed=="tomato" and int(data.guide.money)==starting_money+24,"Carregar restaura semente e dinheiro")
		check(data.guide.orders["0"].complete,"Encomenda concluída mantém-se na gravação")
		SaveManager._delete_dir_recursive(SaveManager._slot_dir(9877))
	print("OVERHAUL_TESTS: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	game.queue_free()
	await wait_frames(3)
	get_tree().quit(0 if failures.is_empty() else 1)
