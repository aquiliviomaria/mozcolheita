extends Node
## Cada contrato é uma ordem com quantidade e cultura da missão, sem salários ocultos.
const NOMES: Array[String] = ["Conduzir tractor","Construir/reparar cerca","Regar","Semear","Colher","Transportar ao armazém","Vender à fábrica","Preparar a terra"]
var mundo: Node3D
var reservas: Dictionary = {}

func iniciar_servico(pessoa: Node3D) -> void:
	limpar(pessoa)
	var plano: Dictionary = pessoa.servico
	pessoa.fila.append({"tipo":int(plano.tipo),"trator":int(plano.trator),"fabrica":int(plano.fabrica),"cultura":int(plano.cultura),"tempo":0.0})
	pessoa.estado = "A iniciar "+str(plano.tarefa)

func adicionar(pessoa: Node3D,tipo: int,tractor: int = 0,fabrica: int = 0) -> bool:
	# Impede ordens gratuitas ou alterações de tarefa fora do orçamento confirmado.
	if pessoa.servico.is_empty() or not pessoa.contratado or not pessoa.fila.is_empty(): return false
	if tipo!=int(pessoa.servico.tipo) or tractor!=int(pessoa.servico.trator) or fabrica!=int(pessoa.servico.fabrica): return false
	iniciar_servico(pessoa); return true

func limpar(pessoa: Node3D) -> void:
	for chave: Vector2i in reservas.keys():
		if reservas[chave]==pessoa.get_instance_id(): reservas.erase(chave)
	for maquina: Node3D in mundo.implementos+mundo.carrinhas:
		if int(maquina.get_meta("reservado_por",0))==pessoa.get_instance_id(): maquina.remove_meta("reservado_por")
	if is_instance_valid(pessoa.ferramenta_servico): pessoa.ferramenta_servico.queue_free()
	pessoa.fila.clear(); pessoa.destino_actual = Vector3.INF; pessoa.percurso.clear()

func escolher_celula(pessoa: Node3D,tarefa: Dictionary) -> bool:
	var plano: Dictionary = pessoa.servico
	var area: Rect2i = plano.area
	var melhor: Vector2i = Vector2i(9999,9999)
	var distancia: float = INF
	for x: int in range(area.position.x,area.end.x):
		for z: int in range(area.position.y,area.end.y):
			var chave: Vector2i = Vector2i(x,z)
			if reservas.has(chave): continue
			var dados: Dictionary = mundo.terreno.celulas.get(chave,{})
			if int(tarefa.tipo)==7:
				if not dados.is_empty() or not mundo.terreno.disponivel(chave): continue
			else:
				var estado: int = {2:2,3:1,4:5}[int(tarefa.tipo)]
				if dados.is_empty() or int(dados.estado)!=estado: continue
				if int(tarefa.tipo)!=3 and int(dados.cultura)!=int(plano.cultura): continue
			var d: float = preload("res://scripts/layout.gd").distancia(pessoa.global_position,Vector3(x+0.5,0,z+0.5))
			if d<distancia: distancia = d; melhor = chave
	if melhor.x==9999: return false
	tarefa.celula = melhor; reservas[melhor] = pessoa.get_instance_id(); return true

func embarcar(pessoa: Node3D,veiculo: CharacterBody3D) -> void:
	if is_instance_valid(pessoa.ferramenta_servico): pessoa.ferramenta_servico.queue_free()
	veiculo.ocupado = true; veiculo.trabalhador = pessoa; pessoa.veiculo = veiculo
	pessoa.collision_layer = 0; pessoa.hide(); pessoa.visual.reparent(veiculo)
	pessoa.visual.transform = Transform3D(Basis.IDENTITY,Vector3(0,0.45,0.6))
	pessoa.destino_actual = Vector3.INF; pessoa.percurso.clear(); pessoa.animar(0,0,true)

func ir(pessoa: Node3D,alvo: Vector3,delta: float,alcance: float = 0.7) -> bool:
	if pessoa.veiculo==null: return pessoa.caminhar(alvo,delta,alcance)
	var veiculo: CharacterBody3D = pessoa.veiculo
	pessoa.global_position = veiculo.global_position; pessoa.animar(delta,0,true)
	if not pessoa.destino_actual.is_equal_approx(alvo): pessoa.planear(alvo)
	if pessoa.percurso.is_empty(): veiculo.rapidez = 0; return preload("res://scripts/layout.gd").distancia(veiculo.position,alvo)<maxf(alcance,1.5)
	veiculo.destino = pessoa.percurso[0]
	if preload("res://scripts/layout.gd").distancia(veiculo.position,veiculo.destino)<1.5:
		pessoa.percurso.pop_front()
		if pessoa.percurso.is_empty(): veiculo.rapidez = 0; veiculo.velocity = Vector3.ZERO; return true
	return false

