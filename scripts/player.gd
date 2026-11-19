extends CharacterBody3D
## Corpo físico e avatar articulado. Os pivôs mantêm os membros ligados ao tronco.
var mundo: Node3D
var mulher: bool = false
var aparencia: int = 0
var saia: MeshInstance3D
var rosto: Node3D
var tom_pele: Color
const PELES: Array[Color] = [Color("6b4433"),Color("87583e"),Color("4d3027"),Color("a2704e"),Color("754936"),Color("56372c")]

var bloqueado: bool = false
var velocidade: float = 4.5
var visual: Node3D
var bracos: Array[Node3D] = []
var pernas: Array[Node3D] = []
var joelhos: Array[Node3D] = []
var cotovelos: Array[Node3D] = []
var maos: Array[Node3D] = []
var mao_direita: Node3D
var fase: float = 0.0
var gesto: float = 0.0
var contratado: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1|2|4|8
	var forma: CapsuleShape3D = CapsuleShape3D.new()
	forma.radius = 0.27
	forma.height = 1.75
	var colisor: CollisionShape3D = CollisionShape3D.new()
	colisor.shape = forma
	colisor.position.y = 0.88
	add_child(colisor)
	criar_avatar()

func peca(pai: Node3D, posicao: Vector3, tamanho: Vector3, cor: Color, redonda: bool = false) -> MeshInstance3D:
	var malha: MeshInstance3D = MeshInstance3D.new()
	if redonda:
		var esfera: SphereMesh = SphereMesh.new()
		esfera.radius = 0.5
		esfera.height = 1.0
		esfera.radial_segments = 16
		esfera.rings = 8
		malha.mesh = esfera
	else:
		malha.mesh = BoxMesh.new()
	malha.scale = tamanho
	malha.position = posicao
	malha.material_override = mundo.material(cor)
	pai.add_child(malha)
	return malha

func contorno(pai: Node3D, aneis: Array[Vector3], cor: Color) -> MeshInstance3D:
	# Secções contínuas evitam membros em forma de contas e juntas de marioneta.
	var superficie: SurfaceTool = SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	superficie.set_material(mundo.material(cor))
	for fila_anel: int in range(aneis.size()-1):
		for segmento: int in range(24):
			for canto: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var anel: Vector3 = aneis[fila_anel+canto.y]
				var angulo: float = TAU*float(segmento+canto.x)/24.0
				superficie.set_smooth_group(0)
				superficie.add_vertex(Vector3(sin(angulo)*anel.y,anel.x,cos(angulo)*anel.z))
	superficie.generate_normals()
	superficie.index()
	var malha: MeshInstance3D = MeshInstance3D.new()
	malha.mesh = superficie.commit()
	pai.add_child(malha)
	return malha

func chapeu() -> void:
	for coroa: bool in [false,true]:
		var malha: MeshInstance3D = MeshInstance3D.new()
		var cilindro: CylinderMesh = CylinderMesh.new()
		cilindro.bottom_radius = 0.13 if coroa else 0.21
		cilindro.top_radius = 0.115 if coroa else 0.21
		cilindro.height = 0.11 if coroa else 0.018
		cilindro.radial_segments = 32
		malha.mesh = cilindro
		malha.position.y = 1.84 if coroa else 1.78
		malha.material_override = mundo.material(Color("cbb47c"))
		visual.add_child(malha)

