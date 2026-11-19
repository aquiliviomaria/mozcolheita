extends RefCounted
## Pavimento que acompanha a colisão do terreno, sem criar degraus nos acessos.
static func piso(mundo: Node3D,pai: Node3D,area: Rect2) -> void:
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = ceili(area.size.x/2); var nz: int = ceili(area.size.y/2)
	for x: int in range(nx):
		for z: int in range(nz):
			for canto: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var ponto: Vector3 = pai.to_global(Vector3(area.position.x+(x+canto.x)*area.size.x/nx,0,area.position.y+(z+canto.y)*area.size.y/nz))
				ponto.y = mundo.altura(ponto)+0.055
				s.set_normal(Vector3.UP); s.add_vertex(pai.to_local(ponto))
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = s.commit(); var material: StandardMaterial3D = mundo.material(Color("9c9c86")).duplicate(); material.cull_mode = BaseMaterial3D.CULL_DISABLED; vista.material_override = material; pai.add_child(vista)
