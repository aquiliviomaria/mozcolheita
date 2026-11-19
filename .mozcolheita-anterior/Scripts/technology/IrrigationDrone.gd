extends Node3D
## Remote camera and flight remain in this module; water changes only through FarmData.
signal flight_changed(flying: bool)
var guide: Node
var flying := false
var spraying := false
var _yaw := 0.0
var _pitch := -0.4
var _camera: Camera3D
var _body: Node3D
var _rotors: Array[Node3D] = []
var _spray: CPUParticles3D
var _timer := 0.0
var _indicator: Label3D
var _bound: PlayerData
func _ready() -> void:
	name = "DroneDeRega"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_body = Node3D.new()
	add_child(_body)
	var kit := MeshWorkshop.new()
	kit.box(Vector3.ZERO,Vector3(0.65,0.16,0.44),Color("dee5e1"))
	kit.box(Vector3(0,0.1,0),Vector3(0.35,0.07,0.3),Color("344b50"))
	kit.ball(Vector3(0,-0.18,0),Vector3(0.23,0.16,0.18),Color("6f9c8a"))
	kit.ball(Vector3(0,-0.08,-0.26),Vector3(0.065,0.065,0.065),Color("233c47"))
	for x: float in [-1,1]:
		for z: float in [-1,1]:
			var point := Vector3(x*0.57,0.03,z*0.48)
			kit.rod(Vector3(x*0.15,0,z*0.1),point,0.035,Color("3e5257"))
			kit.rod(point,point+Vector3.UP*0.08,0.07,Color("8aa69c"))
			var rotor := Node3D.new()
			rotor.position = point+Vector3.UP*0.1
			_body.add_child(rotor)
			var blades := MeshWorkshop.new()
			blades.box(Vector3.ZERO,Vector3(0.68,0.012,0.045),Color("293c42"))
			blades.box(Vector3.ZERO,Vector3(0.045,0.012,0.68),Color("293c42"))
			var view := MeshInstance3D.new()
			view.mesh = blades.finish()
			rotor.add_child(view)
			_rotors.append(rotor)
		for z: float in [-0.2,0.2]: kit.rod(Vector3(x*0.22,-0.05,z),Vector3(x*0.28,-0.4,z),0.018,Color("42565a"))
		kit.rod(Vector3(x*0.28,-0.4,-0.3),Vector3(x*0.28,-0.4,0.3),0.022,Color("42565a"))
	var mesh := MeshInstance3D.new()
	mesh.mesh = kit.finish()
	_body.add_child(mesh)
	_spray = EquipmentVisuals.spray_particles(Vector3(0,-0.3,0),3)
	_spray.amount = 64
	_spray.lifetime = 1.3
	_body.add_child(_spray)
	_body.scale = Vector3.ONE*1.85
	_indicator = preload("res://Scripts/presentation/CouplingIndicator.gd").new()
	_indicator.text = "▼ DRONE · F8 ACTIVAR"
	_indicator.position.y = 2.6
	add_child(_indicator)
	_camera = Camera3D.new()
	_camera.position = Vector3(0,2.8,6.5)
	_camera.rotation.x = _pitch
	_camera.fov = 65
	add_child(_camera)
func _state() -> Dictionary:
	if not guide.data.guide.has("drone"):
		guide.data.guide.drone = {"battery":100.0,"water":40.0}
	return guide.data.guide.drone
func can_launch() -> bool:
	return not flying and guide.data.active_vehicle_id.is_empty() and not get_tree().paused and not guide.blocks_gameplay() and float(_state().battery)>=10
