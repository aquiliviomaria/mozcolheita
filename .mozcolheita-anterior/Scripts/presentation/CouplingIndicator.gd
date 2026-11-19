extends Label3D
## Shared, distance-gated interaction beacon. Caller supplies availability and position.
var clock := 0.0
var _ring: MeshInstance3D
func _ready() -> void:
	text = "▼ ACOPLAR · P"
	font_size = 38
	pixel_size = 0.003
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	modulate = Color("63ff98")
	outline_modulate = Color("12382a")
	outline_size = 9
	no_depth_test = false
	visibility_range_end = 25
	_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.19
	ring.rings = 16
	ring.ring_segments = 8
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("63ff98")
	ring.material = material
	_ring.mesh = ring
	_ring.position.y = 0.3
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
func _process(delta: float) -> void:
	clock += delta
	modulate.a = 0.85+sin(clock*3)*0.15
	_ring.position.y = 0.3+sin(clock*2.5)*0.07
	_ring.rotation.z = sin(clock)*0.12
