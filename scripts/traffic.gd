extends CharacterBody3D
## Tráfego cinemático de ambiente: abranda perante pessoas/veículos e segue vias.
var mundo: Node3D
var tipo: int = 0
var rota: Array[Vector3] = []
var intervalo_sensor: float = 0
var caminho_livre: bool = true
var segmento: int = 0
var rodas: Array[Node3D] = []
func _ready() -> void:
	collision_layer = 16; collision_mask = 2|4|8|16
	var col: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new(); forma.size = Vector3(1.8,1.6,3.8 if tipo!=1 else 6.3); col.shape = forma; col.position.y = 1; add_child(col)
	rodas = preload("res://scripts/vehicle_art.gd").criar_trafego(self,tipo,get_parent().get_child_count())
	preload("res://scripts/vehicle_lights.gd").instalar(self,mundo,"carro" if tipo==0 else "carga" if tipo==1 else "agricola")
	if not rota.is_empty(): position = rota[0]; position.y = mundo.altura(position)+0.1; segmento = 1
func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado() or rota.size()<2: return
	var observador: Vector3 = mundo.camera.camara.global_position
	visible = position.distance_squared_to(observador)<180*180
	var diferenca: Vector3 = rota[segmento]-position; diferenca.y = 0
	if diferenca.length()<0.4: segmento = (segmento+1)%rota.size(); return
	var direccao: Vector3 = diferenca.normalized()
	intervalo_sensor -= delta
	if intervalo_sensor<=0:
		intervalo_sensor = 0.12
		var raio: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(position+Vector3.UP,position+Vector3.UP+direccao*7,1|2|4|8|16); raio.exclude = [get_rid()]
		caminho_livre = get_world_3d().direct_space_state.intersect_ray(raio).is_empty()
	var livre: bool = caminho_livre
	rotation.y = lerp_angle(rotation.y,atan2(-direccao.x,-direccao.z),minf(1,delta*4))
	velocity = direccao*(minf(6.0,diferenca.length()/maxf(delta,0.001)) if livre else 0); velocity.y = 0
	# Circuitos de ambiente seguem a altura da estrada; não resolvem contactos de piso a cada tick.
	move_and_collide(velocity*delta); position.y = mundo.altura(position)+0.1
	if not visible: return
	for roda: Node3D in rodas: roda.rotate_object_local(Vector3.UP,delta*(6 if livre else 0))
