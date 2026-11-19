extends RefCounted
## Dois avatares oficiais, construídos sobre o mesmo rig e escala física.
const VERDE: Color = Color("14532d")
const CLARO: Color = Color("238b45")
const CREME: Color = Color("f5e8c9")
const OURO: Color = Color("dfac43")
const CABELO: Color = Color("201713")

static func contorno(a: Node3D,pai: Node3D,aneis: Array[Vector3],cor: Color) -> MeshInstance3D:
	return a.contorno(pai,aneis,cor)

static func cilindro(a: Node3D,pai: Node3D,pos: Vector3,baixo: float,cima: float,altura: float,cor: Color) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new(); mesh.bottom_radius = baixo; mesh.top_radius = cima; mesh.height = altura; mesh.radial_segments = 32
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = mesh; vista.position = pos; vista.material_override = a.mundo.material(cor); pai.add_child(vista); return vista

static func linha(a: Node3D,pai: Node3D,pontos: Array[Vector3],raio: float,cor: Color) -> void:
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(pontos.size()-1): preload("res://scripts/geometry.gd").tubo(s,pontos[i],pontos[i+1],raio,cor,raio,8)
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = preload("res://scripts/geometry.gd").terminar(s); pai.add_child(vista)

static func bandeira(a: Node3D) -> void:
	var origem: Vector3 = Vector3(0,1.19,-0.164)
	for i: int in range(3): a.peca(a.visual,origem+Vector3(0,0.032-i*0.032,0),Vector3(0.15,0.028,0.006),[CLARO,Color("181b16"),Color("f5ce48")][i])
	for y: float in [-0.016,0.016]: a.peca(a.visual,origem+Vector3(0,y,-0.004),Vector3(0.15,0.004,0.004),Color("f8f1de"))
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	preload("res://scripts/geometry.gd").triangulo(s,origem+Vector3(-0.075,0.048,-0.008),origem+Vector3(0.0,0,-0.008),origem+Vector3(-0.075,-0.048,-0.008),Color("d3342f"))
	# Estrela dourada no triângulo vermelho; distintivo legível à escala do avatar.
	for i: int in range(10):
		var t0: float = -PI/2+i*TAU/10; var t1: float = t0+TAU/10
		var r0: float = 0.019 if i%2==0 else 0.008; var r1: float = 0.008 if i%2==0 else 0.019
		var c: Vector3 = origem+Vector3(-0.049,0,-0.010)
		preload("res://scripts/geometry.gd").triangulo(s,c,c+Vector3(cos(t0)*r0,sin(t0)*r0,0),c+Vector3(cos(t1)*r1,sin(t1)*r1,0),OURO)
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = preload("res://scripts/geometry.gd").terminar(s); a.visual.add_child(vista)

