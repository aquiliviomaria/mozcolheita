extends Node
## A contratação só é efectivada depois da confirmação e dos três movimentos de mão.
var historico: Array[Dictionary] = []
var mundo: Node3D
var activo: bool = false
var pessoa: Node3D
var confirmado: bool = false
var tempo: float = 0.0
var espera: float = 0.0
var som: AudioStreamPlayer
var encontro: Vector3 = Vector3.ZERO

func _ready() -> void:
	som = AudioStreamPlayer.new()
	add_child(som)
	var audio: AudioStreamWAV = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 8000
	var dados: PackedByteArray = PackedByteArray()
	dados.resize(6400*2)
	for indice: int in range(6400):
		var t: float = float(indice)/8000
		var envolvente: float = maxf(0,sin(t*PI*8))*sin(PI*t/0.8)
		dados.encode_s16(indice*2,int(sin(t*TAU*(190+25*sin(t*13)))*envolvente*2400))
	audio.data = dados
	som.stream = audio

const TRABALHOS: Array[int] = [7,2,3,4,5,6]
const TARIFAS: Array[int] = [6,2,4,8,5,10]
const POR_MINUTO: Array[int] = [3,2,3,5,4,6]
const SEGUNDOS: Array[int] = [6,3,4,7,4,6]
var proposta: Dictionary = {}
var centro_trabalho: Vector2i = Vector2i.ZERO

func orcamento(tipo: int,quantidade: int,tractor: int,dificuldade: int,fabrica: int = 0) -> Dictionary:
	if tipo==6 and not mundo.economia.aceita(fabrica,mundo.missoes.cultura()): return {}
	var indice: int = TRABALHOS.find(tipo)
	if indice<0 or quantidade<1 or quantidade>500 or tractor<0 or tractor>=3: return {}
	var centro: Vector3 = Vector3(centro_trabalho.x,0,centro_trabalho.y)
	var distancia: float = preload("res://scripts/layout.gd").distancia(pessoa.global_position if pessoa!=null else mundo.jogador.position,centro)
	if tipo in [5,6]: distancia += 80 if tipo==5 else 180
	var minutos: int = maxi(1,ceili((quantidade*SEGUNDOS[indice]+distancia/2)/60))
	var base: int = quantidade*TARIFAS[indice]
	var tempo_estimado: int = minutos*POR_MINUTO[indice]
	var factor: float = 1+clampi(dificuldade,0,2)*0.2+minf(0.35,absf(mundo.altura(centro)-mundo.jogador.position.y)/20+distancia/600)
	var extra_dificuldade: int = ceili((base+tempo_estimado)*(factor-1))
	var procura: float = 0.18*float(mundo.missoes.restante())/mundo.missoes.METAS[mundo.missoes.cultura()]
	if tipo in [4,6]: procura *= 1.25
	var extra_missao: int = ceili((base+tempo_estimado+extra_dificuldade)*procura)
	var prazo: float = maxf(2400,minutos*120.0+300)/(1.0+clampi(dificuldade,0,2)*0.15)
	var penalidade: int = maxi(10,ceili((base+tempo_estimado+extra_dificuldade+extra_missao)*(0.15+clampi(dificuldade,0,2)*0.10)))
	return {"prazo":prazo,"penalidade":penalidade,"tipo":tipo,"tarefa":mundo.tarefas.NOMES[tipo],"quantidade":quantidade,"trator":tractor,"fabrica":clampi(fabrica,0,2),"cultura":mundo.missoes.cultura(),"missao":mundo.missoes.identificador(),"objectivo":mundo.missoes.titulo(),"area":Rect2i(floori(centro.x)-12,floori(centro.z)-12,24,24),"base":base,"tempo":tempo_estimado,"minutos":minutos,"dificuldade":extra_dificuldade,"nivel":dificuldade,"demanda":extra_missao,"total":base+tempo_estimado+extra_dificuldade+extra_missao}

func activos() -> int:
	var total: int = 0
	for veiculo: Node3D in mundo.tratores:
		if veiculo.atribuido!=null: total += 1
	return total

func iniciar(vizinho: Node3D) -> bool:
	if activo or vizinho.grupo or not vizinho.servico.is_empty() or mundo.trator_actual!=null or mundo.drone_actual!=null: return false
	if vizinho.global_position.distance_to(mundo.jogador.position)>3: mundo.avisar("Aproxime-se do trabalhador."); return false
	if activos()>=3: mundo.avisar("Os três tractores já estão atribuídos."); return false
	activo = true; pessoa = vizinho; pessoa.em_conversa = true; confirmado = false; proposta = {}; tempo = 0; espera = 0
	mundo.jogador.bloqueado = true
	var centro: Vector3 = (pessoa.global_position+mundo.jogador.global_position)*0.5
	mundo.camera.enquadramento = true
	mundo.camera.ponto_fixo = centro+Vector3(2.7,2.1,3)
	mundo.camera.olhar_fixo = centro+Vector3.UP*1.25
	pessoa.dizer("Bom dia! Qual é o trabalho e o orçamento?")
	mundo.hud.mostrar_proposta()
	return true

