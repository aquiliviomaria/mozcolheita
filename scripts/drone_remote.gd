extends RefCounted
static func criar(a: Node3D) -> Node3D:
	var r: Node3D = Node3D.new(); r.name = "ComandoDrone"; a.visual.add_child(r); r.position = Vector3(0,1.12,-0.42); r.rotation.x = 0.25
	a.mundo.caixa(r,Vector3.ZERO,Vector3(0.5,0.1,0.28),Color("283f43"))
	for x: float in [-0.22,0.22]:
		a.mundo.caixa(r,Vector3(x,-0.04,0.06),Vector3(0.09,0.12,0.22),Color("182a2d"))
		a.mundo.caixa(r,Vector3(x,0.12,-0.12),Vector3(0.018,0.25,0.018),Color("33474b"))
		a.mundo.caixa(r,Vector3(x*0.65,0.075,0.03),Vector3(0.04,0.06,0.04),Color("d7bc64"))
	a.mundo.caixa(r,Vector3(0,0.058,-0.035),Vector3(0.2,0.015,0.14),Color("63b8ca"))
	r.visible = a.pilotar_drone; return r
