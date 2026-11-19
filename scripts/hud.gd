extends CanvasLayer
## Menu por ícones e separadores; minimapa independente e sempre visível.
var mundo: Node3D
var raiz: Control
var dinheiro: Label
var missao_hud: Label
var comandos: Label
var abastecer_botao: Button
var dica: Label
var ferramenta: TextureRect
var selecao: PanelContainer
var detalhes: PanelContainer
var kit: HBoxContainer
var aberto: bool = false
var kit_aberto: bool = false
var cultura: OptionButton
var trabalhadores: OptionButton
var tarefa: OptionButton
var trator: OptionButton
var fabrica: OptionButton
var stock: Label
var fila: Label
var tempo_actualizacao: float = 0.0
var texturas: Dictionary = {}
var botoes_itens: Array[Button] = []
var botoes_culturas: Array[Button] = []
var botoes_comandos: Array[Button] = []
var minimapa: Control
var logo: ImageTexture
var proposta_painel: PanelContainer
var op_trabalho: OptionButton
var op_tractor: OptionButton
var op_fabrica: OptionButton
var op_nivel: OptionButton
var op_x: SpinBox
var op_z: SpinBox
var op_quantidade: SpinBox
var custo: Label
var confirmar_pagamento: Button
var progresso: ProgressBar
var missao_label: Label
var paginas: TabContainer

func tema() -> Theme:
	var t: Theme = Theme.new(); t.default_font_size = 15
	for classe: String in ["PanelContainer","Button","OptionButton","TabContainer"]:
		for estado: String in (["panel"] if classe in ["PanelContainer","TabContainer"] else ["normal","hover","pressed","focus","disabled"]):
			var estilo: StyleBoxFlat = StyleBoxFlat.new()
			estilo.bg_color = Color("2c4841") if estado in ["hover","pressed"] else Color("132420")
			estilo.border_color = Color("496458"); estilo.set_border_width_all(1); estilo.set_corner_radius_all(12)
			estilo.content_margin_left = 16; estilo.content_margin_right = 16
			estilo.content_margin_top = 12; estilo.content_margin_bottom = 12
			t.set_stylebox(estado,classe,estilo)
	return t

func legenda(pai: Node,texto: String,tamanho: int = 15) -> Label:
	var l: Label = Label.new(); l.text = texto
	l.add_theme_font_size_override("font_size",tamanho)
	l.add_theme_color_override("font_color",Color("ecebdc"))
	pai.add_child(l); return l

func textura(nome: String) -> Texture2D:
	if not texturas.has(nome):
		var imagem: Image = Image.new()
		imagem.load_svg_from_string(FileAccess.get_file_as_string("res://icons/"+nome+".svg"))
		texturas[nome] = ImageTexture.create_from_image(imagem)
	return texturas[nome]

func botao(pai: Node,texto: String,acao: Callable,icone: String = "") -> Button:
	var b: Button = Button.new(); b.text = texto; b.focus_mode = Control.FOCUS_NONE
	if not icone.is_empty(): b.icon = textura(icone)
	b.pressed.connect(acao); pai.add_child(b); return b

func painel_centrado(largura: float,altura: float) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new(); raiz.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.offset_left = -largura/2; p.offset_right = largura/2
	p.offset_top = -altura/2; p.offset_bottom = altura/2
	return p

func imagem_logo(pai: Node,tamanho: Vector2) -> TextureRect:
	var vista: TextureRect = TextureRect.new(); vista.texture = logo
	vista.custom_minimum_size = tamanho; vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(vista); return vista

