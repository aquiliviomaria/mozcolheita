extends RefCounted
## Malhas de carroçaria e rodas partilhadas. Detalhes estáticos num único desenho.
const G: GDScript = preload("res://scripts/geometry.gd")
static var modelos: Dictionary = {}
static var pneus: Dictionary = {}
static func bloco(s: SurfaceTool,p: Vector3,t: Vector3,cor: Color,chanfro: float = 0.08) -> void:
	var hx: float = t.x/2; var hy: float = t.y/2; var hz: float = t.z/2
	var c: float = minf(chanfro,minf(hx,hy)*0.5)
	var anel: Array[Vector2] = [Vector2(-hx+c,-hy),Vector2(hx-c,-hy),Vector2(hx,-hy+c),Vector2(hx,hy-c),Vector2(hx-c,hy),Vector2(-hx+c,hy),Vector2(-hx,hy-c),Vector2(-hx,-hy+c)]
	var aneis: Array[Array] = []
	for z: float in [-hz,-hz+minf(chanfro,hz*0.4),hz-minf(chanfro,hz*0.4),hz]:
		var pontos: Array[Vector3] = []
		var escala: float = 0.94 if absf(z)==hz else 1.0
		for v: Vector2 in anel: pontos.append(p+Vector3(v.x*escala,v.y*escala,z))
		aneis.append(pontos)
	for j: int in range(3):
		for i: int in range(8):
			var k: int = (i+1)%8
			G.triangulo(s,aneis[j][i],aneis[j+1][i],aneis[j+1][k],cor); G.triangulo(s,aneis[j][i],aneis[j+1][k],aneis[j][k],cor)
	for i: int in range(8):
		G.triangulo(s,p+Vector3(0,0,-hz),aneis[0][i],aneis[0][(i+1)%8],cor)
		G.triangulo(s,p+Vector3(0,0,hz),aneis[3][(i+1)%8],aneis[3][i],cor)
static func vidro(s: SurfaceTool,p: Vector3,t: Vector3) -> void:
	bloco(s,p,t,Color("31586b"),0.04)
	# Reflexo pintado mantém a leitura do vidro sem transparências caras.
	bloco(s,p+Vector3(0,t.y*0.25,-0.006),Vector3(t.x*0.78,0.04,t.z+0.012),Color("91bec8"),0.01)
