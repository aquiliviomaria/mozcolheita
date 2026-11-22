extends Node3D
## Cidade e bairros fora da quinta. Janelas em MultiMesh limitam chamadas de desenho.
var mundo: Node3D
var edificios: Array[Node3D] = []
var casas: Array[Node3D] = []
var trafego: Array[CharacterBody3D] = []
var animais: Array[Node3D] = []
var tempo: float = 0.0
var trocos: Array[Dictionary] = []
func via(pontos: Array[Vector3],largura: float = 9,asfalto: bool = true) -> void:
	for i: int in range(pontos.size()-1):
		var a: Vector3 = pontos[i]; var b: Vector3 = pontos[i+1]; a.y = 0; b.y = 0
		trocos.append({"a":a,"b":b})
	mundo.relevo.estrada(pontos,largura,Color("536058") if asfalto else Color("927553"))
	if not asfalto: return
	var marcas: Array[Transform3D] = []
	for i: int in range(pontos.size()-1):
		var eixo: Vector3 = pontos[i+1]-pontos[i]; var base: Basis = Basis(Vector3.UP,atan2(eixo.x,eixo.z))
		for passo: int in range(1,int(eixo.length()/12)):
			var p: Vector3 = pontos[i].lerp(pontos[i+1],passo*12/eixo.length()); p.y = mundo.altura(p)+0.065; marcas.append(Transform3D(base,p))
	var lote: MultiMeshInstance3D = MultiMeshInstance3D.new(); lote.multimesh = MultiMesh.new(); lote.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var malha: BoxMesh = BoxMesh.new(); malha.size = Vector3(0.13,0.015,3); lote.multimesh.mesh = malha; lote.multimesh.instance_count = marcas.size(); lote.material_override = mundo.material(Color("dddbc1")); add_child(lote)
	for i: int in range(marcas.size()): lote.multimesh.set_instance_transform(i,marcas[i])
func _ready() -> void:
	for rua: Dictionary in preload("res://scripts/road_network.gd").cidade(): via(rua.pontos,rua.largura,rua.asfalto)
	for i: int in range(6):
		predio(Vector3(163+(i%3)*70,0,-48+(i/3)*110),[10,20,40][i%3])
	for i: int in range(7): casa(Vector3(-95+i*27,0,-134),i)
	for i: int in range(5): casa(Vector3(-155,0,-62+i*32),i+7); casa(Vector3(-326,0,-50+i*34),i+12)
	for i: int in range(12):
		var carro: CharacterBody3D = preload("res://scripts/traffic.gd").new(); carro.mundo = mundo; carro.tipo = i%3
		# Circuito comum no mesmo sentido: evita encontros frontais no eixo da via.
		carro.rota = percurso_rectangular(132,345,-100,140,i,12); add_child(carro); trafego.append(carro)
	for i: int in range(8):
		var pessoa: Node3D = preload("res://scripts/npc.gd").new(); pessoa.mundo = mundo; pessoa.numero = 20+i; pessoa.nome = ["Amélia","Celso","Berta","Ernesto","Sofia","Júlio","Nádia","Mário"][i]; pessoa.mulher = i%2==0
		var x: float = [128.0,196.0,278.0,350.0][i%4]; var z: float = -60 if i<4 else 40
		pessoa.position = Vector3(x,0,z); pessoa.position.y = mundo.altura(pessoa.position)+0.1
		pessoa.rota.assign([pessoa.position,Vector3(x,0,z+32),Vector3(x+2,0,z+32),Vector3(x+2,0,z)])
		mundo.add_child(pessoa); mundo.pessoas.append(pessoa)
	for i: int in range(3): criacao(i)
	for i: int in range(3):
		var fabrica: Node3D = preload("res://scripts/factory.gd").new(); fabrica.mundo = mundo; fabrica.numero = i; fabrica.local_filial = preload("res://scripts/industrial_sites.gd").FILIAIS[i]; mundo.add_child(fabrica); mundo.fabricas.append(fabrica)

