extends Node3D
## Fábrica industrial de 48 × 56 m, com cancela, segurança e garagem de entrega.
var mundo: Node3D
var numero: int = 0
var precos: Label3D
var intervalo: float = 0
var local_filial: Vector3 = Vector3.INF
var porta: MeshInstance3D
var abertura: float = 0
var funcionario: Node3D
func _ready() -> void:
	position = preload("res://scripts/industrial_sites.gd").FABRICAS[numero] if not local_filial.is_finite() else local_filial; position.y = mundo.altura(position)
	preload("res://scripts/architecture.gd").piso(mundo,self,Rect2(-24,-28,48,56))
	var cor: Color = [Color("b3bdab"),Color("b4ae98"),Color("baaa96")][numero]
	for lado: float in [-1,1]:
		mundo.caixa(self,Vector3(lado*24,6,0),Vector3(0.4,12,56),cor,true)
		mundo.caixa(self,Vector3(lado*15,6,-28),Vector3(18,12,0.4),cor,true)
		mundo.caixa(self,Vector3(lado*16,3,6),Vector3(10,6,26),Color("768c7a"),true)
		for z: float in [-18,-8,2,12,22]: mundo.caixa(self,Vector3(lado*24.25,7,z),Vector3(0.12,2.5,4),Color("517f84"))
	mundo.caixa(self,Vector3(0,6,28),Vector3(48,12,0.4),cor,true)
	mundo.caixa(self,Vector3(0,10,-28),Vector3(12,4,0.4),cor,true)
	mundo.caixa(self,Vector3(0,12.2,0),Vector3(49,0.4,57),Color("345b53"),true)
	var nome: Label3D = mundo.placa(self,Vector3(0,13.3,-28),preload("res://scripts/deliveries.gd").EMPRESAS[numero]); nome.visibility_range_end = 130; nome.font_size = 48; nome.pixel_size = 0.035
	precos = mundo.placa(self,Vector3(15,4,-28.5),""); precos.visibility_range_end = 25; precos.font_size = 25
	porta = mundo.caixa(self,Vector3(0,4,-28),Vector3(12,8,0.2),Color("608e70"),true)
	mundo.placa(self,Vector3(0,9,-28.3),"RECEPÇÃO · ENTRE E PARE").visibility_range_end = 50
	for lado: float in [-1,1]: mundo.caixa(self,Vector3(lado*5.5,0.08,-5),Vector3(0.15,0.06,40),Color("dfbc49"))
	var cancela: Node3D = preload("res://scripts/industrial_gate.gd").new(); cancela.mundo = mundo; cancela.position = Vector3(0,0,-38); add_child(cancela)
	for z: float in [-14,10]:
		var luz: OmniLight3D = OmniLight3D.new(); luz.position = Vector3(0,8,z); luz.omni_range = 25; luz.light_energy = 1.1; luz.shadow_enabled = false; luz.distance_fade_enabled = true; luz.distance_fade_begin = 65; add_child(luz)
	preload("res://scripts/industrial_art.gd").compactar(self,[porta])
	funcionario = preload("res://scripts/warehouse_attendant.gd").new(); funcionario.mundo = mundo; funcionario.posto = self; funcionario.nome = ["Amélia","Bento","Sara"][numero]; funcionario.assento = Vector3(8,0,-19); funcionario.corredor = Vector3(4.5,0,-16); add_child(funcionario)
	actualizar()
func perto() -> bool:
	return preload("res://scripts/layout.gd").distancia(mundo.jogador.global_position,global_position+Vector3(0,0,-42))<5
func na_garagem(v: Node3D) -> bool:
	var p: Vector3 = to_local(v.global_position)
	return absf(p.x)<5 and p.z>-10 and p.z<18
func carga_aceite(carga: Dictionary) -> int:
	var n: int = 0
	for c: int in carga:
		if mundo.economia.aceita(numero,c): n += int(carga[c])
	return n
func encomendar_descarga(veiculo: Node3D = null) -> bool:
	if funcionario.ocupado(): return false
	var carga: Dictionary = mundo.sacola if veiculo==null else veiculo.carga
	var n: int = carga_aceite(carga)
	if n<=0: return false
	if veiculo!=null:
		var p: Vector3 = to_local(veiculo.global_position)
		if absf(p.x)>5 or p.z<-10 or p.z>18 or not mundo.armazem.parado(veiculo): return false
	elif not perto(): return false
	var alvo: Node3D = mundo.jogador if veiculo==null else veiculo; var espera: Vector3 = alvo.global_position
	var recolha: Vector3 = funcionario.ponto_transporte(veiculo) if veiculo!=null else espera+Vector3(0.9,0,0)
	var condicao: Callable = func() -> bool: return is_instance_valid(alvo) and alvo.global_position.distance_to(espera)<1.5 and (veiculo==null or mundo.armazem.parado(veiculo))
	var aplicar: Callable = func() -> int:
		var antes: int = carga_aceite(carga)
		mundo.entregas.entregar(carga,numero); mundo.economia.vender(carga,numero)
		if is_instance_valid(veiculo): veiculo.actualizar_carga()
		return antes-carga_aceite(carga)
	var cultura: int = numero
	if numero==2 and int(carga.get(2,0))==0: cultura = 3
	return funcionario.iniciar("A receber mercadoria",n,cultura,veiculo,recolha,to_global(Vector3(7.5,0,-10)),condicao,aplicar)
func actualizar() -> void:
	var texto: String = "COMPRA POR UNIDADE"
	for c: int in range(4):
		if mundo.economia.aceita(numero,c): texto += "\n%s · %d MT" % [preload("res://scripts/crop.gd").NOMES[c],mundo.economia.preco(numero,c)]
	precos.text = texto
func _process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	var alvo: Node3D = mundo.trator_actual if mundo.trator_actual!=null else mundo.jogador
	var abrir: bool = alvo.position.distance_to(position+Vector3(0,0,-28))<22
	abertura = move_toward(abertura,1.0 if abrir else 0.0,delta*1.2)
	var h: float = lerpf(8,0.12,abertura); porta.mesh.size.y = h; porta.position.y = 8-h/2
	var colisor: CollisionShape3D = porta.get_child(0).get_child(0); colisor.shape.size.y = h
	var transportes: Array[Node3D] = []; transportes.append_array(mundo.carrinhas)
	if mundo.caminhao!=null: transportes.append(mundo.caminhao)
	for v: Node3D in transportes:
		var conduzido: bool = mundo.trator_actual==v if v==mundo.caminhao else v.tractor!=null and v.tractor==mundo.trator_actual
		if conduzido and na_garagem(v) and mundo.armazem.parado(v): encomendar_descarga(v)
	intervalo += delta
	if intervalo>=2: intervalo = 0; actualizar()
