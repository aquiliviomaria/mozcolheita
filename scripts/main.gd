extends Node3D
## Composição da quinta. Cada sistema recebe referências, sem autoloads nem plugins.
const FASE: int = 7
const LIMITES: Rect2 = Rect2(-380,-380,760,760)
const Jogador: GDScript = preload("res://scripts/player.gd")
const Camara: GDScript = preload("res://scripts/camera.gd")
const Terreno: GDScript = preload("res://scripts/terrain.gd")
const Cerca: GDScript = preload("res://scripts/fence.gd")
const Hud: GDScript = preload("res://scripts/hud.gd")
var carros: Array[CharacterBody3D] = []
var tratores: Array[CharacterBody3D] = []
var implementos: Array[Node3D] = []
var carrinhas: Array[Node3D] = []
var trator_actual: CharacterBody3D
var drones: Array[Node3D] = []
var drone_actual: Node3D
var contrato: Node
var tarefas: Node
var missoes: Node
var armazem: Node3D
var fabricas: Array[Node3D] = []
var economia: Node
var pessoas: Array[Node3D] = []
var stock: Dictionary = {}
var familia: Node3D
var saldo: int = 500_000
var ferramentas: Node3D
var sacola: Dictionary = {}
var aviso: String = ""
var aviso_tempo: float = 0.0
var relevo: Node3D
var aldeia: Node3D
var jogador: CharacterBody3D
var camera: Node3D
var terreno: Node3D
var cerca: Node3D
var hud: CanvasLayer
var caminhao: CharacterBody3D
var equipa_grupo: Node
var entregas: Node
var calendario: Node
var comunidade: Node3D
var mundo_vivo: Node3D
var guia_entrega: CanvasLayer
var luz_diaria: Node
var vitais: Node
var painel_conducao: Control
var feedback: Node3D
var partida: Node
var casa: Node3D
var relogio: float = 0.0
var materiais: Dictionary = {}
var falhas_testes: PackedStringArray = []

func material(cor: Color) -> StandardMaterial3D:
	var chave: String = cor.to_html()
	if not materiais.has(chave):
		var novo: StandardMaterial3D = StandardMaterial3D.new()
		novo.albedo_color = cor.srgb_to_linear()
		novo.roughness = 0.86
		if cor.a<1.0: novo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		materiais[chave] = novo
	return materiais[chave]

func caixa(pai: Node3D, posicao: Vector3, tamanho: Vector3, cor: Color, solida: bool = false) -> MeshInstance3D:
	var malha: MeshInstance3D = MeshInstance3D.new()
	var cubo: BoxMesh = BoxMesh.new()
	cubo.size = tamanho
	malha.mesh = cubo
	malha.material_override = material(cor)
	malha.position = posicao
	pai.add_child(malha)
	if solida:
		var corpo: StaticBody3D = StaticBody3D.new()
		var forma: BoxShape3D = BoxShape3D.new()
		forma.size = tamanho
		var colisor: CollisionShape3D = CollisionShape3D.new()
		colisor.shape = forma
		corpo.add_child(colisor)
		malha.add_child(corpo)
	return malha

func placa(pai: Node3D, posicao: Vector3, texto: String) -> Label3D:
	var rotulo: Label3D = Label3D.new()
	rotulo.text = texto
	rotulo.position = posicao
	rotulo.font_size = 32
	rotulo.pixel_size = 0.005
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.visibility_range_end = 60.0
	pai.add_child(rotulo)
	return rotulo

func sistema(codigo: GDScript) -> Node:
	var novo: Node = codigo.new()
	novo.mundo = self
	add_child(novo)
	return novo

func _ready() -> void:
	var ambiente: WorldEnvironment = WorldEnvironment.new()
	var configuracao: Environment = Environment.new()
	configuracao.background_mode = Environment.BG_SKY
	var ceu: Sky = Sky.new()
	var atmosfera: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	atmosfera.sky_top_color = Color("6597b4")
	atmosfera.sky_horizon_color = Color("c2c6b4")
	atmosfera.ground_bottom_color = Color("60584b")
	atmosfera.ground_horizon_color = Color("b5b6a2")
	ceu.sky_material = atmosfera
	configuracao.sky = ceu
	configuracao.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	configuracao.background_color = Color("90b9cb")
	configuracao.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	configuracao.ambient_light_color = Color("eef2df")
	configuracao.ambient_light_energy = 0.65
	ambiente.environment = configuracao
	add_child(ambiente)
	var sol: DirectionalLight3D = DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50,-25,0)
	sol.light_energy = 1.0
	sol.light_color = Color("fff2d6")
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 160
	add_child(sol)
	luz_diaria = preload("res://scripts/daylight.gd").new()
	luz_diaria.mundo = self; luz_diaria.sol = sol; luz_diaria.ambiente = configuracao; luz_diaria.ceu = atmosfera
	add_child(luz_diaria)
	relevo = sistema(preload("res://scripts/landscape.gd")) as Node3D
	terreno = sistema(Terreno) as Node3D
	cerca = sistema(Cerca) as Node3D
	criar_edificios()
	casa = sistema(preload("res://scripts/farmhouse.gd")) as Node3D
	calendario = sistema(preload("res://scripts/calendar.gd"))
	jogador = sistema(Jogador) as CharacterBody3D
	jogador.position = preload("res://scripts/farmhouse.gd").INICIO
	jogador.position.y = altura(jogador.position)+0.05
	camera = sistema(Camara) as Node3D
	camera.alvo = jogador
	ferramentas = sistema(preload("res://scripts/tools.gd")) as Node3D
	criar_maquinas()
	for indice: int in range(3):
		var carrinha: Node3D = preload("res://scripts/trailer.gd").new()
		carrinha.mundo = self
		carrinha.position = Vector3(-18+indice*8,0,56)
		carrinha.position.y = altura(carrinha.position)
		add_child(carrinha); carrinhas.append(carrinha)
	criar_drones()
	missoes = sistema(preload("res://scripts/missions.gd"))
	tarefas = sistema(preload("res://scripts/tasks.gd"))
	criar_pessoas()
	aldeia = sistema(preload("res://scripts/village.gd")) as Node3D
	contrato = sistema(preload("res://scripts/contract.gd"))
	economia = sistema(preload("res://scripts/economy.gd"))
	entregas = sistema(preload("res://scripts/deliveries.gd"))
	caminhao = sistema(preload("res://scripts/truck.gd")) as CharacterBody3D
	caminhao.position = Vector3(49,altura(Vector3(49,0,18))+0.1,18)
	armazem = sistema(preload("res://scripts/warehouse.gd")) as Node3D
	for indice: int in range(3):
		var fabrica: Node3D = preload("res://scripts/factory.gd").new()
		fabrica.mundo = self
		fabrica.numero = indice
		add_child(fabrica)
		fabricas.append(fabrica)
	equipa_grupo = sistema(preload("res://scripts/crew.gd"))
	comunidade = sistema(preload("res://scripts/community.gd")) as Node3D
	mundo_vivo = sistema(preload("res://scripts/world_details.gd")) as Node3D
	criar_rotinas_comunidade()
	vitais = sistema(preload("res://scripts/vitals.gd"))
	feedback = sistema(preload("res://scripts/farm_feedback.gd")) as Node3D
	familia = sistema(preload("res://scripts/family.gd")) as Node3D
	for i: int in range(2):
		var carro: CharacterBody3D = preload("res://scripts/car.gd").new(); carro.mundo = self; carro.numero = i; carro.position = Vector3(14+i*6,altura(Vector3(14+i*6,0,-28))+0.05,-28); add_child(carro); carros.append(carro)
	partida = sistema(preload("res://scripts/persistence.gd"))
	hud = sistema(Hud) as CanvasLayer
	get_tree().auto_accept_quit = false
	guia_entrega = sistema(preload("res://scripts/delivery_route.gd")) as CanvasLayer
	painel_conducao = preload("res://scripts/driving_hud.gd").new(); painel_conducao.mundo = self; hud.raiz.add_child(painel_conducao)
	if "--capturar-logistica" in OS.get_cmdline_user_args(): capturar_logistica.call_deferred()
	if "--teste-logistica" in OS.get_cmdline_user_args(): testar_logistica.call_deferred()
	if "--teste" in OS.get_cmdline_user_args(): testar.call_deferred()
	if "--capturar" in OS.get_cmdline_user_args(): capturar.call_deferred()
	if "--capturar-condutor" in OS.get_cmdline_user_args(): capturar_condutor.call_deferred()
	if "--teste-percurso" in OS.get_cmdline_user_args(): testar_percurso.call_deferred()
	if "--teste-veiculos" in OS.get_cmdline_user_args(): testar_veiculos.call_deferred()