static func rosto(a: Node3D,pele: Color) -> void:
	a.rosto = Node3D.new(); a.visual.add_child(a.rosto); a.rosto.name = "RostoOficial"
	a.peca(a.rosto,Vector3(0,1.73,0),Vector3(0.42 if a.mulher else 0.43,0.47,0.36),pele,true)
	# Queixo contínuo e testa ampla; sem bochechas em esferas separadas.
	a.peca(a.rosto,Vector3(0,1.60,-0.035),Vector3(0.30,0.22,0.28),pele,true)
	for lado: float in [-1,1]:
		a.peca(a.rosto,Vector3(lado*0.207,1.72,0),Vector3(0.065,0.098,0.055),pele,true)
		a.peca(a.rosto,Vector3(lado*0.217,1.72,-0.027),Vector3(0.034,0.055,0.014),pele.darkened(0.15),true)
		var olho: Node3D = Node3D.new(); a.rosto.add_child(olho); olho.position = Vector3(lado*0.078,1.77,-0.167)
		a.peca(olho,Vector3.ZERO,Vector3(0.105,0.119,0.044),Color("fff9eb"),true)
		a.peca(olho,Vector3(lado*0.004,-0.001,-0.027),Vector3(0.065,0.081,0.015),Color("683d22"),true)
		a.peca(olho,Vector3(lado*0.005,0.001,-0.036),Vector3(0.043,0.060,0.009),Color("181411"),true)
		a.peca(olho,Vector3(-0.012,0.019,-0.043),Vector3(0.021,0.025,0.005),Color.WHITE,true)
		a.peca(olho,Vector3(0.016,-0.016,-0.042),Vector3(0.008,0.009,0.004),Color.WHITE,true)
		linha(a,a.rosto,[Vector3(lado*0.026,1.864,-0.170),Vector3(lado*0.063,1.877,-0.176),Vector3(lado*0.112,1.867,-0.166)],0.012,CABELO)
		if a.mulher:
			var aro: MeshInstance3D = MeshInstance3D.new(); var torus: TorusMesh = TorusMesh.new(); torus.inner_radius = 0.023; torus.outer_radius = 0.029
			aro.mesh = torus; aro.material_override = a.mundo.material(OURO); aro.position = Vector3(lado*0.217,1.65,-0.004); aro.rotation.x = PI/2; a.rosto.add_child(aro)
	a.peca(a.rosto,Vector3(0,1.719,-0.197),Vector3(0.064,0.071,0.065),pele.lightened(0.06),true)
	var sorriso: Array[Vector3] = []; var dentes: Array[Vector3] = []
	for i: int in range(13):
		var x: float = -0.082+i*0.164/12
		sorriso.append(Vector3(x,1.618+pow(x/0.082,2)*0.042,-0.184+absf(x)*0.13))
		if i>1 and i<11: dentes.append(Vector3(x,1.632+pow(x/0.082,2)*0.023,-0.193+absf(x)*0.13))
	linha(a,a.rosto,sorriso,0.013,Color("4a211a")); linha(a,a.rosto,dentes,0.010,Color("fff1d7"))
	for i: int in range(24):
		var angulo: float = i*2.39996
		var raio: float = sqrt(float(i)/24)*0.18
		a.peca(a.rosto,Vector3(cos(angulo)*raio,1.93-0.10*float(i)/24,sin(angulo)*raio+0.025),Vector3.ONE*0.078,CABELO,true)
	if a.mulher:
		cilindro(a,a.rosto,Vector3(0,1.93,0.018),0.164,0.155,0.09,Color("c93c31"))
		for i: int in range(14):
			var t: float = TAU*i/14
			var faixa: MeshInstance3D = a.peca(a.rosto,Vector3(sin(t)*0.164,1.933,cos(t)*0.164+0.018),Vector3(0.033,0.072,0.012),[OURO,CLARO,Color("1c2420")][i%3],true); faixa.rotation.y = t
		a.peca(a.rosto,Vector3(0,2.015,0.08),Vector3(0.19,0.17,0.18),CABELO,true)
		a.peca(a.rosto,Vector3(0.10,1.98,0.035),Vector3(0.15,0.07,0.10),Color("c93c31"),true)
	else:
		cilindro(a,a.rosto,Vector3(0,1.98,0),0.34,0.35,0.035,OURO)
		cilindro(a,a.rosto,Vector3(0,2.045,0),0.18,0.135,0.13,Color("e5b956"))
		cilindro(a,a.rosto,Vector3(0,2.003,0),0.18,0.18,0.026,Color("94642c"))
		for i: int in range(3):
			var anel: MeshInstance3D = MeshInstance3D.new(); var t: TorusMesh = TorusMesh.new(); t.inner_radius = 0.21+i*0.042; t.outer_radius = t.inner_radius+0.005
			anel.mesh = t; anel.position.y = 2.0; anel.material_override = a.mundo.material(Color("bc8b32")); a.rosto.add_child(anel)