func criar_rosto(pele: Color) -> void:
	rosto = Node3D.new(); rosto.name = "Rosto"
	visual.add_child(rosto)
	var largura: float = 0.088 if mulher else 0.096
	contorno(rosto,[Vector3(1.50,0.048,0.055),Vector3(1.53,largura*0.78,0.079),Vector3(1.59,largura,0.095),Vector3(1.66,largura*1.04,0.097),Vector3(1.73,largura,0.086),Vector3(1.78,largura*0.72,0.058),Vector3(1.795,0.015,0.018)],pele)
	for lado: float in [-1.0,1.0]:
		peca(rosto,Vector3(lado*largura,1.638,0),Vector3(0.024,0.054,0.025),pele,true)
		peca(rosto,Vector3(lado*0.038,1.656,-0.088),Vector3(0.026,0.010,0.009),pele.darkened(0.35),true)
		peca(rosto,Vector3(lado*0.038,1.655,-0.092),Vector3(0.020,0.006,0.005),Color("b6aaa0"),true)
		peca(rosto,Vector3(lado*0.038,1.655,-0.095),Vector3(0.010,0.007,0.003),Color("221b17"),true)
		var sobrancelha: MeshInstance3D = peca(rosto,Vector3(lado*0.039,1.678,-0.087),Vector3(0.030,0.006,0.006),Color("30221b"),true)
		sobrancelha.rotation.z = lado*0.1
	# Ponte, ponta nasal e lábios conservam volumes pequenos e proporções naturais.
	peca(rosto,Vector3(0,1.634,-0.097),Vector3(0.019,0.047,0.024),pele.lightened(0.035),true)
	peca(rosto,Vector3(0,1.613,-0.109),Vector3(0.030,0.019,0.022),pele,true)
	peca(rosto,Vector3(0,1.575,-0.087),Vector3(0.037 if mulher else 0.041,0.010,0.010),pele.darkened(0.25),true)
	peca(rosto,Vector3(0,1.569,-0.086),Vector3(0.031,0.007,0.009),pele.lightened(0.04),true)
	var cabelo: Color = Color("241d18").lightened(float(aparencia%3)*0.015)
	contorno(rosto,[Vector3(1.715,0.096,0.09),Vector3(1.76,0.094,0.082),Vector3(1.80,0.067,0.055),Vector3(1.81,0.005,0.006)],cabelo)
	if mulher:
		# Cabelo comprido atrás do rosto; sem chapéu nas personagens femininas.
		var g: GDScript = preload("res://scripts/geometry.gd")
		var superficie: SurfaceTool = SurfaceTool.new(); superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in range(9):
			var x: float = -0.09+i*0.0225
			var base: Vector3 = Vector3(x,1.75,0.05)
			var meio: Vector3 = Vector3(x*1.05,1.54,0.092)
			var fim: Vector3 = Vector3(x*0.85,1.24+absf(x)*0.6,0.09)
			g.tubo(superficie,base,meio,0.025,cabelo,0.026,7)
			g.tubo(superficie,meio,fim,0.026,cabelo,0.012,7)
		var madeixas: MeshInstance3D = MeshInstance3D.new(); madeixas.mesh = g.terminar(superficie); rosto.add_child(madeixas)
	else: chapeu()