func _ready() -> void:
	logo = ImageTexture.create_from_image(Image.load_from_file("res://MozColheita-icon.png"))
	raiz = Control.new(); raiz.theme = tema(); raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz); raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dinheiro = legenda(raiz,"500.000 MT  ·  06:00",19); dinheiro.position = Vector2(22,20)
	var marca: TextureRect = imagem_logo(raiz,Vector2(62,62))
	marca.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	marca.offset_left = -82; marca.offset_right = -20; marca.offset_top = 14; marca.offset_bottom = 76
	missao_hud = legenda(raiz,"",13); missao_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	missao_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	missao_hud.offset_left = -380; missao_hud.offset_right = -98; missao_hud.offset_top = 22; missao_hud.offset_bottom = 65
	minimapa = preload("res://scripts/minimap.gd").new(); minimapa.mundo = mundo; raiz.add_child(minimapa)
	minimapa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	minimapa.offset_left = -238; minimapa.offset_right = -18; minimapa.offset_top = -238; minimapa.offset_bottom = -18
	ferramenta = TextureRect.new(); raiz.add_child(ferramenta)
	ferramenta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ferramenta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ferramenta.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ferramenta.offset_left = -16; ferramenta.offset_right = 16; ferramenta.offset_top = -54; ferramenta.offset_bottom = -22
	dica = legenda(raiz,""); dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dica.offset_left = -400; dica.offset_right = 400; dica.offset_top = -90; dica.offset_bottom = -60
	var painel_comandos: VBoxContainer = VBoxContainer.new(); raiz.add_child(painel_comandos)
	painel_comandos.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	painel_comandos.offset_left = 22; painel_comandos.offset_top = -205; painel_comandos.offset_right = 520; painel_comandos.offset_bottom = -110
	comandos = legenda(painel_comandos,"",13)
	abastecer_botao = botao(painel_comandos,"B · Abastecer sementes · 2 MT/unidade",func() -> void: mundo.reabastecer(),"semeadora")
	var atalhos: HBoxContainer = HBoxContainer.new(); raiz.add_child(atalhos); atalhos.position = Vector2(22,58)
	botao(atalhos,"H",alternar,"painel").tooltip_text = "Gestão da quinta"
	botao(atalhos,"K",alternar_kit,"enxada").tooltip_text = "Ferramentas"
	kit = HBoxContainer.new(); raiz.add_child(kit)
	kit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	kit.offset_left = 20; kit.offset_top = -100; kit.offset_bottom = -20
	for i: int in range(6):
		var indice: int = i
		var b: Button = botao(kit,str(i+1),func() -> void: mundo.ferramentas.seleccionar(indice),mundo.ferramentas.ICONES[i])
		b.tooltip_text = mundo.ferramentas.NOMES[i]; botoes_itens.append(b)
	kit.hide()
	criar_painel()
	criar_menu()
	criar_proposta()

func criar_menu() -> void:
	selecao = painel_centrado(440,440)
	var coluna: VBoxContainer = VBoxContainer.new(); selecao.add_child(coluna)
	imagem_logo(coluna,Vector2(144,144))
	var titulo: Label = legenda(coluna,"MOZCOLHEITA",28); titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var frase: Label = legenda(coluna,"A sua machamba. O seu futuro.",14); frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao(coluna,"Começar",func() -> void: escolher(),"quinta")
	var ajuda: Label = legenda(coluna,"WASD mover · K ferramentas · H gestão\nE interagir · G engatar · F drone",13); ajuda.hide()
	botao(coluna,"Controlos",func() -> void: ajuda.visible = not ajuda.visible,"cursor")
	botao(coluna,"Sair",func() -> void: get_tree().quit(),"interagir")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func pagina(nome: String,icone: String) -> VBoxContainer:
	var margem: MarginContainer = MarginContainer.new(); margem.name = nome; paginas.add_child(margem)
	for lado: String in ["left","right","top","bottom"]: margem.add_theme_constant_override("margin_"+lado,16)
	var coluna: VBoxContainer = VBoxContainer.new(); coluna.add_theme_constant_override("separation",12); margem.add_child(coluna)
	paginas.set_tab_icon(paginas.get_tab_count()-1,textura(icone)); return coluna