func casa(local: Vector3,indice: int) -> void:
	var n: Node3D = Node3D.new(); n.position = local; n.position.y = mundo.altura(local); add_child(n); casas.append(n)
	var interior: Node3D = preload("res://scripts/residence.gd").new(); interior.mundo = mundo; interior.cor = [Color("e7ca91"),Color("d0b193"),Color("b9d5ad")][indice%3]; interior.titulo = "CASA %02d" % (indice+1); n.add_child(interior)
	for lado: float in [-1,1]:
		var telha: Node3D = mundo.caixa(n,Vector3(lado*3.1,4.7,0),Vector3(6.7,0.16,12),Color("ad583b")); telha.rotation.z = -lado*0.25
	for x: float in [-3.5,3.5]: mundo.caixa(n,Vector3(x,2.3,5.55),Vector3(1.6,1.6,0.08),Color("729a9b"))
func predio(local: Vector3,pisos: int) -> void:
	var n: Node3D = Node3D.new(); n.position = local; n.position.y = mundo.altura(local); n.set_meta("pisos",pisos); add_child(n); edificios.append(n)
	var altura: float = pisos*3.0
	mundo.caixa(n,Vector3(0,4+(altura-4)/2,0),Vector3(25,altura-4,25),Color("adc4b1"),true)
	var interior: Node3D = preload("res://scripts/residence.gd").new(); interior.mundo = mundo; interior.largura = 25; interior.profundidade = 25; interior.titulo = "ÁTRIO · %d PISOS" % pisos; n.add_child(interior)
	mundo.caixa(n,Vector3(0,altura+0.4,0),Vector3(26,0.8,26),Color("315d4f"))
	var lote: MultiMeshInstance3D = MultiMeshInstance3D.new(); lote.multimesh = MultiMesh.new(); lote.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var janela: BoxMesh = BoxMesh.new(); janela.size = Vector3(1.9,1.8,0.10); lote.multimesh.mesh = janela; lote.multimesh.instance_count = pisos*6*4; lote.material_override = mundo.material(Color("477a80")); n.add_child(lote)
	var indice: int = 0
	for lado: int in range(4):
		for piso: int in range(pisos):
			for x: int in range(6):
				var base: Basis = Basis(Vector3.UP,lado*PI/2); var p: Vector3 = base*Vector3(-10+x*4,1.6+piso*3,12.55)
				if piso==0 and lado==0 and x in [2,3]: p.y = 4.5
				lote.multimesh.set_instance_transform(indice,Transform3D(base,p)); indice += 1
	mundo.placa(n,Vector3(0,4,12.8),"COMUNIDADE · %d PISOS" % pisos).visibility_range_end = 40
