extends RefCounted
## Produtos partilhados por caixas: espigas com grãos, tomate com cálice e hortícolas.
const G: GDScript = preload("res://scripts/geometry.gd")
static var modelos: Dictionary = {}
static func modelo(cultura: int) -> ArrayMesh:
	if modelos.has(cultura): return modelos[cultura]
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	match cultura:
		0:
			G.oval(s,Vector3.ZERO,Vector3(0.16,0.145,0.16),Color("c94429"),16,10)
			for i: int in range(5):
				var t: float = TAU*i/5; G.folha(s,Vector3(0,0.135,0),Vector3(sin(t)*0.09,0.145,cos(t)*0.09),0.018,Color("238b45"),0.01,false)
		1:
			G.oval(s,Vector3.ZERO,Vector3(0.075,0.075,0.23),Color("c59b35"),12,8)
			for fila: int in range(9):
				var z: float = -0.18+fila*0.045; var raio: float = 0.065*sqrt(maxf(0.12,1-pow(z/0.24,2)))
				for i: int in range(8):
					var t: float = TAU*i/8
					G.oval(s,Vector3(sin(t)*raio,cos(t)*raio,z),Vector3(0.022,0.024,0.022),Color("ebbd4c"),6,4)
			for lado: float in [-1,1]: G.folha(s,Vector3(0,-0.07,0.22),Vector3(lado*0.13,0,-0.16),0.035,Color("658948"),0.02,false)
		2:
			G.oval(s,Vector3.ZERO,Vector3(0.17,0.15,0.17),Color("85ab53"),16,10)
			for i: int in range(7):
				var t: float = TAU*i/7; G.folha(s,Vector3.ZERO,Vector3(sin(t)*0.22,-0.07,cos(t)*0.22),0.10,Color("578c3e"),0.12,false)
		3:
			G.tubo(s,Vector3(0,0,-0.18),Vector3(0,0,0.22),0.075,Color("d97b2c"),0.006,14)
			for i: int in range(4):
				var t: float = i*TAU/4; G.folha(s,Vector3(0,0,-0.18),Vector3(sin(t)*0.09,0.06,-0.29),0.025,Color("238b45"),0.02,false)
	modelos[cultura] = G.terminar(s); return modelos[cultura]
