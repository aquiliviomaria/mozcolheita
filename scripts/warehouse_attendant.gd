extends Node3D
## Funcionário permanente da doca. A carga só muda no gesto final de entrega.
var mundo: Node3D
var posto: Node3D
var pessoa: CharacterBody3D
var rotulo: Label3D
var caixa: Node3D
var nome: String = "Celso"
var assento: Vector3 = Vector3(11,0,-13.5)
var corredor: Vector3 = Vector3(4.5,0,-13)
var fase: String = "sentado"
var percurso: Array[Vector3] = []
var validar: Callable
var transferir: Callable
var concluido: Callable
var veiculo: Node3D
var destino: Vector3
var origem: Vector3
var tempo: float = 0
var duracao: float = 0
var bloqueio: float = 0
var replanear: float = 0
var ultima_posicao: Vector3
var tarefa: String = ""
var unidades: int = 0
func _ready() -> void:
	name = "FuncionarioArmazem"
	# O balcão fica fora da faixa de circulação e das estantes.
	mundo.caixa(self,assento+Vector3(0,0.87,-1.05),Vector3(2.3,0.12,0.8),Color("92704c"),true)
	for x: float in [-0.9,0.9]: mundo.caixa(self,assento+Vector3(x,0.42,-1.05),Vector3(0.12,0.84,0.6),Color("52645e"),true)
	mundo.caixa(self,assento+Vector3(0,0.43,0),Vector3(0.9,0.12,0.8),Color("765337"))
	mundo.caixa(self,assento+Vector3(0,0.93,0.4),Vector3(0.9,0.95,0.12),Color("765337"))
	for x: float in [-0.34,0.34]: mundo.caixa(self,assento+Vector3(x,0.2,0),Vector3(0.08,0.4,0.65),Color("455257"))
	mundo.caixa(self,assento+Vector3(-0.35,0.96,-1.05),Vector3(0.65,0.06,0.42),Color("eee3c7"))
	pessoa = preload("res://scripts/player.gd").new(); pessoa.mundo = mundo; pessoa.bloqueado = true; pessoa.roupa = 1; pessoa.aparencia = absi(roundi(posto.position.x+posto.position.z))%6; pessoa.mulher = nome in ["Amélia","Sara"]; add_child(pessoa); pessoa.set_physics_process(false); pessoa.position = assento+Vector3.UP*0.06
	rotulo = mundo.placa(pessoa,Vector3(0,2.4,0),nome+" · Atendimento"); rotulo.font_size = 25; rotulo.pixel_size = 0.004; rotulo.visibility_range_end = 22
	var luz: OmniLight3D = OmniLight3D.new(); luz.position = assento+Vector3(0,2.7,-0.4); luz.omni_range = 7; luz.light_energy = 1.5; luz.light_color = Color("fff0cc"); luz.shadow_enabled = false; luz.distance_fade_enabled = true; luz.distance_fade_begin = 35; add_child(luz)
	ultima_posicao = pessoa.global_position; sentar()
func ocupado() -> bool: return transferir.is_valid()
func perto_do_posto(p: Vector3) -> bool: return preload("res://scripts/layout.gd").distancia(p,posto.global_position)<32
func iniciar(operacao: String,n: int,cultura: int,transporte: Node3D,recolha: Vector3,entrega: Vector3,condicao: Callable,aplicar: Callable,fim: Callable = Callable()) -> bool:
	if ocupado() or (transporte!=null and transporte.has_meta("operador_doca")): return false
	tarefa = operacao; unidades = n; veiculo = transporte; origem = recolha; destino = entrega; validar = condicao; transferir = aplicar; concluido = fim; duracao = 0; bloqueio = 0
	if veiculo!=null: veiculo.set_meta("operador_doca",get_instance_id())
	pessoa.visual.transform = Transform3D.IDENTITY; pessoa.repor_pose(); criar_caixa(cultura); caixa.hide()
	fase = "ir_buscar"; rota(origem); rotulo.text = nome+" · "+tarefa+" · %d un." % n; mundo.avisar(nome+" · "+tarefa+" · aguarde com a carga parada"); return true
func criar_caixa(cultura: int) -> void:
	if is_instance_valid(caixa): caixa.get_parent().remove_child(caixa); caixa.queue_free()
	caixa = Node3D.new(); pessoa.visual.add_child(caixa); caixa.position = Vector3(0,1.02,-0.4)
	mundo.caixa(caixa,Vector3(0,-0.08,0),Vector3(0.57,0.12,0.4),Color("a97e47"))
	for lado: float in [-1,1]:
		mundo.caixa(caixa,Vector3(lado*0.28,0.03,0),Vector3(0.035,0.22,0.42),Color("bd925b"))
		mundo.caixa(caixa,Vector3(0,0.03,lado*0.2),Vector3(0.57,0.22,0.035),Color("bd925b"))
	for i: int in range(3):
		var produto: MeshInstance3D = MeshInstance3D.new(); produto.mesh = preload("res://scripts/produce_mesh.gd").modelo(clampi(cultura,0,3)); produto.position = Vector3(-0.17+i*0.17,0.1,0); produto.scale = Vector3.ONE*0.45; caixa.add_child(produto)
