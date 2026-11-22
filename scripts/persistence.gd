extends Node
## Dados sem Object/Node, integridade SHA-256 e substituição por ficheiro temporário.
const VERSAO: int = 1
var mundo: Node3D
var caminho: String = "user://quinta.mozsave"
var iniciada: bool = false
var intervalo: float = 0
var estado: String = "F5 guardar · F9 continuar"
func existe() -> bool: return FileAccess.file_exists(caminho) or FileAccess.file_exists(caminho+".bak")
func _process(delta: float) -> void:
	if not iniciada or mundo.pausado() or DisplayServer.get_name()=="headless" or "--script" in OS.get_cmdline_args() or not OS.get_cmdline_user_args().is_empty(): return
	intervalo += delta/maxf(1,Engine.time_scale)
	if intervalo>=60:
		intervalo = 0
		guardar(false)
func posicao_segura(actor: Node3D,veiculo: Node3D = null) -> Vector3:
	if veiculo==null: return actor.global_position
	var consulta: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var forma: CapsuleShape3D = CapsuleShape3D.new(); forma.radius = 0.3; forma.height = 1.8; consulta.shape = forma; consulta.collision_mask = 1|2|4|8|16
	consulta.exclude = [mundo.relevo.corpo_chao.get_rid(),actor.get_rid()]
	for deslocamento: Vector3 in [veiculo.global_basis.x*2.6,-veiculo.global_basis.x*2.6,veiculo.global_basis.z*5,-veiculo.global_basis.z*5]:
		var p: Vector3 = veiculo.position+deslocamento; p.y = mundo.altura(p)+0.08
		consulta.transform = Transform3D(Basis.IDENTITY,p+Vector3.UP*0.9)
		if mundo.get_world_3d().direct_space_state.intersect_shape(consulta,1).is_empty(): return p
	var inicio: Vector3 = preload("res://scripts/farmhouse.gd").INICIO; inicio.y = mundo.altura(inicio)+0.08; return inicio
func limpar_ordem(original: Dictionary) -> Dictionary:
	var copia: Dictionary = original.duplicate(true)
	# A máquina é escolhida novamente ao retomar; nunca serializar referências vivas.
	for chave: String in ["maquina","etapa","busca"]: copia.erase(chave)
	return copia
