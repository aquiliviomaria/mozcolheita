extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,texto: String) -> void:
	if not valor: falhas += 1; push_error(texto)
	else: print("OK · ",texto)
func tecla(codigo: int,pressionada: bool) -> void:
	var evento: InputEventKey = InputEventKey.new(); evento.physical_keycode = codigo; evento.keycode = codigo; evento.pressed = pressionada; Input.parse_input_event(evento)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	exigir(Vector2(mundo.jogador.position.x,mundo.jogador.position.z).distance_to(Vector2(-8,-29))<0.1,"Início à frente da casa")
	exigir(mundo.jogador.bracos.size()==2 and mundo.jogador.maos.size()==2,"Rig masculino completo")
	var posicao_braco: Vector3 = mundo.jogador.bracos[1].position
	mundo.hud.escolher(true)
	exigir(mundo.jogador.mulher and mundo.jogador.bracos[1].position.is_equal_approx(posicao_braco),"Agricultora seleccionável com rig partilhado")
	for acao: String in ["idle","walk","run","planting","watering","harvesting"]:
		mundo.jogador.animacao(acao); mundo.jogador.animar(0.1,7 if acao=="run" else 3 if acao=="walk" else 0)
	mundo.sacola = {0:3}; mundo.jogador.animar(0.1,0); exigir(mundo.jogador.cesto.visible,"Animação e cesto de transporte")
	mundo.sacola.clear(); mundo.jogador.repor_pose(); exigir(mundo.jogador.bracos[1].rotation.z==0,"Repor pose limpa animação de trabalho")
	var chave: Vector2i = Vector2i(7,3)
	mundo.terreno.trabalhar(chave,"lavrar"); mundo.terreno.trabalhar(chave,"semear")
	mundo.calendario.saltar(3); exigir(int(mundo.terreno.celulas[chave].estado)==2,"Semente seca não cresce ao saltar dias")
	mundo.terreno.trabalhar(chave,"regar"); mundo.terreno.avancar(1200)
	exigir(int(mundo.terreno.celulas[chave].estado)!=5,"Dois dias não completam crescimento")
	mundo.terreno.avancar(600); exigir(int(mundo.terreno.celulas[chave].estado)==5,"Três dias completos amadurecem cultura")
	mundo.camera.alternar_livre(); var inicio: Vector3 = mundo.jogador.position
	tecla(KEY_W,true)
	for i: int in range(5): await physics_frame
	tecla(KEY_W,false); exigir(mundo.jogador.position.is_equal_approx(inicio),"Câmara livre bloqueia controlador do jogador")
	mundo.camera.alternar_livre()
	exigir(mundo.comunidade.casas.size()>=45 and mundo.comunidade.edificios.size()>=10,"Bairros distribuídos e pelo menos dez prédios")
	exigir(int(mundo.comunidade.edificios[2].get_meta("pisos"))==40,"Prédio de quarenta pisos")
	exigir(mundo.comunidade.trafego.size()>=20 and mundo.comunidade.animais.size()==24,"Tráfego e três criações com animais")
	exigir(absf(mundo.altura(Vector3(250,0,0)))<0.01,"Terreno da cidade nivelado")
	var compativel: Dictionary = {0:3,1:7}; mundo.economia.vender(compativel,0)
	exigir(not compativel.has(0) and int(compativel.get(1,0))==7,"Empresa aceita apenas produtos próprios")
	mundo.caminhao.carregar({1:550}); exigir(mundo.caminhao.total()==500,"Capacidade real do camião")
	mundo.caminhao.carga.clear(); mundo.caminhao.actualizar_carga()
	exigir(mundo.entregas.aceitar(1) and not mundo.entregas.aceitar(1),"Aceitar encomenda sem duplicar contrato")
	mundo.caminhao.carregar({1:100}); mundo.caminhao.position = mundo.fabricas[1].position+Vector3(0,0,-62); mundo.caminhao.position.y = mundo.altura(mundo.caminhao.position)+0.1; mundo.caminhao.rotation.y = PI
	await physics_frame; exigir(mundo.caminhao.entrar(),"Entrar e conduzir camião")
	mundo.hud.escolher(false)
	exigir(mundo.jogador.visual.get_parent()==mundo.caminhao and mundo.jogador.visual.visible,"Condutor visível na cabine")
	Engine.time_scale = 8; tecla(KEY_W,true)
	for i: int in range(240):
		await physics_frame
		if mundo.fabricas[1].to_local(mundo.caminhao.position).z > -5: break
	tecla(KEY_W,false)
	for i: int in range(30): await physics_frame
	print("CHEGADA · ",mundo.fabricas[1].to_local(mundo.caminhao.position)," · carga ",mundo.caminhao.carga)
	exigir(bool(mundo.entregas.activas[1].concluida) and mundo.caminhao.total()==0,"Entrega física ao parar na garagem da fábrica")
	var saldo: int = mundo.saldo; mundo.entregas.entregar({1:100},1); exigir(mundo.saldo==saldo,"Encomenda concluída não paga duas vezes")
	mundo.caminhao.rapidez = 0; mundo.caminhao.sair(); mundo.caminhao.position = Vector3(49,mundo.altura(Vector3(49,0,18))+0.1,18)
	# Dez trabalhadores a pé: valida execução automática quando todos os tractores estão indisponíveis.
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	for veiculo: CharacterBody3D in mundo.comunidade.trafego: veiculo.set_physics_process(false)
	for tractor: CharacterBody3D in mundo.tratores: tractor.ocupado = true
	exigir(mundo.entregas.aceitar(1),"Nova encomenda após conclusão")
	var normal: Dictionary = mundo.equipa_grupo.orcamento(1,10,0); var dificil: Dictionary = mundo.equipa_grupo.orcamento(1,10,2)
	exigir(not normal.is_empty() and int(dificil.total)>int(normal.total),"Orçamento variável para dez pessoas")
	var antes: int = mundo.saldo; exigir(mundo.equipa_grupo.confirmar(normal),"Grupo confirmado com reserva única")
	exigir(mundo.equipa_grupo.trabalhadores.size()==10 and mundo.saldo==antes-int(normal.total),"Dez trabalhadores contratados de uma vez")
	for i: int in range(10):
		var pessoa: Node3D = mundo.equipa_grupo.trabalhadores[i]; pessoa.position = Vector3(-3+i*3,mundo.altura(Vector3(-3+i*3,0,-15))+0.1,-15); pessoa.set_physics_process(true)
	var saltou: bool = false
	for i: int in range(6000):
		await physics_frame
		if mundo.equipa_grupo.fase==3 and not saltou: mundo.calendario.saltar(3); saltou = true
		if mundo.equipa_grupo.plano.is_empty(): break
		if i%2000==0: print("PROGRESSO GRUPO ",mundo.equipa_grupo.resumo()," pendentes ",mundo.equipa_grupo.pendentes.size())
		if i%2000==0 and mundo.equipa_grupo.fase==5:
			for pessoa: Node3D in mundo.equipa_grupo.trabalhadores:
				if not pessoa.carga.is_empty(): print("CARGA PENDENTE ",pessoa.nome," ",pessoa.position," carga ",pessoa.carga," destino ",pessoa.destino_actual," percurso ",pessoa.percurso," camião ",mundo.caminhao.position)
	exigir(saltou and mundo.equipa_grupo.plano.is_empty() and int(mundo.caminhao.carga.get(1,0))>=100,"Grupo prepara, semeia, rega, espera, colhe e carrega sem intervenção nas tarefas")
	if not mundo.equipa_grupo.plano.is_empty():
		for pessoa: Node3D in mundo.equipa_grupo.trabalhadores: print("PRESO ",pessoa.nome," ",pessoa.estado," ",pessoa.position," ",mundo.equipa_grupo.ordens[pessoa.get_instance_id()])
	mundo.equipa_grupo.terminar("Fim da validação")
	exigir(mundo.saldo>=antes-int(normal.total) and mundo.saldo<=antes,"Pagamento respeita máximo aprovado")
	saldo = mundo.saldo; mundo.equipa_grupo.terminar("Repetido"); exigir(mundo.saldo==saldo,"Cancelamento repetido não duplica reembolso")
	print("COMUNIDADE · ","PASSOU" if falhas==0 else "FALHOU", " · falhas: ",falhas)
	quit(0 if falhas==0 else 1)
