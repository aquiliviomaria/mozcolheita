extends Implement3D

@export var plow_width: float = 3.0

@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	required_power_kw = 25.0
	# Allow custom width
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(plow_width, 0.5, 0.5)
	$DetectionArea/CollisionShape3D.shape = shape
	super._ready()
	_update_processing_state()

func _on_lower_changed(_state: bool) -> void:
	_update_processing_state()

func _on_pto_changed(_state: bool) -> void:
	_update_processing_state()

func _update_processing_state() -> void:
	var should_process: bool = is_lowered and is_active
	set_physics_process(should_process)
	detection_area.monitoring = should_process

func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)
	# Only runs when lowered and active
	var move_speed_sq: float = linear_velocity.length_squared()
	var attached_vehicle := get_attached_vehicle()
	if attached_vehicle != null:
		move_speed_sq = attached_vehicle.linear_velocity.length_squared()
	if move_speed_sq > 0.1:
		_plow_ground()

func _plow_ground() -> void:
	var soil_service: Node = get_tree().get_first_node_in_group("soil_layer_service")
	# Calculate grid coords from left to right along the plow width
	var center_pos: Vector3 = global_position
	var right_dir: Vector3 = global_transform.basis.x.normalized()
	# Sample grid blocks across the width of the plow
	var half_width_samples: int = int(plow_width / 2.0)
	for i: int in range(-half_width_samples, half_width_samples + 1):
		var sample_pos: Vector3 = center_pos + (right_dir * i)
		var guide: Node = get_tree().get_first_node_in_group("farm_guide")
		if guide != null:
			var height: float = guide._ground(sample_pos)
			if absf(sample_pos.y-height)>1.5: continue
			sample_pos.y = height
		else:
			var ray := PhysicsRayQueryParameters3D.create(sample_pos+Vector3.UP*1.5,sample_pos+Vector3.DOWN*2,1,[get_rid()])
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty(): continue
			sample_pos.y = hit.position.y
		if not GameManager.session.farm.can_plow_at(sample_pos):
			continue
		var grid_pos: Vector2i = GameManager.session.farm.world_to_grid(sample_pos)
		if soil_service != null and soil_service.has_method("plow_world"):
			soil_service.plow_world(sample_pos)
		else:
			var tile_data: FarmTileData = GameManager.session.farm.get_tile_data(grid_pos)
			if tile_data.state == FarmData.SoilState.GRASS:
				GameManager.session.farm.set_tile_state(grid_pos, FarmData.SoilState.PLOWED, sample_pos.y)
