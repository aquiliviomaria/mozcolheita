extends CanvasLayer
## Painel compacto M; contratos confirmados e carga/destino escolhidos explicitamente.
var mundo: Node3D
var aberto: bool = false
var raiz: Control
var painel: PanelContainer
var coluna: VBoxContainer
var confirmacao: ConfirmationDialog
var confirmador: Callable
var produto: OptionButton
var quantidade: SpinBox
var transporte: Node3D
var botao_m: Button
var valor: OptionButton
var urgencia: OptionButton
func _ready() -> void:
	layer = 12; raiz = Control.new(); raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE; raiz.theme = mundo.hud.tema(); add_child(raiz); raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	botao_m = Button.new(); botao_m.text = "M · MISSÕES"; raiz.add_child(botao_m); botao_m.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); botao_m.offset_left = -265; botao_m.offset_right = -95; botao_m.offset_top = 18; botao_m.offset_bottom = 62; botao_m.pressed.connect(alternar_missoes)
	painel = PanelContainer.new(); raiz.add_child(painel); painel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); painel.offset_left = -480; painel.offset_right = -18; painel.offset_top = 85; painel.offset_bottom = 535; painel.hide()
	var scroll: ScrollContainer = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; painel.add_child(scroll)
	coluna = VBoxContainer.new(); coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(coluna)
	confirmacao = ConfirmationDialog.new(); confirmacao.title = "Confirmar contrato"; confirmacao.min_size = Vector2i(520,250); add_child(confirmacao); confirmacao.confirmed.connect(func() -> void: if confirmador.is_valid(): confirmador.call())