func criar_rotinas_comunidade() -> void:
	var casas_usadas: Array[Vector2] = []
	for centro: Vector3 in preload("res://scripts/village.gd").CENTROS: casas_usadas.append(Vector2(centro.x-10,centro.z-34))
	for pessoa: Node3D in pessoas:
		# Mantém os candidatos da quinta disponíveis; os moradores recebem uma casa real.
		if pessoa.numero<6: continue
		var lar: Vector3 = pessoa.position
		var quinta: int = -1
		if pessoa.numero<18:
			quinta = (pessoa.numero-6)/2
			lar = preload("res://scripts/village.gd").CENTROS[quinta]+Vector3(-10,0,-34)
		else:
			var distancia: float = INF
			for residencia: Node3D in comunidade.casas:
				if not casas_usadas.has(Vector2(residencia.position.x,residencia.position.z)) and residencia.position.distance_squared_to(pessoa.position)<distancia:
					distancia = residencia.position.distance_squared_to(pessoa.position); lar = residencia.position
			casas_usadas.append(Vector2(lar.x,lar.z))
		pessoa.rotina = preload("res://scripts/community_routine.gd").new()
		pessoa.rotina.configurar(pessoa,lar,quinta)

func altura(ponto: Vector3) -> float:
	return relevo.altura(ponto) if relevo!=null else 0.0

func criar_edificios() -> void:
	var galpao: Node3D = Node3D.new()
	galpao.position = Vector3(-42,altura(Vector3(-42,0,40)),40)
	add_child(galpao)
	for lado: float in [-1.0,1.0]: caixa(galpao,Vector3(lado*15,2.8,0),Vector3(0.3,5.6,22),Color("998b71"),true)
	caixa(galpao,Vector3(0,2.8,11),Vector3(30,5.6,0.3),Color("998b71"),true)
	caixa(galpao,Vector3(0,5.8,0),Vector3(31,0.25,23),Color("52645e"),true)
	placa(galpao,Vector3(0,6.5,-11),"GALPÃO")

func criar_maquinas() -> void:
	for indice: int in range(3):
		var veiculo: CharacterBody3D = preload("res://scripts/tractor.gd").new()
		veiculo.mundo = self
		veiculo.numero = indice
		veiculo.position = Vector3(-51+indice*9,0,24)
		veiculo.position.y = altura(veiculo.position)+0.1
		add_child(veiculo); tratores.append(veiculo)
	for fila_maquinas: int in range(3):
		for tipo: int in range(4):
			var maquina: Node3D = preload("res://scripts/implement.gd").new()
			maquina.mundo = self; maquina.tipo = tipo
			maquina.position = Vector3((-51 if fila_maquinas==0 else -70)+tipo*6,0,44 if fila_maquinas==0 else -40 if fila_maquinas==1 else -28)
			maquina.position.y = altura(maquina.position)
			add_child(maquina); implementos.append(maquina)

func criar_drones() -> void:
	for indice: int in range(3):
		var drone: Node3D = preload("res://scripts/drone.gd").new()
		drone.mundo = self
		drone.numero = indice
		drone.position = Vector3(indice*8,0.7,-18)
		drone.position.y = altura(drone.position)+0.7
		add_child(drone)
		drones.append(drone)

func drone_proximo() -> Node3D:
	for drone: Node3D in drones:
		if drone.disponivel(): return drone
	return null

func alternar_drone() -> void:
	if drone_actual!=null: drone_actual.devolver(); return
	var proximo: Node3D = drone_proximo()
	if proximo!=null: proximo.assumir()

func criar_pessoas() -> void:
	for indice: int in range(6):
		var pessoa: Node3D = preload("res://scripts/npc.gd").new()
		pessoa.mundo = self
		pessoa.numero = indice
		pessoa.nome = ["Afonso","Lídia","Rui","Ana","Tomás","Celina"][indice]
		pessoa.mulher = indice%2==1
		pessoa.position = Vector3(-22+indice*8,0.1,92+indice*1.2)
		pessoa.position.y = altura(pessoa.position)+0.05
		pessoa.rota.assign([Vector3(-24+indice*2,0,92+indice*1.2),Vector3(24-indice*2,0,92+indice*1.2)])
		if indice%2==1: pessoa.rota.append(Vector3(8+indice*2,0,5+indice*3))
		if indice>=4:
			pessoa.position = Vector3(32+(indice-4)*7,0,-44); pessoa.vizinho = true
			pessoa.rota.assign([pessoa.position,pessoa.position+Vector3(0,0,7)])
		pessoa.position.y = altura(pessoa.position)+0.1
		add_child(pessoa)
		pessoas.append(pessoa)

func pessoa_proxima() -> Node3D:
	for pessoa: Node3D in pessoas:
		if pessoa.veiculo==null and pessoa.global_position.distance_to(jogador.global_position)<2.6: return pessoa
	return null

