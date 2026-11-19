extends CharacterBody3D
## Veículo cinemático com colisão, condutor visível e autoridade única por ocupante.
var mundo: Node3D
var numero: int = 0
var rapidez: float = 0.0
var implemento: Node3D
var trabalhador: Node3D
var rodas: Array[Node3D] = []
var ocupado: bool = false
var atribuido: Node3D
var destino: Vector3 = Vector3.ZERO
var recuar: bool = false
var inclinacao_anterior: float = -0.55
var distancia_anterior: float = 7.5

func _ready() -> void:
	add_to_group("tratores_quinta")
	collision_layer = 4
	collision_mask = 1|2|4|8
	var colisor: CollisionShape3D = CollisionShape3D.new()
	var forma: BoxShape3D = BoxShape3D.new()
	forma.size = Vector3(1.7,1.5,3.0)
	colisor.shape = forma
	colisor.position.y = 0.9
	add_child(colisor)
	var cor: Color = [Color("668c76"),Color("b77754"),Color("587c91")][numero]
	mundo.caixa(self,Vector3(0,0.7,0),Vector3(1.4,0.2,3.1),Color("2b3e40"))
	mundo.caixa(self,Vector3(0,1.15,-0.8),Vector3(1.25,0.8,1.6),cor)
	mundo.caixa(self,Vector3(0,1.15,-1.63),Vector3(0.9,0.5,0.04),Color("344548"))
	mundo.caixa(self,Vector3(0,0.83,0.7),Vector3(1.4,0.1,1.3),Color("38484a"))
	mundo.caixa(self,Vector3(0,1.23,0.65),Vector3(0.46,0.14,0.5),Color("303e40"))
	mundo.caixa(self,Vector3(0,1.5,0.88),Vector3(0.46,0.48,0.12),Color("303e40"))
	for lado: float in [-1.0,1.0]:
		for z: float in [-0.05,1.2]: mundo.caixa(self,Vector3(lado*0.66,1.77,z),Vector3(0.055,1.55,0.055),Color("34464a"))
		mundo.caixa(self,Vector3(lado*0.9,1.1,0.9),Vector3(0.45,0.12,1.3),cor)
	mundo.caixa(self,Vector3(0,2.58,0.6),Vector3(1.7,0.12,1.8),cor.lightened(0.12))
	var volante: MeshInstance3D = MeshInstance3D.new()
	var aro: TorusMesh = TorusMesh.new()
	aro.inner_radius = 0.18
	aro.outer_radius = 0.22
	volante.mesh = aro
	volante.material_override = mundo.material(Color("263b3d"))
	volante.position = Vector3(0,1.61,-0.02)
	volante.rotation.x = 0.65
	add_child(volante)
	for lado: float in [-1.0,1.0]:
		for frente: bool in [true,false]:
			var roda: MeshInstance3D = MeshInstance3D.new()
			var pneu: CylinderMesh = CylinderMesh.new()
			pneu.top_radius = 0.47 if frente else 0.62
			pneu.bottom_radius = pneu.top_radius
			pneu.height = 0.36
			pneu.radial_segments = 20
			roda.mesh = pneu
			roda.material_override = mundo.material(Color("293533"))
			roda.rotation.z = PI/2
			roda.position = Vector3(lado*0.9,pneu.top_radius,-1.1 if frente else 0.95)
			add_child(roda)
			rodas.append(roda)
	mundo.placa(self,Vector3(0,2.9,0.6),"TRACTOR %d" % [numero+1]).visibility_range_end = 12

