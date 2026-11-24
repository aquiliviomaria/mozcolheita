extends RefCounted
## Arquitectura com vãos reais, lajes de betão, escadas e estrutura sempre visível.
const BASE: float = 0.64
const PISO: float = 5.64
const COR: Color = Color("c6bdac")
static func bloco(c: Node3D,p: Vector3,t: Vector3,cor: Color,solido: bool = true,superior: bool = false) -> Node3D:
	var n: Node3D = c.mundo.caixa(c,p,t,cor,solido)
	if superior: c.piso_superior.append(n)
	return n
static func parede(c: Node3D,horizontal: bool,fixo: float,inicio: float,fim: float,y: float,vaos: Array[Dictionary],superior: bool) -> void:
	var cursor: float = inicio
	for v: Dictionary in vaos:
		var a: float = float(v.centro)-float(v.largura)/2; var b: float = a+float(v.largura)
		if a>cursor: trecho(c,horizontal,fixo,(cursor+a)/2,a-cursor,y+2.35,4.7,superior)
		var baixo: float = float(v.get("baixo",1.2)); var alto: float = float(v.get("alto",3.4))
		if baixo>0: trecho(c,horizontal,fixo,float(v.centro),float(v.largura),y+baixo/2,baixo,superior)
		if alto<4.7: trecho(c,horizontal,fixo,float(v.centro),float(v.largura),y+(alto+4.7)/2,4.7-alto,superior)
		if baixo>0:
			var p: Vector3 = Vector3(v.centro,y+(baixo+alto)/2,fixo) if horizontal else Vector3(fixo,y+(baixo+alto)/2,v.centro)
			var janela: Node3D = c.vidro(p,Vector3(v.largura,alto-baixo,0.08) if horizontal else Vector3(0.08,alto-baixo,v.largura))
			if superior: c.piso_superior.append(janela)
			for borda: float in [a,b]:
				bloco(c,Vector3(borda,y+(baixo+alto)/2,fixo) if horizontal else Vector3(fixo,y+(baixo+alto)/2,borda),Vector3(0.12,alto-baixo+0.2,0.32) if horizontal else Vector3(0.32,alto-baixo+0.2,0.12),Color("765337"),false,superior)
		cursor = b
	if cursor<fim: trecho(c,horizontal,fixo,(cursor+fim)/2,fim-cursor,y+2.35,4.7,superior)
static func trecho(c: Node3D,h: bool,f: float,centro: float,largura: float,y: float,altura: float,s: bool) -> void:
	bloco(c,Vector3(centro,y,f) if h else Vector3(f,y,centro),Vector3(largura,altura,0.3) if h else Vector3(0.3,altura,largura),COR,true,s)
static func divisoria(c: Node3D,x: float,z0: float,z1: float,y: float,porta0: float,porta1: float,superior: bool) -> void:
	for trecho_z: Vector2 in [Vector2(z0,porta0),Vector2(porta1,z1)]:
		if trecho_z.y>trecho_z.x: bloco(c,Vector3(x,y+2.35,(trecho_z.x+trecho_z.y)/2),Vector3(0.22,4.7,trecho_z.y-trecho_z.x),COR,true,superior)
	bloco(c,Vector3(x,y+4.25,(porta0+porta1)/2),Vector3(0.22,0.9,porta1-porta0),COR,true,superior)
