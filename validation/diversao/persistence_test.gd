extends SceneTree
var mundo: Node3D
var falhas: int = 0
const FICHEIRO: String = "user://teste-diversao-isolado.mozsave"
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,descricao: String) -> void:
	if valor: print("OK · ",descricao)
	else: falhas += 1; push_error(descricao)
func executar() -> void:
	for sufixo: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(FICHEIRO+sufixo): DirAccess.remove_absolute(FICHEIRO+sufixo)
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(true); mundo.calendario.set_process(false); mundo.partida.caminho = FICHEIRO
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	for carro: Node3D in mundo.comunidade.trafego: carro.set_physics_process(false)
	await physics_frame
	mundo.saldo = 456789; mundo.stock = {0:31,1:22}; mundo.sacola = {3:7}; mundo.caminhao.carga = {2:44}; mundo.carrinhas[1].carga = {0:13}
	var chave: Vector2i = Vector2i(8,5)
	mundo.terreno.trabalhar(chave,"lavrar"); mundo.terreno.trabalhar(chave,"semear"); mundo.terreno.trabalhar(chave,"regar"); mundo.terreno.avancar(700)
	mundo.calendario.decorrido = 975; mundo.ferramentas.sementes = 87; mundo.implementos[1].sementes = 123
	mundo.cerca.seccao(Vector3(40,0,-12),false); mundo.cerca.secoes.back().set_meta("durabilidade",65)
	mundo.ferramentas.arvores[0].hide(); mundo.ferramentas.arvores[0].set_meta("golpes",3)
	for tractor: Node3D in mundo.tratores: tractor.ocupado = true
	mundo.entregas.aceitar(1); var proposta: Dictionary = mundo.equipa_grupo.orcamento(1,3)
	exigir(mundo.equipa_grupo.confirmar(proposta),"Equipa activa antes da gravação")
	for tractor: Node3D in mundo.tratores: tractor.ocupado = false
	var funcionario: Node3D
	for pessoa: Node3D in mundo.pessoas:
		if not pessoa.grupo: funcionario = pessoa; break
	funcionario.position = mundo.jogador.position+Vector3(0.6,0,0)
	mundo.contrato.iniciar(funcionario)
	var servico: Dictionary = mundo.contrato.orcamento(7,4,0,0)
	exigir(mundo.contrato.confirmar(servico),"Contrato individual com pagamento confirmado")
	mundo.contrato.terminar(true)
	funcionario.fila[0]["maquina"] = mundo.implementos[0]
	var numero_funcionario: int = funcionario.numero
	var id_grupo_antigo: int = mundo.equipa_grupo.trabalhadores[0].get_instance_id()
	var saldo: int = mundo.saldo; var total_cercas: int = mundo.cerca.secoes.size()
	exigir(mundo.partida.guardar(false),"Gravar quinta com equipa, culturas e carga")
	mundo.queue_free(); await process_frame
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.calendario.set_process(false); mundo.partida.caminho = FICHEIRO
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	for carro: Node3D in mundo.comunidade.trafego: carro.set_physics_process(false)
	mundo.saldo = 1; mundo.stock.clear(); mundo.sacola.clear(); mundo.terreno.celulas.clear(); mundo.caminhao.carga.clear(); mundo.equipa_grupo.terminar("Teste")
	exigir(mundo.partida.carregar(),"Retomar gravação sem cobrar ou devolver contratos")
	exigir(mundo.saldo==saldo and mundo.stock=={0:31,1:22} and mundo.sacola=={3:7},"Dinheiro e produtos conservados")
	exigir(is_equal_approx(mundo.terreno.celulas[chave].tempo,700) and mundo.calendario.decorrido==975,"Crescimento e prazos não avançam fora do jogo")
	exigir(mundo.jogador.mulher and mundo.ferramentas.sementes==87 and mundo.implementos[1].sementes==123,"Personagem e sementes conservadas")
	exigir(mundo.caminhao.carga=={2:44} and mundo.carrinhas[1].carga=={0:13},"Carga do camião e reboques conservada")
	exigir(mundo.cerca.secoes.size()==total_cercas and int(mundo.cerca.secoes.back().get_meta("durabilidade"))==65 and not mundo.ferramentas.arvores[0].visible,"Cercas construídas e árvores cortadas conservadas")
	exigir(mundo.equipa_grupo.trabalhadores.size()==3 and mundo.equipa_grupo.trabalhadores[0].get_instance_id()!=id_grupo_antigo and mundo.tarefas.reservas.size()==int(proposta.parcelas),"Equipa e reservas reconstruídas com identificadores novos")
	var restaurado: Node3D
	for pessoa: Node3D in mundo.pessoas:
		if pessoa.numero==numero_funcionario: restaurado = pessoa
	exigir(restaurado.contratado and not restaurado.servico.is_empty() and mundo.tratores[0].atribuido==restaurado and not restaurado.fila[0].has("maquina"),"Contrato individual, tractor e fila retomados sem referências antigas")
	exigir(mundo.partida.guardar(false),"Segunda gravação mantém cópia anterior")
	var f: FileAccess = FileAccess.open(FICHEIRO,FileAccess.WRITE); f.store_string("danificado"); f.close()
	mundo.saldo = 3
	exigir(mundo.partida.carregar() and mundo.saldo==saldo,"Recupera automaticamente a cópia boa quando o principal está danificado")
	mundo.equipa_grupo.terminar("Teste terminado")
	exigir(mundo.partida.guardar(false),"Grava novamente sem destruir a cópia de recuperação")
	var d: Dictionary = mundo.partida.ler(FICHEIRO); d.erase("grupo")
	exigir(not mundo.partida.validar(d),"Rejeita estado incompleto antes de alterar o mundo")
	mundo.contrato.activo = true; exigir(not mundo.partida.guardar(false),"Não grava a meio do aperto de mão"); mundo.contrato.activo = false
	mundo.calendario.amanhecer.stop(); mundo.contrato.som.stop()
	await create_timer(0.1).timeout
	for sufixo: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(FICHEIRO+sufixo): DirAccess.remove_absolute(FICHEIRO+sufixo)
	print("GRAVAÇÃO · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
