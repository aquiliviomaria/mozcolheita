extends Node3D
## Cada cultura tem anatomia própria, quatro etapas e geometria partilhada entre plantas.
const G: GDScript = preload("res://scripts/geometry.gd")
const NOMES: Array[String] = ["Tomate","Milho","Couve","Cenoura"]
const CORES: Array[Color] = [Color("b8412e"),Color("d6b85e"),Color("5f8151"),Color("bd652d")]
const FAMILIAS: Array[String] = ["solanaceas","cereais","brassicas","raizes"]
const DURACAO: float = 60.0
var mundo: Node3D
var lotes: Array[MultiMeshInstance3D] = []
var modelos: Dictionary = {}

func _ready() -> void:
	for cultura: int in range(4):
		for etapa: int in range(4):
			var lote: MultiMeshInstance3D = MultiMeshInstance3D.new()
			lote.multimesh = MultiMesh.new(); lote.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			lote.multimesh.mesh = modelo(cultura,etapa)
			add_child(lote); lotes.append(lote)

func modelo(cultura: int,etapa: int,distante: bool = false) -> ArrayMesh:
	var chave: String = "%d:%d:%s" % [cultura,etapa,distante]
	if modelos.has(chave): return modelos[chave]
	var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	if etapa==0:
		for i: int in range(3): G.oval(s,Vector3((i-1)*0.07,0.018,0),Vector3(0.018,0.012,0.03),Color("987451"),6,4)
	else:
		match cultura:
			0: tomate(s,etapa,distante)
			1: milho(s,etapa,distante)
			2: couve(s,etapa,distante)
			3: cenoura(s,etapa,distante)
	var malha: ArrayMesh = G.terminar(s)
	modelos[chave] = malha
	return malha

func tomate(s: SurfaceTool,etapa: int,distante: bool) -> void:
	var altura: float = [0.0,0.18,0.62,0.96][etapa]
	var verde: Color = Color("3d6635")
	G.tubo(s,Vector3.ZERO,Vector3(0,altura,0),0.012,verde,0.006)
	var ramos: int = 3 if etapa==1 else 5 if distante else 7
	for i: int in range(ramos):
		var angulo: float = i*2.4
		var origem: Vector3 = Vector3(0,altura*(0.22+0.65*float(i)/ramos),0)
		var ponta: Vector3 = origem+Vector3(cos(angulo)*altura*0.36,altura*0.12,sin(angulo)*altura*0.36)
		G.tubo(s,origem,ponta,0.006,verde,0.003,5)
		for j: int in range(1,4):
			var base: Vector3 = origem.lerp(ponta,float(j)/3)
			for lado: float in [-1.0,1.0]:
				var fim: Vector3 = base+Vector3(cos(angulo+lado),0.2,sin(angulo+lado))*altura*0.19
				G.folha(s,base,fim,altura*0.05,verde.lightened(float(j)*0.015),0.025,not distante)
		if etapa>=2 and i%2==0:
			var fruto: Vector3 = ponta-Vector3(0,0.065,0)
			G.tubo(s,ponta,fruto,0.004,verde,0.003,4)
			G.oval(s,fruto-Vector3.UP*0.04,Vector3(0.054,0.045,0.052),Color("b43c29") if etapa==3 else Color("738044"),10,6)
			for estrela: int in range(5):
				var ang: float = estrela*TAU/5
				G.folha(s,fruto,fruto+Vector3(cos(ang)*0.035,-0.009,sin(ang)*0.035),0.007,verde,0,false)