static func modelo(tipo: int,variante: int) -> ArrayMesh:
	var chave: String = "%d:%d" % [tipo,variante%5]
	if modelos.has(chave): return modelos[chave]
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cor: Color = [Color("bd4f39"),Color("e1c27c"),Color("e2e7dc"),Color("467f9b"),Color("397b59")][variante%5]
	var borracha: Color = Color("263237"); var metal: Color = Color("b6c1bb")
	if tipo==0:
		bloco(s,Vector3(0,0.67,0),Vector3(1.78,0.63,3.7),cor,0.2)
		bloco(s,Vector3(0,0.99,-1.12),Vector3(1.65,0.22,1.25),cor,0.12)
		bloco(s,Vector3(0,1.25,0.08),Vector3(1.53,0.76,1.94),cor,0.18)
		vidro(s,Vector3(0,1.32,-0.91),Vector3(1.3,0.48,0.035))
		vidro(s,Vector3(0,1.32,1.065),Vector3(1.28,0.44,0.035))
		for lado: float in [-1,1]:
			for z: float in [-0.42,0.49]: vidro(s,Vector3(lado*0.77,1.32,z),Vector3(0.025,0.45,0.72))
			bloco(s,Vector3(lado*0.90,1.17,-0.73),Vector3(0.19,0.14,0.24),cor,0.045)
			for z: float in [-0.3,0.6]: bloco(s,Vector3(lado*0.898,0.95,z),Vector3(0.025,0.045,0.18),metal,0.01)
			bloco(s,Vector3(lado*0.61,0.84,-1.86),Vector3(0.4,0.18,0.045),Color("fff1bf"),0.03)
			bloco(s,Vector3(lado*0.64,0.84,1.86),Vector3(0.3,0.2,0.045),Color("c63e35"),0.03)
		bloco(s,Vector3(0,0.57,-1.9),Vector3(1.55,0.16,0.12),borracha,0.04)
		bloco(s,Vector3(0,0.74,-1.89),Vector3(0.65,0.18,0.06),borracha,0.02)
		for x: float in [-0.22,0,0.22]: bloco(s,Vector3(x,0.74,-1.925),Vector3(0.025,0.13,0.02),metal,0.005)
		bloco(s,Vector3(0,0.57,1.89),Vector3(1.55,0.14,0.12),borracha,0.03)
	elif tipo==1:
		cor = [Color("e3d8b7"),Color("487f9e"),Color("b85b3f"),Color("4a8967"),Color("d5ac4c")][variante%5]
		bloco(s,Vector3(0,0.65,0.2),Vector3(1.8,0.27,6.1),borracha)
		bloco(s,Vector3(0,1.08,-1.82),Vector3(1.8,0.95,2.12),cor,0.14)
		bloco(s,Vector3(0,1.89,-1.71),Vector3(1.72,0.74,1.8),cor,0.14)
		vidro(s,Vector3(0,1.89,-2.62),Vector3(1.42,0.49,0.035))
		for lado: float in [-1,1]:
			vidro(s,Vector3(lado*0.87,1.9,-1.72),Vector3(0.025,0.48,1.26))
			bloco(s,Vector3(lado*1.03,1.8,-2.24),Vector3(0.15,0.36,0.17),borracha,0.03)
			bloco(s,Vector3(lado*0.64,1.11,-2.91),Vector3(0.33,0.21,0.055),Color("fff0c1"))
		bloco(s,Vector3(0,1.6,1.31),Vector3(1.9,1.65,3.45),Color("d7d2b9"),0.12)
		for z: float in [-0.15,0.5,1.15,1.8,2.45]:
			for lado: float in [-1,1]: bloco(s,Vector3(lado*0.96,1.6,z),Vector3(0.025,1.4,0.055),metal,0.005)
		bloco(s,Vector3(0,0.86,-2.91),Vector3(1.8,0.2,0.14),metal)
		bloco(s,Vector3(0,1.17,-2.92),Vector3(0.8,0.3,0.03),borracha)
		for lado: float in [-1,1]: bloco(s,Vector3(lado*0.7,0.8,3.1),Vector3(0.3,0.18,0.05),Color("c33e2e"))
	else:
		cor = [Color("238b45"),Color("b95836"),Color("397e98"),Color("ceaa42"),Color("436d3c")][variante%5]
		bloco(s,Vector3(0,0.76,0),Vector3(1.5,0.24,3.6),borracha)
		bloco(s,Vector3(0,1.17,-1.1),Vector3(1.23,0.83,1.8),cor,0.14)
		bloco(s,Vector3(0,1.18,-2.02),Vector3(0.94,0.5,0.045),borracha)
		for x: float in [-0.3,-0.15,0,0.15,0.3]: bloco(s,Vector3(x,1.18,-2.05),Vector3(0.035,0.4,0.015),metal,0.005)
		for lado: float in [-1,1]:
			bloco(s,Vector3(lado*0.88,1.32,1.1),Vector3(0.46,0.14,1.52),cor)
			G.tubo(s,Vector3(lado*0.64,1,0.1),Vector3(lado*0.64,2.5,0.1),0.035,borracha)
			G.tubo(s,Vector3(lado*0.64,1,1.3),Vector3(lado*0.64,2.5,1.3),0.035,borracha)
			bloco(s,Vector3(lado*0.43,1.45,-2.06),Vector3(0.22,0.16,0.04),Color("fff0b9"))
		bloco(s,Vector3(0,2.55,0.68),Vector3(1.8,0.16,1.9),cor,0.1)
		bloco(s,Vector3(0,1.13,0.67),Vector3(0.55,0.18,0.55),borracha)
		bloco(s,Vector3(0,1.44,0.95),Vector3(0.55,0.56,0.14),borracha)
		G.tubo(s,Vector3(0.46,1.4,-1.2),Vector3(0.46,2.3,-1.2),0.055,borracha)
		bloco(s,Vector3(0,0.6,2),Vector3(0.25,0.2,0.8),metal)
	var malha: ArrayMesh = G.terminar(s); var pintura: StandardMaterial3D = malha.surface_get_material(0); pintura.roughness = 0.42; pintura.metallic = 0.12
	modelos[chave] = malha; return malha
