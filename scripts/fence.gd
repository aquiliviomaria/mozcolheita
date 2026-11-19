extends Node3D
## Seis portões independentes; corredores livres para pessoas e máquinas.
const Plano: GDScript = preload("res://scripts/layout.gd")
var mundo: Node3D
var secoes: Array[Node3D] = []
var portoes: Array[Dictionary] = []
var abertura: float = 0.0
var reparacoes: int = 0

func _ready() -> void:
	for lateral: bool in [false,true]:
		var comprimento: int = 156 if lateral else 192
		for lado: float in [-1.0,1.0]:
			for i: int in range(comprimento/3):
				var offset: float = -comprimento*0.5+1.5+i*3
				var ponto: Vector3 = Vector3(lado*96,0,offset) if lateral else Vector3(offset,0,lado*78)
				if not Plano.junto_portao(ponto,6): seccao(ponto,lateral)
	for centro: Vector3 in Plano.PORTOES: criar_portao(centro)

func criar_portao(centro: Vector3) -> void:
	var raiz: Node3D = Node3D.new()
	add_child(raiz)
	raiz.position = Vector3(centro.x,mundo.altura(centro),centro.z)
	if absf(centro.x)==96: raiz.rotation.y = PI/2
	var folhas: Array[Node3D] = []
	for lado: float in [-1.0,1.0]:
		mundo.caixa(raiz,Vector3(lado*6,1,0),Vector3(0.24,2,0.24),Color("665c49"),true)
		var folha: Node3D = Node3D.new()
		raiz.add_child(folha); folha.position.x = lado*6
		for y: float in [0.45,1,1.5]: mundo.caixa(folha,Vector3(-lado*3,y,0),Vector3(6,0.09,0.1),Color("4b6660"))
		for x: int in range(1,6): mundo.caixa(folha,Vector3(-lado*x,0.95,0),Vector3(0.07,1.2,0.07),Color("4b6660"))
		folhas.append(folha)
	var corpo: StaticBody3D = StaticBody3D.new()
	raiz.add_child(corpo)
	var colisao: CollisionShape3D = CollisionShape3D.new()
	var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(12,1.8,0.18)
	colisao.shape = forma; colisao.position.y = 0.9
	corpo.add_child(colisao)
	portoes.append({"centro":centro,"folhas":folhas,"colisao":colisao,"abertura":0.0})

func seccao(centro: Vector3, longitudinal: bool) -> void:
	var raiz: Node3D = Node3D.new()
	add_child(raiz)
	raiz.position = Vector3(centro.x,mundo.altura(centro),centro.z)
	if longitudinal: raiz.rotation.y = PI/2
	for lado: float in [-1.5,1.5]: mundo.caixa(raiz,Vector3(lado,0.8,0),Vector3(0.12,1.6,0.12),Color("7c6b50"))
	for y: float in [0.4,0.9,1.4]: mundo.caixa(raiz,Vector3(0,y,0),Vector3(3,0.08,0.08),Color("968467"))
	mundo.caixa(raiz,Vector3(0,0.8,0),Vector3(3,1.6,0.12),Color(0,0,0,0),true).hide()
	raiz.set_meta("durabilidade",100)
	secoes.append(raiz)

func perto(posicao: Vector3, alcance: float = 3.0) -> Node3D:
	var melhor: Node3D
	for parte: Node3D in secoes:
		var distancia: float = Plano.distancia(parte.global_position,posicao)
		if distancia<alcance: melhor = parte; alcance = distancia
	return melhor

func _physics_process(delta: float) -> void:
	for portao: Dictionary in portoes:
		var abrir: bool = is_instance_valid(mundo.jogador) and Plano.distancia(mundo.jogador.global_position,portao.centro)<13
		for actor: Node3D in get_tree().get_nodes_in_group("pessoas")+get_tree().get_nodes_in_group("tratores_quinta"):
			if Plano.distancia(actor.global_position,portao.centro)<16: abrir = true; break
		portao.abertura = move_toward(float(portao.abertura),1.0 if abrir else 0.0,delta*1.8)
		portao.folhas[0].rotation.y = -float(portao.abertura)*PI*0.52
		portao.folhas[1].rotation.y = float(portao.abertura)*PI*0.52
		portao.colisao.disabled = float(portao.abertura)>0.25
	abertura = float(portoes[0].abertura)

func construir_ou_reparar(posicao: Vector3, direccao: Vector3 = Vector3.ZERO) -> bool:
	var parte: Node3D = perto(posicao)
	if parte!=null and int(parte.get_meta("durabilidade",100))<100:
		if mundo.ferramentas.madeira<1: return false
		mundo.ferramentas.madeira -= 1; parte.set_meta("durabilidade",100); reparacoes += 1
		return true
	var frente: Vector3 = -mundo.jogador.visual.global_basis.z if direccao==Vector3.ZERO else direccao.normalized()
	var ponto: Vector3 = posicao+frente*2
	if Plano.reservado(ponto) or perto(ponto,2.8)!=null or mundo.ferramentas.madeira<2: return false
	if mundo.terreno.celulas.has(mundo.terreno.chave_em(ponto)): return false
	mundo.ferramentas.madeira -= 2
	seccao(Vector3(snappedf(ponto.x,1),0,snappedf(ponto.z,1)),false)
	return true