func milho(s: SurfaceTool,etapa: int,distante: bool) -> void:
	var altura: float = [0.0,0.25,1.05,2.15][etapa]
	var verde: Color = Color("536b35")
	G.tubo(s,Vector3.ZERO,Vector3(0,altura,0),0.018,verde,0.008)
	var folhas: int = 4 if etapa==1 else 6 if distante else 9
	for i: int in range(folhas):
		var ang: float = i*2.65
		var base: Vector3 = Vector3(0,altura*(0.12+float(i)*0.7/folhas),0)
		G.folha(s,base,base+Vector3(cos(ang)*altura*0.36,altura*0.06,sin(ang)*altura*0.36),altura*0.045,verde.lightened(0.06 if i%2==0 else 0),altura*0.12,not distante)
	if etapa==3:
		for lado: float in [-1.0,1.0]:
			var espiga: Vector3 = Vector3(lado*0.08,1.1+lado*0.15,0)
			G.oval(s,espiga,Vector3(0.047,0.19,0.047),Color("c6a54d"),8,6)
			G.folha(s,espiga-Vector3.UP*0.2,espiga+Vector3(lado*0.16,0.16,0),0.055,verde,0.06,not distante)
			G.tubo(s,espiga+Vector3.UP*0.16,espiga+Vector3(0.02,0.24,0),0.012,Color("796245"),0.002,5)
		for i: int in range(5):
			var a: float = TAU*i/5
			G.tubo(s,Vector3(0,altura*0.92,0),Vector3(cos(a)*0.16,altura+0.12,sin(a)*0.16),0.008,Color("b09a63"),0.002,4)

func couve(s: SurfaceTool,etapa: int,distante: bool) -> void:
	var raio: float = [0.0,0.08,0.2,0.34][etapa]
	var folhas: int = 6 if distante else 10
	if etapa>=2:
		# Cabeça compacta de folhas enroladas, rodeada pela roseta exterior.
		G.oval(s,Vector3(0,raio*0.68,0),Vector3(raio*0.53,raio*0.52,raio*0.53),Color("8f9e6b"),12 if distante else 18,8)
		for i: int in range(6):
			var ang: float = i*TAU/6
			var base: Vector3 = Vector3(cos(ang)*raio*0.42,raio*0.55,sin(ang)*raio*0.42)
			var ponta: Vector3 = Vector3(cos(ang)*raio*0.08,raio*1.15,sin(ang)*raio*0.08)
			G.folha(s,base,ponta,raio*0.18,Color("94a276").darkened(i%2*0.04),raio*0.08,not distante)
	for anel: int in range(2 if etapa<3 else 3):
		for i: int in range(folhas):
			var ang: float = i*TAU/folhas+anel*0.4
			var base: Vector3 = Vector3(cos(ang),0,sin(ang))*raio*0.12
			base.y = 0.03+anel*raio*0.26
			var fim: Vector3 = Vector3(cos(ang),0,sin(ang))*raio*(1.1-anel*0.35)
			fim.y = raio*(0.22+anel*0.3)
			G.folha(s,base,fim,raio*(0.58-anel*0.08),Color("668454").lightened(anel*0.1),raio*(0.35+anel*0.12),not distante)

func cenoura(s: SurfaceTool,etapa: int,distante: bool) -> void:
	var altura: float = [0.0,0.1,0.28,0.43][etapa]
	if etapa>=2: G.tubo(s,Vector3(0,0.085,0),Vector3(0,-0.07,0),0.032,Color("c16a31"),0.004,8)
	for i: int in range(5 if distante else 8):
		var ang: float = i*2.4
		var ponta: Vector3 = Vector3(cos(ang)*altura*0.45,altura,sin(ang)*altura*0.45)
		G.tubo(s,Vector3.ZERO,ponta,0.004,Color("527a3d"),0.002,4)
		for j: int in range(1,5):
			var base: Vector3 = ponta*float(j)/5
			for lado: float in [-1.0,1.0]:
				G.folha(s,base,base+Vector3(cos(ang+lado)*altura*0.25,altura*0.08,sin(ang+lado)*altura*0.25),altura*0.025,Color("567d3f"),0.015,false)

func actualizar() -> void:
	var grupos: Array[Array] = []
	for i: int in range(16): grupos.append([])
	for chave: Vector2i in mundo.terreno.celulas:
		var dados: Dictionary = mundo.terreno.celulas[chave]
		if int(dados.estado)<2: continue
		var etapa: int = 0 if int(dados.estado)==2 else 3 if int(dados.estado)==5 else mini(2,1+int(float(dados.tempo)/30))
		var ponto: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5); ponto.y = mundo.altura(ponto)+0.035
		var giro: Basis = Basis(Vector3.UP,float(posmod(chave.x*17+chave.y*31,100))*0.0628)
		grupos[int(dados.cultura)*4+etapa].append(Transform3D(giro,ponto))
	for i: int in range(16):
		lotes[i].multimesh.instance_count = grupos[i].size()
		for j: int in range(grupos[i].size()): lotes[i].multimesh.set_instance_transform(j,grupos[i][j])