static func construir(c: Node3D) -> void:
	bloco(c,Vector3(0,0.5,0),Vector3(33,0.28,23),Color("9b8a6b"))
	for piso: int in range(2):
		var y: float = BASE+piso*5
		var frente: Array[Dictionary] = [{"centro":-10.0,"largura":3.0},{"centro":-5.0,"largura":3.0},{"centro":0.0,"largura":3.2,"baixo":0.0 if piso==0 else 1.0,"alto":3.8 if piso==0 else 3.5},{"centro":5.0,"largura":3.0},{"centro":10.0,"largura":3.0}]
		# A faixa central superior recebe o logótipo, sem vidro atrás.
		if piso==1: frente.remove_at(2)
		parede(c,true,11,-16,16,y,frente,piso==1)
		parede(c,true,-11,-16,16,y,[{"centro":-4.0,"largura":3.0},{"centro":8.0,"largura":3.0}],piso==1)
		for lado: float in [-1,1]: parede(c,false,lado*16,-11,11,y,[{"centro":-7.0,"largura":3.5},{"centro":6.0,"largura":3.5}],piso==1)
	# A laje superior tem uma abertura real de 5 x 11.5 m para as escadas.
	for r: Rect2 in [Rect2(-9,-11,2,22),Rect2(-3,-11,19,22),Rect2(-7,-11,4,4),Rect2(-7,-3,4,14),Rect2(-16,4,7,7),Rect2(-16,-11,7,3.5)]:
		bloco(c,Vector3(r.get_center().x,5.44,r.get_center().y),Vector3(r.size.x,0.4,r.size.y),Color("b9b8a5"),true,true)
	# Sala, corredor e cozinha em baixo; quarto e casa de banho em cima.
	divisoria(c,-2,0,11,BASE,4,7,false); divisoria(c,2,-11,5,BASE,-2,1,false)
	bloco(c,Vector3(8.9,2.99,5),Vector3(13.8,4.7,0.22),COR)
	divisoria(c,2,-11,0,PISO,-7,-4,true)
	divisoria(c,2,0,11,PISO,2,5,true)
	bloco(c,Vector3(9,7.99,0),Vector3(14,4.7,0.22),COR,true,true)
	escadas(c)
	for spec: Vector4 in [Vector4(0,10.5,0,0),Vector4(0,5.25,13.5,1)]:
		var t: Node3D = bloco(c,Vector3(spec.x,spec.y,spec.z),Vector3(33,0.32,23) if spec.w==0 else Vector3(33,0.24,5.7),Color("b9b8a5"))
		c.telhado.append(t)
	for x: float in [-15,-7,7,15]: bloco(c,Vector3(x,2.9,15.6),Vector3(0.23,4.5,0.23),Color("eee3c7"))
	bloco(c,Vector3(0,0.48,13.5),Vector3(33,0.32,5),Color("c8b18a"))
	rampa(c,Vector3(-2.2,0,20),Vector3(2.2,BASE,15.9))
	for lado: float in [-1,1]:
		bloco(c,Vector3(lado*9.2,1.55,15.9),Vector3(13.6,0.14,0.16),Color("eee3c7"))
		for i: int in range(19): bloco(c,Vector3(lado*(2.5+i*0.73),1.07,15.9),Vector3(0.07,0.9,0.07),Color("eee3c7"),false)
	# Porta principal de tamanho humano, sob o alpendre.
	c.porta = Node3D.new(); c.porta.name = "PortaPrincipal"; c.porta.position = Vector3(-1.4,BASE,11.22); c.add_child(c.porta)
	var folha: Node3D = c.mundo.caixa(c.porta,Vector3(1.4,1.9,0),Vector3(2.8,3.8,0.16),Color("14532d"),true); folha.name = "Folha"
	c.mundo.caixa(folha,Vector3(1,-0.1,0.15),Vector3(0.1,0.4,0.1),Color("dfac43"))
	var logo: Sprite3D = Sprite3D.new(); logo.name = "LogoSegundoPiso"; logo.texture = preload("res://MozColheita-icon.png"); logo.pixel_size = 0.003; logo.position = Vector3(0,8.2,11.23); c.add_child(logo); c.piso_superior.append(logo)
static func rampa(c: Node3D,a: Vector3,b: Vector3) -> void:
	var pontos: PackedVector3Array = [Vector3(a.x,a.y,b.z),Vector3(b.x,a.y,b.z),Vector3(a.x,b.y,b.z),Vector3(b.x,b.y,b.z),Vector3(a.x,a.y,a.z),Vector3(b.x,a.y,a.z)]
	var corpo: StaticBody3D = StaticBody3D.new(); var forma: ConvexPolygonShape3D = ConvexPolygonShape3D.new(); forma.points = pontos; var col: CollisionShape3D = CollisionShape3D.new(); col.shape = forma; corpo.add_child(col); c.add_child(corpo)
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in [2,3,4,3,5,4]: s.add_vertex(pontos[i])
	s.generate_normals(); var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = s.commit(); vista.material_override = c.mundo.material(Color("b9b8a5")); c.add_child(vista)
static func escadas(c: Node3D) -> void:
	# Degraus visuais + rampa física contínua evitam prender a cápsula do jogador.
	rampa(c,Vector3(-14.5,BASE,4),Vector3(-9.5,PISO,-7.5))
	for i: int in range(25): bloco(c,Vector3(-12,BASE+(i+0.5)*0.2,4-(i+0.5)*0.46),Vector3(5,0.18,0.46),Color("b9b8a5"),false)
	for x: float in [-14.6,-9.4]:
		var corrimao: Node3D = bloco(c,Vector3(x,4.2,-1.75),Vector3(0.14,0.14,12.55),Color("765337")); corrimao.rotation.x = atan2(5,11.5)
		for i: int in range(7): bloco(c,Vector3(x,BASE+0.6+i*5.0/6,4-i*11.5/6),Vector3(0.12,1.2,0.12),Color("765337"),false)

	# Guarda-corpo no perímetro do vão superior; a chegada z=-7.5 continua livre.
	for x: float in [-14.7,-9.3]:
		var barra: Node3D = bloco(c,Vector3(x,PISO+1.12,-1.7),Vector3(0.09,0.09,11.5),Color("455257"),true,true); barra.name = "GuardaCorpoFerro"
		for i: int in range(13): bloco(c,Vector3(x,PISO+0.55,-7.2+i*0.91),Vector3(0.055,1.1,0.055),Color("455257"),false,true)
		# Barreira contínua invisível entre montantes impede cair pelas aberturas.
		var corpo: StaticBody3D = StaticBody3D.new(); var col: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new(); forma.size = Vector3(0.12,1.15,11.5); col.shape = forma; corpo.position = Vector3(x,PISO+0.575,-1.7); corpo.add_child(col); c.add_child(corpo)
	bloco(c,Vector3(-12,PISO+1.12,4.08),Vector3(5.5,0.09,0.09),Color("455257"),true,true)
	for i: int in range(7): bloco(c,Vector3(-14.7+i*0.9,PISO+0.55,4.08),Vector3(0.055,1.1,0.055),Color("455257"),true,true)
