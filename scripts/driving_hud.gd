extends Control
## Ícones de acção com a tecla no centro; entradas activas acendem o respectivo cartão.
const Entrada: GDScript = preload("res://scripts/input_drive.gd")
var mundo: Node3D
var ferramentas: VBoxContainer
var botoes_ferramentas: Array[Button] = []
var abastecer: Button
var modo: String = ""
var painel: StyleBoxFlat
var cartao_normal: StyleBoxFlat
var cartao_premido: StyleBoxFlat
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel = StyleBoxFlat.new(); painel.bg_color = Color(0.035,0.085,0.07,0.92); painel.border_color = Color("59816a"); painel.set_border_width_all(1); painel.set_corner_radius_all(14)
	cartao_normal = StyleBoxFlat.new(); cartao_normal.bg_color = Color("203a30"); cartao_normal.set_corner_radius_all(10)
	cartao_premido = cartao_normal.duplicate(); cartao_premido.bg_color = Color("347c50"); cartao_premido.border_color = Color("a8ecc2"); cartao_premido.set_border_width_all(2)
	ferramentas = VBoxContainer.new(); ferramentas.position = Vector2(22,140); ferramentas.custom_minimum_size.x = 215; add_child(ferramentas)

	abastecer = mundo.hud.botao(self,"B · Abastecer sementes",func() -> void: mundo.reabastecer(),"semeadora"); abastecer.position.x = 22; abastecer.custom_minimum_size = Vector2(375,42)
func escrever(p: Vector2,texto: String,tamanho: int = 14,cor: Color = Color("f1f1df")) -> void:
	draw_string(ThemeDB.fallback_font,p,texto,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho,cor)
func centro(p: Vector2,texto: String,tamanho: int = 14,cor: Color = Color("f1f1df")) -> void:
	var largura: float = ThemeDB.fallback_font.get_string_size(texto,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho).x
	escrever(p-Vector2(largura/2,0),texto,tamanho,cor)
func icone(nome: String,p: Vector2,tamanho: float,cor: Color = Color.WHITE) -> void:
	draw_texture_rect(mundo.hud.textura(nome),Rect2(p,Vector2.ONE*tamanho),false,cor)
func obter_modo() -> String:
	return "carro" if mundo.trator_actual!=null and mundo.trator_actual.is_in_group("carros_jogaveis") else "drone" if mundo.drone_actual!=null else "camião" if mundo.trator_actual==mundo.caminhao else "tractor" if mundo.trator_actual!=null else "a pé"
func acoes() -> Array[Dictionary]:
	if modo=="drone":
		return [{"icone":"direccao","tecla":"WASD","nome":"Voar","activo":Entrada.eixo(JOY_AXIS_LEFT_X)!=0 or Entrada.eixo(JOY_AXIS_LEFT_Y)!=0 or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D)},
			{"icone":"subir","tecla":"Espaço","nome":"Subir","activo":Input.is_physical_key_pressed(KEY_SPACE) or Entrada.botao(JOY_BUTTON_A)},
			{"icone":"descer","tecla":"Ctrl","nome":"Descer","activo":Input.is_key_pressed(KEY_CTRL) or Entrada.botao(JOY_BUTTON_B)},
			{"icone":"regador","tecla":"R","nome":"Irrigar","activo":mundo.drone_actual!=null and mundo.drone_actual.irrigando},
			{"icone":"regressar","tecla":"F","nome":"Regressar","activo":Input.is_physical_key_pressed(KEY_F)},
			{"icone":"cursor","tecla":"Rato","nome":"Câmara","activo":false}]
	var lista: Array[Dictionary] = [{"icone":"acelerador","tecla":"W","nome":"Acelerar","activo":Entrada.acelerador()>0},
		{"icone":"travao","tecla":"Ctrl","nome":"Travar","activo":Entrada.travao()},
		{"icone":"turbo","tecla":"T","nome":"Turbo + W","activo":Entrada.turbo()},
		{"icone":"recuar","tecla":"S","nome":"Recuar","activo":Entrada.recuar()>0},
		{"icone":"direccao","tecla":"A / D","nome":"Virar","activo":absf(Entrada.direccao())>0},
		{"icone":"engate","tecla":"G","nome":"Engatar","activo":Input.is_physical_key_pressed(KEY_G)},
		{"icone":"maquina","tecla":"Espaço","nome":"Máquina","activo":Input.is_physical_key_pressed(KEY_SPACE)},
		{"icone":"carga","tecla":"X","nome":"Carga","activo":Input.is_physical_key_pressed(KEY_C)},
		{"icone":"regressar","tecla":"E","nome":"Sair","activo":Input.is_physical_key_pressed(KEY_E)}]
	if modo=="carro": return [lista[0],lista[1],lista[2],lista[3],lista[4],{"icone":"maos","tecla":"C","nome":"Companhia","activo":Input.is_physical_key_pressed(KEY_C)},lista[8]]
	return lista

func _process(_delta: float) -> void:
	visible = mundo.hud!=null and not mundo.hud.selecao.visible
	modo = obter_modo()
	ferramentas.visible = false
	abastecer.visible = visible and not mundo.hud.aberto and not mundo.hud.kit_aberto and mundo.trator_actual!=null and mundo.trator_actual.implemento!=null and mundo.trator_actual.implemento.tipo==1
	abastecer.position.y = size.y-398
	queue_redraw()
func _draw() -> void:
	if mundo.vitais==null or mundo.hud==null: return
	modo = obter_modo()
	var v: Node = mundo.vitais
	draw_style_box(painel,Rect2(18,12,435,50))
	for i: int in range(5): icone("vida",Vector2(28+i*28,24),25,Color("fa6d7e") if v.vida>i*20 else Color("67454a"))
	escrever(Vector2(174,45),str(ceili(v.vida)),20)
	icone("fome",Vector2(228,23),28,Color("f0be67")); escrever(Vector2(264,45),str(ceili(v.fome)),20)
	icone("energia",Vector2(328,23),28,Color("82d8b1")); escrever(Vector2(365,45),str(ceili(v.energia)),20)
	if mundo.hud.aberto or mundo.hud.kit_aberto or modo not in ["drone","tractor","camião","carro"]: return
	var lista: Array[Dictionary] = acoes(); var altura: float = 330 if lista.size()>6 else 240
	var origem: Vector2 = Vector2(18,size.y-altura-16)
	draw_style_box(painel,Rect2(origem,Vector2(375,altura)))
	var titulo: String = "DRONE · %.1f m" % (mundo.drone_actual.position.y-mundo.altura(mundo.drone_actual.position)) if modo=="drone" else "%s · %d km/h" % [modo.to_upper(),roundi(absf(mundo.trator_actual.rapidez)*3.6)]
	escrever(origem+Vector2(16,27),titulo,18)
	for i: int in range(lista.size()):
		var a: Dictionary = lista[i]; var p: Vector2 = origem+Vector2(14+(i%3)*117,43+(i/3)*90)
		draw_style_box(cartao_premido if bool(a.activo) else cartao_normal,Rect2(p,Vector2(112,82)))
		icone(a.icone,p+Vector2(30,3),52,Color("bce9c9") if bool(a.activo) else Color("8ea99a"))
		# Tecla no centro do próprio ícone, sobre fundo escuro para leitura.
		var texto: String = a.tecla; var largura: float = maxf(27,ThemeDB.fallback_font.get_string_size(texto,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+10)
		draw_rect(Rect2(p+Vector2(56-largura/2,21),Vector2(largura,24)),Color("10251d"))
		centro(p+Vector2(56,39),texto,15,Color.WHITE)
		centro(p+Vector2(56,72),a.nome,14)