func criar_avatar() -> void:
	if is_instance_valid(visual): remove_child(visual); visual.queue_free()
	bracos.clear(); pernas.clear(); joelhos.clear(); cotovelos.clear(); maos.clear()
	visual = Node3D.new(); add_child(visual)
	tom_pele = PELES[aparencia%PELES.size()]
	var pele: Color = tom_pele
	var camisa: Color = [Color("41675c"),Color("a36f49"),Color("6b7380"),Color("8d6659"),Color("a69a74"),Color("5c736c")][aparencia%6]
	var ombros: float = 0.188 if mulher else 0.218
	var quadris: float = 0.185 if mulher else 0.172
	contorno(visual,[Vector3(0.84,quadris,0.115),Vector3(0.96,0.16 if mulher else 0.17,0.112),Vector3(1.08,0.14 if mulher else 0.17,0.105),Vector3(1.26,0.178 if mulher else 0.20,0.12),Vector3(1.37,ombros,0.10),Vector3(1.425,0.15,0.08),Vector3(1.445,0.062,0.057)],camisa)
	contorno(visual,[Vector3(1.42,0.058,0.053),Vector3(1.50,0.055,0.055),Vector3(1.54,0.058,0.055)],pele)
	criar_rosto(pele)
	if mulher:
		saia = contorno(visual,[Vector3(0.14 if aparencia%3==0 else 0.43,0.29,0.19),Vector3(0.58,0.25,0.165),Vector3(0.8,0.20,0.13),Vector3(0.96,0.17,0.11)],[Color("65536a"),Color("386373"),Color("795e43")][aparencia%3])
		saia.name = "Saia"
	for lado: float in [-1.0,1.0]:
		var braco: Node3D = Node3D.new(); visual.add_child(braco)
		braco.position = Vector3(lado*(ombros+0.01),1.37,0)
		contorno(braco,[Vector3(-0.29,0.042,0.042),Vector3(-0.16,0.049,0.048),Vector3(-0.02,0.057,0.055),Vector3(0.025,0.045,0.044)],camisa)
		var cotovelo: Node3D = Node3D.new(); braco.add_child(cotovelo); cotovelo.position.y = -0.27; cotovelos.append(cotovelo)
		contorno(cotovelo,[Vector3(-0.25,0.029,0.027),Vector3(-0.14,0.039,0.035),Vector3(-0.035,0.043,0.040),Vector3(0.02,0.042,0.042)],pele)
		peca(cotovelo,Vector3(0,-0.27,-0.005),Vector3(0.066,0.1,0.045),pele,true)
		peca(cotovelo,Vector3(-lado*0.034,-0.25,-0.005),Vector3(0.022,0.052,0.028),pele,true)
		var mao: Node3D = Node3D.new(); cotovelo.add_child(mao); mao.position.y = -0.29; maos.append(mao); bracos.append(braco)
		if lado>0: mao_direita = mao
		var perna: Node3D = Node3D.new(); visual.add_child(perna); perna.position = Vector3(lado*0.10,0.87,0)
		var tecido: Color = pele if mulher else Color("3c4546")
		contorno(perna,[Vector3(-0.43,0.057,0.06),Vector3(-0.24,0.074,0.077),Vector3(-0.08,0.089,0.095),Vector3(0.04,0.09,0.1)],tecido)
		var joelho: Node3D = Node3D.new(); perna.add_child(joelho); joelho.position.y = -0.4; joelhos.append(joelho)
		contorno(joelho,[Vector3(-0.37,0.039,0.042),Vector3(-0.23,0.052,0.055),Vector3(-0.07,0.058,0.058),Vector3(0.02,0.058,0.06)],tecido)
		peca(joelho,Vector3(0,-0.4,-0.05),Vector3(0.15,0.10,0.27),Color("3c332a"),true)
		pernas.append(perna)

func animar(delta: float, andamento: float, sentado: bool = false) -> void:
	fase += delta*8.0
	gesto = maxf(0.0,gesto-delta*3.0)
	if mulher and is_instance_valid(saia): saia.rotation.z = sin(fase)*minf(andamento,2)*0.015
	for indice: int in range(2):
		var passo: float = sin(fase+indice*PI)*minf(andamento/4.5,1.0)*0.55
		pernas[indice].rotation = Vector3((1.25 if sentado else passo),0,0)
		bracos[indice].rotation = Vector3((0.9 if sentado else -passo*0.7),0,0)
		cotovelos[indice].rotation = Vector3((0.6 if sentado else 0.1),0,0)
		joelhos[indice].rotation = Vector3((-1.35 if sentado else -maxf(0,-passo)*0.7),0,0)
	if gesto>0.0: bracos[1].rotation.x = sin(gesto*PI)*1.4

func _physics_process(delta: float) -> void:
	if mundo == null: return
	if bloqueado or mundo.bloqueia_jogador():
		velocity = Vector3.ZERO
		if mundo.trator_actual==null: animar(delta,0.0)
		return
	var entrada: Vector2 = Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).limit_length(1.0)
	var direcao: Vector3 = Basis(Vector3.UP,mundo.camera_giro())*Vector3(entrada.x,0,entrada.y)
	var rapidez: float = velocidade*(1.6 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	velocity.x = direcao.x*rapidez
	velocity.z = direcao.z*rapidez
	velocity.y = maxf(-20.0,velocity.y-delta*20.0)
	move_and_slide()
	global_position.x = clampf(global_position.x,mundo.LIMITES.position.x,mundo.LIMITES.end.x)
	global_position.z = clampf(global_position.z,mundo.LIMITES.position.y,mundo.LIMITES.end.y)
	if direcao.length()>0.01: visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direcao.x,-direcao.z),minf(1.0,delta*12.0))
	animar(delta,Vector2(velocity.x,velocity.z).length())

func repor_pose() -> void:
	gesto = 0
	animar(0,0)