func capturar() -> Dictionary:
	var d: Dictionary = {"vitais":{"vida":mundo.vitais.vida,"fome":mundo.vitais.fome,"energia":mundo.vitais.energia,"higiene":mundo.vitais.higiene},"saldo":mundo.saldo,"stock":mundo.stock.duplicate(),"sacola":mundo.sacola.duplicate(),"relogio":mundo.relogio,"calendario":mundo.calendario.decorrido,"terreno":mundo.terreno.celulas.duplicate(true),"jogador":{"mulher":mundo.jogador.mulher,"roupa":mundo.jogador.roupa,"perfil":mundo.jogador.perfil,"posicao":posicao_segura(mundo.jogador,mundo.trator_actual),"giro":mundo.jogador.visual.global_rotation.y},"ferramentas":{"actual":mundo.ferramentas.actual,"cultura":mundo.ferramentas.cultura,"sementes":mundo.ferramentas.sementes,"madeira":mundo.ferramentas.madeira},"missoes":{"indice":mundo.missoes.indice,"produzido":mundo.missoes.produzido,"historico":mundo.missoes.historico},"entregas":{"activas":mundo.entregas.activas.duplicate(true),"historico":mundo.entregas.historico.duplicate(true),"reputacao":mundo.entregas.reputacao.duplicate(),"sequencia":mundo.entregas.sequencia,"concluidas":mundo.entregas.concluidas},"historico_servicos":mundo.contrato.historico.duplicate(true),"vendas":mundo.economia.vendas,"veiculos":[],"maquinas":[],"pessoas":[],"cercas":[],"arvores":[],"drones":[]}
	for veiculo: Node3D in mundo.tratores+[mundo.caminhao]:
		var maquina: int = (mundo.implementos+mundo.carrinhas).find(veiculo.implemento)
		d.veiculos.append({"posicao":veiculo.position,"giro":veiculo.rotation.y,"maquina":maquina})
	d["carga_camiao"] = mundo.caminhao.carga.duplicate()
	for maquina: Node3D in mundo.implementos+mundo.carrinhas:
		d.maquinas.append({"posicao":maquina.position,"giro":maquina.rotation.y,"sementes":maquina.sementes if maquina.tipo<4 else 0,"carga":maquina.carga.duplicate() if maquina.tipo==4 else {}})
	for pessoa: Node3D in mundo.pessoas:
		var fila: Array[Dictionary] = []
		for ordem: Dictionary in pessoa.fila: fila.append(limpar_ordem(ordem))
		d.pessoas.append({"numero":pessoa.numero,"posicao":posicao_segura(pessoa,pessoa.veiculo),"servico":pessoa.servico.duplicate(true),"fila":fila,"carga":pessoa.carga.duplicate(),"pago":pessoa.pago,"concluido":pessoa.concluido,"ultimo":pessoa.ultimo_servico})
	for parte: Node3D in mundo.cerca.secoes: d.cercas.append({"posicao":parte.position,"giro":parte.rotation.y,"durabilidade":parte.get_meta("durabilidade",100)})
	for arvore: Node3D in mundo.ferramentas.arvores: d.arvores.append({"visivel":arvore.visible,"golpes":arvore.get_meta("golpes",0)})
	for drone: Node3D in mundo.drones: d.drones.append(drone.origem if drone.voando else drone.position)
	var equipa: Node = mundo.equipa_grupo
	var grupo: Dictionary = {"plano":equipa.plano.duplicate(true),"campos":equipa.campos.duplicate(),"pendentes":equipa.pendentes.duplicate(),"fase":equipa.fase,"sementes":equipa.sementes,"gasto":equipa.gasto,"carregado":equipa.carregado,"centro":equipa.centro,"ultimo":equipa.ultimo,"membros":[]}
	for pessoa: Node3D in equipa.trabalhadores:
		grupo.membros.append({"numero":pessoa.numero,"ordem":limpar_ordem(equipa.ordens[pessoa.get_instance_id()]),"trator":mundo.tratores.find(equipa.tractores.get(pessoa.get_instance_id(),null))})
	d["casa"] = {"refeicoes":mundo.casa.vida_domestica.refeicoes,"introduzido":mundo.casa.vida_domestica.introduzido}
	d["familia"] = {"preferencia":mundo.familia.preferencia}
	d["carros"] = []
	for carro: Node3D in mundo.carros: d.carros.append({"posicao":carro.position,"giro":carro.rotation.y})
	if mundo.casa.vida_domestica.ocupado(): d.jogador.posicao = mundo.casa.vida_domestica.retorno
	if mundo.casa.vida_domestica.estado=="banho": d.jogador.roupa = mundo.casa.vida_domestica.roupa_anterior
	d["grupo"] = grupo
	return d