static func construir(a: Node3D) -> void:
	if is_instance_valid(a.visual): a.visual.get_parent().remove_child(a.visual); a.visual.queue_free()
	a.bracos.clear(); a.pernas.clear(); a.joelhos.clear(); a.cotovelos.clear(); a.maos.clear()
	a.visual = Node3D.new(); a.visual.name = "Agricultora" if a.mulher else "Agricultor"; a.add_child(a.visual)
	a.tom_pele = a.PELES[a.aparencia%a.PELES.size()]
	var pele: Color = a.tom_pele
	contorno(a,a.visual,[Vector3(0.82,0.21,0.13),Vector3(1.0,0.20,0.14),Vector3(1.25,0.24,0.145),Vector3(1.39,0.23,0.12),Vector3(1.45,0.10,0.08)],CREME)
	contorno(a,a.visual,[Vector3(0.80,0.21,0.14),Vector3(0.94,0.205,0.145),Vector3(1.10,0.21,0.146)],VERDE)
	a.peca(a.visual,Vector3(0,1.18,-0.142),Vector3(0.28,0.29,0.036),VERDE,true)
	for lado: float in [-1,1]:
		a.peca(a.visual,Vector3(lado*0.14,1.32,-0.117),Vector3(0.058,0.28,0.037),VERDE,true)
		a.peca(a.visual,Vector3(lado*0.14,1.25,-0.147),Vector3(0.045,0.037,0.015),OURO,true)
	contorno(a,a.visual,[Vector3(0.93,0.213,0.15),Vector3(0.98,0.213,0.15)],Color("6f4529"))
	a.peca(a.visual,Vector3(0,0.954,-0.154),Vector3(0.065,0.047,0.012),OURO,true)
	bandeira(a)
	contorno(a,a.visual,[Vector3(1.40,0.068,0.065),Vector3(1.59,0.064,0.065)],pele)
	rosto(a,pele)
	if a.mulher:
		a.saia = contorno(a,a.visual,[Vector3(0.62,0.265,0.18),Vector3(0.85,0.23,0.16),Vector3(0.97,0.214,0.15)],Color("c43a31"))
		for i: int in range(18):
			var t: float = TAU*i/18
			var p: MeshInstance3D = a.peca(a.visual,Vector3(sin(t)*0.25,0.72+(i%2)*0.08,cos(t)*0.17),Vector3(0.047,0.07,0.014),[OURO,Color("f2d789"),CLARO][i%3],true); p.rotation.y = t
	for lado: float in [-1,1]:
		var braco: Node3D = Node3D.new(); a.visual.add_child(braco); braco.position = Vector3(lado*0.25,1.37,0)
		contorno(a,braco,[Vector3(-0.29,0.052,0.052),Vector3(-0.13,0.066,0.065),Vector3(0,0.073,0.069)],pele)
		contorno(a,braco,[Vector3(-0.15,0.077,0.074),Vector3(-0.03,0.084,0.077),Vector3(0.045,0.062,0.060)],CREME)
		var cotovelo: Node3D = Node3D.new(); braco.add_child(cotovelo); cotovelo.position.y = -0.27; a.cotovelos.append(cotovelo)
		contorno(a,cotovelo,[Vector3(-0.25,0.036,0.033),Vector3(-0.14,0.049,0.044),Vector3(0.02,0.053,0.052)],pele)
		a.peca(cotovelo,Vector3(0,-0.27,-0.005),Vector3(0.085,0.11,0.061),pele,true)
		a.peca(cotovelo,Vector3(-lado*0.04,-0.25,-0.025),Vector3(0.03,0.06,0.032),pele,true)
		var mao: Node3D = Node3D.new(); cotovelo.add_child(mao); mao.position.y = -0.29; a.maos.append(mao); a.bracos.append(braco)
		if lado>0: a.mao_direita = mao
		var perna: Node3D = Node3D.new(); a.visual.add_child(perna); perna.position = Vector3(lado*0.105,0.87,0)
		contorno(a,perna,[Vector3(-0.43,0.067,0.070),Vector3(-0.22,0.085,0.088),Vector3(0.04,0.10,0.11)],VERDE)
		var joelho: Node3D = Node3D.new(); perna.add_child(joelho); joelho.position.y = -0.4; a.joelhos.append(joelho)
		contorno(a,joelho,[Vector3(-0.32,0.054,0.055),Vector3(-0.08,0.068,0.071),Vector3(0.02,0.067,0.070)],VERDE)
		a.peca(joelho,Vector3(0,-0.34,-0.045),Vector3(0.18,0.22,0.29),Color("70452a"),true)
		a.peca(joelho,Vector3(0,-0.425,-0.05),Vector3(0.18,0.035,0.30),Color("392b22"),true)
		a.pernas.append(perna)
	a.cesto = Node3D.new(); a.visual.add_child(a.cesto)
	a.peca(a.cesto,Vector3(0,1.01,-0.37),Vector3(0.43,0.25,0.30),Color("ad7b44"))
	for i: int in range(5): a.peca(a.cesto,Vector3(-0.15+i*0.075,1.15,-0.37),Vector3.ONE*0.08,Color("d7462e"),true)
	a.cesto.hide()
