extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,texto: String) -> void:
	if valor: print("OK · ",texto)
	else: falhas += 1; push_error(texto)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	var normal: Dictionary = mundo.entregas.oferta(1,0); var urgente: Dictionary = mundo.entregas.oferta(1,2)
	exigir(float(urgente.prazo)<float(normal.prazo) and int(urgente.recompensa)>int(normal.recompensa) and int(urgente.penalidade)>int(normal.penalidade),"Urgência aumenta prémio/multa e reduz prazo")
	exigir(float(urgente.prazo)>mundo.terreno.DURACAO,"Prazo urgente permite três dias de crescimento")
	mundo.entregas.aceitar(1); var pedido: Dictionary = mundo.entregas.activas[1]
	exigir(mundo.entregas.entregar({1:30},1)==30 and not bool(pedido.concluida),"Entrega parcial contabilizada")
	mundo.calendario.decorrido = float(pedido.limite)-float(pedido.prazo)*0.19; mundo.entregas.verificar_prazos()
	exigir(bool(pedido.avisado) and mundo.aviso.begins_with("PRAZO A TERMINAR"),"Aviso nos últimos vinte por cento")
	mundo.entregas.entregar({1:69},1); var antes: int = mundo.saldo
	mundo.calendario.decorrido = float(pedido.limite); mundo.entregas.verificar_prazos()
	exigir(bool(pedido.falhou) and mundo.saldo==antes-int(pedido.penalidade),"Quantidade incompleta no prazo causa multa exacta")
	var tardia: Dictionary = {1:1}; exigir(mundo.entregas.entregar(tardia,1)==0 and int(tardia[1])==1,"Entrega tardia conserva produtos e não conclui missão")
	antes = mundo.saldo; mundo.entregas.verificar_prazos(); exigir(mundo.saldo==antes,"Multa não se repete")
	exigir(mundo.entregas.historico.size()==1 and str(mundo.entregas.historico[0].estado).begins_with("Falhou"),"Falha registada no histórico")
	mundo.entregas.aceitar(1,2); pedido = mundo.entregas.activas[1]; antes = mundo.saldo
	mundo.entregas.entregar({1:100},1)
	exigir(bool(pedido.concluida) and mundo.saldo==antes+100*int(pedido.preco)+int(pedido.bonus),"Sucesso recebe pagamento integral e bónus")
	antes = mundo.saldo; mundo.entregas.verificar_prazos(); mundo.entregas.entregar({1:100},1); exigir(mundo.saldo==antes,"Pagamento/bónus únicos após sucesso")
	mundo.entregas.aceitar(2); pedido = mundo.entregas.activas[2]
	var proposta: Dictionary = mundo.equipa_grupo.orcamento(2,2,0); antes = mundo.saldo
	exigir(mundo.equipa_grupo.confirmar(proposta),"Equipa herda prazo da encomenda")
	var gasto: int = mundo.equipa_grupo.gasto
	mundo.calendario.decorrido = float(pedido.limite); mundo.entregas.verificar_prazos()
	exigir(mundo.equipa_grupo.plano.is_empty() and mundo.saldo==antes-gasto-int(pedido.penalidade),"Falha encerra grupo, devolve reserva e aplica só uma multa")
	var pessoa: Node3D = mundo.pessoas[0]; pessoa.position = Vector3(0,0,0); pessoa.position.y = mundo.altura(pessoa.position)+0.1
	var servico: Dictionary = mundo.assinar_teste(pessoa,2,1)
	exigir(not pessoa.servico.is_empty() and servico.has("penalidade"),"Serviço individual tem prazo e multa no orçamento")
	var total: int = int(pessoa.servico.total); var multa: int = int(pessoa.servico.penalidade); antes = mundo.saldo
	mundo.calendario.decorrido = float(pessoa.servico.limite); mundo.contrato.verificar_prazos()
	exigir(pessoa.servico.is_empty() and mundo.saldo==antes+total-multa,"Serviço expirado devolve trabalho não feito e desconta multa")
	exigir(str(mundo.contrato.historico.back().estado)=="Falhou","Serviço falhado registado")
	mundo.entregas.aceitar(0,2); pedido = mundo.entregas.activas[0]; mundo.hud.alternar()
	mundo.calendario.saltar(3); antes = mundo.saldo; mundo.calendario.saltar(1)
	exigir(bool(pedido.falhou) and mundo.saldo==antes-int(pedido.penalidade),"Saltar dias verifica vencimento imediatamente, mesmo no painel")
	mundo.hud._process(0.3); exigir(mundo.hud.historico_label.text.contains("Falhou"),"Histórico visível no menu H")
	mundo.calendario.alternar_velocidade(); exigir(Engine.time_scale==12 and mundo.calendario.velocidade==12,"Aceleração aplica-se a toda a simulação")
	mundo.calendario.alternar_velocidade(); exigir(Engine.time_scale==1,"Regresso ao tempo normal")
	print("PRAZOS · ","PASSOU" if falhas==0 else "FALHOU"," · falhas: ",falhas); quit(0 if falhas==0 else 1)
