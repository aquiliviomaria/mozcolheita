extends CharacterBody3D
## Corpo físico e avatar articulado. Os pivôs mantêm os membros ligados ao tronco.
static var esfera_partilhada: SphereMesh
static var contornos_partilhados: Dictionary = {}
static var cubo_partilhado: BoxMesh
var mundo: Node3D
var mulher: bool = false
var pilotar_drone: bool = false
var comando_drone: Node3D
var deitado: bool = false
var lado_cama: int = 1
var roupa: int = 0
var idade: String = "adulto"
var perfil: int = 0
const PERFIS: Array[String] = ["Médio","Alto","Baixo","Robusto","Magro"]
var aparencia: int = 0
var saia: MeshInstance3D
var cesto: Node3D
var acao_animacao: String = "idle"
var tempo_acao: float = 0.0
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
	collision_mask = 1|2|4|8|16
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
		if esfera_partilhada==null:
			esfera_partilhada = SphereMesh.new(); esfera_partilhada.radius = 0.5; esfera_partilhada.height = 1.0; esfera_partilhada.radial_segments = 16; esfera_partilhada.rings = 8
		malha.mesh = esfera_partilhada
	else:
		if cubo_partilhado==null: cubo_partilhado = BoxMesh.new()
		malha.mesh = cubo_partilhado
	malha.scale = tamanho
	malha.position = posicao
	malha.material_override = mundo.material(cor)
	pai.add_child(malha)
	return malha

func contorno(pai: Node3D, aneis: Array[Vector3], cor: Color) -> MeshInstance3D:
	var chave_modelo: String = str(aneis)+cor.to_html()
	if contornos_partilhados.has(chave_modelo):
		var reutilizada: MeshInstance3D = MeshInstance3D.new(); reutilizada.mesh = contornos_partilhados[chave_modelo]; pai.add_child(reutilizada); return reutilizada
	# Secções contínuas evitam membros em forma de contas e juntas de marioneta.
	var superficie: SurfaceTool = SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	superficie.set_material(mundo.material(cor))
	for fila_anel: int in range(aneis.size()-1):
		for segmento: int in range(16):
			for canto: Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var anel: Vector3 = aneis[fila_anel+canto.y]
				var angulo: float = TAU*float(segmento+canto.x)/16.0
				superficie.set_smooth_group(0)
				superficie.add_vertex(Vector3(sin(angulo)*anel.y,anel.x,cos(angulo)*anel.z))
	superficie.generate_normals()
	superficie.index()
	var malha: MeshInstance3D = MeshInstance3D.new()
	malha.mesh = superficie.commit(); contornos_partilhados[chave_modelo] = malha.mesh
	pai.add_child(malha)
	return malha

func criar_avatar() -> void:
	preload("res://scripts/avatar.gd").construir(self)
	visual.scale = escala_corpo()
	if self==mundo.jogador: comando_drone = preload("res://scripts/drone_remote.gd").criar(self)

func animacao(acao: String,duracao: float = 1.2) -> void:
	acao_animacao = acao; tempo_acao = duracao

func escala_corpo() -> Vector3:
	var e: Vector3 = [Vector3.ONE,Vector3(0.98,1.12,0.98),Vector3(1,0.88,1),Vector3(1.23,1,1.17),Vector3(0.84,1.04,0.88)][clampi(perfil,0,4)]
	return e*(0.66 if idade=="crianca" else 0.95 if idade=="idoso" else 1.0)

func animar(delta: float, andamento: float, sentado: bool = false) -> void:
	visual.scale = escala_corpo()
	fase += delta*(12.0 if andamento>5 else 8.0)
	rosto.position.y = sin(fase*0.25)*0.006 if not sentado else 0.0
	tempo_acao = maxf(0,tempo_acao-delta)
	if tempo_acao<=0: acao_animacao = "run" if andamento>5 else "walk" if andamento>0.1 else "idle"
	gesto = maxf(0.0,gesto-delta*3.0)
	if mulher and is_instance_valid(saia): saia.rotation.z = sin(fase)*minf(andamento,2)*0.015
	for indice: int in range(2):
		var passo: float = sin(fase+indice*PI)*minf(andamento/4.5,1.0)*0.55
		pernas[indice].rotation = Vector3((1.25 if sentado else passo),0,0)
		bracos[indice].rotation = Vector3((0.9 if sentado else -passo*0.7),0,0)
		cotovelos[indice].rotation = Vector3((0.6 if sentado else 0.1),0,0)
		joelhos[indice].rotation = Vector3((-1.35 if sentado else -maxf(0,-passo)*0.7),0,0)
	if gesto>0.0: bracos[1].rotation.x = sin(gesto*PI)*1.4
	rosto.rotation.x = 0
	var transportar: bool = not sentado and ((get("carga")!=null and not get("carga").is_empty()) or (self==mundo.jogador and not mundo.sacola.is_empty()))
	if tempo_acao>0 and not sentado:
		var ciclo: float = sin(fase*1.4)
		match acao_animacao:
			"planting", "harvesting":
				bracos[1].rotation.x = 0.7+ciclo*0.45; cotovelos[1].rotation.x = 0.5
				rosto.rotation.x = 0.16
			"watering": bracos[1].rotation = Vector3(0.75,0,-0.25+ciclo*0.10); cotovelos[1].rotation.x = 0.45
	else: rosto.rotation.x = 0
	if transportar:
		for i: int in range(2): bracos[i].rotation = Vector3(0.95,0,0); cotovelos[i].rotation.x = 0.5
		acao_animacao = "carrying"
	if is_instance_valid(cesto): cesto.visible = transportar

	if pilotar_drone:
		for i: int in range(2): bracos[i].rotation = Vector3(0.9,0,0); cotovelos[i].rotation = Vector3(1.2,0,0)
		cesto.hide()
		if is_instance_valid(comando_drone): comando_drone.position = visual.to_local((maos[0].global_position+maos[1].global_position)*0.5)+Vector3(0,-0.035,-0.025)
	if is_instance_valid(comando_drone): comando_drone.visible = pilotar_drone
	if deitado: aplicar_pose_cama()

func deitar(lado: int) -> void:
	deitado = true; lado_cama = lado; animar(0,0)

func aplicar_pose_cama() -> void:
	# Frente do avatar (-Z) aponta para cima; cabeça (+Y) fica na cabeceira (+Z).
	visual.position = Vector3.ZERO; visual.rotation = Vector3(PI/2,0,0)
	for i: int in range(2):
		pernas[i].rotation = Vector3.ZERO; joelhos[i].rotation = Vector3.ZERO
		bracos[i].rotation = Vector3(0.05,0,0); cotovelos[i].rotation = Vector3(0.1,0,0)
	var interior: int = 1 if lado_cama>0 else 0
	bracos[interior].rotation = Vector3(0.05,0,lado_cama*1.05)
	cotovelos[interior].rotation = Vector3(0.18,0,lado_cama*0.35)
	cesto.hide()

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
	deitado = false
	gesto = 0; tempo_acao = 0; acao_animacao = "idle"
	animar(0,0)
