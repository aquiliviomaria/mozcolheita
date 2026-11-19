extends Node
## End-to-end regression in the real main scene. Uses a disposable save slot only.
var failures: Array[String] = []
func check(ok: bool, description: String) -> void:
	print("MOZ: ",description," — ",ok)
	if not ok: failures.append(description)
func frames(count: int) -> void:
	for i: int in range(count): await get_tree().process_frame
func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/mozcolheita-"+label+".png")
func _ready() -> void:
	var game: Node = load("res://Scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await frames(2)
	get_tree().current_scene = game
	await get_tree().create_timer(3).timeout
	var guide: Node = get_tree().get_first_node_in_group("farm_guide")
	check(guide != null and guide.hud != null,"Cena principal e HUD inicializam")
	if guide == null or guide.hud == null: get_tree().quit(1); return
	var technology: Node3D = guide.technology
	check(technology != null and technology.equipment != null,"Módulos de tecnologia inicializam")
	if technology == null or technology.equipment == null: get_tree().quit(1); return
	var equipment: Node3D = technology.equipment
	var tractor: Node3D = equipment.vehicle
	var player: CharacterBody3D = guide.player
	var farm: FarmData = guide.farm
	print("MOZ_USER_DIR: ",OS.get_user_data_dir())
	check(ProjectSettings.get_setting("application/config/name")=="MozColheita","Nome MozColheita aplicado")
	check(OS.get_user_data_dir()==OS.get_environment("HOME")+"/.local/share/godot/app_userdata/OpenAcre","Pasta das gravações antigas preservada")
	guide.data.guide.character = 0
	guide._appearance = -1
	guide._apply_character()
	var human: Node3D = player.hero_mesh.get_node_or_null("PersonagemAlternativo")
	check(human != null and human.find_child("ChapeuDePalha",true,false)!=null,"Chapéu de palha permanente também no personagem inicial")
	tractor.freeze = true
	tractor.teleport(Vector3(136,guide._ground(Vector3(136,0,151))+0.75,151),0)
	tractor.linear_velocity = Vector3.ZERO
	tractor.enter_vehicle(player)
	await get_tree().create_timer(0.6).timeout
	for step: int in range(360):
		await get_tree().physics_frame
		if step>120 and tractor.linear_velocity.length()<0.25: break
	var driver: Node3D = tractor.get_node_or_null("ModernTractor/CondutorVisivel")
	check(driver != null and driver.visible and driver.seated and driver.find_child("ChapeuDePalha",true,false)!=null,"Condutor sentado e visível dentro da cabine")
	await press(KEY_7)
	await press(KEY_P)
	check(equipment.attached and equipment.selected==0,"P acopla a charrua da estação")
	await press(KEY_V)
	await press(KEY_B)
	check(equipment.lowered and equipment.active,"V baixa e B activa o equipamento")
	var center := Vector3(95.5,guide._ground(Vector3(95.5,0,104.5)),104.5)
	for x: int in range(-2,3): farm.reset_tile(farm.world_to_grid(center+Vector3(x,0,0)))
	check(equipment.work_at(center,Vector3.RIGHT)==3,"Charrua abre três sulcos na machamba de produção")
	check(equipment.work_at(center,Vector3.RIGHT)==0,"Passagens repetidas não destroem o solo")
	await press(KEY_P)
	await press(KEY_8)
	await press(KEY_P)
	await press(KEY_2)
	check(equipment.attached and equipment.selected==1 and guide.data.guide.selected_seed=="corn","Troca de semeadora e semente funciona ao conduzir")
	guide.data.guide.seeds = 10
	check(equipment.work_at(center,Vector3.RIGHT)==3 and int(guide.data.guide.seeds)==7,"Sementeira de milho em três linhas consome exactamente três sementes")
	check(equipment.work_at(center,Vector3.RIGHT)==0 and int(guide.data.guide.seeds)==7,"Não duplica plantas nem cobra sementes em solo ocupado")
	await press(KEY_P)
	await press(KEY_9)
	await press(KEY_P)
	check(equipment.attached and equipment.selected==2,"Acoplamento do tanque de rega")
	var water_before: float = guide.data.guide.machinery.tank
	for i: int in range(10): equipment.work_at(center,Vector3.RIGHT)
	var grid: Vector2i = farm.world_to_grid(center)
	check(farm.get_tile_data(grid).moisture==100 and is_equal_approx(water_before-float(guide.data.guide.machinery.tank),15),"Rega hidrata três parcelas e conserva litros de água")
	check(equipment.work_at(center,Vector3.RIGHT)==0,"Solo saturado não consome água adicional")
	# Showcase the real tractor and real cultivated terrain for the graphical run.
	tractor.teleport(center+Vector3(0,0.72,-4),0)
	await press(KEY_V)
	await press(KEY_B)
	if DisplayServer.get_name()!="headless":
		var camera := Camera3D.new()
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		game.add_child(camera)
		camera.global_position = tractor.global_position+Vector3(-6,4,-6)
		camera.look_at(tractor.global_position+Vector3(0,1,0.5))
		camera.make_current()
		VehicleSeatController._set_terrain_camera(game,camera)
		await frames(45)
		guide._update_ui()
		print("MOZ_VISUAL: tractor=",tractor.global_position," camera=",camera.global_position," current=",camera.current)
		await shot("tractor")
		camera.queue_free()
	tractor.force_eject()
	check(driver != null and not driver.visible and player.visible,"Sair remove o condutor da cabine e restitui o jogador")
	player.global_position = Vector3(104,guide._ground(Vector3(104,0,125))+0.1,125)
	var drone: Node3D = technology.drone
	await press(KEY_F8)
	check(drone.flying and guide.blocks_gameplay() and drone._camera.current,"F8 lança o drone, assume a câmara e bloqueia movimento terrestre")
	var irrigated := Vector3(104.5,guide._ground(Vector3(104.5,0,125.5)),125.5)
	var drone_grid: Vector2i = farm.world_to_grid(irrigated)
	farm.set_tile_state(drone_grid,FarmData.SoilState.PLOWED,irrigated.y)
	farm.get_tile_data(drone_grid).moisture = 50
	drone.global_position = irrigated+Vector3.UP*6
	var drone_water: float = guide.data.guide.drone.water
	await press(KEY_SPACE)
	check(drone.spraying,"Espaço activa a rega do drone")
	drone._process(0.21)
	check(farm.get_tile_data(drone_grid).moisture>50 and float(guide.data.guide.drone.water)<drone_water,"Drone rega o solo e consome a sua reserva")
	await frames(20)
	await shot("drone")
	await press(KEY_F8)
	check(not guide.blocks_gameplay() and player.camera.current,"Regresso do drone restitui a câmara e os comandos")
	var fences: Node3D = technology.fences
	await press(KEY_N)
	check(fences.building and not guide.blocks_gameplay(),"N inicia cercas e mantém o movimento terrestre disponível")
	check(not guide.use_action("hoe"),"Modo de construção bloqueia uso acidental da enxada")
	await press(KEY_N)
	check(not fences.building,"N termina a construção")
	var a := Vector3(117,guide._ground(Vector3(117,0,116)),116)
	var b := Vector3(120,guide._ground(Vector3(120,0,116)),116)
	check(fences.place(a,b),"Construção cria secção de cerca com colisão")
	check(not fences.place(a,b),"Não duplica uma secção existente")
	check(not fences.place(a,a+Vector3.RIGHT*15),"Rejeita secções fora do alcance máximo")
	check(fences.remove_near(a.lerp(b,0.5)),"Remoção identifica a secção pelo segmento")
	check(fences.place(a,b) and guide.data.guide.modern_fences.size()==1,"Cercas ficam registadas na gravação")
	check(get_tree().get_nodes_in_group("farm_workers").size()==12,"Doze trabalhadores e condutores em seis machambas")
	var away := true
	for worker: Node3D in get_tree().get_nodes_in_group("farm_workers"):
		for point: Vector3 in worker.route:
			if Vector2(point.x-105,point.z-126).length()<45: away = false
	check(away,"Rotas dos vizinhos ficam afastadas da machamba do jogador")
	var saved_tank: float = guide.data.guide.machinery.tank
	var saved_drone_water: float = guide.data.guide.drone.water
	if not SaveManager.slot_exists(9878):
		check(SaveManager.save_slot(9878),"Gravação de teste isolada")
		guide.data.guide.machinery.tank = 0
		guide.data.guide.drone.water = 0
		var loaded: bool = await SaveManager.load_slot(9878)
		await frames(15)
		check(loaded and is_equal_approx(float(guide.data.guide.machinery.tank),saved_tank) and is_equal_approx(float(guide.data.guide.drone.water),saved_drone_water),"Carregamento restaura equipamento, água e drone")
		check(guide.data.guide.modern_fences.size()==1 and technology.fences._views.size()==1,"Carregamento reconstrói as cercas")
		check(is_equal_approx(guide.farm.get_tile_data(grid).moisture,100),"Humidade é preservada no solo carregado")
		SaveManager._delete_dir_recursive(SaveManager._slot_dir(9878))
	await frames(10)
	print("MOZCOLHEITA_TESTS: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	game.queue_free()
	await frames(5)
	get_tree().quit(0 if failures.is_empty() else 1)
