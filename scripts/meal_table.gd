extends Node3D
## Ementas visuais pré-construídas: muda a refeição sem gerar malhas a cada frame.
const NOMES: Array[String] = ["Xima, matapa e tomate","Arroz, feijão e legumes","Milho assado e salada","Pão, fruta e chá"]
var mundo: Node3D
var menus: Array[Node3D] = []
var indice: int = -1
var servida: bool = false
var legenda: Label3D
static var bocados: Dictionary = {}
func oval(pai: Node3D,p: Vector3,t: Vector3,cor: String) -> MeshInstance3D:
	var n: MeshInstance3D = MeshInstance3D.new(); var m: SphereMesh = SphereMesh.new(); m.radius = 0.5; m.height = 1; m.radial_segments = 12; m.rings = 6; n.mesh = m; n.position = p; n.scale = t; n.material_override = mundo.material(Color(cor)); pai.add_child(n); return n
func prato(pai: Node3D,p: Vector3) -> void:
	var n: MeshInstance3D = MeshInstance3D.new(); var m: CylinderMesh = CylinderMesh.new(); m.top_radius = 0.47; m.bottom_radius = 0.42; m.height = 0.045; m.radial_segments = 24; n.mesh = m; n.position = p; n.material_override = mundo.material(Color("f8e9cb")); pai.add_child(n)
func _ready() -> void:
	name = "RefeicaoNaMesa"; position = Vector3(8,1.45,0)
	for x: float in [-1.2,1.2]: prato(self,Vector3(x,0,0.25))
	for menu: int in range(NOMES.size()):
		var n: Node3D = Node3D.new(); n.name = "Ementa%d" % menu; add_child(n); menus.append(n)
		for x: float in [-1.2,1.2]:
			match menu:
				0:
					oval(n,Vector3(x-0.15,0.13,0.25),Vector3(0.39,0.22,0.4),"eee4c8")
					for j: int in range(5): oval(n,Vector3(x+0.19+sin(j*2.4)*0.09,0.07,0.2+cos(j*2.4)*0.16),Vector3(0.17,0.09,0.14),"386a32")
					oval(n,Vector3(x-0.19,0.08,0.51),Vector3(0.19,0.08,0.18),"cf3e27")
				1:
					oval(n,Vector3(x-0.16,0.09,0.25),Vector3(0.38,0.14,0.45),"f2e6c3")
					for j: int in range(10): oval(n,Vector3(x+0.09+(j%3)*0.07,0.065+(j/6)*0.04,0.08+(j/3)*0.09),Vector3(0.075,0.065,0.11),"8b4031")
					oval(n,Vector3(x,0.075,0.52),Vector3(0.22,0.08,0.14),"d38937")
				2:
					for j: int in range(7): oval(n,Vector3(x-0.15,0.13,0.05+j*0.06),Vector3(0.19,0.19,0.1),"e2bd42")
					for j: int in range(4): oval(n,Vector3(x+0.17,0.06,0.08+j*0.12),Vector3(0.21,0.06,0.18),"5a8b3f" if j%2==0 else "d8492d")
				3:
					for j: int in range(2): oval(n,Vector3(x-0.15,0.12,0.12+j*0.23),Vector3(0.29,0.17,0.2),"c99148")
					for j: int in range(3): oval(n,Vector3(x+0.19,0.08,0.07+j*0.16),Vector3(0.19,0.1,0.14),"e8b347" if j%2==0 else "df7844")
			var copo: MeshInstance3D = mundo.caixa(n,Vector3(x,0.13,-0.55),Vector3(0.2,0.25,0.2),Color("729a9b"))
			oval(n,copo.position+Vector3(0,0.13,0),Vector3(0.16,0.015,0.16),"965c32" if menu==3 else "d39b38")
	legenda = mundo.placa(self,Vector3(0,0.3,-0.4),""); legenda.font_size = 22; legenda.pixel_size = 0.003; legenda.visibility_range_end = 5
	mostrar(0)
func mostrar(novo: int) -> void:
	novo = posmod(novo,NOMES.size())
	if novo==indice: return
	indice = novo
	for i: int in range(menus.size()): menus[i].visible = servida and i==indice
	legenda.text = NOMES[indice] if servida else ""
static func bocado(menu: int) -> Mesh:
	var i: int = posmod(menu,4)
	if bocados.has(i): return bocados[i]
	var m: SphereMesh = SphereMesh.new(); m.radius = 0.085; m.height = 0.12; m.radial_segments = 12; m.rings = 6
	var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.albedo_color = Color(["eee4c8","eee1bb","e2bd42","c99148"][i]).srgb_to_linear(); mat.roughness = 0.9; m.material = mat; bocados[i] = m; return m

func servir(valor: bool) -> void:
	servida = valor
	for i: int in range(menus.size()): menus[i].visible = servida and i==indice
	legenda.text = NOMES[indice] if servida else ""