func validar(d: Dictionary) -> bool:
	for chave: String in ["stock","sacola","terreno","jogador","ferramentas","missoes","entregas","grupo","carga_camiao"]:
		if not d.get(chave) is Dictionary: return false
	for chave: String in ["veiculos","maquinas","pessoas","cercas","arvores","drones","historico_servicos"]:
		if not d.get(chave) is Array: return false
	if d.veiculos.size()!=4 or d.maquinas.size()!=15 or d.arvores.size()!=8 or d.drones.size()!=3 or d.pessoas.size()!=mundo.pessoas.size(): return false
	if not d.get("saldo") is int or not is_finite(float(d.get("calendario",NAN))) or float(d.calendario)<0: return false
	if not d.jogador.get("posicao") is Vector3 or not d.jogador.posicao.is_finite(): return false
	if d.terreno.size()>28000 or d.cercas.size()<mundo.cerca.portoes.size() or d.cercas.size()>3000: return false
	for chave: Variant in d.terreno:
		if not chave is Vector2i or not d.terreno[chave] is Dictionary: return false
		var c: Dictionary = d.terreno[chave]
		for campo: String in ["estado","cultura","tempo","humidade","saude","familia"]:
			if not c.has(campo): return false
		if int(c.estado)<0 or int(c.estado)>5 or int(c.cultura)<0 or int(c.cultura)>3: return false
	for campo: String in ["relogio","vendas"]:
		if not d.has(campo): return false
	for campo: String in ["mulher","giro"]:
		if not d.jogador.has(campo): return false
	for campo: String in ["actual","cultura","sementes","madeira"]:
		if not d.ferramentas.has(campo): return false
	for campo: String in ["indice","produzido","historico"]:
		if not d.missoes.has(campo): return false
	for campo: String in ["activas","historico","sequencia","concluidas"]:
		if not d.entregas.has(campo): return false
	for campo: String in ["plano","campos","pendentes","fase","sementes","gasto","carregado","centro","ultimo","membros"]:
		if not d.grupo.has(campo): return false
	if d.has("familia"):
		if not d.familia is Dictionary or not d.familia.get("preferencia") is int or int(d.familia.preferencia) not in range(-1,2): return false
	if d.has("carros"):
		if not d.carros is Array or d.carros.size()!=mundo.carros.size(): return false
		for carro: Variant in d.carros:
			if not carro is Dictionary or not carro.get("posicao") is Vector3 or not carro.posicao.is_finite() or not is_finite(float(carro.get("giro",NAN))): return false
	for chave: String in ["roupa","perfil"]:
		if d.jogador.has(chave) and (not d.jogador[chave] is int or int(d.jogador[chave])<0 or int(d.jogador[chave])>(3 if chave=="roupa" else 4)): return false
	if d.has("casa"):
		if not d.casa is Dictionary or not d.casa.get("refeicoes") is int: return false
		if int(d.casa.refeicoes)<0 or int(d.casa.refeicoes)>4: return false
	if d.has("vitais"):
		if not d.vitais is Dictionary: return false
		for campo: String in ["vida","fome","energia"]:
			if not d.vitais.has(campo) or not is_finite(float(d.vitais[campo])): return false
	var numeros: Dictionary = {}
	for pessoa: Node3D in mundo.pessoas: numeros[pessoa.numero] = true
	var vistos: Dictionary = {}
	for p: Variant in d.pessoas:
		if not p is Dictionary or not numeros.has(p.get("numero")) or vistos.has(p.numero): return false
		vistos[p.numero] = true
		for campo: String in ["posicao","servico","fila","carga","pago","concluido","ultimo"]:
			if not p.has(campo): return false
		if not p.posicao is Vector3 or not p.posicao.is_finite() or not p.servico is Dictionary or not p.fila is Array or not p.carga is Dictionary: return false
		if not p.servico.is_empty() and int(p.servico.get("trator",-1)) not in range(3): return false
	var maquinas_vistas: Array[int] = []
	for item: Dictionary in d.veiculos:
		if not item.get("posicao") is Vector3 or not item.posicao.is_finite() or int(item.get("maquina",-2)) not in range(-1,15): return false
		var indice: int = int(item.maquina)
		if indice>=0:
			if indice in maquinas_vistas: return false
			maquinas_vistas.append(indice)
	for item: Variant in d.maquinas:
		if not item is Dictionary or not item.get("posicao") is Vector3 or not item.posicao.is_finite() or not item.has("giro") or not item.has("sementes") or not item.get("carga") is Dictionary: return false
	for item: Variant in d.cercas:
		if not item is Dictionary or not item.get("posicao") is Vector3 or not item.posicao.is_finite() or not item.has("giro") or not item.has("durabilidade"): return false
	for item: Variant in d.arvores:
		if not item is Dictionary or not item.has("visivel") or not item.has("golpes"): return false
	for posicao: Variant in d.drones:
		if not posicao is Vector3 or not posicao.is_finite(): return false
	for item: Variant in d.grupo.membros:
		if not item is Dictionary or not numeros.has(item.get("numero")) or not item.get("ordem") is Dictionary or int(item.get("trator",-2)) not in range(-1,3): return false
	return true
