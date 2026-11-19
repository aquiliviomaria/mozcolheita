extends Node3D
## Distribuição determinista: reserva ruas, quintas e edifícios antes de decorar.
var mundo: Node3D
var ocupados: Array[Rect2] = []
var arvores: int = 0
var pedras: int = 0
var pontes: int = 0
var residentes: int = 0
func reservar(p: Vector3,tamanho: Vector2) -> void:
	ocupados.append(Rect2(Vector2(p.x,p.z)-tamanho/2,tamanho))
func livre(p: Vector3,margem: float = 0) -> bool:
	if absf(p.x)<112 and absf(p.z)<94: return false
	for area: Rect2 in ocupados:
		if area.grow(margem).has_point(Vector2(p.x,p.z)): return false
	for trecho: Dictionary in mundo.comunidade.trocos:
		var a: Vector3 = trecho.a; var b: Vector3 = trecho.b
		var t: float = clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1)
		if p.distance_to(a+(b-a)*t)<9+margem: return false
	if absf(p.z-leito(p.x))<7+margem: return false
	return true
func _ready() -> void:
	for n: Node3D in mundo.comunidade.casas: reservar(n.position,Vector2(17,17))
	for n: Node3D in mundo.comunidade.edificios: reservar(n.position,Vector2(32,32))
	for n: Node3D in mundo.fabricas: reservar(n.position,Vector2(22,28))
	for p: Vector3 in preload("res://scripts/village.gd").CENTROS: reservar(p,Vector2(95,95))
	var cidade: Node3D = mundo.comunidade
	via([Vector3(-350,0,-240),Vector3(350,0,-240)],9)
	via([Vector3(-350,0,245),Vector3(350,0,245)],9)
	via([Vector3(-350,0,-240),Vector3(-350,0,245)],8)
	via([Vector3(350,0,-240),Vector3(350,0,245)],8)
	for x: float in [-300,-122,132,270]:
		via([Vector3(x,0,-350),Vector3(x,0,-102)],8)
		via([Vector3(x,0,140),Vector3(x,0,350)],7,false)
	for i: int in range(4):
		var p: Vector3 = [Vector3(-265,0,-205),Vector3(-160,0,282),Vector3(310,0,-198),Vector3(310,0,294)][i]
		if livre(p,18):
			cidade.predio(p,[10,20,10,40][i]); reservar(p,Vector2(34,34))
	# Ruas diferentes recebem casas com lotes e passagens, sem filas compactas.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = 241119
	var novas: Array[Node3D] = []
	for i: int in range(1800):
		var p: Vector3 = Vector3(rng.randf_range(-335,335),0,rng.randf_range(-285,330))
		if not livre(p,13): continue
		var rua: Vector3 = mundo.guia_entrega.projectar(p) if mundo.guia_entrega!=null else projectar(p)
		if p.distance_to(rua)>42: continue
		cidade.casa(p,cidade.casas.size()); var casa: Node3D = cidade.casas.back(); novas.append(casa); reservar(p,Vector2(23,23))
		# Caminho pedonal da porta até à via mais próxima.
		var caminho: Array[Vector3] = [p+Vector3(0,0,6),p+Vector3(0,0,10),rua]
		mundo.relevo.estrada(caminho,1.8,Color("a08e6b"))
		if novas.size()>=32: break
	for i: int in range(mini(20,novas.size())):
		var n: Node3D = novas[i]
		var p: Vector3 = n.position+Vector3(0,0,8); p.y = mundo.altura(p)+0.1
		var pessoa: Node3D = preload("res://scripts/npc.gd").new(); pessoa.mundo = mundo; pessoa.numero = 40+i; pessoa.nome = ["Fátima","Bento","Sara","Nelson","Amina","Dário"][i%6]+" · residente"; pessoa.mulher = i%2==0; pessoa.position = p
		pessoa.rota.assign([p,n.position+Vector3(0,0,2),p,p+Vector3(3,0,2)])
		mundo.add_child(pessoa); mundo.pessoas.append(pessoa); residentes += 1
	for i: int in range(6): melhorar_quinta(i)
	for i: int in range(8):
		var carro: CharacterBody3D = preload("res://scripts/traffic.gd").new(); carro.mundo = mundo; carro.tipo = 2 if i<5 else 1
		var esquerda: bool = i%2==0
		var x: float = -347 if esquerda else 347; var outro: float = -126 if esquerda else 128
		var topo: float = -237 if i<4 else 144; var fundo: float = -106 if i<4 else 241
		carro.rota.assign([Vector3(x,0,topo+(fundo-topo)*(i%4)/4),Vector3(x,0,fundo),Vector3(outro,0,fundo),Vector3(outro,0,topo),Vector3(x,0,topo)])
		cidade.add_child(carro); cidade.trafego.append(carro)
	criar_riacho(); decorar()
func via(pontos: Array[Vector3],largura: float = 9,asfalto: bool = true) -> void:
	mundo.comunidade.via(pontos,largura,asfalto)

