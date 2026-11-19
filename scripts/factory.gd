extends Node3D
## Cada fábrica apresenta os seus preços e tem uma zona de entrega na fachada.
var mundo: Node3D
var numero: int = 0
var precos: Label3D
var intervalo: float = 0.0

func _ready() -> void:
	position = Vector3(-60+numero*60,0,110)
	position.y = mundo.altura(position)
	var cor: Color = [Color("a4a88b"),Color("9c9983"),Color("ad927b")][numero]
	mundo.caixa(self,Vector3(0,3,0),Vector3(16,6,12),cor,true)
	mundo.caixa(self,Vector3(0,6.2,0),Vector3(17,0.3,13),Color("4b666b"))
	mundo.caixa(self,Vector3(0,2,-6.05),Vector3(4,4,0.08),Color("597e78"))
	mundo.placa(self,Vector3(0,7,-6),"FÁBRICA DE FRUTOS "+["A","B","C"][numero])
	precos = mundo.placa(self,Vector3(0,3.4,-6.15),"")
	precos.font_size = 25
	precos.visibility_range_end = 18
	actualizar()

func perto() -> bool:
	var diferenca: Vector3 = mundo.jogador.global_position-(global_position+Vector3(0,0,-8))
	diferenca.y = 0
	return diferenca.length()<3.5

func actualizar() -> void:
	var texto: String = "COMPRA POR UNIDADE"
	for cultura: int in range(4): texto += "\n%s · %d MT" % [preload("res://scripts/crop.gd").NOMES[cultura],mundo.economia.preco(numero,cultura)]
	precos.text = texto

func _process(delta: float) -> void:
	intervalo += delta
	if intervalo>=2:
		intervalo = 0
		actualizar()