func contratar(pessoa: Node3D,plano: Dictionary = {}) -> bool:
	# A activação só ocorre após pagamento confirmado e aperto de mão.
	if plano.is_empty() or pessoa.servico.is_empty() or not bool(pessoa.servico.get("pagamento_confirmado",false)): return false
	pessoa.contratado = true
	pessoa.estado = "A iniciar "+str(plano.tarefa)
	tarefas.iniciar_servico(pessoa)
	avisar(pessoa.nome+" · "+str(plano.tarefa)+" · H acompanha o progresso")
	return true

func depositar(carga: Dictionary) -> void:
	armazem.receber(carga)

func retirar_stock() -> Dictionary:
	return armazem.retirar()

func trator_proximo() -> CharacterBody3D:
	if caminhao!=null and not caminhao.ocupado and caminhao.position.distance_to(jogador.position)<4: return caminhao
	for veiculo: CharacterBody3D in tratores+carros:
		if veiculo.global_position.distance_to(jogador.global_position)<3.0 and not veiculo.ocupado and veiculo.atribuido==null: return veiculo
	return null

func interagir() -> void:
	if contrato!=null and contrato.activo: contrato.confirmar(); return
	if trator_actual!=null:
		if not trator_actual.sair(): avisar("Pare antes de sair do tractor.")
		return
	if casa!=null and casa.vida_domestica.interagir(): return
	for fabrica: Node3D in fabricas:
		if fabrica.perto(): entregas.entregar(sacola,fabrica.numero); economia.vender(sacola,fabrica.numero); return
	if armazem!=null and armazem.perto():
		var carga: Dictionary = retirar_stock()
		for cultura_id: int in carga: sacola[cultura_id] = int(sacola.get(cultura_id,0))+int(carga[cultura_id])
		avisar("Carga recolhida. Leve-a a uma fábrica e prima E.")
		return
	var pessoa: Node3D = pessoa_proxima()
	if pessoa!=null:
		if not pessoa.contratado: contrato.iniciar(pessoa)
		else: avisar(pessoa.nome+" · "+pessoa.estado+" · H acompanha o contrato")
		return
	var proximo: CharacterBody3D = trator_proximo()
	if proximo!=null: proximo.entrar()

func accionar() -> void:
	if drone_actual!=null: return
	if trator_actual==caminhao and caminhao!=null: caminhao.transferir(); return
	if trator_actual!=null:
		if trator_actual.implemento!=null:
			if trator_actual.implemento.is_in_group("reboques"): trator_actual.implemento.transferir()
			else: trator_actual.implemento.activo = not trator_actual.implemento.activo
	else: ferramentas.usar()

func bloqueia_jogador() -> bool:
	return (casa!=null and casa.vida_domestica!=null and casa.vida_domestica.ocupado()) or pausado() or (camera!=null and camera.livre) or trator_actual!=null or drone_actual!=null or (contrato!=null and contrato.activo)

func camera_giro() -> float:
	return float(camera.giro) if is_instance_valid(camera) else 0.0

func dinheiro() -> int:
	return saldo

func pausado() -> bool:
	return hud==null or hud.selecao.visible or hud.aberto or hud.kit_aberto

func receber_colheita(cultura: int, quantidade: int) -> void:
	sacola[cultura] = int(sacola.get(cultura,0))+quantidade
	avisar("+%d %s" % [quantidade,preload("res://scripts/crop.gd").NOMES[cultura]])

func avisar(texto: String) -> void:
	aviso = texto
	aviso_tempo = 3.0

func dica() -> String:
	if contrato!=null and contrato.activo: return "A assinar contrato…" if contrato.confirmado else "Escolha tarefa, quantidade e tractor · Confirme o orçamento · Esc cancela"
	if drone_actual!=null: return "F · Regressar   WASD · Voar   Espaço/Ctrl · Subir/descer   R · Irrigar"
	if aviso_tempo>0: return aviso
	if drone_proximo()!=null: return "F · Controlar drone"
	if trator_actual!=null:
		if trator_actual.implemento!=null and trator_actual.implemento.is_in_group("reboques"): return "Carrinha %d/120 · X carregar/entregar · G soltar · E sair" % trator_actual.implemento.total()
		if trator_actual.implemento!=null: return "WASD · Conduzir   E · Sair   G · Desacoplar   Espaço · "+("Parar" if trator_actual.implemento.activo else "Trabalhar")
		var maquina: Node3D = trator_actual.candidato()
		return "G · Acoplar "+maquina.NOMES[maquina.tipo]+"   E · Sair" if maquina!=null else "WASD · Conduzir   E · Sair do tractor"
	for fabrica: Node3D in fabricas:
		if fabrica.perto(): return "E · Vender carga à fábrica "+["A","B","C"][fabrica.numero]
	if armazem!=null and armazem.perto(): return "E · Recolher produtos para entrega   H · Stock e sementes"
	if pessoa_proxima()!=null: return "E · Conversar / contratar"
	if trator_proximo()!=null: return "E · Entrar no tractor"
	if ferramentas==null: return ""
	var chave: Vector2i = ferramentas.chave_alvo()
	if terreno.celulas.has(chave):
		var dados: Dictionary = terreno.celulas[chave]
		return ["Enxada · Preparar terra","Semeadora · Semear","Regador · Sementes secas, sem crescimento","Cultura regada","A crescer","Mãos livres · Colher"][int(dados.estado)]
	return ""

func ajuda() -> String:
	return "MOZCOLHEITA · H fecha\nWASD andar · Shift correr · Rato olhar · Roda/+/- zoom\nL dia/noite e nova manhã · V câmara livre · J comer · F5 guardar · F9 retomar\nK kit · 1–6 ferramentas · Clique/Espaço usar\nE conversar/entrar/sair/entregar · G engatar · Espaço no tractor liga máquina\nF pilota/devolve drone · Espaço/Ctrl sobem/descem · R irrigação\nLavrar → semear → regar → crescer (3 dias) → colher\nFuncionários: tarefa e orçamento obrigatórios · máximo três contratos\nSaldo: %s · Sementes: %d · Madeira: %d" % [preload("res://scripts/economy.gd").formatar(saldo),ferramentas.sementes,ferramentas.madeira]

func resumo_stock() -> String:
	var texto: String = "PRODUTOS · consigo / armazém\n"
	for cultura_id: int in range(4): texto += "%s: %d / %d   " % [preload("res://scripts/crop.gd").NOMES[cultura_id],int(sacola.get(cultura_id,0)),int(stock.get(cultura_id,0))]
	return texto

func _process(delta: float) -> void:
	aviso_tempo = maxf(0,aviso_tempo-delta)
	if not pausado(): relogio += delta

func alternar_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _input(evento: InputEvent) -> void:
	if hud==null or hud.selecao.visible: return
	if evento is InputEventMouseButton and evento.pressed and hud.kit_aberto:
		if evento.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			ferramentas.seleccionar(ferramentas.actual+(1 if evento.button_index==MOUSE_BUTTON_WHEEL_DOWN else -1))
			get_viewport().set_input_as_handled()

