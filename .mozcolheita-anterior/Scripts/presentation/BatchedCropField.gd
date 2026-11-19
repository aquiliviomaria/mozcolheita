extends Node3D
## Dense fields use one MultiMesh per crop/stage, rebuilding only when the signature changes.
var _groups: Dictionary = {}
var _signature := 0
var _icons: Array[Label3D] = []
func sync(farm: FarmData, loaded_chunks: Dictionary, player_position: Vector3) -> void:
	var batches: Dictionary = {}
	var records: Array = []
	var nearby: Array[Vector3] = []
	for chunk: Vector2i in loaded_chunks:
		for grid: Vector2i in farm.get_seeded_chunk_tiles(chunk):
			var tile: FarmTileData = farm.get_tile_data(grid)
			var ripe := tile.state == FarmData.SoilState.HARVESTABLE
			var stage := CropCatalog.stage(farm.get_tile_growth_progress(grid),ripe)
			var id := CropCatalog.normalize_id(tile.crop_type)
			var key := "%s:%d" % [id,stage]
			var pos := Vector3(grid.x+0.5,tile.height,grid.y+0.5)
			if not batches.has(key): batches[key] = {"id":id,"stage":stage,"positions":[]}
			batches[key].positions.append(pos)
			records.append([grid,id,stage,tile.height])
			if ripe and player_position.distance_to(pos)<6: nearby.append(pos+Vector3.UP*(float(CropCatalog.get_crop(id).height)+0.2))
	var signature := hash(records)
	if signature != _signature:
		_signature = signature
		for key: String in _groups: _groups[key].hide()
		for key: String in batches:
			var batch: Dictionary = batches[key]
			var instance: MultiMeshInstance3D
			if not _groups.has(key):
				instance = MultiMeshInstance3D.new()
				add_child(instance)
				_groups[key] = instance
			else: instance = _groups[key]
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = CropVisualFactory.mesh_for(batch.id,int(batch.stage))
			multi.instance_count = batch.positions.size()
			for i: int in range(batch.positions.size()): multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,batch.positions[i]))
			instance.multimesh = multi
			instance.show()
	nearby.sort_custom(func(a: Vector3,b: Vector3) -> bool: return a.distance_squared_to(player_position)<b.distance_squared_to(player_position))
	for i: int in range(mini(8,nearby.size())):
		if _icons.size() <= i:
			var icon := Label3D.new()
			icon.text = "[R]"
			icon.font_size = 30
			icon.pixel_size = 0.003
			icon.modulate = Color("f2d484")
			icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(icon)
			_icons.append(icon)
		_icons[i].position = nearby[i]
		_icons[i].show()
	for i: int in range(nearby.size(),_icons.size()): _icons[i].hide()