func confirmar(plano: Dictionary = {}) -> bool:
	if not activo or confirmado: return false
	if not plano.is_empty(): proposta = plano.duplicate(true)
	if proposta.is_empty() or TRABALHOS.find(int(proposta.get("tipo",-1)))<0: mundo.avisar("Escolha a tarefa antes de contratar."); return false
	if int(proposta.get("quantidade",0))<1 or int(proposta.get("total",0))<=0: return false
	if int(proposta.missao)!=mundo.missoes.identificador(): mundo.hud.actualizar_orcamento(); mundo.avisar("A missão mudou. Reveja e confirme o novo orçamento."); return false
	var veiculo: Node3D = mundo.tratores[int(proposta.trator)]
	if activos()>=3 or veiculo.atribuido!=null or veiculo.ocupado: mundo.avisar("Escolha um tractor livre."); return false
	if pessoa.global_position.distance_to(mundo.jogador.global_position)>1.15: mundo.avisar("Aguarde o trabalhador aproximar-se."); return false
	if mundo.saldo<int(proposta.total): mundo.avisar("Saldo insuficiente para o orçamento aprovado."); return false
	# Reserva o máximo aprovado uma única vez; o trabalho não executado é reembolsado.
	mundo.saldo -= int(proposta.total)
	pessoa.servico = proposta.duplicate(true)
	pessoa.servico.merge({"realizado":0,"pago":0,"pagamento_confirmado":true,"estado":"A assinar","limite":mundo.calendario.decorrido+float(proposta.prazo),"avisado":false})
	veiculo.atribuido = pessoa
	confirmado = true; tempo = 0
	mundo.hud.fechar_proposta()
	pessoa.dizer("Combinado: "+str(proposta.tarefa)+". Vamos cumprir a missão!")
	som.play()
	return true

func creditar(trabalhador: Node3D,quantidade: int) -> void:
	verificar_prazos()
	if trabalhador.servico.is_empty(): return
	var plano: Dictionary = trabalhador.servico
	var antes: int = int(plano.realizado)
	plano.realizado = mini(int(plano.quantidade),int(plano.realizado)+quantidade)
	var ganho: int = floori(float(plano.total)*int(plano.realizado)/int(plano.quantidade))
	trabalhador.pago += ganho-int(plano.pago); plano.pago = ganho
	trabalhador.concluido += int(plano.realizado)-antes
	if int(plano.realizado)>=int(plano.quantidade): encerrar(trabalhador,"Serviço concluído")

func desembarcar(trabalhador: Node3D) -> void:
	if trabalhador.veiculo==null: return
	var veiculo: CharacterBody3D = trabalhador.veiculo
	veiculo.recuar = false; veiculo.rapidez = 0; veiculo.velocity = Vector3.ZERO; veiculo.trabalhador = null; veiculo.ocupado = false
	if veiculo.implemento!=null: veiculo.implemento.activo = false
	trabalhador.visual.reparent(trabalhador); trabalhador.visual.transform = Transform3D.IDENTITY
	trabalhador.global_position = veiculo.global_position+veiculo.global_basis.x*2.2
	trabalhador.position.y = mundo.altura(trabalhador.position)+0.05
	trabalhador.collision_layer = 2; trabalhador.show(); trabalhador.veiculo = null; trabalhador.animar(0,0)

func encerrar(trabalhador: Node3D,motivo: String) -> void:
	if trabalhador.servico.is_empty(): return
	var plano: Dictionary = trabalhador.servico
	var devolucao: int = maxi(0,int(plano.total)-int(plano.pago))
	mundo.saldo += devolucao
	var veiculo: Node3D = mundo.tratores[int(plano.trator)]
	if veiculo.atribuido==trabalhador: veiculo.atribuido = null
	desembarcar(trabalhador)
	trabalhador.ultimo_servico = "%s · %s · %d/%d · pago %d MT · devolvido %d MT" % [motivo,plano.tarefa,plano.realizado,plano.quantidade,plano.pago,devolucao]
	mundo.tarefas.limpar(trabalhador)
	historico.append({"nome":trabalhador.nome,"tarefa":plano.tarefa,"estado":"Falhou" if motivo.begins_with("Prazo") else "Sucesso" if motivo=="Serviço concluído" else "Cancelado","quantidade":plano.quantidade,"realizado":plano.realizado,"penalidade":int(plano.penalidade) if motivo.begins_with("Prazo") else 0})
	trabalhador.servico = {}; trabalhador.contratado = false; trabalhador.estado = motivo

