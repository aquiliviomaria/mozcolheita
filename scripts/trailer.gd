extends Node3D
## Reboque com carga própria: transfere produtos entre sacola, armazém e fábricas.
const NOMES: Array[String] = ["","","","","Carrinha de colheita"]
const CAPACIDADE: int = 120
var distancia_engate: float = 4.8
var volume: Vector3 = Vector3(2.65,1.5,3.7)
var centro_colisao: Vector3 = Vector3(0,0.9,0)
var mundo: Node3D
var tipo: int = 4
var tractor: CharacterBody3D
var activo: bool = false
var carga: Dictionary = {}
var sinal: MeshInstance3D
var caixas: Array[MeshInstance3D] = []
var corpo: StaticBody3D

func _ready() -> void:
	add_to_group("reboques")
	mundo.caixa(self,Vector3(0,0.75,0),Vector3(2.2,0.18,3.6),Color("4a6152"))
	for lado: float in [-1.0,1.0]:
		mundo.caixa(self,Vector3(lado*1.1,1.14,0),Vector3(0.10,0.75,3.65),Color("6b7961"))
		mundo.caixa(self,Vector3(lado*0.55,0.55,-2.25),Vector3(0.10,0.12,1.3),Color("454e46"))
		for z: float in [-0.85,0.85]:
			var roda: MeshInstance3D = MeshInstance3D.new()
			var pneu: CylinderMesh = CylinderMesh.new(); pneu.top_radius = 0.42; pneu.bottom_radius = 0.42; pneu.height = 0.28; pneu.radial_segments = 20
			roda.mesh = pneu; roda.rotation.z = PI/2; roda.position = Vector3(lado*1.2,0.43,z)
			roda.material_override = mundo.material(Color("292e2b")); add_child(roda)
	for z: float in [-1.8,1.8]: mundo.caixa(self,Vector3(0,1.12,z),Vector3(2.2,0.75,0.08),Color("6b7961"))
	for i: int in range(6):
		var caixa: MeshInstance3D = mundo.caixa(self,Vector3(-0.5+(i%2),1.1,-1.1+floorf(float(i)/2)*1.1),Vector3(0.85,0.5,0.9),Color("9a7953"))
		caixa.hide(); caixas.append(caixa)
	corpo = StaticBody3D.new(); corpo.collision_layer = 8; add_child(corpo)
	var colisor: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(2.65,1.5,3.7); colisor.shape = forma; colisor.position.y = 0.9; corpo.add_child(colisor)
	sinal = mundo.caixa(self,Vector3(0,2.2,0),Vector3(0.22,0.22,0.22),Color("65fc98"))
	mundo.placa(self,Vector3(0,2.6,0),"CARRINHA · 120 un.").visibility_range_end = 14

func total() -> int:
	var quantidade: int = 0
	for valor: int in carga.values(): quantidade += valor
	return quantidade

func carregar(origem: Dictionary) -> int:
	var movidas: int = 0
	for cultura: int in origem.keys():
		var quantidade: int = mini(maxi(0,int(origem[cultura])),CAPACIDADE-total())
		if quantidade<=0: continue
		carga[cultura] = int(carga.get(cultura,0))+quantidade
		origem[cultura] = int(origem[cultura])-quantidade
		if int(origem[cultura])==0: origem.erase(cultura)
		movidas += quantidade
	actualizar_carga(); return movidas

func actualizar_carga() -> void:
	for i: int in range(caixas.size()): caixas[i].visible = total()>i*20

func disponivel(veiculo: Node3D) -> bool:
	return tractor==null and veiculo!=null and veiculo.implemento==null and absf(veiculo.rapidez)<0.3 and preload("res://scripts/layout.gd").distancia(global_position,veiculo.global_position)<5.5 and preload("res://scripts/clearance.gd").livre(mundo,veiculo,self)

func acoplar(veiculo: CharacterBody3D) -> bool:
	if not disponivel(veiculo): return false
	if not preload("res://scripts/clearance.gd").livre(mundo,veiculo,self):
		mundo.avisar("Liberte o espaço atrás do tractor antes de engatar.")
		return false
	tractor = veiculo; veiculo.implemento = self; veiculo.add_collision_exception_with(corpo)
	global_position = tractor.to_global(Vector3(0,0,4.8)); rotation.y = tractor.rotation.y
	return true

func soltar() -> void:
	if tractor==null: return
	tractor.remove_collision_exception_with(corpo); tractor.implemento = null; tractor = null
	global_position.y = mundo.altura(global_position); activo = false

func transferir() -> int:
	if tractor==null or absf(tractor.rapidez)>0.3: return 0
	var plano: GDScript = preload("res://scripts/layout.gd")
	for fabrica: Node3D in mundo.fabricas:
		if plano.distancia(tractor.global_position,fabrica.global_position+Vector3(0,0,-42))<15:
			var entregues: int = mundo.entregas.entregar(carga,fabrica.numero)
			var receita: int = mundo.economia.vender(carga,fabrica.numero); actualizar_carga(); return receita+entregues
	if mundo.armazem.perto():
		if not carga.is_empty():
			var quantidade: int = total(); mundo.depositar(carga); actualizar_carga(); mundo.avisar("Carrinha descarregada no armazém."); return quantidade
		mundo.armazem.solicitar_carga(self); return 0
	var recolhidas: int = carregar(mundo.sacola)
	mundo.avisar("Carrinha: %d/%d unidades" % [total(),CAPACIDADE]); return recolhidas

func _physics_process(_delta: float) -> void:
	sinal.visible = disponivel(mundo.trator_actual) and not mundo.pausado()
	if tractor==null: return
	var alvo: Vector3 = tractor.to_global(Vector3(0,0,4.8))
	global_position = alvo; global_position.y = mundo.altura(alvo)
	rotation.y = tractor.rotation.y
