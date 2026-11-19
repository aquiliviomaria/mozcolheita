extends Control
## Mapa 2D a 8 Hz: sem segunda câmara nem segunda renderização do mundo 3D.
const Plano: GDScript = preload("res://scripts/layout.gd")
var mundo: Node3D
var intervalo: float = 0.0
var centro: Vector3 = Vector3.ZERO
var alcance: float = 360.0
var fundo: ImageTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(210,210)
	var imagem: Image = Image.create(160,160,false,Image.FORMAT_RGB8)
	for z: int in range(160):
		for x: int in range(160):
			var h: float = mundo.altura(Vector3(-400+x*5,0,-400+z*5))
			imagem.set_pixel(x,z,Color("363f32").lerp(Color("69715b"),clampf((h+31)/43,0,1)))
	fundo = ImageTexture.create_from_image(imagem)

func ponto(p: Vector3) -> Vector2:
	return size*0.5+Vector2(p.x-centro.x,p.z-centro.z)*(size.x/alcance)

func marca(p: Vector3,cor: Color,raio: float = 2.5) -> void:
	var local: Vector2 = ponto(p)
	if Rect2(Vector2(8,24),size-Vector2(16,42)).has_point(local): draw_circle(local,raio,cor)

func _process(delta: float) -> void:
	intervalo += delta
	if intervalo<0.125: return
	intervalo = 0
	if mundo.jogador==null: return
	var alvo: Node3D = mundo.drone_actual if mundo.drone_actual!=null else mundo.trator_actual if mundo.trator_actual!=null else mundo.jogador
	centro = alvo.global_position
	queue_redraw()

func _draw() -> void:
	draw_style_box(get_theme_stylebox("panel","PanelContainer"),Rect2(Vector2.ZERO,size))
	if fundo!=null:
		var origem: Vector2 = Vector2(centro.x-alcance*0.5+400,centro.z-alcance*0.5+400)*0.2
		draw_texture_rect_region(fundo,Rect2(Vector2(5,25),size-Vector2(10,44)),Rect2(origem,Vector2.ONE*alcance*0.2))
	var canto: Vector2 = ponto(Vector3(-96,0,-78))
	var fim: Vector2 = ponto(Vector3(96,0,78))
	draw_rect(Rect2(canto,fim-canto),Color("b0b6a0"),false,1)
	for p: Vector3 in Plano.PORTOES: marca(p,Color("8ed5a5"),3)
	for area: Rect2 in [Plano.CASA,Plano.GALPAO,Plano.ARMAZEM]:
		draw_rect(Rect2(ponto(Vector3(area.position.x,0,area.position.y)),area.size*size.x/alcance),Color("b9ac83"))
	if mundo.comunidade!=null:
		for trecho: Dictionary in mundo.comunidade.trocos: draw_line(ponto(trecho.a),ponto(trecho.b),Color("879187"),2)
		for n: Node3D in mundo.comunidade.casas: marca(n.position,Color("c3b591"),1.8)
		for n: Node3D in mundo.comunidade.edificios: marca(n.position,Color("9eb9b0"),3)
	if mundo.guia_entrega!=null:
		var anterior: Vector3 = centro
		for p: Vector3 in mundo.guia_entrega.rota:
			draw_line(ponto(anterior),ponto(p),Color("ffe17b"),2); anterior = p
	for fabrica: Node3D in mundo.fabricas: marca(fabrica.global_position,Color("d9ac6a"),4)
	for veiculo: Node3D in mundo.tratores: marca(veiculo.global_position,Color("80b8d2"),3)
	if mundo.caminhao!=null: marca(mundo.caminhao.position,Color("f1c45c"),4)
	for drone: Node3D in mundo.drones: marca(drone.global_position,Color("b5d5e2"),2)
	for pessoa: Node3D in mundo.pessoas: marca(pessoa.global_position,Color("d5c785") if pessoa.contratado else Color("8fa98b"),1.6)
	for c: Vector3 in preload("res://scripts/village.gd").CENTROS: marca(c,Color("b7b57d"),4)
	var seta: PackedVector2Array = PackedVector2Array([Vector2(0,-6),Vector2(4,5),Vector2(0,3),Vector2(-4,5)])
	var giro: float = mundo.jogador.visual.global_rotation.y if mundo.jogador!=null else 0.0
	for i: int in range(seta.size()): seta[i] = seta[i].rotated(-giro)+size*0.5
	draw_colored_polygon(seta,Color("f2e9c6"))
	draw_string(ThemeDB.fallback_font,Vector2(12,17),"N  ·  MAPA DA QUINTA",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("dfdfca"))
	draw_string(ThemeDB.fallback_font,Vector2(12,size.y-9),"Portões • Veículos • Pessoas",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("c2c6b5"))