func criar_painel() -> void:
	detalhes = painel_centrado(720,510)
	var base: VBoxContainer = VBoxContainer.new(); detalhes.add_child(base)
	legenda(base,"GESTÃO DA QUINTA",22)
	missao_label = legenda(base,"",13)
	paginas = TabContainer.new(); paginas.size_flags_vertical = Control.SIZE_EXPAND_FILL; base.add_child(paginas)
	var plantio: VBoxContainer = pagina("Culturas","semeadora")
	legenda(plantio,"Escolha as sementes. Prepare a terra antes de semear.",14)
	cultura = OptionButton.new(); plantio.add_child(cultura)
	for nome: String in preload("res://scripts/crop.gd").NOMES: cultura.add_item(nome)
	cultura.item_selected.connect(func(i: int) -> void: mundo.ferramentas.cultura = i)
	var escolhas: HBoxContainer = HBoxContainer.new(); plantio.add_child(escolhas)
	for i: int in range(4):
		var indice: int = i
		botoes_culturas.append(botao(escolhas,preload("res://scripts/crop.gd").NOMES[i],func() -> void: cultura.select(indice); mundo.ferramentas.cultura = indice,["tomate","milho","couve","cenoura"][i]))
	legenda(plantio,"Enxada → sementes → água → crescimento → colheita",14)
	var equipa: VBoxContainer = pagina("Equipa","interagir")
	trabalhadores = OptionButton.new(); equipa.add_child(trabalhadores)
	for pessoa: Node3D in mundo.pessoas: trabalhadores.add_item(pessoa.nome)
	var accoes: HBoxContainer = HBoxContainer.new(); equipa.add_child(accoes)
	botao(accoes,"Definir contrato",ordenar,"interagir")
	botao(accoes,"Cancelar e reembolsar",func() -> void: mundo.contrato.encerrar(mundo.pessoas[trabalhadores.selected],"Cancelado pelo jogador"),"carga")
	progresso = ProgressBar.new(); progresso.max_value = 100; progresso.custom_minimum_size.y = 22; equipa.add_child(progresso)
	fila = legenda(equipa,"",13); fila.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao(equipa,"Recolher carga do trabalhador",func() -> void:
		var pessoa: Node3D = mundo.pessoas[trabalhadores.selected]
		if pessoa.global_position.distance_to(mundo.jogador.position)>3: mundo.avisar("Aproxime-se do trabalhador."); return
		for c: int in pessoa.carga: mundo.sacola[c] = int(mundo.sacola.get(c,0))+int(pessoa.carga[c])
		pessoa.carga.clear(),"carga")
	var mercado: VBoxContainer = pagina("Mercado","carga")
	stock = legenda(mercado,""); stock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao(mercado,"Encher semeadoras · 2 MT/semente",func() -> void: mundo.reabastecer(true),"semeadora")
	botao(mercado,"20 sementes · 40 MT",func() -> void: mundo.avisar("Sementes compradas." if mundo.economia.sementes() else "Visite o armazém com saldo suficiente."),"semeadora")
	var comandos: VBoxContainer = pagina("Controlos","cursor")
	for i: int in range(6):
		var textos: Array[String] = ["WASD · Mover     Shift · Correr","1–6 / K · Ferramentas     Clique · Usar","E · Interagir / conduzir / conversar","G · Engatar     Espaço · Máquina     C · Carga","F · Drone     Espaço / Ctrl · Altura     R · Rega","Tab · Cursor     H · Gestão     Esc · Menu"]
		botoes_comandos.append(botao(comandos,textos[i],func() -> void: pass,["cursor","enxada","interagir","engate","drone","painel"][i]))
	botao(base,"Voltar ao campo  ·  H",alternar)
	detalhes.hide()

func escolher(_feminino: bool = false) -> void:
	# O jogador começa sempre como homem, sem pergunta de género.
	mundo.jogador.mulher = false
	selecao.hide(); Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func alternar() -> void:
	if selecao.visible or mundo.contrato.activo: return
	kit_aberto = false; kit.hide(); aberto = not aberto; detalhes.visible = aberto
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if aberto else Input.MOUSE_MODE_CAPTURED

func alternar_kit() -> void:
	if selecao.visible or aberto: return
	kit_aberto = not kit_aberto; kit.visible = kit_aberto
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if kit_aberto else Input.MOUSE_MODE_CAPTURED

