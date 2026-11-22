extends Control
## Telejornal contínuo: ordem variada, sem repetir notícias antes de esgotar a edição.
const CATALOGO: GDScript = preload("res://scripts/tv_news.gd")
const NOTICIAS: Array[Dictionary] = CATALOGO.NOTICIAS
const DURACAO: float = 7.0
var mundo: Node3D
var tempo: float = 0
var tempo_noticia: float = 0
var ordem: Array[int] = []
var actual: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
func _ready() -> void:
	rng.randomize(); proxima()
func proxima() -> void:
	if ordem.is_empty():
		for i: int in range(NOTICIAS.size()): ordem.append(i)
		for i: int in range(ordem.size()-1,0,-1):
			var j: int = rng.randi_range(0,i); var v: int = ordem[i]; ordem[i] = ordem[j]; ordem[j] = v
	# Alterna temas quando possível, incluindo na passagem entre edições.
	var escolha: int = 0
	for i: int in range(ordem.size()):
		if actual<0 or NOTICIAS[ordem[i]].tema!=NOTICIAS[actual].tema:
			escolha = i; break
	if ordem[escolha]==actual and ordem.size()>1: escolha = 1
	actual = ordem[escolha]; ordem.remove_at(escolha); tempo_noticia = 0
func noticia_actual() -> Dictionary:
	return CATALOGO.actualizar(NOTICIAS[maxi(0,actual)],mundo)
func _process(delta: float) -> void:
	var real_delta: float = delta/maxf(1,Engine.time_scale)
	tempo += real_delta; tempo_noticia += real_delta
	if tempo_noticia>=DURACAO: proxima()
	queue_redraw()
func texto(p: Vector2,t: String,tamanho: int = 12,cor: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho,cor)
func _draw() -> void:
	var noticia: Dictionary = noticia_actual()
	draw_rect(Rect2(0,0,320,180),Color("122c40"))
	# Cenário original de estúdio: horizonte urbano, apresentadora e painéis animados.
	for i: int in range(13):
		var h: float = 15+(i*17)%53
		draw_rect(Rect2(i*26,105-h,20,h),Color("294c65"))
		for j: int in range(3): draw_rect(Rect2(i*26+4,100-h+j*12,3,4),Color("7cb5bb"))
	draw_rect(Rect2(122,32,185,67),Color("203b59"))
	texto(Vector2(133,61),str(noticia.painel),22,Color("efb6d1"))
	texto(Vector2(133,81),str(noticia.tema),11)
	var respirar: float = sin(tempo*2)*0.6
	draw_circle(Vector2(66,58+respirar),15,Color("87583e"))
	draw_arc(Vector2(66,56+respirar),16,PI,TAU,20,Color("221c24"),7)
	draw_circle(Vector2(61,57+respirar),1.4,Color("1b1b23")); draw_circle(Vector2(71,57+respirar),1.4,Color("1b1b23"))
	draw_line(Vector2(62,66+respirar),Vector2(70,66+respirar),Color("e4b49b"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(46,77),Vector2(86,77),Vector2(100,117),Vector2(32,117)]),Color("d4b869"))
	draw_line(Vector2(50,92),Vector2(67+sin(tempo)*4,106),Color("87583e"),7)
	draw_rect(Rect2(15,106,288,13),Color("43798b"))
	draw_rect(Rect2(0,0,320,23),Color("14532d")); texto(Vector2(8,16),"MOZTV · NOTICIAS",13)
	texto(Vector2(244,15),"TELEJORNAL",9)
	draw_rect(Rect2(0,119,320,61),Color("10212f"))
	texto(Vector2(8,135),str(noticia.titulo),14,Color("f1cf78"))
	texto(Vector2(8,150),str(noticia.linha1),11)
	texto(Vector2(8,164),str(noticia.linha2),11)
	texto(Vector2(8,177),str(noticia.fonte),8,Color("9abdc8"))
	draw_rect(Rect2(0,117,tempo_noticia/DURACAO*320,2),Color("efb6d1"))
