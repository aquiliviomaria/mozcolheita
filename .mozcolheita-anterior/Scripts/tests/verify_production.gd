extends Node
## Integration checks use the real scene and an isolated save slot; never overwrite user slots.
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	print("PRODUCTION: ",message," — ",ok)
	if not ok: failures.append(message)
func frames(count: int) -> void:
	for i: int in range(count): await get_tree().process_frame
func _ready() -> void:
	var game: Node = load("res://Scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await frames(2)
	get_tree().current_scene = game
	await get_tree().create_timer(4).timeout
	var guide: Node = get_tree().get_first_node_in_group("farm_guide")
	if guide == null or guide.missions == null: check(false,"Scene initialisation"); get_tree().quit(1); return
	check(int(guide.data.guide.money)==500_000,"New farm receives 500,000 MT")
	check("500.000 MT" in guide.hud.resource_label.text,"HUD displays the full capital with Portuguese thousands grouping")
	var legacy := PlayerData.new()
	legacy.restore_guide({"money":37,"mission":4})
	check(int(legacy.guide.money)==500_037 and int(legacy.guide.mission)==4,"Old save receives capital while preserving earnings and progress")
	legacy.guide.money = 499_900
	var saved_balance: Dictionary = legacy.guide.duplicate(true)
	legacy.restore_guide(saved_balance)
	check(int(legacy.guide.money)==499_900,"Reload does not duplicate the capital grant")
	check(ProjectSettings.get_setting("application/config/icon")=="res://MozColheita-icon.png","Project icon")
	check(guide.hud.bars.size()==4 and not guide.hud.bars.health is ProgressBar,"Compact drawn life icons")
	guide.select_tool(&"hoe")
	guide.cycle_tool(1)
	check(guide.data.guide.tool=="saw" and guide.player._tool_inventory.get_active_tool_name()=="Serrote","Mouse wheel tool cycle and actual inventory")
	guide.cycle_tool(1)
	check(guide.data.guide.tool=="hammer","Hammer selection")
	guide.cycle_tool(1)
	check(guide.data.guide.tool=="hoe","Tool wraparound")
	var money: int = int(guide.data.guide.money)
	guide.missions.record("plow",12)
	check(int(guide.data.guide.money)==money+24,"Mission reward paid")
	guide.missions.record("plow",1)
	check(int(guide.data.guide.money)==money+24,"Mission reward cannot repeat")
	var worker: Node3D
	for candidate: Node3D in get_tree().get_nodes_in_group("farm_workers"):
		if not candidate.driving: worker = candidate; break
	worker.set_physics_process(false)
	guide.data.guide.money = 100
	check(guide.employment.hire(worker.farm_index),"NPC hired")
	var id: String = guide.employment.worker_id(worker)
	var grid := Vector2i(99,120)
	guide.farm.reset_tile(grid)
	worker.global_position = Vector3(99.5,guide._ground(Vector3(99.5,0,120.5)),120.5)
	guide.employment._targets[id] = grid
	money = int(guide.data.guide.money)
	guide.employment.process_employee(worker,3.1)
	check(guide.farm.get_tile_data(grid).state==FarmData.SoilState.PLOWED,"Worker prepares assigned tile")
	check(int(guide.data.guide.money)==money-8,"Worker paid exactly once per successful task")
	guide.employment._targets[id] = grid
	var seeds: int = int(guide.data.guide.seeds)
	guide.employment.process_employee(worker,3.1)
	check(guide.farm.get_tile_data(grid).has_active_crop() and int(guide.data.guide.seeds)==seeds-1,"Worker plants using real seed inventory")
	guide.employment._targets[id] = grid
	guide.farm.get_tile_data(grid).moisture = 50
	guide.employment.process_employee(worker,3.1)
	check(guide.farm.get_tile_data(grid).moisture==80,"Worker irrigates assigned crop")
	var irrigation_count: int = int(guide.data.guide.production_missions.get("irrigate",0))
	guide.farm.get_tile_data(grid).moisture = 0
	guide.employment._targets[id] = grid
	guide.employment.process_employee(worker,3.1)
	check(guide.farm.get_tile_data(grid).moisture==30 and int(guide.data.guide.production_missions.get("irrigate",0))==irrigation_count,"Partial worker irrigation does not complete a mission parcel")
	guide.farm.get_tile_data(grid).moisture = 80
	guide.farm.get_tile_data(grid).state = FarmData.SoilState.HARVESTABLE
	guide.employment._targets[id] = grid
	var food: int = int(guide.data.guide.food)
	guide.employment.process_employee(worker,3.1)
	check(int(guide.data.guide.food)>food and not guide.farm.get_tile_data(grid).has_active_crop(),"Worker harvest reaches player inventory")
	guide.data.guide.money = 0
	money = int(guide.employment.records()[id].tasks)
	guide.employment.process_employee(worker,5)
	check(int(guide.employment.records()[id].tasks)==money and int(guide.data.guide.money)==0,"No work or negative balance without wages")
	var farm: FarmData = guide.farm
	grid = Vector2i(106,123)
	farm.reset_tile(grid)
	var yields: Array[int] = []
	for crop: StringName in [&"corn",&"wheat",&"tomato"]:
		farm.set_tile_state(grid,FarmData.SoilState.PLOWED,guide._ground(Vector3(grid.x,0,grid.y)))
		farm.plant_crop(grid,crop,1)
		farm.get_tile_data(grid).state = FarmData.SoilState.HARVESTABLE
		yields.append(int(farm.harvest_crop(grid)["yield"]))
	check(yields==[2,3,4],"First harvest, same-family penalty and rotation bonus")
	var restored := FarmData.new()
	restored.import_exact_tiles(farm.export_exact_tiles())
	check(restored.get_tile_data(grid).last_family=="solanaceae" and is_equal_approx(restored.get_tile_data(grid).nutrients,farm.get_tile_data(grid).nutrients),"Rotation history and soil health serialise")
	var tree: Node3D = get_tree().get_nodes_in_group("harvestable_tree")[0]
	guide.player.global_position = tree.global_position+Vector3(1,0,0)
	var wood: int = int(guide.data.guide.get("wood",0))
	for i: int in range(3): guide.hand_tools.cut_tree()
	check(not tree.visible and int(guide.data.guide.wood)==wood+6,"Saw fells tree and supplies wood")
	guide.player.set_physics_process(false)
	var ground: float = guide._ground(Vector3(109.5,0,128.5))
	guide.player.global_position = Vector3(109.5,ground+0.1,131)
	guide.player.camera.global_position = Vector3(109.5,ground+2.5,131)
	guide.player.camera.look_at(Vector3(109.5,ground,128.5))
	await get_tree().physics_frame
	guide.data.guide.wood = 12
	check(guide.hand_tools.build_greenhouse(),"Hammer constructs greenhouse from ground aim")
	check(int(guide.data.guide.wood)==0 and guide.hand_tools._greenhouses.size()==1,"Greenhouse consumes exactly twelve wood")
	check(not guide.hand_tools.build_greenhouse(),"Insufficient wood prevents another greenhouse")
	var human: Node = guide.player.hero_mesh.get_node("PersonagemAlternativo")
	var face: ArrayMesh = human._head.get_child(0).mesh
	var skin_indices: PackedInt32Array = face.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	check(skin_indices.has(0),"Continuous face remains indexed when merged with nose and ears")
	var equipment: Node = guide.technology.equipment
	check(equipment._indicators.size()==3,"Three coupling beacons")
	var drone: Node = guide.technology.drone
	check(drone._body.scale.x>1.5 and drone._indicator!=null,"Large drone with activation beacon")
	# Beacons and coupling use the same distance, speed and socket conditions.
	var tractor: Node3D = equipment.vehicle
	tractor.freeze = true
	tractor.linear_velocity = Vector3.ZERO
	var dock: Array = guide.data.guide.machinery.docks[0]
	tractor.teleport(Vector3(dock[0],dock[1]+0.75,dock[2]),0)
	check(equipment.can_couple(0),"Green coupling available at the station")
	tractor.linear_velocity = Vector3(1,0,0)
	check(not equipment.can_couple(0),"Moving tractor cannot advertise coupling")
	tractor.linear_velocity = Vector3.ZERO
	tractor.teleport(Vector3(dock[0]+9,dock[1],dock[2]),0)
	check(not equipment.can_couple(0),"Outside seven metres coupling is unavailable")
	check(human.find_child("ChapeuDePalha",true,false)!=null,"Permanent straw hat on human model")
	check(drone.launch(),"Drone enters pilot mode")
	guide._update_ui()
	check(guide.hud.vehicle_label.visible and "Q/E" in guide.hud.vehicle_label.text,"Drone controls persist in right HUD")
	check(guide.hud.controls_panel.visible and "Espaço" in guide.hud.controls_label.text,"Flight and irrigation commands in persistent controls card")
	drone.land()
	var save_slot := 9879
	if not SaveManager.slot_exists(save_slot):
		check(SaveManager.save_slot(save_slot),"Isolated save")
		guide.data.guide.employees = {}
		guide.data.guide.greenhouses = []
		tree.show()
		var loaded: bool = await SaveManager.load_slot(save_slot)
		await frames(15)
		check(loaded and guide.employment.records().has(id),"Employee contracts reload")
		check(guide.hand_tools._greenhouses.size()==1,"Greenhouse rebuilds on load")
		check(not tree.visible,"Felled tree remains hidden on load")
		check(guide.data.guide.production_missions.paid_plow,"Reward claims reload")
		check(guide.farm.get_tile_data(grid).last_family=="solanaceae","Rotation reloads through SaveManager")
		SaveManager._delete_dir_recursive(SaveManager._slot_dir(save_slot))
	guide.employment.manage(worker)
	var plot: int = int(guide.employment.records()[id].plot)
	guide.employment._timers[id] = 2.9
	guide._on_dialogue_action("assign_worker")
	check(int(guide.employment.records()[id].plot)==1-plot,"Employee dialogue changes assigned plot")
	check(not guide.employment._timers.has(id),"Reassigning workers clears time spent on the previous plot")
	guide._on_dialogue_action("dismiss_worker")
	check(not guide.employment.records().has(id),"Employee dialogue dismisses worker")
	print("PRODUCTION_TESTS: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	game.queue_free()
	await frames(4)
	get_tree().quit(0 if failures.is_empty() else 1)