func limpar(titulo: String) -> void:
	mundo.hud.aberto = false; mundo.hud.detalhes.hide(); mundo.hud.kit_aberto = false; mundo.hud.kit.hide()
	for filho: Node in coluna.get_children(): coluna.remove_child(filho); filho.queue_free()
	mundo.hud.legenda(coluna,titulo,20)
	mundo.hud.botao(coluna,"Fechar · Esc",fechar)
	aberto = true; painel.show(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func fechar() -> void:
	aberto = false; painel.hide(); confirmacao.hide(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mundo.hud.aberto or mundo.hud.selecao.visible else Input.MOUSE_MODE_CAPTURED
func alternar_missoes() -> void:
	if mundo.hud.selecao.visible or mundo.contrato.activo: return
	if aberto: fechar(); return
	if mundo.casa.vida_domestica.ocupado(): mundo.avisar("Termine a actividade antes de abrir as missões."); return
	abrir_missoes()
func abrir_missoes() -> void:
	limpar("MISSÕES · ENCOMENDAS")
	valor = OptionButton.new(); coluna.add_child(valor)
	for p: String in mundo.entregas.PERFIS: valor.add_item(p)
	urgencia = OptionButton.new(); coluna.add_child(urgencia)
	for u: String in ["Normal","Prioritária +25%","Urgente +50%"]: urgencia.add_item(u)
	var lista: VBoxContainer = VBoxContainer.new(); coluna.add_child(lista)
	valor.item_selected.connect(func(_i: int) -> void: ofertas(lista))
	urgencia.item_selected.connect(func(_i: int) -> void: ofertas(lista))
	ofertas(lista)
func ofertas(lista: VBoxContainer) -> void:
	for filho: Node in lista.get_children(): lista.remove_child(filho); filho.queue_free()
	for i: int in range(3):
		var empresa: int = i
		var l: Label = mundo.hud.legenda(lista,mundo.entregas.descricao(i,urgencia.selected,valor.selected),13); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size.x = 380
		var activa: bool = mundo.entregas.activas.has(i) and not bool(mundo.entregas.activas[i].concluida) and not bool(mundo.entregas.activas[i].falhou)
		if activa: mundo.hud.botao(lista,"Cancelar contrato · multa em dobro",func() -> void: propor_cancelamento(empresa))
		else: mundo.hud.botao(lista,"Rever e aceitar",func() -> void: propor(empresa,urgencia.selected,valor.selected))
func propor(empresa: int,nivel: int,perfil: int) -> void:
	if not aberto: limpar("CONFIRMAÇÃO DE ENCOMENDA")
	var oferta: Dictionary = mundo.entregas.oferta(empresa,nivel,perfil)
	confirmacao.dialog_text = "%s\n%d unidades · recebe %d MT\nPrazo: %s\nAtrasar OU cancelar: paga %d MT (2× contrato).\nA multa é debitada automaticamente. Confirmar?" % [mundo.entregas.EMPRESAS[empresa],oferta.quantidade,oferta.recompensa,mundo.calendario.restante(oferta.prazo),oferta.penalidade]
	confirmador = func() -> void:
		if mundo.entregas.aceitar(empresa,nivel,perfil): abrir_missoes()
	confirmacao.popup_centered()
func propor_cancelamento(empresa: int) -> void:
	var p: Dictionary = mundo.entregas.activas[empresa]
	confirmacao.dialog_text = "Cancelar %s?\nQuebra de contrato: %d MT (2× valor acordado).\nO desconto é imediato e só ocorre uma vez." % [mundo.entregas.EMPRESAS[empresa],p.penalidade]
	confirmador = func() -> void: mundo.entregas.cancelar(empresa); abrir_missoes()
	confirmacao.popup_centered()
func abrir_carga(veiculo: Node3D = null) -> void:
	transporte = veiculo; limpar("ARMAZÉM · ESCOLHER CARGA")
	produto = OptionButton.new(); coluna.add_child(produto)
	for c: int in range(4): produto.add_item("%s · %d disponíveis" % [preload("res://scripts/crop.gd").NOMES[c],int(mundo.stock.get(c,0))],c)
	quantidade = SpinBox.new(); quantidade.min_value = 1; quantidade.max_value = 9999; quantidade.value = 50; coluna.add_child(quantidade)
	mundo.hud.legenda(coluna,"O funcionário leva a carga ao transporte.
Mantenha-o parado até terminar.",14)
	mundo.hud.botao(coluna,"Pedir ao funcionário para carregar",confirmar_carga)
	if veiculo!=null and veiculo.total()>0:
		mundo.hud.botao(coluna,"Pedir ao funcionário para descarregar",func() -> void:
			if mundo.armazem.encomendar_descarga(veiculo): fechar(); mundo.avisar("Funcionário a descarregar · mantenha o transporte parado"))
	if veiculo==null and not mundo.sacola.is_empty():
		mundo.hud.botao(coluna,"Entregar a colheita que trago",func() -> void:
			if mundo.armazem.encomendar_descarga(): fechar(); mundo.avisar("Funcionário a receber a sua colheita"))
	mundo.hud.botao(coluna,"Consultar missões antes de carregar · M",abrir_missoes)
func carregar_escolha(c: int,q: int,veiculo: Node3D = null) -> int:
	if c<0 or c>3 or q<=0: return 0
	if veiculo!=null and (not is_instance_valid(veiculo) or veiculo.position.distance_to(mundo.armazem.CENTRO)>65): return 0
	if veiculo==null and not mundo.armazem.perto(): return 0
	var disponivel: int = mini(q,int(mundo.stock.get(c,0)))
	if disponivel<=0: return 0
	var movidas: int = disponivel
	if veiculo!=null:
		var lote: Dictionary = {c:disponivel}; movidas = veiculo.carregar(lote)
	else: mundo.sacola[c] = int(mundo.sacola.get(c,0))+movidas
	mundo.stock[c] = int(mundo.stock[c])-movidas
	if int(mundo.stock[c])==0: mundo.stock.erase(c)
	return movidas
func confirmar_carga() -> void:
	var c: int = produto.get_selected_id()
	if not mundo.armazem.encomendar_carga(c,int(quantidade.value),transporte): mundo.avisar("Funcionário ocupado, sem stock ou capacidade · pare junto ao armazém"); return
	fechar(); mundo.avisar("Funcionário a carregar · aguarde com o transporte parado")
func abrir_destinos(c: int) -> void:
	limpar("CARGA PRONTA · ONDE ENTREGAR?")
	mundo.hud.legenda(coluna,"Escolha a empresa. A seta e o minimapa\nindicam o percurso para a garagem.",14)
	for site: Node3D in mundo.fabricas:
		if not mundo.economia.aceita(site.numero,c): continue
		var alvo: Node3D = site
		var distancia: int = roundi(mundo.jogador.position.distance_to(site.position))
		var nome: String = mundo.entregas.EMPRESAS[site.numero]+(" · sede" if not site.local_filial.is_finite() else " · filial")+" · %d m" % distancia
		mundo.hud.botao(coluna,nome,func() -> void:
			mundo.guia_entrega.empresa_escolhida = alvo.numero; mundo.guia_entrega.local_escolhido = alvo; mundo.guia_entrega.intervalo = 0; fechar(); mundo.avisar("Destino escolhido · siga a seta até à garagem"))
	mundo.hud.botao(coluna,"Aceitar uma missão antes de partir · M",abrir_missoes)
func _process(_delta: float) -> void:
	botao_m.visible = not mundo.hud.selecao.visible and not mundo.hud.aberto and not mundo.hud.kit_aberto
