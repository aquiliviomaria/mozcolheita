extends RefCounted
## Rotinas de cenário separadas da produção e dos contratos pagos do jogador.
var pessoa: CharacterBody3D
var mundo: Node3D
var passos: Array[Dictionary] = []
var indice: int = 0
var restante: float = -1
var casa: Vector3
var agricultor: bool = false
var noite_anterior: bool = false
var acesso_casa: bool = false
var ferramenta: Node3D
var regador: Node3D
var enxada: Node3D
var gotas: CPUParticles3D
var trabalhos: int = 0
var fase_lavoura: int = 0
var campo: MultiMeshInstance3D
var planta: int = -1

func ponto(p: Vector3) -> Vector3:
	p.y = mundo.altura(p)+0.08
	return p
func adicionar(p: Vector3,tipo: String,duracao: float) -> void:
	passos.append({"p":ponto(p),"tipo":tipo,"duracao":duracao})
func configurar(n: CharacterBody3D,lar: Vector3,quinta: int = -1) -> void:
	pessoa = n; mundo = n.mundo; casa = lar; agricultor = quinta>=0
	if agricultor:
		campo = mundo.aldeia.campos[quinta]
		var centro: Vector3 = preload("res://scripts/village.gd").CENTROS[quinta]
		var linha: int = 3 if n.numero%2==0 else 12
		for x: int in [3,8,13,18]:
			var p: Vector3 = centro+Vector3(-18+x*1.5,0,-16+linha*1.5)
			adicionar(p+Vector3(0.65,0,0.65),"lavoura",5+n.numero%3)
	else:
		adicionar(casa+Vector3(0,0,9),"passear",1)
		if n.idade=="crianca":
			adicionar(casa+Vector3(4,0,10),"brincar",5)
			adicionar(casa+Vector3(-4,0,12),"brincar",4)
		elif n.idade=="idoso":
			adicionar(casa+Vector3(3,0,9),"descansar",8)
			adicionar(casa+Vector3(-3,0,10),"conversar",6)
		else:
			# Canteiro doméstico visível, separado da economia da quinta principal.
			var canteiro: Vector3 = ponto(casa+Vector3(4,0,8))
			mundo.caixa(mundo,canteiro,Vector3(2.2,0.12,1),Color("72543a"))
			for i: int in range(4):
				var planta_domestica: MeshInstance3D = MeshInstance3D.new()
				planta_domestica.mesh = mundo.terreno.cultivos.modelo(n.numero%4,3,true)
				planta_domestica.position = canteiro+Vector3(-0.75+i*0.5,0.08,0); planta_domestica.scale = Vector3.ONE*0.65; mundo.add_child(planta_domestica)
			adicionar(casa+Vector3(4,0,9),"regar",6)
			adicionar(casa+Vector3(-4,0,9),"varrer",5)
		adicionar(casa+Vector3(0,0,9),"passear",0)
		adicionar(casa+Vector3(0,0,3),"descansar",8)
	indice = n.numero%passos.size()
	noite_anterior = false
func suspender() -> void:
	if is_instance_valid(ferramenta): ferramenta.hide(); gotas.emitting = false
	restante = -1
func preparar_ferramentas() -> void:
	if is_instance_valid(ferramenta): return
	ferramenta = Node3D.new(); pessoa.mao_direita.add_child(ferramenta)
	regador = Node3D.new(); ferramenta.add_child(regador)
	mundo.caixa(regador,Vector3(0,-0.13,-0.05),Vector3(0.22,0.26,0.3),Color("438b71"))
	var bico: Node3D = mundo.caixa(regador,Vector3(0,-0.08,-0.34),Vector3(0.055,0.055,0.35),Color("99aca1")); bico.rotation.x = -0.35
	mundo.caixa(regador,Vector3(0.14,-0.08,0),Vector3(0.04,0.2,0.18),Color("438b71"))
	enxada = Node3D.new(); ferramenta.add_child(enxada)
	mundo.caixa(enxada,Vector3(0,-0.3,0),Vector3(0.035,0.9,0.035),Color("ac865a"))
	mundo.caixa(enxada,Vector3(0,-0.7,-0.08),Vector3(0.26,0.04,0.2),Color("8fa8a1"))
	gotas = CPUParticles3D.new(); gotas.position = Vector3(0,-0.14,-0.5); gotas.amount = 16; gotas.lifetime = 0.45; gotas.direction = Vector3(0,-1,-0.6); gotas.spread = 12; gotas.initial_velocity_min = 0.7; gotas.initial_velocity_max = 1.1; gotas.gravity = Vector3(0,-4,0); gotas.local_coords = false
	var malha: BoxMesh = BoxMesh.new(); malha.size = Vector3(0.015,0.08,0.015); malha.material = mundo.material(Color("84c5db")); gotas.mesh = malha; gotas.emitting = false; regador.add_child(gotas)
