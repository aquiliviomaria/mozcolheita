extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func esperar(f: Node3D) -> void:
	var andou: bool = false; var levou_caixa: bool = false
	for i: int in range(1500):
		await physics_frame
		andou = andou or f.pessoa.position.distance_to(f.assento)>1
		levou_caixa = levou_caixa or (is_instance_valid(f.caixa) and f.caixa.visible)
		if not f.ocupado(): break
	print("OPERAÇÃO · ",f.fase," · duração ",f.duracao," · posição ",f.pessoa.position)
	exigir(not f.ocupado() and andou and levou_caixa,"Funcionário caminha, transporta caixa e termina a operação")
	mundo.central_logistica.fechar()
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://teste-funcionarios.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.jogador.set_physics_process(false); mundo.familia.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	for v: Node3D in mundo.comunidade.trafego: v.set_physics_process(false)
	mundo.armazem.set_physics_process(false)
	for f: Node3D in mundo.fabricas: f.set_process(false)
	var w: Node3D = mundo.armazem; var a: Node3D = w.funcionario; var camiao: Node3D = mundo.caminhao; camiao.set_physics_process(false)
	camiao.position = w.CENTRO; camiao.rotation.y = 0; mundo.jogador.position = w.ENTREGA; mundo.trator_actual = camiao; mundo.stock = {0:100,1:50}; camiao.carga.clear()
	Engine.time_scale = 4
	for i: int in range(3): await physics_frame
	exigir(a.fase=="sentado" and a.pessoa.visual.position.y<0,"Funcionário permanente espera sentado dentro do armazém")
	exigir(mundo.pessoas.size()==46,"Funcionários permanentes não entram nos contratos de lavoura")
	mundo.central_logistica.abrir_carga(camiao); mundo.central_logistica.produto.select(0); mundo.central_logistica.quantidade.value = 30; mundo.central_logistica.confirmar_carga()
	exigir(a.ocupado() and mundo.stock[0]==100 and camiao.total()==0 and not mundo.central_logistica.aberto,"Pedido começa trabalho real sem transferir antecipadamente")
	exigir(not w.encomendar_carga(1,10,camiao),"Pedido duplicado recusado enquanto funcionário trabalha")
	await esperar(a)
	exigir(camiao.carga=={0:30} and mundo.stock[0]==70,"Carregamento transfere quantidade exacta uma vez")
	for i: int in range(900):
		await physics_frame
		if a.fase=="sentado": break
	exigir(a.fase=="sentado" and a.pessoa.position.distance_to(a.assento)<0.1,"Após carregar regressa ao balcão e senta no mesmo lugar")
	exigir(w.encomendar_descarga(camiao),"Funcionário aceita descarregar camião")
	await esperar(a)
	exigir(camiao.carga.is_empty() and mundo.stock[0]==100,"Descarrega e guarda toda a mercadoria no stock")
	a.cancelar(false,true); exigir(w.encomendar_carga(1,20,camiao),"Novo carregamento aceite")
	camiao.position.x += 4; await physics_frame; await physics_frame
	exigir(not a.ocupado() and camiao.total()==0 and mundo.stock[1]==50 and not camiao.has_meta("operador_doca"),"Sair antes de terminar cancela sem perder ou duplicar produtos")
	a.cancelar(false,true); camiao.position = w.CENTRO
	var save: Dictionary = mundo.partida.capturar(); w.encomendar_carga(0,15,camiao); mundo.partida.aplicar(save)
	exigir(not a.ocupado() and a.fase=="sentado" and not camiao.has_meta("operador_doca") and mundo.stock[0]==100,"Retomar gravação cancela operação pendente sem a cobrar ou executar depois")
	mundo.central_logistica.fechar(); mundo.trator_actual = null
	var f: Node3D = mundo.fabricas[0]; camiao.position = f.position; camiao.carga = {0:40,1:7}; camiao.rapidez = 0; mundo.jogador.position = f.position+Vector3(0,0,-42)
	var saldo: int = mundo.saldo
	exigir(f.encomendar_descarga(camiao),"Funcionário da fábrica recebe o transporte na garagem")
	exigir(mundo.saldo==saldo and camiao.carga[0]==40,"Venda só acontece depois da descarga")
	await esperar(f.funcionario)
	exigir(mundo.saldo>saldo and camiao.carga=={1:7},"Fábrica paga e retira apenas os produtos que aceita")
	var novo_saldo: int = mundo.saldo
	exigir(not f.encomendar_descarga(camiao) and mundo.saldo==novo_saldo,"Não repete pagamento da mesma entrega")
	for site: Node3D in mundo.fabricas: exigir(site.funcionario!=null,"Cada fábrica tem recepcionista para descarregar")
	Engine.time_scale = 1; mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); print("FUNCIONÁRIOS · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(falhas)
