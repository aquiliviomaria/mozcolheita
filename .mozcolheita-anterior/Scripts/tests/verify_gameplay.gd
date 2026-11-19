extends Node
var failures: Array[String] = []
func check(condition: bool, text: String) -> void:
	print("GAMEPLAY: ", text, " — ", condition)
	if not condition: failures.append(text)
func wait_frames(count: int) -> void:
	for i: int in range(count): await get_tree().physics_frame
func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().process_frame
	var release: InputEventKey = event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame
	await get_tree().process_frame
func shot(name_text: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/openacre-" + name_text + ".png")
func _ready() -> void:
	var scene: PackedScene = load("res://Scenes/Main.tscn")
	var game: Node = scene.instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	get_tree().current_scene = game
	await wait_frames(180)
	var guide: Node = get_tree().get_first_node_in_group("farm_guide")
	var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
	check(guide != null and player != null, "Jogo e guia inicializam")
	if guide == null or player == null: get_tree().quit(1); return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.global_position = Vector3(105.5, guide._ground(Vector3(105.5,0,128.5)) + 0.2, 128.5)
	player._camera_controller.pitch = -0.9
	player._camera_controller.yaw_global = 0
	await wait_frames(90)
	guide._update_target()
	print("POSITION: ", player.global_position, " TARGET ", guide.target, " VALID ", guide.target_valid)
	check(guide.target_valid, "Marcador detecta terra próxima")
	var grid: Vector2i = guide.farm.world_to_grid(guide.target)
	guide.farm.reset_tile(grid)
	await press(KEY_H)
	check(guide.farm.get_tile_data(grid).state == FarmData.SoilState.PLOWED, "H usa enxada")
	await get_tree().create_timer(0.6).timeout
	await press(KEY_I)
	check(guide.farm.get_tile_data(grid).state == FarmData.SoilState.SEEDED, "I semeia por teclado")
	await shot("semente")
	await press(KEY_T)
	await get_tree().create_timer(0.6).timeout
	check(guide.farm.get_tile_data(grid).state == FarmData.SoilState.HARVESTABLE, "Descanso amadurece a plantação")
	await shot("madura")
	await press(KEY_R)
	check(int(guide.data.guide.harvests) == 1, "R colhe e guarda alimento")
	await press(KEY_J)
	check(int(guide.data.guide.mission) == 4, "Tutorial acompanha a alimentação")
	check(get_tree().get_nodes_in_group("vehicle").size() > 0, "Tractor aparece no mapa")
	await press(KEY_M)
	check(guide.map_panel.visible and get_tree().paused, "M abre o mapa táctico")
	await shot("mapa")
	await press(KEY_M)
	await press(KEY_O)
	guide.data.guide.character = 1
	guide.data.guide.tractor = 1
	guide._apply_character()
	guide._apply_tractors()
	check(player.hero_mesh.has_node("PersonagemAlternativo"), "Menu permite trocar personagem")
	await shot("menu")
	await press(KEY_O)
	await wait_frames(30)
	var village: Node = guide.village
	check(get_tree().get_nodes_in_group("farm_workers").size() == 12, "Doze NPCs trabalham e conduzem em seis machambas")
	var worker: Node3D = get_tree().get_nodes_in_group("farm_workers")[1]
	var before_worker: Vector3 = worker.global_position
	await get_tree().create_timer(0.7).timeout
	check(worker.global_position.distance_to(before_worker) > 0.2, "NPC percorre a sua rota")
	var van: Vehicle3D = null
	var tractor: Vehicle3D = null
	for vehicle: Vehicle3D in get_tree().get_nodes_in_group("vehicle"):
		if vehicle.entity_data.definition_id == &"vehicle.van": van = vehicle
		else: tractor = vehicle
	check(van != null, "Carrinha conduzível aparece no mundo")
	player.global_position = Vector3(87,guide._ground(Vector3(87,0,141)),141)
	guide.data.guide.food = 12
	guide.data.guide.warehouse_food = 0
	village.transfer(true)
	check(guide.data.guide.warehouse_food == 5 and guide.data.guide.food == 7, "Guardar alimentos no armazém")
	village.transfer(false)
	check(guide.data.guide.warehouse_food == 0 and guide.data.guide.food == 12, "Retirar alimentos do armazém")
	if van != null:
		player.global_position = van.global_position + Vector3(3,0,0)
		guide.data.guide.van_food = 0
		village.transfer(true)
		check(guide.data.guide.van_food == 5 and guide.data.guide.food == 7, "Carregar alimentos na carrinha")
		village.transfer(false)
		check(guide.data.guide.van_food == 0 and guide.data.guide.food == 12, "Descarregar alimentos da carrinha")
		van.enter_vehicle(player)
		await get_tree().create_timer(0.8).timeout
		check(guide.data.active_vehicle_id == van.entity_data.runtime_id and int(guide.data.guide.mission) == 5, "Conduzir e concluir tutorial")
		await press(KEY_F)
		check(guide.data.active_vehicle_id == &"", "F sai da carrinha")
	if tractor != null:
		tractor.global_position = Vector3(122,guide._ground(Vector3(122,0,151))+1,151)
		tractor.linear_velocity = Vector3.ZERO
		tractor.reset_physics_state()
		await wait_frames(360)
		print("GARAGE: ",tractor.global_position," velocity ",tractor.linear_velocity," flag ",guide.data.guide.get("tractor_parked",false))
		check(guide.data.guide.get("tractor_parked",false), "Garagem reconhece tractor estacionado")
	var saved_food: int = int(guide.data.guide.food)
	if not SaveManager.slot_exists(9876):
		var saved: bool = SaveManager.save_slot(9876)
		check(saved, "Guardar jogo completo")
		if saved:
			guide.data.guide.food = 0
			var loaded: bool = await SaveManager.load_slot(9876)
			check(loaded and int(guide.data.guide.food) == saved_food, "Carregar restaura alimentos e progresso")
			SaveManager._delete_dir_recursive(SaveManager._slot_dir(9876))
		await wait_frames(60)
	player.global_position = Vector3(105.5,guide._ground(Vector3(105.5,0,132))+0.2,132)
	player._camera_controller.pitch = -0.45
	player._camera_controller.yaw_global = -0.6
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await wait_frames(45)
	await shot("fazenda")
	guide.data.calories = 0
	guide.data.hydration = 0
	guide.data.guide.health = 0.1
	await wait_frames(30)
	check(guide.death_panel.visible and get_tree().paused, "Fome e sede levam à morte")
	guide._respawn()
	check(not get_tree().paused and guide.data.guide.health == 100, "Recomeçar em casa recupera o jogador")
	print("GAMEPLAY_TESTS: ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	await wait_frames(2)
	game.queue_free()
	await wait_frames(3)
	get_tree().quit(0 if failures.is_empty() else 1)