func terminar(assinado: bool) -> void:
	if not activo: return
	if assinado and confirmado:
		mundo.contratar(pessoa,proposta)
		var icone: Label3D = mundo.placa(pessoa,Vector3(0,2.6,0),"▤ CONTRATO")
		icone.modulate = Color("85e5b1")
		var animacao: Tween = create_tween(); animacao.tween_property(icone,"modulate:a",0,1.5); animacao.tween_callback(icone.queue_free)
	elif confirmado: encerrar(pessoa,"Contrato cancelado")
	pessoa.em_conversa = false; pessoa.repor_pose()
	mundo.jogador.bloqueado = false; mundo.jogador.repor_pose()
	mundo.camera.enquadramento = false; mundo.hud.fechar_proposta(); som.stop(); activo = false

func ajustar_mao(avatar: Node3D, alvo: Vector3) -> void:
	# Cinemática de dois ossos: ombro e cotovelo conduzem a mão ao mesmo ponto.
	var braco: Node3D = avatar.bracos[1]
	var cotovelo: Node3D = avatar.cotovelos[1]
	var ombro: Vector3 = braco.global_position
	var diferenca: Vector3 = alvo-ombro
	var distancia: float = clampf(diferenca.length(),0.05,0.555)
	var direccao: Vector3 = diferenca.normalized()
	var cosseno: float = clampf((0.27*0.27+distancia*distancia-0.29*0.29)/(2*0.27*distancia),-1,1)
	var flexao: Vector3 = (Vector3.DOWN-direccao*Vector3.DOWN.dot(direccao)).normalized()
	var centro: Vector3 = ombro+direccao*(cosseno*0.27)+flexao*(sqrt(maxf(0,1-cosseno*cosseno))*0.27)
	braco.quaternion = Quaternion(Vector3.DOWN,(braco.get_parent().global_basis.inverse()*(centro-ombro)).normalized())
	cotovelo.quaternion = Quaternion(Vector3.DOWN,(braco.global_basis.inverse()*(alvo-centro)).normalized())

func actualizar(delta: float) -> void:
	if not activo or mundo.pausado(): return
	var direccao: Vector3 = pessoa.global_position-mundo.jogador.global_position
	direccao.y = 0
	if direccao.length()<0.01: direccao = Vector3.FORWARD
	direccao = direccao.normalized()
	if not confirmado:
		espera += delta
		var alvo: Vector3 = mundo.jogador.global_position+direccao*0.9
		pessoa.caminhar(alvo,delta,0.08)

		return
	tempo += delta
	mundo.jogador.visual.rotation.y = atan2(-direccao.x,-direccao.z)
	pessoa.visual.rotation.y = atan2(direccao.x,direccao.z)
	encontro = (pessoa.global_position+mundo.jogador.global_position)*0.5+Vector3.UP*(1.17+sin(tempo*TAU*2)*0.045)
	ajustar_mao(mundo.jogador,encontro)
	ajustar_mao(pessoa,encontro)
	if tempo>=1.5: terminar(true)

func _process(delta: float) -> void:
	actualizar(delta)
	if mundo.hud!=null and not mundo.pausado(): verificar_prazos()

func verificar_prazos() -> void:
	for trabalhador: Node3D in mundo.pessoas:
		if trabalhador.servico.is_empty() or not trabalhador.servico.has("limite"): continue
		var plano: Dictionary = trabalhador.servico
		var restante: float = float(plano.limite)-mundo.calendario.decorrido
		if restante<=0:
			var multa: int = int(plano.penalidade)
			if activo and pessoa==trabalhador: confirmado = false; terminar(false)
			mundo.saldo -= multa; encerrar(trabalhador,"Prazo expirado · quebra de contrato")
			mundo.avisar("CONTRATO VENCIDO · %s · penalização %d MT" % [trabalhador.nome,multa])
		elif restante<=float(plano.prazo)*0.2 and not bool(plano.get("avisado",false)):
			plano.avisado = true; mundo.avisar("Prazo de %s a terminar · %s" % [trabalhador.nome,mundo.calendario.restante(restante)])

func texto_historico() -> String:
	var texto: String = "SERVIÇOS · HISTÓRICO DA SESSÃO\n"
	for item: Dictionary in historico: texto += "%s · %s · %s · %d/%d · multa %d MT\n" % [item.nome,item.tarefa,item.estado,item.realizado,item.quantidade,item.penalidade]
	return texto