func launch() -> bool:
	if not guide.data.active_vehicle_id.is_empty():
		guide.notify("Saia do veículo [F] antes de controlar o drone."); return false
	if guide.blocks_gameplay() or get_tree().paused: return false
	if float(_state().battery)<10:
		guide.notify("Carregue o drone na estação junto à garagem [K]."); return false
	flying = true
	spraying = false
	global_position = guide.player.global_position+Vector3(0,5,-2)
	_yaw = guide.player.camera.global_rotation.y
	rotation.y = _yaw
	_camera.make_current()
	VehicleSeatController._set_terrain_camera(self,_camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flight_changed.emit(true)
	guide.notify("DRONE · WASD voa · Q desce / E sobe · Espaço rega · F8 regressa")
	return true
func land() -> void:
	if not flying: return
	flying = false
	spraying = false
	_spray.emitting = false
	guide.player.camera.make_current()
	VehicleSeatController._set_terrain_camera(self,guide.player.camera)
	flight_changed.emit(false)
	guide.notify("Drone recolhido. K recarrega água e bateria junto à garagem.")
func refill() -> bool:
	var p: Vector3 = guide.player.global_position
	if Vector2(p.x-132,p.z-151).length()>12: return false
	_state().battery = 100.0
	_state().water = 40.0
	guide.notify("Drone abastecido: bateria 100% · água 40 L.")
	return true
func _input(event: InputEvent) -> void:
	if not is_instance_valid(guide) or guide.data == null or get_tree().paused: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F8:
			if flying: land()
			else: launch()
			get_viewport().set_input_as_handled()
		elif flying and event.physical_keycode == KEY_SPACE:
			spraying = not spraying
			get_viewport().set_input_as_handled()
		elif flying and event.physical_keycode == KEY_ESCAPE:
			land()
			get_viewport().set_input_as_handled()
	if flying and event is InputEventMouseMotion:
		_yaw -= event.relative.x*0.002
		_pitch = clampf(_pitch-event.relative.y*0.002,-1.4,-0.2)
		rotation.y = _yaw
		_camera.rotation.x = _pitch
		get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
	if not is_instance_valid(guide) or guide.data == null: return
	if _bound != guide.data:
		if flying: land()
		_bound = guide.data
		_state()
	_indicator.visible = can_launch() and guide.player.global_position.distance_to(global_position)<12
	if not flying:
		global_position = Vector3(129,guide._ground(Vector3(129,0,151))+0.8,151)
		return
	if get_tree().paused or guide.menu.visible or guide.map_panel.visible: return
	var state := _state()
	state.battery = maxf(0,float(state.battery)-delta*0.22)
	if float(state.battery)<=0 or float(guide.data.guide.health)<=0:
		land(); return
	var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	direction = Basis(Vector3.UP,_yaw)*direction.limit_length(1)
	direction.y = float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q))
	global_position += direction*delta*7
	var horizontal := Vector2(global_position.x-105,global_position.z-145).limit_length(150)
	global_position.x = 105+horizontal.x
	global_position.z = 145+horizontal.y
	var height: float = guide._ground(global_position)
	global_position.y = clampf(global_position.y,height+3,height+20)
	_body.rotation.z = lerpf(_body.rotation.z,-direction.x*0.08,delta*5)
	for rotor: Node3D in _rotors: rotor.rotate_y(delta*65)
	_spray.emitting = spraying and float(state.water)>0
	_timer += delta
	if _timer>=0.2:
		_timer = 0
		if spraying and float(state.water)>0:
			# Visible spray costs water even when no cultivated land is below it.
			var budget := minf(float(state.water),0.6)
			for x: int in range(-1,2):
				for z: int in range(-1,2):
					var grid: Vector2i = guide.farm.world_to_grid(global_position+Vector3(x,0,z))
					var tile: FarmTileData = guide.farm.get_tile_data(grid)
					var before := tile.moisture
					guide.farm.irrigate(grid,budget/9)
					if before<80 and tile.moisture>=80: guide.missions.record("irrigate")
			state.water = maxf(0,float(state.water)-budget)
			if float(state.water)<=0:
				spraying = false
				guide.notify("Drone sem água. F8 regressa; K reabastece junto à garagem.")
func status() -> String:
	var state := _state()
	return "DRONE · %.0f%% bateria · %.1f L\nWASD · Voar   Q/E · Altura\nEspaço · %s   F8 · Regressar" % [state.battery,state.water,"Parar rega" if spraying else "Regar"]
