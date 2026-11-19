extends Node3D
## Single-plant view. The authoritative state stays in FarmData.
var grid_position: Vector2i
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _stage := -1
var _crop_id: StringName = &""
var _refresh_timer := 0.0
var _harvest_icon: Label3D
var _ring: MeshInstance3D
var _player: Node3D
func _ready() -> void:
	add_to_group("crop_node")
	mesh_instance.position = Vector3.ZERO
	mesh_instance.set_surface_override_material(0,null)
	if GameManager.session != null:
		GameManager.session.farm.tile_updated.connect(_on_farm_tile_updated)
	refresh_from_data()
func _exit_tree() -> void:
	if GameManager.session != null and GameManager.session.farm.tile_updated.is_connected(_on_farm_tile_updated):
		GameManager.session.farm.tile_updated.disconnect(_on_farm_tile_updated)
func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer < 0.7: return
	_refresh_timer = 0
	refresh_from_data()
func refresh_from_data() -> void:
	if GameManager.session == null: return
	var farm: FarmData = GameManager.session.farm
	apply_visual_from_tile_data(farm.get_tile_data(grid_position))
func apply_visual_from_tile_data(tile: FarmTileData) -> void:
	if not tile.has_active_crop(): return
	var ripe := tile.state == FarmData.SoilState.HARVESTABLE
	var progress := GameManager.session.farm.get_tile_growth_progress(grid_position)
	var current := CropCatalog.stage(progress,ripe)
	var id := CropCatalog.normalize_id(tile.crop_type)
	if current != _stage or id != _crop_id:
		_stage = current
		_crop_id = id
		mesh_instance.mesh = CropVisualFactory.mesh_for(id,current)
	set_harvestable_visual(ripe)
func set_harvestable_visual(ripe: bool) -> void:
	if ripe and _harvest_icon == null:
		_harvest_icon = Label3D.new()
		_harvest_icon.text = "[R]"
		_harvest_icon.font_size = 32
		_harvest_icon.pixel_size = 0.003
		_harvest_icon.modulate = Color("f2d484")
		_harvest_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_harvest_icon.outline_size = 5
		_harvest_icon.position.y = float(CropCatalog.get_crop(_crop_id).height)+0.2
		add_child(_harvest_icon)
		_ring = MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.29
		ring.outer_radius = 0.31
		_ring.mesh = ring
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("e6cd8a")
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring.material_override = material
		_ring.position.y = 0.04
		_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_ring)
	if _harvest_icon != null:
		if not is_instance_valid(_player): _player = get_tree().get_first_node_in_group("player") as Node3D
		var nearby := _player != null and _player.global_position.distance_to(global_position)<5
		_harvest_icon.visible = ripe and nearby
		_ring.visible = ripe and nearby
func _on_farm_tile_updated(grid: Vector2i, state: int) -> void:
	if grid != grid_position: return
	if state == FarmData.SoilState.SEEDED or state == FarmData.SoilState.HARVESTABLE: refresh_from_data()
	else: queue_free()