func rota(alvo: Vector3) -> void:
	percurso.clear()
	# Corredor frontal livre, com pontos laterais para não atravessar o camião.
	var a: Vector3 = to_local(pessoa.global_position); var b: Vector3 = to_local(alvo)
	var lado: float = -1 if b.x<0 else 1
	if absf(a.x)>6: percurso.append(to_global(Vector3(signf(a.x)*6,0,corredor.z)))
	percurso.append(to_global(Vector3(lado*4.5,0,corredor.z)))
	if b.z < corredor.z: percurso.append(to_global(Vector3(lado*4.5,0,b.z)))
	percurso.append(alvo); bloqueio = 0; ultima_posicao = pessoa.global_position
func ponto_transporte(transporte: Node3D) -> Vector3:
	return transporte.to_global(Vector3(2.8,0,1.4))
func libertar() -> void:
	if is_instance_valid(veiculo) and int(veiculo.get_meta("operador_doca",0))==get_instance_id(): veiculo.remove_meta("operador_doca")
	veiculo = null; validar = Callable(); transferir = Callable(); concluido = Callable()
func cancelar(notificar: bool = true,repor: bool = false) -> void:
	var activa: bool = ocupado(); libertar()
	if is_instance_valid(caixa): caixa.hide()
	if repor:
		pessoa.position = assento+Vector3.UP*0.06; sentar()
	else: fase = "voltar"; rota(to_global(assento))
	if activa and notificar: mundo.avisar("Operação interrompida · a mercadoria continua na origem")
func sentar() -> void:
	fase = "sentado"; pessoa.position = assento+Vector3.UP*0.06; pessoa.velocity = Vector3.ZERO; pessoa.visual.transform = Transform3D.IDENTITY; pessoa.sentar_no_assento(to_global(assento+Vector3.UP*0.49).y); rotulo.text = nome+" · Atendimento"
func andar(delta: float) -> bool:
	while not percurso.is_empty() and preload("res://scripts/layout.gd").distancia(pessoa.global_position,percurso[0])<0.45: percurso.pop_front()
	if percurso.is_empty(): return true
	var d: Vector3 = percurso[0]-pessoa.global_position; d.y = 0; d = d.normalized()
	replanear -= delta
	if pessoa.test_move(pessoa.global_transform,d*0.7):
		for angulo: float in [0.65,-0.65,1.2,-1.2,1.7,-1.7]:
			var alternativa: Vector3 = d.rotated(Vector3.UP,angulo)
			if not pessoa.test_move(pessoa.global_transform,alternativa*0.7): d = alternativa; break
	pessoa.velocity = d*3.2; pessoa.velocity.y = -2; pessoa.move_and_slide()
	pessoa.global_position.y = mundo.altura(pessoa.global_position)+0.06
	pessoa.visual.rotation.y = lerp_angle(pessoa.visual.rotation.y,atan2(-d.x,-d.z),minf(1,delta*9))
	bloqueio = bloqueio+delta if pessoa.global_position.distance_to(ultima_posicao)<delta*0.25 else maxf(0,bloqueio-delta)
	ultima_posicao = pessoa.global_position
	if bloqueio>0.8 and replanear<=0:
		var desvio: Array[Vector3] = preload("res://scripts/navigation.gd").contornar(pessoa,percurso[0])
		if not desvio.is_empty(): percurso = desvio+percurso
		replanear = 1; bloqueio = 0
	return false
func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	pessoa.visible = pessoa.global_position.distance_squared_to(mundo.camera.camara.global_position)<120*120
	if fase=="sentado": return
	if ocupado():
		duracao += delta
		if not validar.is_valid() or not validar.call() or duracao>60: cancelar(); return
	var passo: bool = fase in ["ir_buscar","ir_entregar","voltar"]
	if passo and andar(delta):
		if fase=="voltar": sentar(); return
		fase = "recolher" if fase=="ir_buscar" else "colocar"; tempo = 0
	pessoa.animar(delta,3.2 if passo else 0)
	if is_instance_valid(caixa) and caixa.visible:
		for i: int in range(2): pessoa.bracos[i].rotation.x = 0.95; pessoa.cotovelos[i].rotation.x = 0.7
	if fase in ["recolher","colocar"]:
		tempo += delta; pessoa.bracos[1].rotation.x = 0.8+sin(tempo*4)*0.3
		if tempo<0.85: return
		if fase=="recolher": caixa.show(); fase = "ir_entregar"; rota(destino)
		else:
			# Valida novamente no instante do gesto. Gravações e cancelamentos nunca duplicam carga.
			var n: int = int(transferir.call()) if validar.is_valid() and validar.call() else 0
			var fim: Callable = concluido; libertar(); caixa.hide(); fase = "voltar"; rota(to_global(assento))
			if fim.is_valid(): fim.call(n)
