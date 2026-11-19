extends Node
## Contrato de produção em grupo: trabalho físico por etapas e reserva máxima aprovada.
const FASES: Array[String] = ["Preparar","Plantar","Regar","Aguardar três dias de crescimento","Colher","Carregar camião","Terminado"]
var mundo: Node3D
var plano: Dictionary = {}
var trabalhadores: Array[Node3D] = []
var campos: Array[Vector2i] = []
var pendentes: Array[Vector2i] = []
var ordens: Dictionary = {}
var tractores: Dictionary = {}
var fase: int = -1
var sementes: int = 0
var gasto: int = 0
var carregado: int = 0
var ultimo: String = "Aceite uma encomenda em Entregas para contratar uma equipa."
var centro: Vector2i = Vector2i(12,0)
func livres() -> Array[Node3D]:
	var resultado: Array[Node3D] = []
	for pessoa: Node3D in mundo.pessoas:
		if not pessoa.contratado and not pessoa.grupo and not pessoa.em_conversa and pessoa.servico.is_empty(): resultado.append(pessoa)
	resultado.sort_custom(func(a: Node3D,b: Node3D) -> bool: return a.position.distance_squared_to(mundo.jogador.position)<b.position.distance_squared_to(mundo.jogador.position))
	return resultado
func orcamento(fabrica: int,pessoas: int,dificuldade: int = 0) -> Dictionary:
	if not plano.is_empty() or not mundo.entregas.activas.has(fabrica): return {}
	var pedido: Dictionary = mundo.entregas.activas[fabrica]
	if bool(pedido.concluida) or bool(pedido.falhou) or pessoas<1 or pessoas>10 or livres().size()<pessoas: return {}
	var quantidade: int = int(pedido.quantidade)-int(pedido.entregue)
	var parcelas: int = ceili(quantidade/2.0)
	var factor: float = 1.0+clampi(dificuldade,0,2)*0.2+0.18*quantidade/int(pedido.quantidade)
	var tarifas: Array[int] = [ceili(6*factor),ceili(4*factor),ceili(2*factor),ceili(8*factor),ceili(5*factor)]
	var trabalho: int = parcelas*(tarifas[0]+tarifas[1]+tarifas[2]+tarifas[3])+quantidade*tarifas[4]
	var materiais: int = parcelas*2; var coordenacao: int = pessoas*12
	return {"limite":float(pedido.limite),"penalidade":int(pedido.penalidade),"id":int(pedido.id),"fabrica":fabrica,"cultura":int(pedido.cultura),"quantidade":quantidade,"pessoas":pessoas,"parcelas":parcelas,"dificuldade":dificuldade,"tarifas":tarifas,"trabalho":trabalho,"materiais":materiais,"coordenacao":coordenacao,"total":trabalho+materiais+coordenacao,"centro":centro}
func confirmar(proposta: Dictionary) -> bool:
	if proposta.is_empty() or not plano.is_empty(): return false
	var actual: Dictionary = orcamento(int(proposta.fabrica),int(proposta.pessoas),int(proposta.dificuldade))
	if actual.is_empty() or int(actual.total)!=int(proposta.total) or int(actual.id)!=int(proposta.id) or mundo.saldo<int(actual.total): return false
	if mundo.caminhao.ocupado or mundo.caminhao.CAPACIDADE-mundo.caminhao.total()<int(actual.quantidade): mundo.avisar("Estacione o camião com espaço para a encomenda antes de contratar."); return false
	var candidatos: Array[Vector2i] = []
	for x: int in range(centro.x-12,centro.x+12):
		for z: int in range(centro.y-12,centro.y+12):
			var chave: Vector2i = Vector2i(x,z)
			if mundo.terreno.disponivel(chave) and not mundo.terreno.celulas.has(chave) and not mundo.tarefas.reservas.has(chave): candidatos.append(chave)
	candidatos.sort_custom(func(a: Vector2i,b: Vector2i) -> bool: return a.distance_squared_to(centro)<b.distance_squared_to(centro))
	if candidatos.size()<int(actual.parcelas): mundo.avisar("Escolha centro com terreno natural suficiente para a equipa."); return false
	plano = actual; mundo.saldo -= int(plano.total); gasto = int(plano.coordenacao); sementes = int(plano.parcelas); carregado = 0
	campos.clear()
	for i: int in range(int(plano.parcelas)): campos.append(candidatos[i]); mundo.tarefas.reservas[candidatos[i]] = get_instance_id()
	trabalhadores.clear(); var disponiveis: Array[Node3D] = livres()
	for i: int in range(int(plano.pessoas)):
		var pessoa: Node3D = disponiveis[i]; trabalhadores.append(pessoa); pessoa.grupo = true; pessoa.estado = "Contrato de equipa confirmado"; pessoa.percurso.clear(); pessoa.destino_actual = Vector3.INF
		for tractor: CharacterBody3D in mundo.tratores:
			if tractor.atribuido==null and not tractor.ocupado:
				tractor.atribuido = pessoa; tractores[pessoa.get_instance_id()] = tractor; break
	mundo.contrato.som.play(); iniciar_fase(0)
	mundo.avisar("Equipa contratada: %d pessoas · orçamento máximo %d MT" % [trabalhadores.size(),int(plano.total)]); return true
