extends Node3D
## Centro logístico afastado: descarga por entrada; carregamento escolhido pelo jogador.
const SITES: GDScript = preload("res://scripts/industrial_sites.gd")
const CENTRO: Vector3 = SITES.ARMAZEM
const ENTREGA: Vector3 = SITES.ARMAZEM+Vector3(0,0,-48)
const ZONA: Rect2 = Rect2(-215,5,20,34)
var mundo: Node3D
var dentro: bool = false
var portas: Array[Node3D] = []
var visitas: Dictionary = {}
var caixas: Array[Node3D] = []
var letreiro: Label3D
func _ready() -> void:
	position = CENTRO; position.y = mundo.altura(position)
	preload("res://scripts/architecture.gd").piso(mundo,self,Rect2(-25,-32,50,64))
	for x: float in [-25,25]: mundo.caixa(self,Vector3(x,6,0),Vector3(0.4,12,64),Color("9caa9b"),true)
	mundo.caixa(self,Vector3(0,12.1,0),Vector3(51,0.3,65),Color("345b53"),true)
	for z: float in [-32,32]:
		for x: float in [-16,16]: mundo.caixa(self,Vector3(x,6,z),Vector3(18,12,0.4),Color("9caa9b"),true)
		mundo.caixa(self,Vector3(0,10,z),Vector3(14,4,0.4),Color("9caa9b"),true)
		var porta: MeshInstance3D = mundo.caixa(self,Vector3(0,4,z),Vector3(14,8,0.22),Color("45685d"),true); porta.set_meta("abertura",0.0); portas.append(porta)
	for x: float in [-18,18]:
		for z: float in [-18,0,18]:
			mundo.caixa(self,Vector3(x,1.5,z),Vector3(8,3,6),Color("94754e"),true)
	for i: int in range(4):
		var caixa: Node3D = preload("res://scripts/produce_crate.gd").new(); caixa.mundo = mundo; caixa.cultura = i; caixa.position = Vector3(-11 if i%2==0 else 11,0,-10+(i/2)*20); add_child(caixa); caixas.append(caixa)
	for z: float in [-20,0,20]:
		var luz: OmniLight3D = OmniLight3D.new(); luz.position = Vector3(0,8,z); luz.omni_range = 26; luz.light_energy = 1.3; luz.shadow_enabled = false; luz.distance_fade_enabled = true; luz.distance_fade_begin = 65; add_child(luz)
	letreiro = mundo.placa(self,Vector3(0,13,-32),"MOZCOLHEITA · CENTRO LOGÍSTICO"); letreiro.visibility_range_end = 100; letreiro.font_size = 48; letreiro.pixel_size = 0.035
	var cancela: Node3D = preload("res://scripts/industrial_gate.gd").new(); cancela.mundo = mundo; cancela.position = Vector3(0,0,-45); add_child(cancela)
	preload("res://scripts/industrial_art.gd").compactar(self,portas)
func perto() -> bool:
	return preload("res://scripts/layout.gd").distancia(mundo.jogador.global_position,ENTREGA)<10 or ZONA.has_point(Vector2(mundo.jogador.position.x,mundo.jogador.position.z))
func receber(carga: Dictionary) -> void:
	for cultura: int in carga: mundo.stock[cultura] = int(mundo.stock.get(cultura,0))+int(carga[cultura])
	carga.clear()
func retirar() -> Dictionary:
	var carga: Dictionary = mundo.stock.duplicate(); mundo.stock.clear(); return carga
func solicitar_carga(transporte: Node3D = null) -> void:
	if mundo.central_logistica!=null: mundo.central_logistica.abrir_carga(transporte)
func actualizar(delta: float) -> void:
	var actores: Array[Node3D] = [mundo.jogador]; actores.append_array(mundo.pessoas); actores.append_array(mundo.tratores); actores.append_array(mundo.carrinhas)
	if mundo.caminhao!=null: actores.append(mundo.caminhao)
	for porta: Node3D in portas:
		var aberta: bool = false
		for actor: Node3D in actores:
			if actor is CharacterBody3D and actor.collision_layer==0: continue
			var p: Vector3 = to_local(actor.global_position)
			if absf(p.x)<11 and absf(p.z-porta.position.z)<19: aberta = true; break
		var abertura: float = move_toward(float(porta.get_meta("abertura")),1.0 if aberta else 0.0,delta*1.5); porta.set_meta("abertura",abertura)
		var h: float = lerpf(8.0,0.12,abertura); porta.mesh.size.y = h; porta.position.y = 8-h/2
		var colisor: CollisionShape3D = porta.get_child(0).get_child(0); colisor.shape.size.y = h
	var agora: bool = mundo.trator_actual==null and mundo.drone_actual==null and ZONA.has_point(Vector2(mundo.jogador.position.x,mundo.jogador.position.z))
	if agora and not dentro:
		if not mundo.sacola.is_empty(): receber(mundo.sacola); mundo.avisar("Colheita guardada · E escolhe produto e quantidade para carregar")
		else: solicitar_carga()
	dentro = agora
	var transportes: Array[Node3D] = []; transportes.append_array(mundo.carrinhas)
	if mundo.caminhao!=null: transportes.append(mundo.caminhao)
	for transporte: Node3D in transportes:
		var id: int = transporte.get_instance_id()
		var conduzida: bool = mundo.trator_actual==transporte if transporte==mundo.caminhao else transporte.tractor!=null and transporte.tractor==mundo.trator_actual
		var na_zona: bool = conduzida and ZONA.has_point(Vector2(transporte.position.x,transporte.position.z))
		if na_zona and not bool(visitas.get(id,false)):
			if transporte.total()>0: receber(transporte.carga); transporte.actualizar_carga(); mundo.avisar("Carga guardada · saia e volte para escolher o carregamento")
			else:
				if mundo.trator_actual!=null: mundo.trator_actual.rapidez = 0; mundo.trator_actual.velocity = Vector3.ZERO
				solicitar_carga(transporte)
		visitas[id] = na_zona
	for i: int in range(caixas.size()): caixas[i].actualizar(int(mundo.stock.get(i,0)))
func _physics_process(delta: float) -> void:
	if mundo.hud!=null and not mundo.pausado(): actualizar(delta)