static func roda(pai: Node3D,posicao: Vector3,raio: float,largura: float,agricola: bool = false) -> Node3D:
	var chave: String = "%s:%s:%s" % [raio,largura,agricola]
	if not pneus.has(chave):
		var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
		G.tubo(s,Vector3(0,-largura/2,0),Vector3(0,largura/2,0),raio,Color("222b2c"),raio,20)
		for lado: float in [-1,1]:
			G.tubo(s,Vector3(0,lado*largura*0.51,0),Vector3(0,lado*largura*0.54,0),raio*0.55,Color("acb9b3"),raio*0.53,16)
			G.tubo(s,Vector3(0,lado*largura*0.55,0),Vector3(0,lado*largura*0.58,0),raio*0.19,Color("586b6b"),raio*0.19,12)
			for i: int in range(6):
				var p: Vector3 = Vector3(cos(i*TAU/6)*raio*0.36,lado*largura*0.57,sin(i*TAU/6)*raio*0.36)
				G.oval(s,p,Vector3.ONE*raio*0.045,Color("374546"),6,3)
		for i: int in range(16):
			var a: float = i*TAU/16; var direccao: Vector3 = Vector3(cos(a),0,sin(a))
			G.tubo(s,direccao*(raio-0.015)+Vector3(0,-largura*0.4,0),direccao*(raio+0.005)+Vector3(0,largura*0.4,0),0.035 if agricola else 0.012,Color("37403a"),-1,5)
		pneus[chave] = G.terminar(s)
	var n: MeshInstance3D = MeshInstance3D.new(); n.mesh = pneus[chave]; n.position = posicao; n.rotation.z = PI/2; pai.add_child(n); return n
static func criar_trafego(pai: Node3D,tipo: int,variante: int) -> Array[Node3D]:
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = modelo(tipo,variante); pai.add_child(vista)
	var rodas: Array[Node3D] = []
	for lado: float in [-1,1]:
		var eixos: Array[float] = []
		eixos.assign([-1.2,1.2] if tipo==0 else [-1.85,1.7,2.65] if tipo==1 else [-1.25,1.13])
		for z: float in eixos:
			var raio: float = 0.38 if tipo==0 else 0.48 if tipo==1 else 0.72 if z>0 else 0.44
			rodas.append(roda(pai,Vector3(lado*(0.86 if tipo==0 else 0.91),raio,z),raio,0.26 if tipo!=2 else 0.38,tipo==2))
	return rodas
static func polir_caminhao(pai: Node3D) -> void:
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	bloco(s,Vector3(0,1.4,-2.7),Vector3(2.5,0.9,1.3),Color("238b45"),0.17)
	bloco(s,Vector3(0,1.2,-3.39),Vector3(1.4,0.43,0.055),Color("253b36"),0.04)
	for x: float in [-0.5,-0.25,0,0.25,0.5]: bloco(s,Vector3(x,1.2,-3.43),Vector3(0.045,0.32,0.015),Color("c8d0bd"),0.005)
	bloco(s,Vector3(0,0.89,-3.5),Vector3(2.6,0.2,0.23),Color("a4b5a8"),0.07)
	bloco(s,Vector3(0,1.83,-2.78),Vector3(2.38,0.08,1.15),Color("327e43"),0.04)
	for lado: float in [-1,1]:
		bloco(s,Vector3(lado*1.45,2.3,-2.35),Vector3(0.18,0.48,0.25),Color("31403c"),0.04)
		bloco(s,Vector3(lado*1.45,2.3,-2.2),Vector3(0.13,0.37,0.04),Color("8faeb0"),0.02)
		bloco(s,Vector3(lado*1.32,0.85,-1.5),Vector3(0.3,0.12,1.1),Color("95a69b"),0.03)
		bloco(s,Vector3(lado*1.35,1.72,-1.05),Vector3(0.035,0.07,0.3),Color("c7d1ba"),0.01)
		bloco(s,Vector3(lado*0.91,1.45,-3.4),Vector3(0.38,0.24,0.08),Color("fff3c8"),0.04)
		bloco(s,Vector3(lado*1.12,1.4,-3.41),Vector3(0.12,0.19,0.08),Color("e3a048"),0.02)
		bloco(s,Vector3(lado*1.05,1.16,3.78),Vector3(0.35,0.18,0.06),Color("cf4635"),0.03)
		bloco(s,Vector3(lado*1.38,0.55,3.45),Vector3(0.12,0.7,0.44),Color("283a34"),0.025)
	bloco(s,Vector3(0,2.94,-2.7),Vector3(2.68,0.12,0.4),Color("14532d"),0.06)
	var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = G.terminar(s); pai.add_child(vista)