func iniciar_fase(nova: int) -> void:
	fase = nova; pendentes.clear(); ordens.clear()
	if fase in [0,1,2,4]: pendentes.assign(campos)
	for pessoa: Node3D in trabalhadores:
		mundo.contrato.desembarcar(pessoa); mundo.tarefas.limpar(pessoa); pessoa.destino_actual = Vector3.INF; pessoa.percurso.clear()
		ordens[pessoa.get_instance_id()] = {"tempo":0.0,"manual":not tractores.has(pessoa.get_instance_id())}
		pessoa.estado = FASES[fase]
func actualizar(pessoa: Node3D,delta: float) -> void:
	if plano.is_empty(): return
	var id: int = pessoa.get_instance_id(); var ordem: Dictionary = ordens[id]
	if fase==3: pessoa.estado = FASES[3]; pessoa.animar(delta,0); return
	if fase==5: carregar(pessoa,delta); return
	if fase not in [0,1,2,4]: return
	var tractor: CharacterBody3D = tractores.get(id,null)
	var equipamento: int = {0:0,1:1,2:2,4:3}[fase]
	if tractor!=null and not mundo.tarefas.preparar_equipamento(pessoa,ordem,tractor,equipamento,delta): return
	if tractor==null: mundo.tarefas.enxada(pessoa)
	if not ordem.has("celula"):
		if pendentes.is_empty():
			pessoa.estado = "Etapa concluída · a libertar a parcela"
			# Quem termina afasta-se para não bloquear a última célula da equipa.
			if pessoa.veiculo==null:
				var indice: int = trabalhadores.find(pessoa)
				pessoa.caminhar(Vector3(centro.x+18+(indice%2)*3,0,centro.y-12+(indice/2)*4),delta)
			else: pessoa.animar(delta,0,true)
			return
		var melhor: int = 0
		for i: int in range(pendentes.size()):
			if Vector2(pessoa.position.x,pessoa.position.z).distance_squared_to(Vector2(pendentes[i]))<Vector2(pessoa.position.x,pessoa.position.z).distance_squared_to(Vector2(pendentes[melhor])): melhor = i
		ordem.celula = pendentes[melhor]; pendentes.remove_at(melhor)
	var chave: Vector2i = ordem.celula; var alvo: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5)
	if pessoa.veiculo!=null:
		if not ordem.has("alvo"):
			var direccao: Vector3 = alvo-pessoa.veiculo.position; direccao.y = 0; ordem.alvo = alvo+direccao.normalized()*2.8
		alvo = ordem.alvo
	if not mundo.tarefas.ir(pessoa,alvo,delta,1.5 if pessoa.veiculo!=null else 0.75): return
	pessoa.estado = "%s · %s" % [FASES[fase],preload("res://scripts/crop.gd").NOMES[int(plano.cultura)]]
	pessoa.animacao("watering" if fase==2 else "harvesting" if fase==4 else "planting"); pessoa.animar(delta,0,pessoa.veiculo!=null)
	ordem.tempo = float(ordem.tempo)+delta
	if float(ordem.tempo)<1.7: return
	var acao: String = {0:"lavrar",1:"semear",2:"regar",4:"colher"}[fase]
	if mundo.terreno.trabalhar(chave,acao,int(plano.cultura),pessoa,self if fase==1 else null):
		var tarifa: int = int(plano.tarifas[3 if fase==4 else fase]); gasto += tarifa+(2 if fase==1 else 0); pessoa.pago += tarifa; pessoa.concluido += 1
	ordem.erase("celula"); ordem.erase("alvo"); ordem.tempo = 0
