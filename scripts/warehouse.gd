extends Node3D
## Armazém da quinta: acesso livre, descarga e carregamento escolhido pelo jogador.
const SITES: GDScript = preload("res://scripts/industrial_sites.gd")
const CENTRO: Vector3 = SITES.ARMAZEM
const ENTREGA: Vector3 = SITES.ARMAZEM+Vector3(0,0,-22)
const ZONA: Rect2 = Rect2(46,30,12,20)
var mundo: Node3D
var dentro: bool = false
var portas: Array[Node3D] = []
var visitas: Dictionary = {}
var caixas: Array[Node3D] = []
var letreiro: Label3D
var funcionario: Node3D
func _ready() -> void:
	position = CENTRO; position.y = mundo.altura(position)
	preload("res://scripts/architecture.gd").piso(mundo,self,Rect2(-18,-16,36,32))
	for x: float in [-18,18]: mundo.caixa(self,Vector3(x,3.5,0),Vector3(0.4,7,32),Color("9caa9b"),true)
	mundo.caixa(self,Vector3(0,7.1,0),Vector3(37,0.3,33),Color("345b53"),true)
	for z: float in [-16,16]:
		for x: float in [-12,12]: mundo.caixa(self,Vector3(x,3.5,z),Vector3(12,7,0.4),Color("9caa9b"),true)
		mundo.caixa(self,Vector3(0,6.5,z),Vector3(12,1,0.4),Color("9caa9b"),true)
		var porta: MeshInstance3D = mundo.caixa(self,Vector3(0,3,z),Vector3(12,6,0.22),Color("45685d"),true); porta.set_meta("abertura",0.0); portas.append(porta)
	for x: float in [-14,14]:
		for z: float in [-10,0,10]:
			mundo.caixa(self,Vector3(x,1.5,z),Vector3(5,3,5),Color("94754e"),true)
	for i: int in range(4):
		var caixa: Node3D = preload("res://scripts/produce_crate.gd").new(); caixa.mundo = mundo; caixa.cultura = i; caixa.position = Vector3(-9 if i%2==0 else 9,0,-7+(i/2)*14); add_child(caixa); caixas.append(caixa)
	for z: float in [-10,0,10]:
		var luz: OmniLight3D = OmniLight3D.new(); luz.position = Vector3(0,5.5,z); luz.omni_range = 26; luz.light_energy = 1.3; luz.shadow_enabled = false; luz.distance_fade_enabled = true; luz.distance_fade_begin = 65; add_child(luz)
	letreiro = mundo.placa(self,Vector3(0,8,-16),"ARMAZÉM DA QUINTA"); letreiro.visibility_range_end = 100; letreiro.font_size = 48; letreiro.pixel_size = 0.035
	preload("res://scripts/industrial_art.gd").compactar(self,portas)
	funcionario = preload("res://scripts/warehouse_attendant.gd").new(); funcionario.mundo = mundo; funcionario.posto = self; add_child(funcionario)
func perto() -> bool:
	return preload("res://scripts/layout.gd").distancia(mundo.jogador.global_position,ENTREGA)<10 or SITES.AREA_ARMAZEM.grow(-1).has_point(Vector2(mundo.jogador.position.x,mundo.jogador.position.z))
func receber(carga: Dictionary) -> void:
	for cultura: int in carga: mundo.stock[cultura] = int(mundo.stock.get(cultura,0))+int(carga[cultura])
	carga.clear()
func retirar() -> Dictionary:
	var carga: Dictionary = mundo.stock.duplicate(); mundo.stock.clear(); return carga
func parado(veiculo: Node3D) -> bool:
	if not is_instance_valid(veiculo): return false
	var condutor: Node3D = veiculo.tractor if veiculo.get("tractor")!=null else veiculo
	return condutor.get("rapidez")==null or absf(float(condutor.get("rapidez")))<0.4
func transporte_proximo() -> Node3D:
	var candidatos: Array[Node3D] = []; if mundo.caminhao!=null: candidatos.append(mundo.caminhao)
	candidatos.append_array(mundo.carrinhas)
	for v: Node3D in candidatos:
		if v.position.distance_to(CENTRO)<28 and v.position.distance_to(mundo.jogador.position)<18 and parado(v): return v
	return null
func solicitar_carga(transporte: Node3D = null) -> void:
	if funcionario.ocupado(): mundo.avisar("O funcionário está a terminar a operação actual."); return
	if transporte==null: transporte = transporte_proximo()
	if mundo.central_logistica!=null: mundo.central_logistica.abrir_carga(transporte)
