extends Node3D
## O voo é remoto; o corpo do jogador fica parado no ponto de lançamento.
var mundo: Node3D
var numero: int = 0
var corpo: StaticBody3D
var origem: Vector3
var voando: bool = false
var rotores: Array[Node3D] = []
var irrigando: bool = false
var intervalo_rega: float = 0.0
var gotas: MultiMeshInstance3D
var tempo_gotas: float = 0.0
var sinal: MeshInstance3D

func _ready() -> void:
	origem = position
	preload("res://scripts/vehicle_lights.gd").instalar(self,mundo,"drone")
	corpo = StaticBody3D.new(); corpo.collision_layer = 8; add_child(corpo)
	var colisao: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(2.1,0.5,2.0); colisao.shape = forma; corpo.add_child(colisao)
	mundo.caixa(mundo,origem+Vector3(0,-0.55,0),Vector3(2.6,0.12,2.6),Color("85928a"))
	mundo.caixa(self,Vector3.ZERO,Vector3(0.7,0.25,0.6),Color("dae0d1"))
	mundo.caixa(self,Vector3(0,0.17,0),Vector3(0.38,0.12,0.38),Color("3b5454"))
	for lado: float in [-1.0,1.0]:
		for z: float in [-1.0,1.0]:
			var braco: MeshInstance3D = mundo.caixa(self,Vector3(lado*0.45,0,z*0.4),Vector3(1.0,0.06,0.08),Color("42575a"))
			braco.rotation.y = -lado*z*0.65
			var rotor: Node3D = Node3D.new()
			add_child(rotor)
			rotor.position = Vector3(lado*0.9,0.15,z*0.8)
			mundo.caixa(rotor,Vector3.ZERO,Vector3(0.8,0.02,0.07),Color("253e42"))
			mundo.caixa(rotor,Vector3.ZERO,Vector3(0.07,0.02,0.8),Color("253e42"))
			rotores.append(rotor)
	for lado: float in [-1.0,1.0]: mundo.caixa(self,Vector3(lado*0.35,-0.3,0),Vector3(0.045,0.55,0.65),Color("496164"))
	gotas = MultiMeshInstance3D.new()
	gotas.multimesh = MultiMesh.new()
	gotas.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var gota: BoxMesh = BoxMesh.new()
	gota.size = Vector3(0.025,0.17,0.025)
	gotas.multimesh.mesh = gota
	gotas.multimesh.instance_count = 36
	gotas.material_override = mundo.material(Color("83c9dd"))
	add_child(gotas)
	gotas.hide()
	sinal = mundo.caixa(self,Vector3(0,1.2,0),Vector3(0.15,0.15,0.15),Color("65fc98"))
	sinal.material_override = mundo.material(Color("65fc98"))
	mundo.placa(self,Vector3(0,0.7,0),"DRONE %d" % [numero+1]).visibility_range_end = 8

func disponivel() -> bool:
	return not voando and mundo.drone_actual==null and mundo.trator_actual==null and mundo.jogador.global_position.distance_to(global_position)<3.2 and not mundo.pausado()

func assumir() -> bool:
	if not disponivel(): return false
	corpo.collision_layer = 0
	voando = true
	mundo.drone_actual = self
	mundo.jogador.bloqueado = true
	position.y = mundo.altura(position)+3.0
	mundo.camera.alvo = self
	mundo.camera.distancia = 5.0
	return true

func devolver() -> void:
	corpo.collision_layer = 8
	voando = false
	irrigando = false
	gotas.hide()
	position = origem
	rotation = Vector3.ZERO
	mundo.drone_actual = null
	mundo.jogador.bloqueado = false
	mundo.camera.alvo = mundo.jogador
	mundo.camera.distancia = 7.5

func irrigar() -> int:
	var regadas: int = 0
	var centro: Vector2i = mundo.terreno.chave_em(global_position)
	for x: int in range(-2,3):
		for z: int in range(-2,3):
			if mundo.terreno.trabalhar(centro+Vector2i(x,z),"regar"): regadas += 1
	return regadas

func _physics_process(delta: float) -> void:
	sinal.visible = disponivel()
	if not voando or mundo.pausado(): return
	var controlo: GDScript = preload("res://scripts/input_drive.gd")
	var entrada: Vector3 = Vector3(clampf(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))+controlo.eixo(JOY_AXIS_LEFT_X),-1,1),0,clampf(float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))+controlo.eixo(JOY_AXIS_LEFT_Y),-1,1))
	entrada = Basis(Vector3.UP,mundo.camera_giro())*entrada.limit_length(1)
	entrada.y = clampf(float(Input.is_physical_key_pressed(KEY_SPACE))-float(Input.is_physical_key_pressed(KEY_CTRL))+float(controlo.botao(JOY_BUTTON_A))-float(controlo.botao(JOY_BUTTON_B)),-1,1)
	position += entrada*delta*7.0
	position.x = clampf(position.x,-370,370)
	position.z = clampf(position.z,-370,370)
	var chao: float = mundo.altura(position)
	position.y = clampf(position.y,chao+3,chao+22)
	for rotor: Node3D in rotores: rotor.rotate_y(delta*65)
	gotas.visible = irrigando
	if irrigando:
		intervalo_rega -= delta
		if intervalo_rega<=0:
			irrigar()
			intervalo_rega = 0.3
		tempo_gotas += delta*8
		var altura_voo: float = maxf(1,position.y-chao)
		for indice: int in range(36):
			var ponto: Vector3 = Vector3((indice%6-2.5)*0.65,-fposmod(tempo_gotas+indice*0.37,altura_voo),(floorf(float(indice)/6.0)-2.5)*0.65)
			gotas.multimesh.set_instance_transform(indice,Transform3D(Basis.IDENTITY,ponto))
