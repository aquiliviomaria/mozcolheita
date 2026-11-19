extends Node
## Encomendas com prazo, recompensa fixada e quebra de contrato debitada uma só vez.
const EMPRESAS: Array[String] = ["Tomates do Zambeze","Moageira Nhamatanda","Hortícolas Maputo"]
const CULTURAS: Array[int] = [0,1,2]
const QUANTIDADES: Array[int] = [120,100,80]
const DIAS: Array[int] = [8,6,4]
var mundo: Node3D
var activas: Dictionary = {}
var historico: Array[Dictionary] = []
var sequencia: int = 0
var concluidas: int = 0
func oferta(fabrica: int,urgencia: int = 0) -> Dictionary:
	var nivel: int = clampi(urgencia,0,2); var cultura: int = CULTURAS[fabrica]; var quantidade: int = QUANTIDADES[fabrica]
	var preco: int = ceili(mundo.economia.preco(fabrica,cultura)*(1.0+nivel*0.3))
	var bonus: int = quantidade*(5+nivel*3); var recompensa: int = quantidade*preco+bonus
	return {"cultura":cultura,"quantidade":quantidade,"preco":preco,"bonus":bonus,"recompensa":recompensa,"prazo":DIAS[nivel]*preload("res://scripts/calendar.gd").SEGUNDOS_DIA,"penalidade":ceili(recompensa*(0.15+nivel*0.12)),"urgencia":nivel}
func aceitar(fabrica: int,urgencia: int = 0) -> bool:
	if fabrica<0 or fabrica>=3: return false
	verificar_prazos()
	if activas.has(fabrica) and not bool(activas[fabrica].concluida) and not bool(activas[fabrica].falhou): return false
	sequencia += 1
	var pedido: Dictionary = oferta(fabrica,urgencia)
	pedido.merge({"id":sequencia,"fabrica":fabrica,"entregue":0,"concluida":false,"falhou":false,"avisado":false,"limite":mundo.calendario.decorrido+float(pedido.prazo)})
	activas[fabrica] = pedido
	mundo.avisar("Encomenda aceite: %s · prazo %s · multa %d MT" % [EMPRESAS[fabrica],mundo.calendario.restante(pedido.prazo),pedido.penalidade]); return true
func entregar(carga: Dictionary,fabrica: int) -> int:
	verificar_prazos()
	if not activas.has(fabrica) or bool(activas[fabrica].concluida) or bool(activas[fabrica].falhou): return 0
	var pedido: Dictionary = activas[fabrica]; var cultura: int = int(pedido.cultura)
	var unidades: int = mini(int(carga.get(cultura,0)),int(pedido.quantidade)-int(pedido.entregue))
	if unidades<=0: return 0
	pedido.entregue = int(pedido.entregue)+unidades; carga[cultura] = int(carga[cultura])-unidades
	if int(carga[cultura])==0: carga.erase(cultura)
	var pagamento: int = unidades*int(pedido.preco)
	if int(pedido.entregue)==int(pedido.quantidade):
		pedido.concluida = true; pagamento += int(pedido.bonus); concluidas += 1
		historico.append({"id":pedido.id,"empresa":EMPRESAS[fabrica],"estado":"Sucesso","entregue":pedido.entregue,"quantidade":pedido.quantidade,"penalidade":0,"dia":mundo.calendario.dia()})
	mundo.saldo += pagamento; mundo.avisar("%s · entrega %d/%d · +%d MT" % [EMPRESAS[fabrica],pedido.entregue,pedido.quantidade,pagamento]); return unidades
func verificar_prazos() -> void:
	for fabrica: int in activas:
		var p: Dictionary = activas[fabrica]
		if bool(p.concluida) or bool(p.falhou): continue
		var restante: float = float(p.limite)-mundo.calendario.decorrido
		if restante<=0:
			p.falhou = true; mundo.saldo -= int(p.penalidade)
			historico.append({"id":p.id,"empresa":EMPRESAS[fabrica],"estado":"Falhou · quebra de contrato","entregue":p.entregue,"quantidade":p.quantidade,"penalidade":p.penalidade,"dia":mundo.calendario.dia()})
			if mundo.equipa_grupo!=null and not mundo.equipa_grupo.plano.is_empty() and int(mundo.equipa_grupo.plano.id)==int(p.id): mundo.equipa_grupo.terminar("Encomenda vencida · equipa encerrada")
			mundo.avisar("QUEBRA DE CONTRATO · %s · -%d MT" % [EMPRESAS[fabrica],p.penalidade])
		elif restante<=float(p.prazo)*0.2 and not bool(p.avisado):
			p.avisado = true; mundo.avisar("PRAZO A TERMINAR · %s · faltam %s" % [EMPRESAS[fabrica],mundo.calendario.restante(restante)])
func _process(_delta: float) -> void:
	if mundo.hud!=null and not mundo.pausado(): verificar_prazos()
func resumo() -> String:
	var texto: String = ""
	for fabrica: int in activas:
		var p: Dictionary = activas[fabrica]
		if not bool(p.concluida) and not bool(p.falhou): texto += "%s %d/%d · %s%s\n" % [preload("res://scripts/crop.gd").NOMES[int(p.cultura)],p.entregue,p.quantidade,"! " if bool(p.avisado) else "",mundo.calendario.restante(float(p.limite)-mundo.calendario.decorrido)]
	return texto.strip_edges() if not texto.is_empty() else "H → Entregas · empresas e encomendas"
func descricao(fabrica: int,urgencia: int = 0) -> String:
	if activas.has(fabrica):
		var p: Dictionary = activas[fabrica]
		if not bool(p.concluida) and not bool(p.falhou): return "%s · %d/%d · faltam %s\n%d MT/un. + %d MT bónus · multa por atraso: %d MT" % [EMPRESAS[fabrica],p.entregue,p.quantidade,mundo.calendario.restante(float(p.limite)-mundo.calendario.decorrido),p.preco,p.bonus,p.penalidade]
	var p: Dictionary = oferta(fabrica,urgencia)
	return "%s · %d %s · prazo %s\nRecebe %d MT · penalização por atraso: %d MT" % [EMPRESAS[fabrica],p.quantidade,preload("res://scripts/crop.gd").NOMES[int(p.cultura)],mundo.calendario.restante(p.prazo),p.recompensa,p.penalidade]
func texto_historico() -> String:
	var texto: String = "ENCOMENDAS · HISTÓRICO DA SESSÃO\n"
	for item: Dictionary in historico: texto += "Dia %d · %s · %s · %d/%d · multa %d MT\n" % [item.dia,item.empresa,item.estado,item.entregue,item.quantidade,item.penalidade]
	return texto