func menu() -> void:
	aberto = false; detalhes.hide(); kit_aberto = false; kit.hide()
	selecao.show(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func ordenar() -> void:
	var pessoa: Node3D = mundo.pessoas[trabalhadores.selected]
	if not pessoa.servico.is_empty(): mundo.avisar("Este trabalhador já tem uma tarefa contratada."); return
	if pessoa.global_position.distance_to(mundo.jogador.position)>3: mundo.avisar("Aproxime-se para definir e assinar o contrato."); return
	aberto = false; detalhes.hide(); mundo.contrato.iniciar(pessoa)

func criar_proposta() -> void:
	proposta_painel = painel_centrado(700,690)
	var base: VBoxContainer = VBoxContainer.new(); proposta_painel.add_child(base)
	legenda(base,"CONTRATO DE TRABALHO",22)
	legenda(base,"Tarefa obrigatória · um tractor por trabalhador · máximo 3",13)
	op_trabalho = OptionButton.new(); base.add_child(op_trabalho)
	op_trabalho.add_item("Escolha a tarefa (obrigatório)",-1)
	for tipo: int in mundo.contrato.TRABALHOS: op_trabalho.add_item(mundo.tarefas.NOMES[tipo],tipo)
	var linha: HBoxContainer = HBoxContainer.new(); base.add_child(linha)
	op_tractor = OptionButton.new(); linha.add_child(op_tractor)
	for i: int in range(3): op_tractor.add_item("Tractor %d" % [i+1])
	op_fabrica = OptionButton.new(); linha.add_child(op_fabrica)
	for nome: String in ["Fábrica A","Fábrica B","Fábrica C"]: op_fabrica.add_item(nome)
	op_nivel = OptionButton.new(); linha.add_child(op_nivel)
	for nome: String in ["Normal","Exigente","Difícil"]: op_nivel.add_item(nome)
	var quantidade: HBoxContainer = HBoxContainer.new(); base.add_child(quantidade)
	legenda(quantidade,"Quantidade (células ou produtos)",14)
	op_quantidade = SpinBox.new(); op_quantidade.min_value = 1; op_quantidade.max_value = 500; op_quantidade.value = 10; quantidade.add_child(op_quantidade)
	var parcela: HBoxContainer = HBoxContainer.new(); base.add_child(parcela)
	legenda(parcela,"Centro da parcela · X / Z",13)
	op_x = SpinBox.new(); op_x.min_value = -72; op_x.max_value = 72; parcela.add_child(op_x)
	op_z = SpinBox.new(); op_z.min_value = -58; op_z.max_value = 58; parcela.add_child(op_z)
	op_x.value_changed.connect(func(_v: float) -> void: actualizar_orcamento())
	op_z.value_changed.connect(func(_v: float) -> void: actualizar_orcamento())
	custo = legenda(base,"",13); custo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legenda(base,"Área de 24 × 24 m no centro indicado, apenas cultura da missão.
Com implemento adequado usa o tractor; sem ele trabalha manualmente.",12)
	legenda(base,"Reserva o máximo aprovado. Não cobra espera nem aumenta o preço.
Trabalho não executado é reembolsado ao cancelar ou terminar a missão.",12)
	confirmar_pagamento = botao(base,"Escolha uma tarefa",func() -> void: mundo.contrato.confirmar(),"interagir")
	botao(base,"Cancelar",func() -> void: mundo.contrato.terminar(false))
	for escolha: OptionButton in [op_trabalho,op_tractor,op_fabrica,op_nivel]: escolha.item_selected.connect(func(_i: int) -> void: actualizar_orcamento())
	op_quantidade.value_changed.connect(func(_v: float) -> void: actualizar_orcamento())
	proposta_painel.hide()

func mostrar_proposta() -> void:
	aberto = false; detalhes.hide(); kit_aberto = false; kit.hide()
	op_trabalho.select(0); op_quantidade.value = 10
	var livre: int = -1
	for i: int in range(3):
		var ocupado: bool = mundo.tratores[i].atribuido!=null or mundo.tratores[i].ocupado
		op_tractor.set_item_disabled(i,ocupado)
		if not ocupado and livre==-1: livre = i
	op_tractor.select(livre)
	proposta_painel.show(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; actualizar_orcamento()

func fechar_proposta() -> void:
	if proposta_painel!=null: proposta_painel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func actualizar_orcamento() -> void:
	if not mundo.contrato.activo or op_trabalho.selected<=0 or op_tractor.selected<0:
		mundo.contrato.proposta = {}; custo.text = "Escolha tarefa e tractor para ver o orçamento."; confirmar_pagamento.text = "Escolha tarefa e tractor"; confirmar_pagamento.disabled = true; return
	mundo.contrato.centro_trabalho = Vector2i(int(op_x.value),int(op_z.value))
	var plano: Dictionary = mundo.contrato.orcamento(op_trabalho.get_selected_id(),int(op_quantidade.value),op_tractor.selected,op_nivel.selected,op_fabrica.selected)
	mundo.contrato.proposta = plano
	custo.text = "%s
%s · %d unidades · Tractor %d
Trabalho: %d MT
Tempo estimado: %d min · %d MT
Dificuldade / distância: +%d MT
Procura da missão: +%d MT
TOTAL MÁXIMO: %d MT" % [plano.objectivo,plano.tarefa,plano.quantidade,int(plano.trator)+1,plano.base,plano.minutos,plano.tempo,plano.dificuldade,plano.demanda,plano.total]
	confirmar_pagamento.text = "Confirmar e reservar %d MT" % plano.total
	confirmar_pagamento.disabled = mundo.saldo<int(plano.total)

func _process(delta: float) -> void:
	tempo_actualizacao += delta
	if tempo_actualizacao<0.15: return
	tempo_actualizacao = 0
	dinheiro.text = "%s   ·   %02d:%02d" % [preload("res://scripts/economy.gd").formatar(mundo.saldo),(6+int(mundo.relogio/60))%24,int(mundo.relogio)%60]
	missao_hud.text = mundo.missoes.resumo()+"\nContratos: %d/3" % mundo.contrato.activos()
	ferramenta.texture = textura(mundo.ferramentas.ICONES[mundo.ferramentas.actual])
	ferramenta.visible = not selecao.visible and not aberto and not kit_aberto
	dica.text = mundo.dica(); dica.visible = not selecao.visible and not aberto
	for i: int in range(6): botoes_itens[i].modulate = Color("a2d1a8") if i==mundo.ferramentas.actual else Color.WHITE
	comandos.text = mundo.comandos_actuais()
	comandos.get_parent().visible = not selecao.visible and not aberto and not kit_aberto and not mundo.contrato.activo
	abastecer_botao.visible = (mundo.trator_actual!=null and mundo.trator_actual.implemento!=null and mundo.trator_actual.implemento.tipo==1) or (mundo.trator_actual==null and mundo.ferramentas.actual==5)
	if mundo.trator_actual==null:
		for maquina: Node3D in mundo.implementos:
			if maquina.tipo==1 and preload("res://scripts/layout.gd").distancia(mundo.jogador.position,maquina.position)<5: abastecer_botao.visible = true
	if aberto:
		var pessoa: Node3D = mundo.pessoas[trabalhadores.selected]
		missao_label.text = mundo.missoes.resumo()+" · contratos %d/3" % mundo.contrato.activos()
		if pessoa.servico.is_empty():
			fila.text = pessoa.ultimo_servico; progresso.value = 0
		else:
			var plano: Dictionary = pessoa.servico
			progresso.value = 100.0*int(plano.realizado)/int(plano.quantidade)
			fila.text = "%s
%s · Tractor %d
Progresso: %d/%d · %s
Orçamento reservado: %d MT · pago pelo trabalho: %d MT
Saldo reembolsável: %d MT" % [plano.objectivo,plano.tarefa,int(plano.trator)+1,plano.realizado,plano.quantidade,pessoa.estado,plano.total,plano.pago,int(plano.total)-int(plano.pago)]
		stock.text = mundo.resumo_stock()+"\nSementes: %d   Madeira: %d\n" % [mundo.ferramentas.sementes,mundo.ferramentas.madeira]
		for maquina: Node3D in mundo.implementos:
			if maquina.tipo==1: stock.text += "Semeadora: %d/300 · encher: %d MT\n" % [maquina.sementes,maquina.custo_abastecer()]
		for i: int in range(3):
			stock.text += "\nFábrica "+["A","B","C"][i]+": "
			for c: int in range(4): stock.text += "%s %d MT  " % [preload("res://scripts/crop.gd").NOMES[c],mundo.economia.preco(i,c)]