func _unhandled_input(evento: InputEvent) -> void:
	if hud==null: return
	if hud.selecao.visible:
		if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode==KEY_F9: partida.carregar()
		return
	if casa!=null and casa.vida_domestica.ocupado():
		casa.vida_domestica.entrada(evento); return
	if evento is InputEventJoypadButton and evento.pressed:
		if evento.button_index==JOY_BUTTON_START: hud.alternar(); return
		if pausado(): return
		if drone_actual!=null:
			if evento.button_index==JOY_BUTTON_X: alternar_drone()
			if evento.button_index==JOY_BUTTON_Y: drone_actual.irrigando = not drone_actual.irrigando
		elif trator_actual!=null:
			if evento.button_index==JOY_BUTTON_A: interagir()
			if evento.button_index==JOY_BUTTON_X: trator_actual.engatar()
			if evento.button_index==JOY_BUTTON_B: accionar()
			if evento.button_index==JOY_BUTTON_Y and trator_actual==caminhao: caminhao.transferir()
			elif evento.button_index==JOY_BUTTON_Y and trator_actual!=null and trator_actual.implemento!=null and trator_actual.implemento.is_in_group("reboques"): trator_actual.implemento.transferir()
		elif evento.button_index==JOY_BUTTON_A: interagir()
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.physical_keycode==KEY_C and not pausado() and not contrato.activo: familia.chamar()
		if evento.physical_keycode==KEY_J: vitais.comer()
		if evento.physical_keycode == KEY_F5: partida.guardar()
		if evento.physical_keycode == KEY_F9: partida.carregar()
		if evento.physical_keycode == KEY_L and not pausado(): calendario.proximo_periodo()
		if evento.physical_keycode == KEY_V and not pausado(): camera.alternar_livre()
		if camera.livre and evento.physical_keycode not in [KEY_V,KEY_L,KEY_H,KEY_ESCAPE,KEY_TAB,KEY_F5,KEY_F9]: return
		if evento.physical_keycode == KEY_TAB: alternar_cursor()
		if evento.physical_keycode == KEY_H and not contrato.activo: hud.alternar()
		if evento.physical_keycode == KEY_K and trator_actual==null and drone_actual==null and not contrato.activo: hud.alternar_kit()
		if evento.physical_keycode == KEY_X and trator_actual==caminhao and not pausado(): caminhao.transferir()
		if evento.physical_keycode == KEY_X and trator_actual!=null and trator_actual.implemento!=null and trator_actual.implemento.is_in_group("reboques") and not pausado(): trator_actual.implemento.transferir()
		if evento.physical_keycode == KEY_B and not pausado() and not contrato.activo: reabastecer()
		if evento.physical_keycode == KEY_R and drone_actual!=null and not pausado(): drone_actual.irrigando = not drone_actual.irrigando
		if evento.physical_keycode == KEY_F and not pausado() and not contrato.activo: alternar_drone()
		if evento.physical_keycode == KEY_E and not pausado() and drone_actual==null: interagir()
		if evento.physical_keycode == KEY_G and not pausado() and trator_actual!=null: trator_actual.engatar()
		if evento.physical_keycode>=KEY_1 and evento.physical_keycode<=KEY_6 and not hud.aberto:
			ferramentas.seleccionar(evento.physical_keycode-KEY_1)
			if hud.kit_aberto: hud.alternar_kit()
		if evento.physical_keycode == KEY_SPACE and not pausado() and not contrato.activo: accionar()
		if evento.physical_keycode == KEY_ESCAPE:
			if contrato.activo: contrato.terminar(false); return
			if hud.aberto: hud.alternar(); return
			if hud.kit_aberto: hud.alternar_kit(); return
			hud.menu()

	if evento is InputEventMouseButton and evento.button_index==MOUSE_BUTTON_LEFT and evento.pressed and not bloqueia_jogador() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		ferramentas.usar()

func verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas_testes.append(descricao)
		push_error("Validação falhou: "+descricao)

func assinar_teste(pessoa: Node3D,tipo: int,quantidade: int,tractor: int = 0) -> Dictionary:
	var anterior: Vector3 = jogador.position
	jogador.position = pessoa.position+Vector3(0,0,0.9)
	verificar(contrato.iniciar(pessoa),"Abrir proposta local")
	var plano: Dictionary = contrato.orcamento(tipo,quantidade,tractor,0)
	verificar(contrato.confirmar(plano),"Confirmar orçamento antes da animação")
	contrato.actualizar(0.25)
	verificar(jogador.maos[1].global_position.distance_to(pessoa.maos[1].global_position)<0.14,"Mãos encontram-se no contrato")
	contrato.actualizar(1.3)
	verificar(pessoa.contratado and not pessoa.fila.is_empty(),"Tarefa definida inicia logo após o aperto de mão")
	jogador.position = anterior
	return plano

func testar_contratos() -> void:
	var pessoa: Node3D = pessoas[0]
	verificar(not contratar(pessoa),"É impossível contratar sem tarefa e pagamento")
	var anterior: Vector3 = jogador.position
	jogador.position = pessoa.position+Vector3(0,0,0.9)
	verificar(contrato.iniciar(pessoa) and not contrato.confirmar(),"Proposta vazia não inicia aperto de mão")
	var agua: Dictionary = contrato.orcamento(2,10,0,0)
	var colheita: Dictionary = contrato.orcamento(4,10,0,0)
	verificar(int(colheita.total)>int(agua.total),"Colher paga mais do que regar")
	verificar(int(contrato.orcamento(6,10,0,0).total)>int(agua.total),"Vender paga mais do que regar")
	verificar(int(contrato.orcamento(2,20,0,0).total)>int(agua.total) and int(contrato.orcamento(2,10,0,2).total)>int(agua.total),"Quantidade e dificuldade alteram custo")
	var procura_antes: Dictionary = contrato.orcamento(4,100,0,0)
	var produzido_antes: int = missoes.produzido
	missoes.produzido = 450
	verificar(int(contrato.orcamento(4,100,0,0).demanda)<int(procura_antes.demanda),"Procura da missão altera orçamento")
	missoes.produzido = produzido_antes
	var reserva: int = saldo
	saldo = 0; verificar(not contrato.confirmar(agua) and pessoa.servico.is_empty(),"Sem saldo não reserva nem contrata"); saldo = reserva
	contrato.terminar(false)
	var plano: Dictionary = assinar_teste(pessoa,2,10)
	verificar(saldo==reserva-int(plano.total),"Aprovação reserva exactamente o orçamento apresentado")
	verificar(not tarefas.adicionar(pessoa,4),"Não muda o trabalho fora do contrato aprovado")
	contrato.creditar(pessoa,2)
	var ganho: int = int(pessoa.servico.pago)
	contrato.encerrar(pessoa,"Cancelado no teste")
	verificar(saldo==reserva-ganho and tratores[0].atribuido==null,"Cancelar devolve apenas trabalho não executado e liberta tractor")
	contrato.encerrar(pessoa,"Cancelar outra vez")
	verificar(saldo==reserva-ganho,"Cancelamento repetido não duplica reembolso")
	for i: int in range(2): assinar_teste(pessoas[i],2,5,i)
	jogador.position = pessoas[3].position+Vector3(0,0,0.9)
	verificar(contrato.iniciar(pessoas[3]),"Terceira proposta disponível")
	verificar(not contrato.confirmar(contrato.orcamento(2,5,0,0)),"Dois trabalhadores não partilham tractor reservado")
	contrato.terminar(false)
	assinar_teste(pessoas[2],2,5,2)
	verificar(contrato.activos()==3,"Três trabalhadores ocupam três tractores diferentes")
	jogador.position = pessoas[3].position+Vector3(0,0,0.9)
	verificar(not contrato.iniciar(pessoas[3]),"Quarto trabalhador é rejeitado")
	for i: int in range(3): contrato.encerrar(pessoas[i],"Fim do teste")
	verificar(contrato.activos()==0,"Cancelamentos libertam todas as reservas")
	jogador.position = anterior

