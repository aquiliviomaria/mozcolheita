extends SceneTree
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,descricao: String) -> void:
	if valor: print("OK · ",descricao)
	else: falhas += 1; push_error(descricao)
func executar() -> void:
	var mundo: Node3D = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false)
	var pequena: Dictionary = mundo.entregas.oferta(1,0,0); var regular: Dictionary = mundo.entregas.oferta(1,0,1); var grande: Dictionary = mundo.entregas.oferta(1,0,2); var urgente: Dictionary = mundo.entregas.oferta(1,2,1)
	exigir(int(pequena.quantidade)<int(regular.quantidade) and int(grande.quantidade)>int(regular.quantidade),"Tamanhos de encomenda criam quantidades diferentes")
	exigir(float(grande.prazo)>float(regular.prazo) and int(grande.trabalhadores)>int(pequena.trabalhadores),"Grande entrega dá mais prazo e recomenda equipa maior")
	exigir(float(urgente.prazo)<float(regular.prazo) and int(urgente.recompensa)>int(regular.recompensa) and int(urgente.penalidade)>int(regular.penalidade),"Urgência troca prazo por recompensa e risco")
	for perfil: int in range(3):
		for urgencia: int in range(3):
			var p: Dictionary = mundo.entregas.oferta(2,urgencia,perfil)
			exigir(float(p.prazo)>=2400 and int(p.recompensa)>int(p.estimativa),"Oferta tem tempo para crescer e margem de contratação: %d/%d" % [perfil,urgencia])
	exigir(mundo.entregas.aceitar(1,0,0),"Aceitar entrega pequena")
	var pedido: Dictionary = mundo.entregas.activas[1]; var quantidade: int = pedido.quantidade
	var cotacao: Dictionary = mundo.equipa_grupo.orcamento(1,int(pedido.trabalhadores),0)
	exigir(int(cotacao.total)==int(pedido.estimativa),"Estimativa corresponde ao orçamento normal recomendado")
	var preco_fixo: int = pedido.preco; var antes: int = mundo.saldo
	mundo.entregas.entregar({1:quantidade-1},1)
	exigir(mundo.entregas.reputacao[1]==0,"Entrega parcial não aumenta reputação")
	mundo.entregas.entregar({1:1},1)
	exigir(mundo.entregas.reputacao[1]==1 and mundo.saldo==antes+quantidade*preco_fixo+int(pedido.bonus),"Sucesso paga valor fixado e reputação uma vez")
	mundo.entregas.entregar({1:quantidade},1); exigir(mundo.entregas.reputacao[1]==1,"Repetir entrega concluída não duplica reputação")
	mundo.entregas.reputacao[1] = 80
	var fiel: Dictionary = mundo.entregas.oferta(1,0,1)
	exigir(int(fiel.preco)>int(regular.preco),"Reputação melhora preços de futuras encomendas")
	mundo.entregas.aceitar(1,0,1); pedido = mundo.entregas.activas[1]; preco_fixo = pedido.preco
	mundo.entregas.reputacao[1] = 0; mundo.relogio += 500
	exigir(int(pedido.preco)==preco_fixo,"Preço de contrato aceite não muda com reputação nem mercado")
	mundo.entregas.reputacao[1] = 10; mundo.calendario.decorrido = float(pedido.limite); mundo.entregas.verificar_prazos()
	exigir(mundo.entregas.reputacao[1]==8,"Quebra de contrato reduz reputação")
	mundo.entregas.verificar_prazos(); exigir(mundo.entregas.reputacao[1]==8,"Sanção de reputação também é única")
	var d: Dictionary = mundo.partida.capturar(); mundo.entregas.reputacao[1] = 0; mundo.partida.aplicar(d)
	exigir(mundo.entregas.reputacao[1]==8,"Reputação faz parte da gravação")
	mundo.hud.alternar(); mundo.hud.perfil_entrega.select(2); mundo.hud._process(0.3)
	exigir(mundo.hud.descricoes_entregas[0].text.contains("equipa") and mundo.hud.descricoes_entregas[0].text.contains("margem"),"Painel mostra perfil, custo, margem, prazo e multa")
	print("CONTRATOS · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
