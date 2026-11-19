extends Node3D
## Engate cinemático: a máquina acompanha o tractor, sem juntas rígidas instáveis.
const NOMES: Array[String] = ["Preparador de solo","Semeadora","Irrigador","Ceifeira"]
const ACOES: Array[String] = ["lavrar","semear","regar","colher"]
const CAPACIDADE_SEMENTES: int = 300
var sementes: int = 300
var distancia_engate: float = 2.8
var volume: Vector3 = Vector3(2.9,1.4,1.9)
var centro_colisao: Vector3 = Vector3(0,0.8,0.3)
var mundo: Node3D
var tipo: int = 0
var tractor: CharacterBody3D
var activo: bool = false
var sinal: MeshInstance3D
var anterior: Vector3 = Vector3.INF
var corpo: StaticBody3D

func _ready() -> void:
	add_to_group("implementos")
	corpo = StaticBody3D.new(); corpo.collision_layer = 8; add_child(corpo)
	var colisor: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(2.9,1.4,1.9); colisor.shape = forma; colisor.position = Vector3(0,0.8,0.3); corpo.add_child(colisor)
	var cor: Color = [Color("cb934d"),Color("547d6c"),Color("92aca6"),Color("a77953")][tipo]
	mundo.caixa(self,Vector3(0,0.5,0.3),Vector3(2.7,0.15,1.2),cor)
	for lado: float in [-1.0,1.0]:
		mundo.caixa(self,Vector3(lado*0.6,0.6,-0.55),Vector3(0.08,0.1,1.0),Color("b6c0b5"))
	if tipo==0:
		for x: int in range(-1,2):
			mundo.caixa(self,Vector3(x,0.25,0.6),Vector3(0.08,0.5,0.08),Color("a6b4b0"))
			var lamina: MeshInstance3D = mundo.caixa(self,Vector3(x,0.06,0.7),Vector3(0.6,0.07,0.5),Color("a6b4b0"))
			lamina.rotation.z = 0.3
	elif tipo==1:
		mundo.caixa(self,Vector3(0,0.95,0.3),Vector3(2.3,0.7,0.9),cor)
		mundo.caixa(self,Vector3(0,1.33,0.3),Vector3(2.4,0.05,1.0),Color("d2d8c9"))
	elif tipo==2:
		mundo.caixa(self,Vector3(0,1,0.3),Vector3(1.7,0.9,1.0),Color("bdd2c6"))
		mundo.caixa(self,Vector3(0,0.8,0.9),Vector3(3.5,0.06,0.08),cor)
		for x: int in range(-1,2): mundo.caixa(self,Vector3(x,0.6,0.9),Vector3(0.04,0.35,0.04),Color("6eb5c5"))
	else:
		mundo.caixa(self,Vector3(0,0.23,0.7),Vector3(2.8,0.3,0.7),cor)
		for x: int in range(12): mundo.caixa(self,Vector3(-1.3+x*0.23,0.12,1.2),Vector3(0.08,0.08,0.6),Color("b6c3ba"))
	sinal = MeshInstance3D.new()
	var anel: TorusMesh = TorusMesh.new()
	anel.inner_radius = 0.16
	anel.outer_radius = 0.24
	sinal.mesh = anel
	var material_sinal: StandardMaterial3D = StandardMaterial3D.new()
	material_sinal.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_sinal.albedo_color = Color("5bff94")
	sinal.material_override = material_sinal
	sinal.position.y = 2.0
	add_child(sinal)
	sinal.hide()

func disponivel(veiculo: Node3D) -> bool:
	return tractor==null and veiculo!=null and veiculo.implemento==null and absf(veiculo.rapidez)<0.3 and global_position.distance_to(veiculo.global_position)<4.5 and preload("res://scripts/clearance.gd").livre(mundo,veiculo,self)

func acoplar(veiculo: CharacterBody3D) -> bool:
	if not disponivel(veiculo): return false
	if not preload("res://scripts/clearance.gd").livre(mundo,veiculo,self):
		mundo.avisar("Liberte o espaço atrás do tractor antes de engatar.")
		return false
	tractor = veiculo
	veiculo.implemento = self
	veiculo.add_collision_exception_with(corpo)
	anterior = Vector3.INF
	return true

func soltar() -> void:
	if tractor==null: return
	tractor.remove_collision_exception_with(corpo)
	tractor.implemento = null
	tractor = null
	activo = false
	global_position.y = mundo.altura(global_position)

func trabalhar(posicao: Vector3) -> int:
	var quantidade: int = 0
	var direita: Vector3 = tractor.global_basis.x if tractor!=null else Vector3.RIGHT
	for faixa: int in range(-1,2):
		var chave: Vector2i = mundo.terreno.chave_em(posicao+direita*faixa)
		if mundo.terreno.trabalhar(chave,ACOES[tipo],mundo.ferramentas.cultura,null,self if tipo==1 else null): quantidade += 1
	return quantidade

func _physics_process(_delta: float) -> void:
	var veiculo: Node3D = mundo.trator_actual
	sinal.visible = disponivel(veiculo) and not mundo.pausado()
	if tractor==null: return
	global_transform = tractor.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0,distancia_engate))
	global_position.y = mundo.altura(global_position)
	if not activo or mundo.pausado(): anterior = Vector3.INF; return
	var centro: Vector3 = global_position
	if anterior.is_finite() and anterior.distance_to(centro)<8.0:
		var passos: int = maxi(1,ceili(anterior.distance_to(centro)/0.4))
		for passo: int in range(1,passos+1): trabalhar(anterior.lerp(centro,float(passo)/passos))
	else: trabalhar(centro)
	anterior = centro

func custo_abastecer() -> int:
	return (CAPACIDADE_SEMENTES-sementes)*2 if tipo==1 else 0

func abastecer() -> bool:
	var custo: int = custo_abastecer()
	if tipo!=1 or custo<=0 or mundo.saldo<custo: return false
	mundo.saldo -= custo; sementes = CAPACIDADE_SEMENTES
	return true