func testar() -> void:
	hud.escolher(false)
	verificar(relevo.amplitude>5 and cerca.portoes.size()==6,"Relevo original e seis portões")
	verificar(aldeia.campos.size()==6 and pessoas.size()>=26,"Seis fazendas e comunidade com pelo menos 26 NPCs")
	verificar(not jogador.mulher and hud.logo!=null and hud.minimapa.visible,"Homem, logótipo e minimapa por defeito")
	verificar(terreno.celulas.is_empty() and terreno.lote_solo.multimesh.instance_count==0,"Nenhum solo demarcado ou preparado no início")
	var estacionados: Array[Node3D] = []; estacionados.append_array(implementos); estacionados.append_array(tratores); estacionados.append_array(drones); estacionados.append_array(carrinhas)
	for i: int in range(estacionados.size()):
		verificar(not preload("res://scripts/layout.gd").junto_portao(estacionados[i].position,18),"Máquinas afastadas dos portões")
		for j: int in range(i+1,estacionados.size()): verificar(preload("res://scripts/layout.gd").distancia(estacionados[i].position,estacionados[j].position)>4,"Estacionamento separado")
	for centro: Vector3 in preload("res://scripts/layout.gd").PORTOES:
		jogador.position = centro; jogador.position.y = altura(centro)+0.05; cerca._physics_process(1)
		var aberto: bool = false
		for portao: Dictionary in cerca.portoes:
			if portao.centro==centro: aberto = float(portao.abertura)>0.5
		verificar(aberto,"Portão abre junto ao jogador")
	var chave: Vector2i = Vector2i(0,0)
	verificar(not terreno.trabalhar(chave,"semear"),"Não semeia sem preparar")
	verificar(terreno.trabalhar(chave,"lavrar") and terreno.trabalhar(chave,"semear"),"Preparar e semear")
	terreno.avancar(100)
	verificar(int(terreno.celulas[chave].estado)==2 and float(terreno.celulas[chave].tempo)==0,"Secas não crescem")
	terreno.trabalhar(chave,"regar"); terreno.avancar(Terreno.DURACAO)
	verificar(terreno.trabalhar(chave,"colher") and not terreno.trabalhar(chave,"colher"),"Colheita única")
	verificar(int(sacola.get(0,0))==3 and missoes.produzido==3,"Produção entra na sacola e na missão uma única vez")
	verificar(tratores.size()==3 and implementos.size()==12 and drones.size()==3,"Veículos preservados")
	var veiculo: CharacterBody3D = tratores[0]
	var maquina: Node3D = implementos[0]
	maquina.position = veiculo.position+Vector3(0,0,2.8)
	verificar(veiculo.entrar() and veiculo.engatar() and jogador.visual.get_parent()==veiculo,"Condutor visível e máquina engatada")
	verificar(maquina.trabalhar(Vector3(4.5,0,3.5))>0,"Charrua prepara linhas")
	verificar(veiculo.engatar() and veiculo.sair(),"Desengatar e sair")
	jogador.position = drones[0].position+Vector3(2,0,0)
	verificar(drones[0].assumir() and camera.alvo==drones[0],"Drone remoto")
	terreno.trabalhar(Vector2i(3,3),"lavrar"); terreno.trabalhar(Vector2i(3,3),"semear")
	drones[0].position = Vector3(3.5,10,3.5)
	verificar(drones[0].irrigar()>0,"Drone rega culturas")
	drones[0].devolver()
	var carga: Dictionary = {0:4}; depositar(carga)
	var venda: Dictionary = retirar_stock(); var antes: int = saldo
	verificar(economia.vender(venda,0)>0 and saldo>antes and venda.is_empty(),"Economia conserva produtos")
	verificar(economia.vender(venda,0)==0,"Venda não duplica receita")
	var reboque: Node3D = carrinhas[0]; var origem: Dictionary = {0:150,1:5}
	verificar(reboque.carregar(origem)==120 and reboque.total()==120 and int(origem[0])+int(origem[1])==35,"Capacidade e excedente da carrinha")
	reboque.carga.clear(); reboque.actualizar_carga()
	var tractor_teste: CharacterBody3D = tratores[2]
	reboque.position = tractor_teste.position+Vector3(0,0,4.8)
	var bloqueio: MeshInstance3D = caixa(self,tractor_teste.to_global(Vector3(0,1.2,4.8)),Vector3(3,3,3),Color.GRAY,true)
	await get_tree().physics_frame
	verificar(not reboque.acoplar(tractor_teste),"Volume bloqueado impede engate")
	bloqueio.free(); await get_tree().physics_frame
	verificar(reboque.acoplar(tractor_teste),"Carrinha acopla após libertar espaço")
	reboque.carregar({0:7}); tractor_teste.position = Vector3(32,altura(Vector3(32,0,18)),18)
	verificar(reboque.transferir()==7 and int(stock.get(0,0))==7,"Carrinha deposita no armazém")
	reboque.carregar({1:8}); tractor_teste.position = Vector3(0,altura(Vector3(0,0,102)),102)
	verificar(reboque.transferir()>0 and reboque.total()==0 and reboque.transferir()==0,"Carrinha vende sem duplicação")
	reboque.soltar()
	testar_contratos()
	var dinheiro_antes: int = saldo
	var identificador_antes: int = missoes.identificador()
	missoes.registar(missoes.cultura(),missoes.restante())
	await get_tree().process_frame
	verificar(missoes.identificador()==identificador_antes+1 and missoes.historico==1 and saldo==dinheiro_antes+15000,"Missão acompanha produção e recompensa uma única vez")
	missoes.finalizar()
	verificar(missoes.historico==1 and saldo==dinheiro_antes+15000,"Recompensa não pode ser repetida")
	print("SISTEMAS · VALIDAÇÃO: ","PASSOU" if falhas_testes.is_empty() else "FALHOU")
	get_tree().quit(0 if falhas_testes.is_empty() else 1)

