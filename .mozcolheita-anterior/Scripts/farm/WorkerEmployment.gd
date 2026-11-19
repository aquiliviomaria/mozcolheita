extends Node
## Workers receive 8 MT per successfully completed task; no charge for travel or waiting.
## A task reserves one tile while the worker walks, preventing duplicate assignments.
const WAGE := 8
var guide: Node
var _targets: Dictionary = {}
var _timers: Dictionary = {}
var _tasks: Dictionary = {}
var _bound: PlayerData
func _ready() -> void:
	EventBus.game_loaded_successfully.connect(func() -> void: _bound = null)
func worker_id(worker: Node) -> String:
	var start: Vector3 = worker.route[0]
	return "%d:%d:%d" % [worker.farm_index,roundi(start.x),roundi(start.z)]
func records() -> Dictionary:
	if _bound != guide.data:
		_bound = guide.data
		_targets.clear()
		_timers.clear()
		_tasks.clear()
	if not guide.data.guide.has("employees"): guide.data.guide.employees = {}
	return guide.data.guide.employees
func hire(farm_index: int) -> bool:
	var staff := records()
	for worker: Node in get_tree().get_nodes_in_group("farm_workers"):
		if worker.driving or worker.farm_index != farm_index: continue
		var id := worker_id(worker)
		if staff.has(id): continue
		if int(guide.data.guide.get("money",0))<WAGE:
			guide.notify("Precisa de 8 MT para a primeira tarefa. Complete missões ou entregas.")
			return false
		# Assignment is explicit and saved: alternating staff cover the two owned plots.
		var plot := 0 if staff.size()%2==0 else 1
		staff[id] = {"plot":plot,"tasks":0,"paid":0}
		worker.say("Vou trabalhar na sua machamba. 8 MT por tarefa.")
		guide.missions.record("hire")
		guide.notify("Contratado para %s · 8 MT/tarefa. F permite mudar parcela ou dispensar." % ["horta" if plot==0 else "campo de produção"])
		return true
	guide.notify("Todos os trabalhadores desta fazenda já estão contratados.")
	return false
func manage(worker: Node) -> void:
	var record: Dictionary = records()[worker_id(worker)]
	guide._employment_worker = worker
	guide.hud.show_dialogue({"name":"Trabalhador contratado", "text":"%s · %d tarefas · %d MT pagos\n8 MT por tarefa. Sem saldo ou sementes, aguarda sem cobrar." % ["Horta" if int(record.plot)==0 else "Campo de produção",record.tasks,record.paid],"action":"assign_worker","button":"Mudar parcela"})
func dismiss(worker: Node) -> void:
	var id := worker_id(worker)
	records().erase(id)
	_targets.erase(id)
	_timers.erase(id)
	_tasks.erase(id)
func reassign(worker: Node) -> void:
	var id := worker_id(worker)
	var record: Dictionary = records()[id]
	record.plot = 1-int(record.plot)
	_targets.erase(id)
	_timers.erase(id)
	_tasks.erase(id)
func _task(grid: Vector2i) -> String:
	var tile: FarmTileData = guide.farm.get_tile_data(grid)
	if tile.state == FarmData.SoilState.HARVESTABLE: return "harvest"
	if tile.state == FarmData.SoilState.GRASS: return "plow"
	if tile.state == FarmData.SoilState.PLOWED and int(guide.data.guide.seeds)>0: return "plant"
	if tile.state == FarmData.SoilState.SEEDED and tile.moisture<80: return "irrigate"
	return ""
func process_employee(worker: Node3D, delta: float) -> bool:
	if worker.driving or not records().has(worker_id(worker)): return false
	var id := worker_id(worker)
	var record: Dictionary = records()[id]
	worker._bubble_timer = maxf(0,worker._bubble_timer-delta)
	worker._bubble.visible = worker._bubble_timer>0
	worker._work_state.text = "Funcionário · %s · 8 MT/tarefa" % ["horta" if int(record.plot)==0 else "produção"]
	worker._work_state.visible = worker.global_position.distance_to(guide.player.global_position)<22
	worker._human.activity = &"idle"
	worker._human.movement_speed = 0
	if int(guide.data.guide.get("money",0))<WAGE: return true
	if not _targets.has(id):
		# Bounded scans cover 24 assigned cells per worker, rather than the entire farm.
		var origin := Vector2i(99,120) if int(record.plot)==0 else Vector2i(74,95)
		for i: int in range(24):
			var grid := origin+Vector2i(i%6,i/6)
			if grid in _targets.values() or _task(grid).is_empty(): continue
			_targets[id] = grid
			break
		if not _targets.has(id): return true
	var grid: Vector2i = _targets[id]
	var destination := Vector3(grid.x+0.5,0,grid.y+0.5)
	destination.y = guide._ground(destination)
	var distance := Vector2(destination.x-worker.global_position.x,destination.z-worker.global_position.z).length()
	if distance>0.65:
		var direction := destination-worker.global_position
		# Travel around the house/garage via the west field access lane.
		if worker.global_position.z>135 and destination.z<135:
			var waypoint := Vector3(79,guide._ground(Vector3(79,0,135)),135)
			direction = waypoint-worker.global_position
		worker.rotation.y = lerp_angle(worker.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*5))
		var step := direction.normalized()*minf(distance,delta*2.1)
		var position := worker.global_position+step
		position.y = guide._ground(position)
		# Do not pass through the player or a parked vehicle.
		if position.distance_to(guide.player.global_position)<1:
			worker.say("Com licença, preciso de passar.")
			return true
		for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
			if position.distance_to(vehicle.global_position)<2.4: return true
		worker.global_position = position
		worker._human.movement_speed = 2.1
		return true
	var task := _task(grid)
	if task.is_empty():
		_targets.erase(id)
		_timers.erase(id)
		_tasks.erase(id)
		return true
	# Time belongs to a specific tile and action; reassignment never carries work over.
	var task_key := "%s:%s" % [grid,task]
	if _tasks.get(id,"") != task_key:
		_tasks[id] = task_key
		_timers[id] = 0.0
	var moisture_before: float = guide.farm.get_tile_data(grid).moisture
	worker._human.activity = StringName("hoe" if task=="plow" else task)
	_timers[id] = float(_timers.get(id,0))+delta
	if float(_timers[id])<3: return true
	_timers[id] = 0.0
	var success := false
	match task:
		"plow":
			guide.farm.set_tile_state(grid,FarmData.SoilState.PLOWED,destination.y)
			success = true
		"plant":
			success = guide.farm.plant_crop(grid,StringName(guide.data.guide.get("selected_seed","tomato")),240,destination.y)
			if success: guide.data.guide.seeds = int(guide.data.guide.seeds)-1
		"irrigate": success = guide.farm.irrigate(grid,3)>0
		"harvest":
			var harvest: Dictionary = guide.farm.harvest_crop(grid)
			success = not harvest.is_empty()
			if success:
				ProduceInventory.add_harvest(guide.data,StringName(harvest.crop_type),int(harvest["yield"]))
				guide.data.guide.seeds = int(guide.data.guide.seeds)+2
				guide.data.guide.harvests = int(guide.data.guide.harvests)+1
	if success:
		guide.data.guide.money = int(guide.data.guide.money)-WAGE
		record.tasks = int(record.tasks)+1
		record.paid = int(record.paid)+WAGE
		if task != "irrigate" or (moisture_before<80 and guide.farm.get_tile_data(grid).moisture>=80):
			guide.missions.record(task)
	_targets.erase(id)
	return true