func encomendar_carga(cultura: int,q: int,veiculo: Node3D = null) -> bool:
	if funcionario.ocupado() or cultura<0 or cultura>3 or q<=0: return false
	if veiculo!=null and (not parado(veiculo) or veiculo.position.distance_to(CENTRO)>28): return false
	if veiculo==null and not perto(): return false
	var n: int = mini(q,int(mundo.stock.get(cultura,0)))
	if veiculo!=null: n = mini(n,veiculo.CAPACIDADE-veiculo.total())
	if n<=0: return false
	var alvo: Node3D = mundo.jogador if veiculo==null else veiculo
	var espera: Vector3 = alvo.global_position
	var origem: Vector3 = to_global(Vector3(-6.8 if cultura%2==0 else 6.8,0,-7+(cultura/2)*14))
	var entrega: Vector3 = funcionario.ponto_transporte(veiculo) if veiculo!=null else espera+Vector3(0.8,0,0)
	var condicao: Callable = func() -> bool: return is_instance_valid(alvo) and alvo.global_position.distance_to(espera)<1.5 and (veiculo==null or parado(veiculo))
	var aplicar: Callable = func() -> int: return mundo.central_logistica.carregar_escolha(cultura,n,veiculo)
	var fim: Callable = func(movidas: int) -> void:
		if movidas>0: mundo.avisar("Funcionário carregou %d unidades" % movidas); mundo.central_logistica.abrir_destinos(cultura)
		else: mundo.avisar("Stock ou capacidade mudou · nada foi retirado")
	return funcionario.iniciar("A carregar",n,cultura,veiculo,origem,entrega,condicao,aplicar,fim)
func encomendar_descarga(veiculo: Node3D = null) -> bool:
	if funcionario.ocupado(): return false
	if veiculo!=null and (not parado(veiculo) or veiculo.position.distance_to(CENTRO)>28): return false
	var carga: Dictionary = mundo.sacola if veiculo==null else veiculo.carga
	if carga.is_empty(): return false
	var alvo: Node3D = mundo.jogador if veiculo==null else veiculo; var espera: Vector3 = alvo.global_position
	var n: int = 0
	for valor: int in carga.values(): n += valor
	var cultura: int = int(carga.keys()[0])
	var recolha: Vector3 = funcionario.ponto_transporte(veiculo) if veiculo!=null else espera+Vector3(0.8,0,0)
	var condicao: Callable = func() -> bool: return is_instance_valid(alvo) and alvo.global_position.distance_to(espera)<1.5 and (veiculo==null or parado(veiculo))
	var aplicar: Callable = func() -> int:
		var total: int = 0
		for valor: int in carga.values(): total += valor
		receber(carga)
		if is_instance_valid(veiculo): veiculo.actualizar_carga()
		return total
	var fim: Callable = func(movidas: int) -> void: mundo.avisar("Funcionário guardou %d unidades no armazém" % movidas)
	return funcionario.iniciar("A descarregar",n,cultura,veiculo,recolha,to_global(Vector3(6.8,0,7)),condicao,aplicar,fim)
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
		var h: float = lerpf(6.0,0.12,abertura); porta.mesh.size.y = h; porta.position.y = 6-h/2
		var colisor: CollisionShape3D = porta.get_child(0).get_child(0); colisor.shape.size.y = h
	var agora: bool = mundo.trator_actual==null and mundo.drone_actual==null and ZONA.has_point(Vector2(mundo.jogador.position.x,mundo.jogador.position.z))
	if agora and not dentro:
		if not mundo.sacola.is_empty():
			if not encomendar_descarga(): agora = false
		else: solicitar_carga()
	dentro = agora
	var transportes: Array[Node3D] = []; transportes.append_array(mundo.carrinhas)
	if mundo.caminhao!=null: transportes.append(mundo.caminhao)
	for transporte: Node3D in transportes:
		var id: int = transporte.get_instance_id()
		var conduzida: bool = mundo.trator_actual==transporte if transporte==mundo.caminhao else transporte.tractor!=null and transporte.tractor==mundo.trator_actual
		var na_zona: bool = conduzida and ZONA.has_point(Vector2(transporte.position.x,transporte.position.z))
		if na_zona and not bool(visitas.get(id,false)):
			if transporte.total()>0:
				if not encomendar_descarga(transporte): na_zona = false
			else:
				if mundo.trator_actual!=null: mundo.trator_actual.rapidez = 0; mundo.trator_actual.velocity = Vector3.ZERO
				solicitar_carga(transporte)
		visitas[id] = na_zona
	for i: int in range(caixas.size()): caixas[i].actualizar(int(mundo.stock.get(i,0)))
func _physics_process(delta: float) -> void:
	if mundo.hud!=null and not mundo.pausado(): actualizar(delta)