func fotografia(nome: String) -> void:
	for indice: int in range(2): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print("CAPTURA · ",nome," · selecção: ",hud.selecao.visible," · ",hud.selecao.get_global_rect())
	get_viewport().get_texture().get_image().save_png("/tmp/moz-autonomo-final-"+nome+".png")

func capturar() -> void:
	if DisplayServer.get_name()=="headless": get_tree().quit(); return
	await fotografia("inicio")
	hud.escolher(false)
	jogador.position = Vector3(0,0.05,10)
	jogador.position.y = altura(jogador.position)+0.05
	camera.giro = -0.35
	await fotografia("jogo")
	for x: int in range(-5,6):
		for z: int in range(1,7):
			var chave: Vector2i = Vector2i(x,z)
			terreno.trabalhar(chave,"lavrar")
			if x<3: terreno.trabalhar(chave,"semear",posmod(x,4))
			if x<0: terreno.trabalhar(chave,"regar")
	terreno.avancar(Terreno.DURACAO)
	terreno._process(0.3)
	await fotografia("cultivo")
	camera.enquadramento = true
	camera.ponto_fixo = Vector3(1,2.9,7.8)
	camera.olhar_fixo = Vector3(-2,0.7,3.8)
	camera.camara.global_position = camera.ponto_fixo
	await fotografia("culturas-detalhe")
	camera.enquadramento = false
	hud.alternar_kit()
	await fotografia("kit")
	hud.alternar_kit()
	hud.alternar()
	await fotografia("painel")
	hud.alternar()
	camera.enquadramento = true
	camera.ponto_fixo = Vector3(145,130,180)
	camera.olhar_fixo = Vector3(0,0,8)
	camera.camara.global_position = camera.ponto_fixo
	await fotografia("quinta")
	camera.ponto_fixo = Vector3(290,245,340)
	camera.olhar_fixo = Vector3(0,-8,0)
	camera.camara.global_position = camera.ponto_fixo
	await fotografia("vizinhas")
	camera.enquadramento = false
	tratores[0].entrar()
	camera.giro = -0.8
	camera.distancia = 5.0
	await fotografia("condutor")
	tratores[0].sair()
	var reboque: Node3D = carrinhas[0]
	var transporte: CharacterBody3D = tratores[2]
	transporte.position = reboque.position-Vector3(0,0,4.8)
	transporte.position.y = altura(transporte.position)+0.05
	await get_tree().physics_frame
	transporte.entrar(); reboque.acoplar(transporte); reboque.carregar({0:60})
	camera.enquadramento = true
	camera.ponto_fixo = reboque.position+Vector3(7,4,-6)
	camera.olhar_fixo = reboque.position+Vector3(0,1,-1)
	camera.camara.global_position = camera.ponto_fixo
	await fotografia("carrinha")
	reboque.soltar(); transporte.sair(); camera.enquadramento = false
	var pessoa: Node3D = pessoas[1]
	jogador.position = Vector3(2,0.05,18)
	jogador.position.y = altura(jogador.position)+0.05
	pessoa.position = Vector3(2,0.05,17.1)
	pessoa.position.y = altura(pessoa.position)+0.05
	jogador.animar(0,0)
	pessoa.animar(0,0)
	contrato.iniciar(pessoa)
	hud.op_trabalho.select(1); hud.actualizar_orcamento()
	await fotografia("orcamento")
	contrato.confirmar()
	contrato.set_process(false)
	jogador.set_physics_process(false)
	pessoa.set_physics_process(false)
	contrato.actualizar(0.2)
	await fotografia("contrato")
	contrato.actualizar(1.4)
	hud.alternar(); hud.paginas.current_tab = 1
	for i: int in range(pessoas.size()):
		if pessoas[i]==pessoa: hud.trabalhadores.select(i)
	hud._process(0.3)
	await fotografia("equipa-contrato")
	hud.alternar()
	contrato.encerrar(pessoa,"Fim da captura")
	get_tree().quit()

func testar_percurso() -> void:
	hud.escolher(false); Engine.time_scale = 10
	var pessoa: Node3D = pessoas[0]
	pessoa.position = Vector3(0,altura(Vector3(0,0,85))+0.05,85)
	jogador.position = Vector3(12,altura(Vector3(12,0,10))+0.05,10)
	terreno.trabalhar(Vector2i(0,0),"lavrar")
	var pagamentos: int = 0
	for tipo: int in [3,2,4,5,6]:
		if tipo==4: calendario.saltar(3)
		var plano: Dictionary = assinar_teste(pessoa,tipo,3 if tipo in [5,6] else 1)
		pagamentos += int(plano.total)
		for i: int in range(4000):
			await get_tree().physics_frame
			if pessoa.servico.is_empty(): break
		if not pessoa.servico.is_empty(): print("DIAGNÓSTICO ",pessoa.estado," peão ",pessoa.position," veículo ",pessoa.veiculo.position if pessoa.veiculo!=null else Vector3.ZERO," fila ",pessoa.fila," percurso ",pessoa.percurso)
		verificar(pessoa.servico.is_empty(),"Contrato físico conclui "+tarefas.NOMES[tipo])
	verificar(economia.vendas>0 and pessoa.pago==pagamentos,"Ciclo completo paga exactamente os cinco orçamentos")
	print("PERCURSO E CICLO COMPLETO · VALIDAÇÃO: ","PASSOU" if falhas_testes.is_empty() else "FALHOU")
	get_tree().quit(0 if falhas_testes.is_empty() else 1)

func capturar_condutor() -> void:
	if DisplayServer.get_name()=="headless": get_tree().quit(); return
	hud.escolher(false)
	tratores[0].entrar()
	camera.giro = -0.8
	camera.distancia = 5.0
	await fotografia("condutor")
	get_tree().quit()

