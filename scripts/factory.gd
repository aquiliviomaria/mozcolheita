extends Node3D
## Fábrica industrial de 48 × 56 m, com cancela, segurança e garagem de entrega.
var mundo: Node3D
var numero: int = 0
var precos: Label3D
var intervalo: float = 0
var local_filial: Vector3 = Vector3.INF
var porta: MeshInstance3D
var abertura: float = 0
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
	actualizar()
func perto() -> bool:
	return preload("res://scripts/layout.gd").distancia(mundo.jogador.global_position,global_position+Vector3(0,0,-42))<5
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
	if mundo.caminhao!=null and mundo.trator_actual==mundo.caminhao:
		var p: Vector3 = to_local(mundo.caminhao.position)
		if absf(p.x)<5 and p.z>-10 and p.z<18 and absf(mundo.caminhao.rapidez)<0.5:
			mundo.entregas.entregar(mundo.caminhao.carga,numero); mundo.economia.vender(mundo.caminhao.carga,numero); mundo.caminhao.actualizar_carga()
	intervalo += delta
	if intervalo>=2: intervalo = 0; actualizar()