func criacao(tipo: int) -> void:
	var centro: Vector3 = preload("res://scripts/village.gd").CENTROS[tipo+3]+Vector3(-18,0,32)
	mundo.placa(self,Vector3(centro.x,mundo.altura(centro)+3,centro.z),["CRIAÇÃO DE PORCOS","GALINHEIRO","GADO BOVINO"][tipo]).visibility_range_end = 80
	for x: float in [-13,13]:
		var p: Vector3 = centro+Vector3(x,0,0); p.y = mundo.altura(p)+0.8; mundo.caixa(self,p,Vector3(0.12,0.1,22),Color("bc955b"))
	for z: float in [-11,11]:
		var p: Vector3 = centro+Vector3(0,0,z); p.y = mundo.altura(p)+0.8; mundo.caixa(self,p,Vector3(26,0.1,0.12),Color("bc955b"))
	for i: int in range(8):
		var animal: Node3D = Node3D.new(); add_child(animal); animal.position = centro+Vector3(-8+(i%4)*5,0,-6+(i/4)*9); animal.position.y = mundo.altura(animal.position); animal.set_meta("inicio",animal.position); animal.set_meta("tipo",tipo); animais.append(animal)
		var escala: float = [0.9,0.7,1.3][tipo]; var cor: Color = [Color("c98e7d"),Color("e0d8b5"),Color("84593e")][tipo]
		var g: GDScript = preload("res://scripts/geometry.gd"); var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
		g.oval(s,Vector3(0,0.7,0)*escala,Vector3(0.43,0.36,0.7)*escala,cor,12,8); g.oval(s,Vector3(0,0.85,-0.7)*escala,Vector3(0.26,0.29,0.32)*escala,cor,12,8)
		for lado: float in [-1,1]:
			for z: float in ([0.0] if tipo==1 else [-0.4,0.4]): g.tubo(s,Vector3(lado*0.26,0.55,z)*escala,Vector3(lado*0.26,0.09,z)*escala,0.06*escala,cor)
			g.oval(s,Vector3(lado*0.12,0.91,-0.96)*escala,Vector3(0.025,0.03,0.025)*escala,Color("201c14"))
		if tipo==1:
			g.oval(s,Vector3(0,1.13,-0.65)*escala,Vector3(0.09,0.12,0.12)*escala,Color("ce3e2e"))
			g.tubo(s,Vector3(0,0.82,-0.95)*escala,Vector3(0,0.79,-1.2)*escala,0.095*escala,Color("d4aa36"),0,8)
			for lado: float in [-1,1]: g.oval(s,Vector3(lado*0.36,0.72,0.05)*escala,Vector3(0.12,0.23,0.38)*escala,Color("bca779"),12,8)
		elif tipo==0:
			g.oval(s,Vector3(0,0.76,-0.99)*escala,Vector3(0.18,0.11,0.08)*escala,Color("d69c8d"),12,8)
			for lado: float in [-1,1]:
				g.oval(s,Vector3(lado*0.07,0.77,-1.06)*escala,Vector3(0.025,0.025,0.009)*escala,Color("704b47"))
				g.oval(s,Vector3(lado*0.21,1.02,-0.58)*escala,Vector3(0.13,0.17,0.065)*escala,cor)
		else:
			g.oval(s,Vector3(0,0.70,-0.99)*escala,Vector3(0.24,0.15,0.09)*escala,Color("d8bf96"),12,8)
			for lado: float in [-1,1]:
				g.tubo(s,Vector3(lado*0.15,1.08,-0.61)*escala,Vector3(lado*0.29,1.3,-0.60)*escala,0.055*escala,Color("d9d1b1"),0.007,8)
				g.oval(s,Vector3(lado*0.29,0.96,-0.63)*escala,Vector3(0.18,0.065,0.10)*escala,cor)
			g.oval(s,Vector3(0.38,0.79,0.1)*escala,Vector3(0.065,0.18,0.27)*escala,Color("dfd0b2"))
			g.tubo(s,Vector3(0,0.79,0.65)*escala,Vector3(0,0.34,0.92)*escala,0.025*escala,cor)
		var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = g.terminar(s); animal.add_child(vista)
func _process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	tempo += delta
	for i: int in range(animais.size()):
		var animal: Node3D = animais[i]; var inicio: Vector3 = animal.get_meta("inicio")
		animal.position = inicio+Vector3(sin(tempo*0.18+i)*1.3,0,cos(tempo*0.18+i)*1.3); animal.position.y = mundo.altura(animal.position); animal.rotation.y = -tempo*0.18-i

func percurso_rectangular(esquerda: float,direita: float,topo: float,fundo: float,indice: int,total: int) -> Array[Vector3]:
	# Todos os segmentos seguem o eixo real da estrada; início distribuído pelo perímetro.
	var cantos: Array[Vector3] = [Vector3(esquerda,0,topo),Vector3(direita,0,topo),Vector3(direita,0,fundo),Vector3(esquerda,0,fundo)]
	var fase: float = float(indice)*4.0/total
	var lado: int = floori(fase)%4
	var pontos: Array[Vector3] = [cantos[lado].lerp(cantos[(lado+1)%4],fmod(fase,1.0))]
	for passo: int in range(1,5): pontos.append(cantos[(lado+passo)%4])
	return pontos