func hash_dados(dados: PackedByteArray) -> PackedByteArray:
	var contexto: HashingContext = HashingContext.new(); contexto.start(HashingContext.HASH_SHA256); contexto.update(dados); return contexto.finish()
func ler(ficheiro: String) -> Dictionary:
	if not FileAccess.file_exists(ficheiro): return {}
	var f: FileAccess = FileAccess.open(ficheiro,FileAccess.READ)
	if f==null or f.get_length()<44 or f.get_length()>32*1024*1024: return {}
	if f.get_buffer(4).get_string_from_ascii()!="MOZS" or f.get_32()!=VERSAO: return {}
	var tamanho: int = f.get_32()
	if tamanho!=f.get_length()-44: return {}
	var hash_guardado: PackedByteArray = f.get_buffer(32); var dados: PackedByteArray = f.get_buffer(tamanho); f.close()
	if hash_dados(dados)!=hash_guardado: return {}
	var d: Variant = bytes_to_var(dados)
	return d if d is Dictionary and validar(d) else {}
func guardar(notificar: bool = true) -> bool:
	if mundo.casa.vida_domestica.estado in ["dormindo","elevador"]: mundo.avisar("Aguarde o fim do sono ou da deslocação do elevador."); return false
	if mundo.contrato.activo or mundo.missoes.a_finalizar:
		if notificar: mundo.avisar("Termine a negociação antes de guardar.")
		return false
	var d: Dictionary = capturar()
	if not validar(d): mundo.avisar("Não foi possível validar a gravação."); return false
	var bytes: PackedByteArray = var_to_bytes(d)
	var f: FileAccess = FileAccess.open(caminho+".tmp",FileAccess.WRITE)
	if f==null: mundo.avisar("Não foi possível escrever a gravação."); return false
	f.store_buffer("MOZS".to_utf8_buffer()); f.store_32(VERSAO); f.store_32(bytes.size()); f.store_buffer(hash_dados(bytes)); f.store_buffer(bytes); f.flush()
	var erro: Error = f.get_error(); f.close()
	if erro!=OK: mundo.avisar("Falha ao gravar. A gravação anterior foi mantida."); return false
	if FileAccess.file_exists(caminho):
		# Uma gravação principal danificada nunca substitui a cópia boa.
		if not ler(caminho).is_empty():
			if FileAccess.file_exists(caminho+".bak"): DirAccess.remove_absolute(caminho+".bak")
			if DirAccess.rename_absolute(caminho,caminho+".bak")!=OK: return false
		else: DirAccess.remove_absolute(caminho)
	if DirAccess.rename_absolute(caminho+".tmp",caminho)!=OK: mundo.avisar("Falha ao concluir gravação; cópia de recuperação disponível."); return false
	iniciada = true; intervalo = 0; estado = "Guardado · "+mundo.calendario.hora()
	if notificar: mundo.avisar(estado)
	return true
func carregar() -> bool:
	if mundo.contrato.activo: mundo.avisar("Termine a negociação antes de carregar."); return false
	var d: Dictionary = ler(caminho)
	var recuperada: bool = d.is_empty()
	if recuperada: d = ler(caminho+".bak")
	if d.is_empty(): mundo.avisar("Não há gravação válida. O estado actual foi mantido."); return false
	aplicar(d)
	iniciada = true; intervalo = 0; estado = "Cópia recuperada" if recuperada else "Quinta retomada"
	mundo.avisar(estado+" · "+mundo.calendario.hora()); return true