func actualizar(pessoa: Node3D,delta: float) -> void:
	if pessoa.servico.is_empty() or pessoa.fila.is_empty(): return
	var plano: Dictionary = pessoa.servico
	if int(plano.missao)!=mundo.missoes.identificador(): mundo.contrato.encerrar(pessoa,"Missão alterada"); return
	var tarefa: Dictionary = pessoa.fila[0]
	var tipo: int = int(tarefa.tipo)
	var veiculo: CharacterBody3D = mundo.tratores[int(plano.trator)]
	var equipamento: int = {7:0,3:1,2:2,4:3,5:4,6:4}[tipo]
	if not preparar_equipamento(pessoa,tarefa,veiculo,equipamento,delta): return
	pessoa.estado = str(plano.tarefa)+(" · no tractor" if pessoa.veiculo!=null else " · manual")
	if tipo in [2,3,4,7]:
		var fonte: Node = pessoa.veiculo.implemento if pessoa.veiculo!=null and tipo==3 else mundo.ferramentas
		if tipo==3 and fonte.sementes<=0: pessoa.estado = "Sem sementes · B junto à máquina ou H → Mercado"; return
		if not tarefa.has("celula"):
			tarefa.procura = maxf(0,float(tarefa.get("procura",0))-delta)
			if float(tarefa.procura)>0: return
			if not escolher_celula(pessoa,tarefa):
				tarefa.procura = 1.0; pessoa.estado = "A aguardar parcela / cultura da missão"; return
		var chave: Vector2i = tarefa.celula
		var alvo: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5)
		if pessoa.veiculo!=null:
			if not tarefa.has("alvo_tractor"):
				var direccao: Vector3 = alvo-veiculo.position; direccao.y = 0
				tarefa.alvo_tractor = alvo+direccao.normalized()*2.8
			if not ir(pessoa,tarefa.alvo_tractor,delta,1.5): return
		elif not ir(pessoa,alvo,delta): return
		tarefa.tempo = float(tarefa.tempo)+delta
		pessoa.gesto = 0.75; pessoa.animar(delta,0,pessoa.veiculo!=null)
		if float(tarefa.tempo)<2: return
		var acao: String = {2:"regar",3:"semear",4:"colher",7:"lavrar"}[tipo]
		var sucesso: bool = mundo.terreno.trabalhar(chave,acao,int(plano.cultura),pessoa,fonte if tipo==3 else null)
		reservas.erase(chave); tarefa.erase("celula"); tarefa.erase("alvo_tractor"); tarefa.tempo = 0
		if sucesso: mundo.contrato.creditar(pessoa,1)
	elif tipo in [5,6]: transportar(pessoa,tarefa,delta)

func transportar(pessoa: Node3D,tarefa: Dictionary,delta: float) -> void:
	var plano: Dictionary = pessoa.servico
	var cultura: int = int(plano.cultura)
	var restante: int = int(plano.quantidade)-int(plano.realizado)
	var reboque: Node3D = pessoa.veiculo.implemento if pessoa.veiculo!=null and pessoa.veiculo.implemento!=null and pessoa.veiculo.implemento.tipo==4 else null
	var carga: Dictionary = reboque.carga if reboque!=null else pessoa.carga
	if int(carga.get(cultura,0))==0:
		var da_sacola: bool = int(tarefa.tipo)==5
		var da_pessoa: bool = int(pessoa.carga.get(cultura,0))>0
		var origem: Dictionary = mundo.sacola if da_sacola else mundo.stock
		if int(pessoa.carga.get(cultura,0))>0: origem = pessoa.carga
		if int(origem.get(cultura,0))<=0: pessoa.estado = "A aguardar produtos da missão"; return
		var ponto: Vector3 = mundo.jogador.global_position if da_sacola else mundo.armazem.ENTREGA
		if not da_pessoa and not ir(pessoa,ponto,delta,2.5): return
		var quantidade: int = mini(restante,int(origem[cultura]))
		if reboque!=null: quantidade = mini(quantidade,reboque.CAPACIDADE-reboque.total())
		if quantidade<=0: pessoa.estado = "Carrinha cheia"; return
		carga[cultura] = int(carga.get(cultura,0))+quantidade
		origem[cultura] = int(origem[cultura])-quantidade
		if int(origem[cultura])==0: origem.erase(cultura)
		if reboque!=null: reboque.actualizar_carga()
	var alvo: Vector3 = mundo.armazem.ENTREGA if int(tarefa.tipo)==5 else Vector3(-60+int(tarefa.fabrica)*60,0,102)
	if not ir(pessoa,alvo,delta,2.5): return
	var unidades: int = mini(restante,int(carga.get(cultura,0)))
	if unidades<=0: return
	var lote: Dictionary = {cultura:unidades}
	if int(tarefa.tipo)==5: mundo.depositar(lote)
	else: mundo.economia.vender(lote,int(tarefa.fabrica))
	carga[cultura] = int(carga[cultura])-unidades
	if int(carga[cultura])==0: carga.erase(cultura)
	if reboque!=null: reboque.actualizar_carga()
	mundo.contrato.creditar(pessoa,unidades)

