class_name EquipmentVisuals
extends RefCounted
## Visual-only equipment; work is performed by TractorEquipment through FarmData.
static func build(kind: StringName) -> Node3D:
	var root := Node3D.new()
	var mesh := MeshWorkshop.new()
	var steel := Color("a6b4b5")
	var paint := Color("d19a48") if kind == &"plow" else Color("519583")
	for side: float in [-1,1]:
		mesh.rod(Vector3(side*0.4,0.2,-0.45),Vector3(side*0.7,0.4,0.9),0.045,steel)
	mesh.rod(Vector3(0,0.6,0),Vector3(0,0.35,0.8),0.065,steel)
	mesh.box(Vector3(0,0.4,0.9),Vector3(3,0.14,0.16),paint)
	if kind == &"plow":
		for x: float in [-1,0,1]:
			mesh.rod(Vector3(x,0.4,0.9),Vector3(x,-0.3,1.3),0.045,steel)
			mesh.box(Vector3(x,-0.27,1.46),Vector3(0.52,0.08,0.62),steel,Vector3(0.15,0,0.5))
			mesh.append(_moldboard(),Transform3D(Basis.IDENTITY,Vector3(x,-0.27,1.12)),steel)
			mesh.box(Vector3(x-0.21,-0.27,1.4),Vector3(0.045,0.4,0.35),steel)
	elif kind == &"seeder":
		mesh.box(Vector3(0,0.85,1),Vector3(2.5,0.7,0.72),paint)
		mesh.box(Vector3(0,1.23,1),Vector3(2.65,0.08,0.8),Color("dce0d6"))
		for x: float in [-1,0,1]:
			mesh.rod(Vector3(x,0.55,1),Vector3(x,-0.25,1.3),0.045,Color("343f42"))
			mesh.rod(Vector3(x-0.065,-0.16,1.4),Vector3(x+0.065,-0.16,1.4),0.24,Color("394548"))
	else:
		mesh.rod(Vector3(0,0.45,0.9),Vector3(0,1.6,0.9),0.65,Color("d3ded6"))
		mesh.box(Vector3(0,1.66,0.9),Vector3(0.28,0.1,0.28),paint)
		mesh.rod(Vector3(-2.5,0.5,1.4),Vector3(2.5,0.5,1.4),0.045,paint)
		for x: float in [-2,-1,0,1,2]:
			mesh.rod(Vector3(x,0.5,1.4),Vector3(x,0.34,1.4),0.026,steel)
			var spray := spray_particles(Vector3(x,0.3,1.4),0.65)
			root.add_child(spray)
	if kind != &"irrigator":
		var dust := spray_particles(Vector3(0,-0.1,1.3),0.6)
		dust.name = "Poeira"
		dust.direction = Vector3.UP
		dust.spread = 65
		dust.color = Color(0.55,0.4,0.24,0.4)
		dust.emission_sphere_radius = 1.1
		dust.scale_amount_min = 2
		dust.scale_amount_max = 5
		root.add_child(dust)
	var view := MeshInstance3D.new()
	view.mesh = mesh.finish()
	root.add_child(view)
	return root
static func spray_particles(pos: Vector3, reach: float) -> CPUParticles3D:
	var spray := CPUParticles3D.new()
	spray.name = "Agua"
	spray.position = pos
	spray.amount = 24
	spray.lifetime = 0.7
	spray.direction = Vector3.DOWN
	spray.spread = 28
	spray.initial_velocity_min = reach
	spray.initial_velocity_max = reach*1.6
	spray.gravity = Vector3(0,-3,0)
	spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	spray.emission_sphere_radius = 0.16
	var drop := SphereMesh.new()
	drop.radius = 0.018
	drop.height = 0.05
	drop.radial_segments = 4
	drop.rings = 2
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = material
	spray.mesh = drop
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spray.color = Color(0.45,0.8,1,0.7)
	spray.emitting = false
	return spray

## Curved mouldboard rolls the cut strip to the side instead of a flat toy blade.
static func _moldboard() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in range(8):
		for corner: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
			var t := (row+corner.y)/8.0
			st.set_smooth_group(0)
			st.add_vertex(Vector3((corner.x-0.5)*0.6+t*0.18,(1-cos(t*1.7))*0.36,t*0.65))
	st.generate_normals()
	st.index()
	return st.commit()