func testar_veiculos() -> void:
	hud.escolher(false); Engine.time_scale = 10
	var pessoa: Node3D = pessoas[0]
	var maquina: Node3D = implementos[0]
	maquina.position = tratores[0].position+Vector3(0,0,2.8)
	await get_tree().physics_frame
	verificar(maquina.acoplar(tratores[0]),"Máquina preparada para funcionário")
	pessoa.position = tratores[0].position+Vector3(0,0,-3)
	pessoa.position.y = altura(pessoa.position)+0.05
	assinar_teste(pessoa,7,1)
	for i: int in range(1600):
		await get_tree().physics_frame
		if pessoa.servico.is_empty(): break
	verificar(pessoa.servico.is_empty() and pessoa.veiculo==null and pessoa.concluido==1 and terreno.celulas.size()==1,"Funcionário usa tractor na tarefa contratada e desembarca")
	var veiculo: CharacterBody3D = tratores[2]; var reboque: Node3D = carrinhas[0]
	veiculo.position = reboque.position-Vector3(0,0,4.8); veiculo.position.y = altura(veiculo.position)+0.05; veiculo.rotation.y = 0
	await get_tree().physics_frame
	verificar(veiculo.entrar() and reboque.acoplar(veiculo),"Engate físico da carrinha")
	reboque.carregar({0:40}); var inicio: Vector3 = veiculo.position
	var tecla: InputEventKey = InputEventKey.new(); tecla.physical_keycode = KEY_W; tecla.keycode = KEY_W; tecla.pressed = true; Input.parse_input_event(tecla)
	for i: int in range(80): await get_tree().physics_frame
	tecla.pressed = false; Input.parse_input_event(tecla)
	for i: int in range(30): await get_tree().physics_frame
	verificar(preload("res://scripts/layout.gd").distancia(inicio,veiculo.position)>10 and reboque.total()==40,"Transporte real mantém a carga")
	reboque.soltar(); verificar(reboque.total()==40,"Desengatar conserva produtos")
	print("VEÍCULOS · VALIDAÇÃO: ","PASSOU" if falhas_testes.is_empty() else "FALHOU")
	get_tree().quit(0 if falhas_testes.is_empty() else 1)

func reabastecer(todas: bool = false) -> void:
	var maquinas: Array[Node3D] = []
	for maquina: Node3D in implementos:
		if maquina.tipo==1 and (todas or (trator_actual!=null and trator_actual.implemento==maquina) or preload("res://scripts/layout.gd").distancia(jogador.position,maquina.position)<5): maquinas.append(maquina)
	if maquinas.is_empty():
		if ferramentas.actual==5 and saldo>=40: saldo -= 40; ferramentas.sementes += 20; avisar("+20 sementes manuais · 40 MT")
		else: avisar("B junto à semeadora ou engatada · 2 MT/semente · H → Mercado")
		return
	var custo: int = 0
	for maquina: Node3D in maquinas: custo += maquina.custo_abastecer()
	if custo==0: avisar("Depósito de sementes cheio."); return
	if saldo<custo: avisar("Saldo insuficiente: abastecimento custa %d MT." % custo); return
	for maquina: Node3D in maquinas: maquina.abastecer()
	avisar("Semeadoras reabastecidas · %d MT" % custo)

func comandos_actuais() -> String:
	if trator_actual==caminhao and caminhao!=null: return "CAMIÃO · WASD conduzir · W+T turbo · E sair parado\nX carregar/entregar · Carga %d/500 · Pare dentro da garagem da empresa" % caminhao.total()
	if camera.livre: return "CÂMARA LIVRE · WASD mover · Q/E altura · Shift acelerar\nRato olhar · V regressar · L alterna dia/noite"
	if drone_actual!=null: return "DRONE · WASD voar · Espaço subir · Ctrl descer\nR ligar/desligar irrigação · F devolver"
	if trator_actual!=null:
		var texto: String = "TRACTOR · WASD conduzir · W+T turbo\nE sair parado · G engatar/soltar · Espaço ligar máquina"
		var maquina: Node3D = trator_actual.implemento
		if maquina!=null and maquina.tipo==4: texto += "\nX carregar / depositar / vender · %d/120 unidades" % maquina.total()
		if maquina!=null and maquina.tipo==1: texto += "\nSementes: %d/300 · B abastecer (%d MT)" % [maquina.sementes,maquina.custo_abastecer()]
		return texto
	if armazem.perto(): return "GARAGEM · Entre a pé para guardar a colheita\nEntre com carrinha para carregar · E retirar à mão"
	for maquina: Node3D in implementos:
		if maquina.tipo==1 and preload("res://scripts/layout.gd").distancia(jogador.position,maquina.position)<5:
			return "SEMEADORA · %d/300 sementes\nB abastecer · %d MT · G engata com tractor parado" % [maquina.sementes,maquina.custo_abastecer()]
	if ferramentas.actual==5: return "SEMEADORA MANUAL · Clique/Espaço semear\nB comprar 20 sementes · 40 MT · K mudar ferramenta"
	return "WASD andar · K ferramentas · H gestão · E interagir"

