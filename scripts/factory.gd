extends Node3D
## Cada fábrica apresenta os seus preços e tem uma zona de entrega na fachada.
var mundo: Node3D
var numero: int = 0
var precos: Label3D
var intervalo: float = 0.0
var dentro_caminhao: bool = false
var local_filial: Vector3 = Vector3.INF
var porta: Node3D
var abertura: float = 0.0

func _ready() -> void:
	position = Vector3(-60+numero*60,0,110) if not local_filial.is_finite() else local_filial
	position.y = mundo.altura(position)
	preload("res://scripts/architecture.gd").piso(mundo,self,Rect2(-8,-9,16,18))
	var cor: Color = [Color("a4a88b"),Color("9c9983"),Color("ad927b")][numero]
	for lado: float in [-1,1]: mundo.caixa(self,Vector3(lado*8,3.2,0),Vector3(0.35,6.4,18),cor,true)
	mundo.caixa(self,Vector3(0,3.2,9),Vector3(16,6.4,0.35),cor,true)
	mundo.caixa(self,Vector3(0,6.5,0),Vector3(17,0.3,19),Color("315c49"))
	for lado: float in [-1,1]: mundo.caixa(self,Vector3(lado*6.5,3,-9),Vector3(3,6,0.3),cor,true)
	var nome_empresa: Label3D = mundo.placa(self,Vector3(0,7.4,-9),preload("res://scripts/deliveries.gd").EMPRESAS[numero])
	nome_empresa.visibility_range_end = 90; nome_empresa.pixel_size = 0.015; nome_empresa.font_size = 40
	precos = mundo.placa(self,Vector3(6,3.4,-9.2),"")
	precos.font_size = 25
	precos.visibility_range_end = 18
	# Portal de dez metros, cais pintado e acesso sem obstáculos para o camião.
	porta = mundo.caixa(self,Vector3(0,3,-9),Vector3(10,6,0.12),Color("608e70"))
	var instrucao: Label3D = mundo.placa(self,Vector3(0,5.6,-9.3),"ENTREGA · ENTRE E PARE")
	instrucao.visibility_range_end = 45; instrucao.pixel_size = 0.012
	for lado: float in [-1,1]:
		mundo.caixa(self,Vector3(lado*4.7,0.12,0),Vector3(0.18,0.08,14),Color("dfbc49"))
		for z: float in [-8,7]: mundo.caixa(self,Vector3(lado*5.4,0.65,z),Vector3(0.22,1.3,0.22),Color("e5be44"),true)
	actualizar()

func perto() -> bool:
	var diferenca: Vector3 = mundo.jogador.global_position-(global_position+Vector3(0,0,-8))
	diferenca.y = 0
	return diferenca.length()<3.5

func actualizar() -> void:
	var texto: String = "COMPRA POR UNIDADE"
	for cultura: int in range(4):
		if not mundo.economia.aceita(numero,cultura): continue
		texto += "\n%s · %d MT" % [preload("res://scripts/crop.gd").NOMES[cultura],mundo.economia.preco(numero,cultura)]
	precos.text = texto

func _process(delta: float) -> void:
	var perto_porta: bool = mundo.jogador!=null and mundo.jogador.global_position.distance_to(global_position+Vector3(0,0,-9))<15
	if mundo.caminhao!=null and mundo.caminhao.position.distance_to(position)<27: perto_porta = true
	abertura = move_toward(abertura,1.0 if perto_porta else 0.0,delta*1.5)
	porta.scale.y = maxf(0.03,1-abertura); porta.position.y = 6-3*porta.scale.y
	if mundo.caminhao!=null and mundo.trator_actual==mundo.caminhao:
		var local: Vector3 = to_local(mundo.caminhao.position)
		var dentro: bool = absf(local.x)<5.5 and local.z>-3 and local.z<7
		if dentro and absf(mundo.caminhao.rapidez)<0.5:
			mundo.entregas.entregar(mundo.caminhao.carga,numero)
			mundo.economia.vender(mundo.caminhao.carga,numero)
			mundo.caminhao.actualizar_carga()
	intervalo += delta
	if intervalo>=2:
		intervalo = 0
		actualizar()
