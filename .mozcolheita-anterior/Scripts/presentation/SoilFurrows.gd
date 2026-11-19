extends Node3D
## Shared meshes and two MultiMeshes make worked, wet and dry soil readable at field scale.
var _farm: FarmData
var _timer := 0.0
var _dirty := true
var _batches: Array[MultiMeshInstance3D] = []
var _last_center := Vector3.INF
func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for wet: bool in [false,true]:
		var kit := MeshWorkshop.new()
		var earth := Color("342b23") if wet else Color("66452d")
		kit.box(Vector3(0,0,0),Vector3(0.99,0.035,0.99),earth.darkened(0.18))
		for row: int in range(4):
			kit.rod(Vector3(-0.375+row*0.25,0.025,-0.49),Vector3(-0.375+row*0.25,0.025,0.49),0.072,earth.lightened(0.12))
		for clod: int in range(7):
			kit.ball(Vector3(sin(clod*21.7)*0.4,0.045,cos(clod*17.1)*0.4),Vector3(0.025,0.018,0.035),earth.lightened(0.1))
		var view := MultiMeshInstance3D.new()
		view.multimesh = MultiMesh.new()
		view.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		view.multimesh.mesh = kit.finish()
		add_child(view)
		_batches.append(view)
func _process(delta: float) -> void:
	if GameManager.session == null: return
	if _farm != GameManager.session.farm:
		if _farm != null and _farm.tile_updated.is_connected(_changed): _farm.tile_updated.disconnect(_changed)
		_farm = GameManager.session.farm
		_farm.tile_updated.connect(_changed)
		_dirty = true
	_timer += delta
	if _timer < 0.35: return
	_timer = 0
	var player: Node3D = get_tree().get_first_node_in_group("player")
	if player == null: return
	var center := player.global_position
	var pd: PlayerData = GameManager.session.entities.get_player()
	if not pd.active_vehicle_id.is_empty():
		for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
			if vehicle.entity_data.runtime_id == pd.active_vehicle_id: center = vehicle.global_position
	if center.distance_to(_last_center)>12: _dirty = true
	if not _dirty: return
	_dirty = false
	_last_center = center
	var groups: Array = [[],[]]
	for grid: Vector2i in _farm._grid:
		var tile: FarmTileData = _farm.get_tile_data(grid)
		var pos := Vector3(grid.x+0.5,tile.height+0.035,grid.y+0.5)
		if tile.state == FarmData.SoilState.GRASS or pos.distance_to(center)>85: continue
		groups[1 if tile.moisture>=80 else 0].append(Transform3D(Basis.IDENTITY,pos))
	for i: int in range(2):
		var multi := _batches[i].multimesh
		multi.instance_count = groups[i].size()
		for j: int in range(groups[i].size()): multi.set_instance_transform(j,groups[i][j])
func _changed(_grid: Vector2i, _state: int) -> void: _dirty = true
