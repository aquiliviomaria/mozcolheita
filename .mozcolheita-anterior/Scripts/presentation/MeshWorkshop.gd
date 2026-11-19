class_name MeshWorkshop
extends RefCounted
## Batches coloured primitives into one ArrayMesh with shared material surfaces.
var detail := 1
var _surfaces: Dictionary = {}
static var _materials: Dictionary = {}
func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.82
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
		if color.a < 0.99:
			result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			result.roughness = 0.25
		_materials[key] = result
	return _materials[key]
func append(mesh: Mesh, transform: Transform3D, color: Color) -> void:
	var key := color.to_html()
	if not _surfaces.has(key):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(material(color))
		_surfaces[key] = surface
	_surfaces[key].append_from(mesh, 0, transform)
func ball(pos: Vector3, radii: Vector3, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	sphere.radial_segments = 12*detail
	sphere.rings = 6*detail
	append(sphere, Transform3D(Basis.IDENTITY.scaled(radii), pos), color)
func box(pos: Vector3, dimensions: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var cube := BoxMesh.new()
	cube.size = dimensions
	append(cube, Transform3D(Basis.from_euler(rotation), pos), color)
func rod(start: Vector3, end: Vector3, radius: float, color: Color, end_radius: float = -1.0) -> void:
	var delta := end - start
	if delta.length() < 0.001: return
	var cylinder := CylinderMesh.new()
	cylinder.bottom_radius = radius
	cylinder.top_radius = radius if end_radius < 0 else end_radius
	cylinder.height = delta.length()
	cylinder.radial_segments = 8*detail
	cylinder.rings = 1
	append(cylinder, Transform3D(Basis(Quaternion(Vector3.UP, delta.normalized())), (start + end) * 0.5), color)
func leaf(pos: Vector3, width: float, length: float, color: Color, yaw: float, tilt: float = 0) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3.ZERO, Vector3(-width*0.5, 0.035, length*0.45), Vector3(0, -0.025, length), Vector3(width*0.5, 0.035, length*0.45)]
	for index: int in [0, 2, 1, 0, 3, 2]: st.add_vertex(points[index])
	st.generate_normals()
	st.index()
	append(st.commit(), Transform3D(Basis.from_euler(Vector3(tilt, yaw, 0)), pos), color)
func finish() -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface: SurfaceTool in _surfaces.values(): surface.commit(result)
	return result

## Continuous elliptical cross sections for anatomy and fitted clothing.
## Each ring is (height, half-width, depth, centre-Z), in metres.
func contour(rings: Array[Vector4], color: Color, segments: int = 32) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in range(rings.size()-1):
		for segment: int in range(segments):
			for corner: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var ring := rings[row+corner.y]
				var angle := TAU*(segment+corner.x)/segments
				st.set_smooth_group(0)
				st.add_vertex(Vector3(sin(angle)*ring.y,ring.x,cos(angle)*ring.z+ring.w))
	st.generate_normals()
	st.index()
	append(st.commit(),Transform3D.IDENTITY,color)