func aplicar(d: Dictionary) -> void:
	mundo.familia.desembarcar()
	mundo.casa.vida_domestica.levantar()
	mundo.casa.vida_domestica.introduzido = true
	mundo.jogador.roupa = clampi(int(d.jogador.get("roupa",0)),0,3)
	mundo.jogador.perfil = clampi(int(d.jogador.get("perfil",0)),0,4)
	mundo.familia.preferencia = clampi(int(d.get("familia",{}).get("preferencia",-1)),-1,1)
	mundo.familia.actividade = "casa"; mundo.familia.pronta = false; mundo.familia.pessoa.position = mundo.casa.to_global(Vector3(5,5.64,3))
	for i: int in range(mini(mundo.carros.size(),d.get("carros",[]).size())):
		mundo.carros[i].position = d.carros[i].posicao; mundo.carros[i].rotation.y = d.carros[i].giro
	mundo.vitais.higiene = clampf(float(d.get("vitais",{}).get("higiene",100)),0,100)
	mundo.casa.vida_domestica.refeicoes = clampi(int(d.get("casa",{}).get("refeicoes",4)),0,4)
	# Primeiro desmontar ocupações e excepções; não pagar nem devolver dinheiro aqui.
	if mundo.drone_actual!=null: mundo.drone_actual.devolver()
	if mundo.trator_actual!=null:
		mundo.trator_actual.rapidez = 0; mundo.trator_actual.sair()
	for pessoa: Node3D in mundo.pessoas:
		mundo.contrato.desembarcar(pessoa); mundo.tarefas.limpar(pessoa); pessoa.grupo = false; pessoa.contratado = false; pessoa.servico = {}
	for maquina: Node3D in mundo.implementos+mundo.carrinhas:
		maquina.soltar()
		if maquina.has_meta("reservado_por"): maquina.remove_meta("reservado_por")
	mundo.tarefas.reservas.clear()
	var vitais: Dictionary = d.get("vitais",{"vida":100,"fome":100,"energia":100})
	for campo: String in ["vida","fome","energia"]: mundo.vitais.set(campo,clampf(float(vitais[campo]),0,100))
	mundo.saldo = d.saldo; mundo.stock = d.stock.duplicate(); mundo.sacola = d.sacola.duplicate(); mundo.relogio = d.relogio
	mundo.calendario.decorrido = d.calendario; mundo.calendario.ultimo_dia = mundo.calendario.dia(); mundo.calendario.velocidade = 1; Engine.time_scale = 1
	mundo.terreno.celulas = d.terreno.duplicate(true); mundo.terreno.pendente = true
	for campo: String in ["indice","produzido","historico"]: mundo.missoes.set(campo,d.missoes[campo])
	mundo.missoes.a_finalizar = false
	mundo.entregas.activas = d.entregas.activas.duplicate(true); mundo.entregas.historico.assign(d.entregas.historico); mundo.entregas.sequencia = d.entregas.sequencia; mundo.entregas.concluidas = d.entregas.concluidas
	mundo.entregas.reputacao.assign(d.entregas.get("reputacao",[0,0,0]))
	mundo.contrato.historico.assign(d.historico_servicos); mundo.economia.vendas = d.vendas
	for i: int in range(4):
		var veiculo: Node3D = (mundo.tratores+[mundo.caminhao])[i]; var v: Dictionary = d.veiculos[i]
		veiculo.position = v.posicao; veiculo.rotation.y = v.giro; veiculo.rapidez = 0; veiculo.velocity = Vector3.ZERO; veiculo.ocupado = false; veiculo.trabalhador = null; veiculo.atribuido = null; veiculo.recuar = false
	for i: int in range(15):
		var maquina: Node3D = (mundo.implementos+mundo.carrinhas)[i]; var m: Dictionary = d.maquinas[i]
		maquina.position = m.posicao; maquina.rotation.y = m.giro; maquina.activo = false
		if maquina.tipo<4: maquina.sementes = m.sementes
		else: maquina.carga = m.carga.duplicate(); maquina.actualizar_carga()
	for i: int in range(3):
		var indice: int = int(d.veiculos[i].maquina)
		if indice>=0:
			var maquina: Node3D = (mundo.implementos+mundo.carrinhas)[indice]; var tractor: CharacterBody3D = mundo.tratores[i]
			maquina.tractor = tractor; tractor.implemento = maquina; tractor.add_collision_exception_with(maquina.corpo)
	mundo.caminhao.carga = d.carga_camiao.duplicate(); mundo.caminhao.actualizar_carga()
	var pessoas_por_numero: Dictionary = {}
	for pessoa: Node3D in mundo.pessoas: pessoas_por_numero[pessoa.numero] = pessoa
	for p: Dictionary in d.pessoas:
		var pessoa: Node3D = pessoas_por_numero[p.numero]; pessoa.position = p.posicao; pessoa.velocity = Vector3.ZERO; pessoa.servico = p.servico.duplicate(true); pessoa.fila.assign(p.fila); pessoa.carga = p.carga.duplicate(); pessoa.pago = p.pago; pessoa.concluido = p.concluido; pessoa.ultimo_servico = p.ultimo
		pessoa.contratado = not pessoa.servico.is_empty(); pessoa.repor_pose(); pessoa.percurso.clear(); pessoa.destino_actual = Vector3.INF; pessoa.em_conversa = false
		if pessoa.contratado:
			mundo.tratores[int(pessoa.servico.trator)].atribuido = pessoa
			for ordem: Dictionary in pessoa.fila:
				if ordem.has("celula"): mundo.tarefas.reservas[ordem.celula] = pessoa.get_instance_id()
	var equipa: Node = mundo.equipa_grupo; var g: Dictionary = d.grupo
	equipa.plano = g.plano.duplicate(true); equipa.campos.assign(g.campos); equipa.pendentes.assign(g.pendentes); equipa.fase = g.fase; equipa.sementes = g.sementes; equipa.gasto = g.gasto; equipa.carregado = g.carregado; equipa.centro = g.centro; equipa.ultimo = g.ultimo; equipa.trabalhadores.clear(); equipa.ordens.clear(); equipa.tractores.clear()
	for membro: Dictionary in g.membros:
		var pessoa: Node3D = pessoas_por_numero[membro.numero]; pessoa.grupo = true; equipa.trabalhadores.append(pessoa); equipa.ordens[pessoa.get_instance_id()] = membro.ordem.duplicate(true)
		if int(membro.trator)>=0:
			var tractor: CharacterBody3D = mundo.tratores[int(membro.trator)]; equipa.tractores[pessoa.get_instance_id()] = tractor; tractor.atribuido = pessoa
	if not equipa.plano.is_empty():
		for chave: Vector2i in equipa.campos: mundo.tarefas.reservas[chave] = equipa.get_instance_id()
	while mundo.cerca.secoes.size()>d.cercas.size(): mundo.cerca.secoes.pop_back().free()
	for i: int in range(d.cercas.size()):
		var c: Dictionary = d.cercas[i]
		if i>=mundo.cerca.secoes.size(): mundo.cerca.seccao(c.posicao,false)
		var parte: Node3D = mundo.cerca.secoes[i]; parte.position = c.posicao; parte.rotation.y = c.giro; parte.set_meta("durabilidade",c.durabilidade)
	for i: int in range(8):
		var arvore: Node3D = mundo.ferramentas.arvores[i]; arvore.visible = d.arvores[i].visivel; arvore.set_meta("golpes",d.arvores[i].golpes)
		for forma: Node in arvore.find_children("*","CollisionShape3D",true,false): forma.set_deferred("disabled",not arvore.visible)
	for i: int in range(3): mundo.drones[i].position = d.drones[i]; mundo.drones[i].voando = false; mundo.drones[i].irrigando = false
	mundo.jogador.position = d.jogador.posicao; mundo.jogador.velocity = Vector3.ZERO; mundo.jogador.bloqueado = false; mundo.jogador.visual.rotation.y = d.jogador.giro; mundo.camera.livre = false; mundo.camera.enquadramento = false; mundo.camera.alvo = mundo.jogador
	for campo: String in ["cultura","sementes","madeira"]: mundo.ferramentas.set(campo,d.ferramentas[campo])
	iniciada = true
	mundo.jogador.mulher = bool(d.jogador.mulher); mundo.jogador.criar_avatar()
	mundo.hud.escolher(bool(d.jogador.mulher)); mundo.jogador.visual.rotation.y = d.jogador.giro; mundo.jogador.repor_pose(); mundo.ferramentas.seleccionar(int(d.ferramentas.actual))
	mundo.hud.aberto = false; mundo.hud.detalhes.hide(); mundo.hud.kit_aberto = false; mundo.hud.kit.hide()
	mundo.armazem.actualizar(1); mundo.guia_entrega.intervalo = 0
