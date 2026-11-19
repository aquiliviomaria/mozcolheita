extends RefCounted
## Malhas partilhadas com cor por vértice; sem materiais por folha nem recursos externos.
static func triangulo(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,cor: Color) -> void:
	s.set_color(cor.srgb_to_linear()); s.set_smooth_group(0)
	s.add_vertex(a); s.add_vertex(c); s.add_vertex(b)

static func tubo(s: SurfaceTool,a: Vector3,b: Vector3,raio: float,cor: Color,raio_fim: float = -1.0,lados: int = 7) -> void:
	var eixo: Vector3 = (b-a).normalized()
	var u: Vector3 = eixo.cross(Vector3.RIGHT if absf(eixo.y)>0.9 else Vector3.UP).normalized()
	var v: Vector3 = eixo.cross(u).normalized()
	var fim: float = raio if raio_fim<0 else raio_fim
	for i: int in range(lados):
		var d0: Vector3 = u*cos(TAU*i/lados)+v*sin(TAU*i/lados)
		var d1: Vector3 = u*cos(TAU*(i+1)/lados)+v*sin(TAU*(i+1)/lados)
		triangulo(s,a+d0*raio,a+d1*raio,b+d1*fim,cor)
		triangulo(s,a+d0*raio,b+d1*fim,b+d0*fim,cor)
		triangulo(s,b,b+d0*fim,b+d1*fim,cor)
		triangulo(s,a,a+d1*raio,a+d0*raio,cor)

static func oval(s: SurfaceTool,centro: Vector3,escala: Vector3,cor: Color,lados: int = 10,aneis: int = 6) -> void:
	for j: int in range(aneis):
		for i: int in range(lados):
			var p: Array[Vector3] = []
			for canto: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var latitude: float = PI*(j+canto.y)/aneis
				var longitude: float = TAU*(i+canto.x)/lados
				p.append(centro+Vector3(sin(latitude)*cos(longitude),cos(latitude),sin(latitude)*sin(longitude))*escala)
			triangulo(s,p[0],p[1],p[2],cor); triangulo(s,p[0],p[2],p[3],cor)

static func folha(s: SurfaceTool,base: Vector3,ponta: Vector3,largura: float,cor: Color,curva: float = 0.12,nervura: bool = true) -> void:
	var eixo: Vector3 = ponta-base
	var lado: Vector3 = eixo.cross(Vector3.UP).normalized()
	if lado.length()<0.5: lado = Vector3.RIGHT
	for i: int in range(5):
		var pontos: Array[Vector3] = []
		for canto: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
			var t: float = float(i+canto.y)/5
			var centro: Vector3 = base+eixo*t+Vector3.UP*sin(t*PI)*curva
			pontos.append(centro+lado*(canto.x*2-1)*sin(t*PI)*largura)
		triangulo(s,pontos[0],pontos[1],pontos[2],cor); triangulo(s,pontos[0],pontos[2],pontos[3],cor.darkened(0.04))
	if nervura:
		var anterior: Vector3 = base
		for i: int in range(1,5):
			var t: float = float(i)/5
			var actual: Vector3 = base+eixo*t+Vector3.UP*(sin(t*PI)*curva+0.003)
			tubo(s,anterior,actual,0.0025,cor.lightened(0.12),0.0015,4); anterior = actual

static func terminar(s: SurfaceTool) -> ArrayMesh:
	s.generate_normals(); s.index()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.86
	s.set_material(material)
	return s.commit()