func tipo_actual() -> String:
	if passos.is_empty(): return "descansar"
	if passos[indice].tipo=="lavoura": return ["preparar","semear","regar","colher"][fase_lavoura]
	return passos[indice].tipo
func actualizar(delta: float) -> void:
	if passos.is_empty(): return
	# Cada vizinho regressa a casa ao anoitecer; não é teletransportado ao saltar dias.
	var noite: bool = fmod(mundo.calendario.decorrido,600)>=300
	if noite!=noite_anterior:
		noite_anterior = noite; acesso_casa = false; restante = -1; pessoa.destino_actual = Vector3.INF
		if not noite: indice = 0
	var p: Vector3 = passos[indice].p
	if noite:
		# Passa primeiro pelo acesso frontal, sem tentar atravessar a parede lateral.
		var lado: float = (0.6 if pessoa.numero%2==0 else -0.6) if agricultor else 0.0
		p = ponto(casa+Vector3(lado,0,3 if acesso_casa else 9))
	var tipo: String = "descansar" if noite else tipo_actual()
	if restante<0:
		suspender(); pessoa.estado = "A voltar a casa" if noite else "A caminho · "+tipo
		if not pessoa.caminhar(p,delta,0.55): return
		if noite and not acesso_casa:
			acesso_casa = true; return
		restante = 12 if noite else float(passos[indice].duracao)
		pessoa.velocity = Vector3.ZERO
		if agricultor and not noite:
			var centro: Vector3 = preload("res://scripts/village.gd").CENTROS[(pessoa.numero-6)/2]
			var alvo: Vector3 = p-centro-Vector3(0.65,0,0.65)
			planta = clampi(roundi((alvo.z+16)/1.5)*24+roundi((alvo.x+18)/1.5),0,431)
	if noite and pessoa.position.distance_to(p)>0.8: restante = -1; return
	pessoa.estado = {"preparar":"A preparar a machamba","semear":"A semear","regar":"A regar","colher":"A colher","varrer":"A cuidar do quintal","descansar":"Em casa a descansar","brincar":"A brincar no quintal","conversar":"A conversar com vizinhos","passear":"A passear"}.get(tipo,"Em casa")
	if tipo in ["preparar","semear","regar","colher","varrer"]: pessoa.visual.rotation.y = PI/4 if agricultor else 0.0
	preparar_ferramentas(); ferramenta.visible = tipo in ["preparar","regar","varrer"]
	regador.visible = tipo=="regar"; enxada.visible = tipo in ["preparar","varrer"]
	gotas.emitting = tipo=="regar" and pessoa.visual.visible
	pessoa.tempo_acao = 1; pessoa.acao_animacao = "watering" if tipo=="regar" else "planting" if tipo in ["preparar","semear","varrer"] else "harvesting" if tipo=="colher" else "idle"
	pessoa.animar(delta,0)
	if tipo=="brincar": pessoa.bracos[1].rotation.x = 0.7+sin(pessoa.fase)*0.4
	if tipo=="conversar": pessoa.bracos[0].rotation.x = 0.6+sin(pessoa.fase)*0.25
	if tipo=="descansar":
		for i: int in range(2): pessoa.bracos[i].rotation.x = 0.1
	restante -= delta
	if restante<=0:
		trabalhos += 1; suspender()
		if noite: return
		# Pequenas alterações visíveis nas plantas locais; nunca mexe nos produtos do jogador.
		if agricultor and planta>=0:
			var t: Transform3D = campo.multimesh.get_instance_transform(planta)
			t.basis = Basis.IDENTITY.scaled(Vector3.ONE*(0.18 if tipo in ["preparar","colher"] else 0.55 if tipo=="semear" else 1.0))
			campo.multimesh.set_instance_transform(planta,t)
		indice = (indice+1)%passos.size()
		if agricultor and indice==0: fase_lavoura = (fase_lavoura+1)%4
