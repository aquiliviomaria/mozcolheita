extends RefCounted
const A: GDScript = preload("res://scripts/house_architecture.gd")
static func caixa(c: Node3D,p: Vector3,t: Vector3,cor: String,solida: bool = true) -> Node3D:
	return A.bloco(c,p,t,Color(cor),solida,p.y>5.4)
static func oval(c: Node3D,p: Vector3,t: Vector3,cor: String) -> Node3D:
	var n: MeshInstance3D = MeshInstance3D.new(); var m: SphereMesh = SphereMesh.new(); m.radius = 0.5; m.height = 1; m.radial_segments = 16; m.rings = 8; n.mesh = m; n.scale = t; n.position = p; n.material_override = c.mundo.material(Color(cor)); c.add_child(n)
	if p.y>5.4: c.piso_superior.append(n)
	return n
static func construir(c: Node3D) -> void:
	# Sala de estar: sofá para duas pessoas e televisão virada para o sofá.
	caixa(c,Vector3(-7,1.18,7),Vector3(5.5,1.05,2),"397b59")
	caixa(c,Vector3(-7,2.05,7.9),Vector3(5.5,1.5,0.25),"238b45")
	for x: float in [-9.7,-4.3]: caixa(c,Vector3(x,1.65,7),Vector3(0.3,0.7,2),"238b45")
	caixa(c,Vector3(-7,0.67,4),Vector3(7,0.025,5),"a55c3a",false)
	caixa(c,Vector3(-7,1.2,3),Vector3(2.5,1,1.3),"765337")
	caixa(c,Vector3(-7,1.3,0.5),Vector3(4.2,1.3,0.9),"765337")
	caixa(c,Vector3(-7,3.1,0.3),Vector3(4.1,2.3,0.16),"202c2d",false).name = "Televisao"
	# Cozinha, duas cadeiras e bancada. Corredor x -2..2 fica livre.
	caixa(c,Vector3(8,1.63,0),Vector3(4,0.18,2.2),"aa7450")
	for x: float in [6.8,9.2]:
		for lado: float in [-1,1]: caixa(c,Vector3(x+lado*0.38,1.12,0),Vector3(0.14,1,1.6),"765337")
		caixa(c,Vector3(x,1.17,2),Vector3(1.2,0.16,1),"765337")
		caixa(c,Vector3(x,1.8,2.45),Vector3(1.2,1.2,0.14),"765337")
		for lado: float in [-1,1]: caixa(c,Vector3(x+lado*0.45,0.9,2),Vector3(0.12,0.5,0.8),"765337")
	caixa(c,Vector3(10,1.4,-8.5),Vector3(8,1.5,1.5),"7d9a76")
	caixa(c,Vector3(10,2.2,-8.5),Vector3(8.2,0.15,1.7),"d3c9aa")
	caixa(c,Vector3(13.8,2.2,-5.5),Vector3(2,3.1,1.7),"e9dfc5")
	for y: float in [1.1,2.4,3.6]: caixa(c,Vector3(4, y,-8.6),Vector3(2.8,0.15,1),"765337")
	# Quarto com cama de casal, duas almofadas e roupeiro.
	caixa(c,Vector3(8,6.1,6),Vector3(5,0.9,4.5),"765337")
	caixa(c,Vector3(8,6.65,6),Vector3(4.9,0.3,4.4),"c4bb9f")
	caixa(c,Vector3(8,7.2,8.2),Vector3(5,1.3,0.2),"765337")
	for x: float in [7.52,8.48]: caixa(c,Vector3(x,6.9,7.65),Vector3(0.9,0.16,0.75),"f8e9cb",false)
	caixa(c,Vector3(13.8,7.3,2),Vector3(2.8,3.3,2.4),"987449")
	for z: float in [1.5,2.5]: caixa(c,Vector3(12.35,7.3,z),Vector3(0.1,0.55,0.1),"dfac43",false)
	# Casa de banho: sanita com assento, lavatório e duche duplo.
	oval(c,Vector3(6,6.15,-7),Vector3(1.1,0.9,1.5),"eeeadd")
	var aro: MeshInstance3D = MeshInstance3D.new(); var toro: TorusMesh = TorusMesh.new(); toro.inner_radius = 0.32; toro.outer_radius = 0.48; aro.mesh = toro; aro.position = Vector3(6,6.65,-7); aro.scale.z = 1.3; aro.material_override = c.mundo.material(Color("eeeadd")); c.add_child(aro); c.piso_superior.append(aro)
	caixa(c,Vector3(6,6.7,-7.8),Vector3(1.1,1.4,0.45),"eeeadd")
	caixa(c,Vector3(4.2,6.5,-9.5),Vector3(2.5,1.6,1.2),"7d9a76")
	oval(c,Vector3(4.2,7.4,-9.5),Vector3(2.1,0.3,1.1),"eeeadd")
	caixa(c,Vector3(11,5.68,-7),Vector3(4,0.08,4),"b4c8c6",false)
	for x: float in [9,13]:
		var vidro: Node3D = c.vidro(Vector3(x,7.2,-7),Vector3(0.05,3,4)); c.piso_superior.append(vidro)
	for x: float in [10.2,11.8]:
		caixa(c,Vector3(x,8.2,-8.7),Vector3(0.08,2,0.08),"a2b3b6",false)
		caixa(c,Vector3(x,9.15,-8.3),Vector3(0.5,0.09,0.6),"a2b3b6",false)
	# Elevador aberto com plataforma móvel e acesso por ambos os pisos.
	c.elevador = Node3D.new(); c.elevador.name = "Elevador"; c.elevador.position = Vector3(-5,0.64,-5); c.add_child(c.elevador)
	c.mundo.caixa(c.elevador,Vector3(0,-0.15,0),Vector3(3.8,0.3,3.8),Color("697d7a"),true)
	for x: float in [-7,-3]: caixa(c,Vector3(x,5,-5),Vector3(0.12,9,4),"697d7a")
	caixa(c,Vector3(-5,5,-7),Vector3(4,9,0.12),"697d7a")
	for y: float in [1.3,6.3]: caixa(c,Vector3(-5,y,-2.9),Vector3(4,0.15,0.12),"d6b85b")