func projectar(ponto: Vector3) -> Vector3:
	var resultado: Vector3 = ponto; var distancia: float = INF
	for trecho: Dictionary in mundo.comunidade.trocos:
		var a: Vector3 = trecho.a; var b: Vector3 = trecho.b
		var p: Vector3 = a+(b-a)*clampf((ponto-a).dot(b-a)/(b-a).length_squared(),0,1)
		if p.distance_squared_to(ponto)<distancia: resultado = p; distancia = p.distance_squared_to(ponto)
	return resultado
func melhorar_quinta(indice: int) -> void:
	var centro: Vector3 = preload("res://scripts/village.gd").CENTROS[indice]
	for lado: int in range(4):
		var inicio: Vector3 = centro+Vector3(-24 if lado<2 else (-24 if lado==2 else 39),0,-23 if lado==0 else 22 if lado==1 else -23)
		var fim: Vector3 = inicio+Vector3(63,0,0) if lado<2 else inicio+Vector3(0,0,45)
		for i: int in range(ceili(inicio.distance_to(fim)/3)):
			var p: Vector3 = inicio.move_toward(fim,i*3)
			if lado==1 and p.x>centro.x+18 and p.x<centro.x+30: continue
			p.y = mundo.altura(p)
			mundo.caixa(self,p+Vector3.UP*0.75,Vector3(0.14,1.5,0.14),Color("987449"))
			var rail: Vector3 = Vector3(3,0.09,0.1) if lado<2 else Vector3(0.1,0.09,3)
			for h: float in [0.65,1.15]: mundo.caixa(self,p+Vector3.UP*h+(Vector3.RIGHT if lado<2 else Vector3.BACK)*1.5,rail,Color("b29460"))
	mundo.comunidade.casa(centro+Vector3(-10,0,-34),mundo.comunidade.casas.size())
	reservar(centro+Vector3(-10,0,-34),Vector2(20,18))
func leito(x: float) -> float: return -316+sin(x*0.019)*9
func criar_riacho() -> void:
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x: int in range(-380,380,2):
		for canto: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
			var px: float = x+canto.x*2; var p: Vector3 = Vector3(px,0,leito(px)+(canto.y*2-1)*2.5); p.y = mundo.altura(p)+0.12
			s.set_uv(Vector2(px*0.1,canto.y)); s.set_normal(Vector3.UP); s.add_vertex(p)
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = s.commit(); var material: ShaderMaterial = ShaderMaterial.new(); material.shader = preload("res://shaders/stream.gdshader"); vista.material_override = material; add_child(vista)
	for x: float in [-300,-122,132,270]:
		var p: Vector3 = Vector3(x,0,leito(x)); p.y = mundo.altura(p)+0.15
		mundo.caixa(self,p,Vector3(8.2,0.18,12),Color("9e8e74"),true)
		for lado: float in [-1,1]:
			mundo.caixa(self,p+Vector3(lado*4.3,0.8,0),Vector3(0.12,0.12,12),Color("bda580"))
		pontes += 1
func lote(malha: Mesh,transformacoes: Array[Transform3D],cor: Color) -> void:
	var n: MultiMeshInstance3D = MultiMeshInstance3D.new(); n.multimesh = MultiMesh.new(); n.multimesh.transform_format = MultiMesh.TRANSFORM_3D; n.multimesh.mesh = malha; n.multimesh.instance_count = transformacoes.size(); n.material_override = mundo.material(cor)
	for i: int in range(transformacoes.size()): n.multimesh.set_instance_transform(i,transformacoes[i])
	add_child(n)
func decorar() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = 9814
	var troncos: Array[Transform3D] = []; var copas: Array[Transform3D] = []; var rochas: Array[Transform3D] = []
	for i: int in range(2200):
		var p: Vector3 = Vector3(rng.randf_range(-375,375),0,rng.randf_range(-370,370))
		if not livre(p,3): continue
		p.y = mundo.altura(p)
		if troncos.size()<280:
			var escala: float = rng.randf_range(0.8,1.6); var giro: Basis = Basis(Vector3.UP,rng.randf()*TAU)
			troncos.append(Transform3D(giro.scaled(Vector3.ONE*escala),p+Vector3.UP*1.8*escala))
			for j: int in range(3): copas.append(Transform3D(giro.scaled(Vector3(2.4,1.4,2.0)*escala),p+Vector3((j-1)*1.4*escala,(3.5+sin(j))*escala,cos(j)*0.7*escala)))
		elif rochas.size()<150:
			rochas.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(rng.randf_range(0.3,1.2),rng.randf_range(0.2,0.6),rng.randf_range(0.4,0.9))),p+Vector3.UP*0.1))
	var tronco: CylinderMesh = CylinderMesh.new(); tronco.top_radius = 0.13; tronco.bottom_radius = 0.23; tronco.height = 3.6; tronco.radial_segments = 7
	var copa: SphereMesh = SphereMesh.new(); copa.radius = 1; copa.height = 2; copa.radial_segments = 10; copa.rings = 5
	var rocha: SphereMesh = SphereMesh.new(); rocha.radius = 1; rocha.height = 2; rocha.radial_segments = 5; rocha.rings = 3
	lote(tronco,troncos,Color("715032")); lote(copa,copas,Color("46783d")); lote(rocha,rochas,Color("92917d"))
	arvores = troncos.size(); pedras = rochas.size()