func testar_logistica() -> void:
	hud.escolher(false); Engine.time_scale = 5
	for pessoa: Node3D in pessoas: pessoa.set_physics_process(false)
	verificar(carrinhas.size()==3 and fabricas.size()>=6,"Três carrinhas e seis garagens de fábricas")
	for fabrica_teste: Node3D in fabricas: verificar(not preload("res://scripts/layout.gd").dentro(fabrica_teste.position),"Fábrica fora da quinta")
	stock.clear(); sacola = {0:80,1:70}
	jogador.position = Vector3(32,altura(Vector3(32,0,35)),35)
	armazem.actualizar(1)
	verificar(sacola.is_empty() and int(stock[0])+int(stock[1])==150,"Entrada a pé deposita colheita")
	jogador.position = Vector3(5,altura(Vector3(5,0,5)),5); armazem.actualizar(1)
	verificar(armazem.portas[0].position.y==3 and armazem.portas[1].position.y==3 and int(stock[0])+int(stock[1])==150,"Portas fecham sem perder stock")
	var veiculo: CharacterBody3D = tratores[2]
	var reboque: Node3D = carrinhas[2]
	veiculo.position = Vector3(32,altura(Vector3(32,0,40))+0.1,40); veiculo.rotation.y = PI
	reboque.position = veiculo.to_global(Vector3(0,0,4.8)); reboque.position.y = altura(reboque.position)
	await get_tree().physics_frame
	verificar(veiculo.entrar() and reboque.acoplar(veiculo),"Carrinha entra na garagem engatada")
	armazem.actualizar(1)
	verificar(reboque.total()==120 and int(stock.get(0,0))+int(stock.get(1,0))==30,"Garagem carrega carrinha e guarda excedente")
	armazem.actualizar(1)
	verificar(reboque.total()==120,"Carga automática não duplica em permanência")
	reboque.position.z = 18; armazem.actualizar(1)
	reboque.position.z = 35; armazem.actualizar(1)
	verificar(reboque.total()==0 and int(stock.get(0,0))+int(stock.get(1,0))==150,"Carrinha com colheita descarrega numa nova entrada")
	armazem.actualizar(1); verificar(reboque.total()==0,"Não recarrega antes de sair")
	reboque.position.z = 18; armazem.actualizar(1)
	reboque.position.z = 35; armazem.actualizar(1)
	verificar(reboque.total()==120,"Voltar com carrinha vazia recolhe carga guardada")
	veiculo.position = Vector3(32,altura(Vector3(32,0,52)),52)
	reboque.position = veiculo.to_global(Vector3(0,0,4.8)); armazem.actualizar(1)
	verificar(float(armazem.portas[1].get_meta("abertura"))>0.9,"Porta mantém passagem para tractor e reboque")
	reboque.soltar(); veiculo.sair(); reboque.position = Vector3(6,altura(Vector3(6,0,56)),56)
	veiculo.position = Vector3(6,altura(Vector3(6,0,20)),20)
	# Aproximação física: a porta deve abrir antes do tractor chegar.
	veiculo.position = Vector3(32,altura(Vector3(32,0,8))+0.1,8); veiculo.rotation.y = PI
	jogador.position = Vector3(5,altura(Vector3(5,0,5)),5)
	armazem.actualizar(1); veiculo.entrar()
	var acelerar: InputEventKey = InputEventKey.new(); acelerar.physical_keycode = KEY_W; acelerar.keycode = KEY_W; acelerar.pressed = true; Input.parse_input_event(acelerar)
	for i: int in range(130): await get_tree().physics_frame
	acelerar.pressed = false; Input.parse_input_event(acelerar)
	verificar(veiculo.position.z>56,"Tractor atravessa as duas portas em movimento")
	for i: int in range(25): await get_tree().physics_frame
	veiculo.sair(); veiculo.position = Vector3(6,altura(Vector3(6,0,20)),20)
	var semeadora: Node3D = implementos[1]
	semeadora.sementes = 0
	var chave: Vector2i = Vector2i(7,3); terreno.trabalhar(chave,"lavrar")
	verificar(not terreno.trabalhar(chave,"semear",0,null,semeadora),"Máquina vazia não semeia")
	var antes: int = saldo; jogador.position = semeadora.position+Vector3(0,0,-2)
	reabastecer()
	verificar(semeadora.sementes==300 and saldo==antes-600,"B enche depósito com custo exacto")
	var manuais: int = ferramentas.sementes
	verificar(terreno.trabalhar(chave,"semear",0,null,semeadora) and semeadora.sementes==299 and ferramentas.sementes==manuais,"Máquina usa sementes próprias")
	antes = saldo; reabastecer(); verificar(saldo==antes-2 and semeadora.sementes==300,"Só paga sementes em falta")
	var pessoa: Node3D = pessoas[0]
	pessoa.position = Vector3(10,altura(Vector3(10,0,10))+0.05,10)
	assinar_teste(pessoa,7,1)
	verificar(jogador.bracos[1].rotation.y==0 and jogador.bracos[1].rotation.z==0 and jogador.cotovelos[1].rotation.z==0,"Mão volta à pose após aperto")
	pessoa.set_physics_process(true)
	var embarcou: bool = false
	var engatou: bool = false
	for i: int in range(2300):
		await get_tree().physics_frame
		if pessoa.veiculo!=null: embarcou = true
		if tratores[0].implemento!=null: engatou = true
		if pessoa.servico.is_empty(): break
	verificar(embarcou and engatou and pessoa.servico.is_empty(),"Funcionário busca máquina, engata e trabalha")
	if not pessoa.servico.is_empty(): print("ESTADO EQUIPAMENTO ",pessoa.estado," ",pessoa.position," tractor ",tratores[0].position," fila ",pessoa.fila); contrato.encerrar(pessoa,"Fim teste")
	# Obstáculo real atravessado por um percurso directo; peão deve contornar.
	pessoa.set_physics_process(false); pessoa.position = Vector3(12,altura(Vector3(12,0,-8))+0.05,-8)
	pessoa.destino_actual = Vector3.INF
	var obstaculo: Node3D = caixa(self,Vector3(12,altura(Vector3(12,0,-3))+1.5,-3),Vector3(5,3,3),Color.GRAY,true)
	await get_tree().physics_frame
	var chegou: bool = false
	for i: int in range(800):
		await get_tree().physics_frame
		if pessoa.caminhar(Vector3(12,0,3),get_physics_process_delta_time()): chegou = true; break
	verificar(chegou,"NPC contorna obstáculo sólido sem teletransporte")
	obstaculo.queue_free()
	veiculo.position = Vector3(15,altura(Vector3(15,0,-30))+0.1,-30); veiculo.rotation.y = 0
	verificar(veiculo.entrar(),"Tractor disponível para turbo")
	for codigo: int in [KEY_W,KEY_T]:
		var evento: InputEventKey = InputEventKey.new(); evento.physical_keycode = codigo; evento.keycode = codigo; evento.pressed = true; Input.parse_input_event(evento)
	for i: int in range(30): await get_tree().physics_frame
	verificar(veiculo.rapidez>6,"W+T acelera acima da velocidade normal")
	for codigo: int in [KEY_W,KEY_T]:
		var evento: InputEventKey = InputEventKey.new(); evento.physical_keycode = codigo; evento.keycode = codigo; evento.pressed = false; Input.parse_input_event(evento)
	print("LOGÍSTICA · VALIDAÇÃO: ","PASSOU" if falhas_testes.is_empty() else "FALHOU")
	get_tree().quit(0 if falhas_testes.is_empty() else 1)

func capturar_logistica() -> void:
	if DisplayServer.get_name()=="headless": get_tree().quit(); return
	hud.escolher(false)
	var veiculo: CharacterBody3D = tratores[2]
	veiculo.position = Vector3(32,altura(Vector3(32,0,17))+0.1,17); veiculo.rotation.y = PI
	var reboque: Node3D = carrinhas[2]; reboque.position = veiculo.to_global(Vector3(0,0,4.8)); reboque.position.y = altura(reboque.position)
	await get_tree().physics_frame
	veiculo.entrar(); reboque.acoplar(veiculo); reboque.carregar({0:40,1:30})
	armazem.actualizar(1); stock = {0:80,1:20}
	camera.giro = 3.7; camera.inclinacao = -0.4; camera.distancia = 16
	await fotografia("garagem-logistica")
	reboque.soltar(); veiculo.sair()
	var maquina: Node3D = implementos[1]
	veiculo.position = maquina.position-Vector3(0,0,2.8); veiculo.position.y = altura(veiculo.position); veiculo.rotation.y = 0
	await get_tree().physics_frame
	veiculo.entrar(); maquina.acoplar(veiculo); maquina.sementes = 0
	camera.giro = -0.8; camera.inclinacao = -0.2; camera.distancia = 6
	await fotografia("sementes-comandos")
	get_tree().quit()

func sair_guardando() -> void:
	if partida!=null and partida.iniciada and not partida.guardar(): return
	get_tree().quit()

func _notification(tipo: int) -> void:
	if tipo==NOTIFICATION_WM_CLOSE_REQUEST: sair_guardando()