func entrar() -> bool:
	if ocupado or atribuido!=null or mundo.trator_actual!=null or mundo.drone_actual!=null: return false
	ocupado = true
	mundo.trator_actual = self
	mundo.jogador.bloqueado = true
	mundo.jogador.collision_layer = 0
	mundo.jogador.hide()
	mundo.jogador.visual.reparent(self)
	mundo.jogador.visual.transform = Transform3D(Basis.IDENTITY,Vector3(0,0.45,0.6))
	mundo.ferramentas.vista.hide()
	mundo.camera.alvo = self
	inclinacao_anterior = mundo.camera.inclinacao
	distancia_anterior = mundo.camera.distancia
	# Enquadramento ao nível da cabine deixa ver o condutor debaixo do tejadilho.
	mundo.camera.inclinacao = -0.12
	mundo.camera.distancia = 6.0
	return true

func sair() -> bool:
	# Só sai parado; consulta de colisão evita deixar o jogador dentro de paredes.
	if not ocupado or trabalhador!=null or absf(rapidez)>0.3: return false
	var destino: Vector3 = global_position+global_basis.x*2.0
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,destino+Vector3.UP,1)
	if not get_world_3d().direct_space_state.intersect_ray(consulta).is_empty(): destino = global_position-global_basis.x*2.0
	mundo.jogador.visual.reparent(mundo.jogador)
	mundo.jogador.visual.transform = Transform3D.IDENTITY
	mundo.jogador.global_position = destino+Vector3.UP*0.05
	mundo.jogador.collision_layer = 2
	mundo.jogador.show()
	mundo.jogador.animar(0,0)
	mundo.jogador.bloqueado = false
	mundo.ferramentas.vista.show()
	mundo.camera.alvo = mundo.jogador
	mundo.camera.inclinacao = inclinacao_anterior
	mundo.camera.distancia = distancia_anterior
	mundo.trator_actual = null
	ocupado = false
	if implemento!=null: implemento.activo = false
	return true

func candidato() -> Node3D:
	var melhor: Node3D
	var distancia: float = 5.5
	for maquina: Node3D in mundo.implementos+mundo.carrinhas:
		var actual: float = maquina.global_position.distance_to(global_position)
		if maquina.disponivel(self) and actual<distancia: melhor = maquina; distancia = actual
	return melhor

func engatar() -> bool:
	if absf(rapidez)>0.3: mundo.avisar("Pare o tractor para usar o engate."); return false
	if implemento!=null: implemento.soltar(); return true
	var maquina: Node3D = candidato()
	return maquina.acoplar(self) if maquina!=null else false

func _physics_process(delta: float) -> void:
	var anterior_transform: Transform3D = global_transform
	if mundo.trator_actual==self and not mundo.pausado():
		var acelerador: float = float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
		var turbo: bool = acelerador>0 and Input.is_physical_key_pressed(KEY_T)
		rapidez = move_toward(rapidez,acelerador*(12.0 if turbo else 6.0),delta*(8 if turbo else 4))
		var direccao: float = float(Input.is_physical_key_pressed(KEY_A))-float(Input.is_physical_key_pressed(KEY_D))
		rotation.y += direccao*delta*rapidez*0.25
	elif trabalhador!=null and not mundo.pausado():
		var diferenca: Vector3 = destino-global_position
		diferenca.y = 0
		var angulo: float = atan2(-diferenca.x,-diferenca.z)+(PI if recuar else 0)
		if diferenca.length()>0.1: rotation.y = lerp_angle(rotation.y,angulo,minf(1,delta*2))
		rapidez = move_toward(rapidez,(minf(1.5 if recuar else 3.5,diferenca.length()*1.5)*(-1 if recuar else 1)) if diferenca.length()>0.7 else 0,delta*3)
	else: rapidez = move_toward(rapidez,0,delta*6)
	velocity = -global_basis.z*rapidez
	velocity.y = -2.0
	move_and_slide()
	if implemento!=null and not preload("res://scripts/clearance.gd").livre(mundo,self,implemento):
		global_transform = anterior_transform; rapidez = 0; velocity = Vector3.ZERO
	for roda: Node3D in rodas: roda.rotate_object_local(Vector3.UP,delta*rapidez/0.6)
	if mundo.trator_actual==self:
		mundo.jogador.global_position = global_position
		mundo.jogador.animar(delta,0,true)