func enxada(pessoa: Node3D) -> void:
	if is_instance_valid(pessoa.ferramenta_servico): return
	pessoa.ferramenta_servico = Node3D.new(); pessoa.mao_direita.add_child(pessoa.ferramenta_servico)
	mundo.caixa(pessoa.ferramenta_servico,Vector3(0,-0.3,0),Vector3(0.035,0.9,0.035),Color("ac865a"))
	mundo.caixa(pessoa.ferramenta_servico,Vector3(0,-0.7,-0.08),Vector3(0.26,0.04,0.2),Color("8fa8a1"))

func preparar_equipamento(pessoa: Node3D,tarefa: Dictionary,veiculo: CharacterBody3D,tipo: int,delta: float) -> bool:
	if bool(tarefa.get("manual",false)): enxada(pessoa); return true
	if veiculo.implemento!=null and veiculo.implemento.tipo==tipo:
		if pessoa.veiculo==null:
			pessoa.estado = "A recolher tractor equipado"
			if veiculo.ocupado or not pessoa.caminhar(veiculo.position,delta,2.3): return false
			embarcar(pessoa,veiculo)
		return true
	if not tarefa.has("maquina"):
		var melhor: Node3D
		var distancia: float = INF
		for maquina: Node3D in mundo.implementos+mundo.carrinhas:
			if maquina.tipo!=tipo or maquina.tractor!=null or maquina.has_meta("reservado_por"): continue
			var d: float = maquina.position.distance_to(veiculo.position)
			if d<distancia: melhor = maquina; distancia = d
		if melhor==null: tarefa.manual = true; enxada(pessoa); return true
		tarefa.maquina = melhor; melhor.set_meta("reservado_por",pessoa.get_instance_id()); tarefa.etapa = 0; tarefa.busca = 0.0
	var maquina: Node3D = tarefa.maquina
	tarefa.busca = float(tarefa.busca)+delta
	if float(tarefa.busca)>90:
		maquina.remove_meta("reservado_por"); veiculo.recuar = false
		mundo.contrato.desembarcar(pessoa); tarefa.manual = true; enxada(pessoa); return true
	pessoa.estado = "A buscar equipamento: "+(["Preparador","Semeadora","Irrigador","Ceifeira","Carrinha"][tipo])
	if pessoa.veiculo==null:
		if veiculo.ocupado or not pessoa.caminhar(veiculo.position,delta,2.3): return false
		embarcar(pessoa,veiculo)
	if veiculo.implemento!=null: veiculo.implemento.soltar()
	if int(tarefa.etapa)==0:
		if not ir(pessoa,maquina.position-Vector3(0,0,8),delta,1.0): return false
		tarefa.etapa = 1; pessoa.destino_actual = Vector3.INF; pessoa.percurso.clear()
	if int(tarefa.etapa)==1:
		veiculo.destino = veiculo.position; veiculo.rapidez = 0
		veiculo.rotation.y = rotate_toward(veiculo.rotation.y,0,delta*2)
		if absf(wrapf(veiculo.rotation.y,-PI,PI))>0.05: return false
		tarefa.etapa = 2; veiculo.recuar = true
	if int(tarefa.etapa)==2:
		if not ir(pessoa,maquina.position-Vector3(0,0,maquina.distancia_engate),delta,0.6): return false
		veiculo.recuar = false; veiculo.rapidez = 0
		if maquina.acoplar(veiculo):
			maquina.remove_meta("reservado_por"); tarefa.erase("maquina"); pessoa.destino_actual = Vector3.INF; pessoa.percurso.clear(); return true
	return false