func carregar(pessoa: Node3D,delta: float) -> void:
	pessoa.estado = "A carregar o camião"
	if mundo.caminhao.ocupado or absf(mundo.caminhao.rapidez)>0.3: pessoa.estado = "Estacione e saia do camião para carregar"; return
	if pessoa.carga.is_empty():
		pessoa.estado = "Carga entregue · a libertar o acesso"
		pessoa.caminhar(Vector3(4+trabalhadores.find(pessoa)*1.8,0,-14),delta)
		return
	if carregado>=int(plano.quantidade):
		pessoa.estado = "A guardar excedente no armazém"
		if pessoa.caminhar(mundo.armazem.ENTREGA,delta,2.2): mundo.armazem.receber(pessoa.carga)
		return
	if not pessoa.caminhar(mundo.caminhao.position,delta,4.4): return
	var cultura: int = int(plano.cultura); var existente: int = int(pessoa.carga.get(cultura,0))
	var unidades: int = mini(existente,mini(int(plano.quantidade)-carregado,mundo.caminhao.CAPACIDADE-mundo.caminhao.total()))
	if unidades>0:
		var lote: Dictionary = {cultura:unidades}; var movidas: int = mundo.caminhao.carregar(lote)
		pessoa.carga[cultura] = existente-movidas; carregado += movidas; gasto += movidas*int(plano.tarifas[4]); pessoa.pago += movidas*int(plano.tarifas[4])
		if int(pessoa.carga[cultura])==0: pessoa.carga.erase(cultura)
	# Excedente da produção pertence ao jogador e fica conservado no armazém.
	mundo.armazem.receber(pessoa.carga)
func _process(_delta: float) -> void:
	if plano.is_empty() or mundo.pausado(): return
	if fase==3:
		for chave: Vector2i in campos:
			if int(mundo.terreno.celulas.get(chave,{}).get("estado",0))!=5: return
		iniciar_fase(4); return
	if fase in [0,1,2,4] and pendentes.is_empty():
		for ordem: Dictionary in ordens.values():
			if ordem.has("celula"): return
		iniciar_fase(fase+1)
	elif fase==5:
		for pessoa: Node3D in trabalhadores:
			if not pessoa.carga.is_empty(): return
		if carregado>=int(plano.quantidade): terminar("Equipa terminou: camião carregado. Entregue na empresa.")
func terminar(motivo: String) -> void:
	if plano.is_empty(): return
	var devolucao: int = maxi(0,int(plano.total)-gasto); mundo.saldo += devolucao
	for pessoa: Node3D in trabalhadores:
		mundo.contrato.desembarcar(pessoa); mundo.tarefas.limpar(pessoa); pessoa.grupo = false; pessoa.estado = motivo; pessoa.ultimo_servico = motivo
		mundo.armazem.receber(pessoa.carga)
		var tractor: CharacterBody3D = tractores.get(pessoa.get_instance_id(),null)
		if tractor!=null and tractor.atribuido==pessoa: tractor.atribuido = null
	for chave: Vector2i in campos: mundo.tarefas.reservas.erase(chave)
	ultimo = "%s · custo real %d MT · devolvido %d MT" % [motivo,gasto,devolucao]
	plano = {}; trabalhadores.clear(); ordens.clear(); tractores.clear(); pendentes.clear(); fase = -1; mundo.avisar(ultimo)
func resumo() -> String:
	if plano.is_empty(): return ultimo
	return "%d trabalhadores · %s · camião %d/%d\nReserva %d MT · contabilizado %d MT · sementes %d\nPrazo da encomenda: %s · multa %d MT" % [trabalhadores.size(),FASES[fase],carregado,plano.quantidade,plano.total,gasto,sementes,mundo.calendario.restante(float(plano.limite)-mundo.calendario.decorrido),plano.penalidade]
