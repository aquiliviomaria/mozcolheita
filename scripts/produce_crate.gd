extends Node3D
## Caixa aberta: produtos e contagem representam stock real, nunca uma textura de tampa.
var mundo: Node3D
var cultura: int = 0
var quantidade: int = -1
var produtos: Array[Node3D] = []
var rotulo: Label3D
func _ready() -> void:
	mundo.caixa(self,Vector3(0,0.10,0),Vector3(1.9,0.18,1.65),Color("a97e47"))
	for y: float in [0.30,0.57]:
		for lado: float in [-1,1]:
			mundo.caixa(self,Vector3(lado*0.92,y,0),Vector3(0.08,0.21,1.7),Color("bd925b"))
			mundo.caixa(self,Vector3(0,y,lado*0.8),Vector3(1.8,0.21,0.08),Color("bd925b"))
	for i: int in range(12):
		var produto: Node3D = Node3D.new(); add_child(produto); produtos.append(produto)
		produto.position = Vector3(-0.63+(i%4)*0.42,0.50,-0.5+(i/4)*0.48)
		var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = preload("res://scripts/produce_mesh.gd").modelo(cultura); produto.add_child(vista)
	rotulo = mundo.placa(self,Vector3(0,1.2,0),""); rotulo.visibility_range_end = 24; rotulo.font_size = 36
	actualizar(0)
func actualizar(nova: int) -> void:
	if nova==quantidade: return
	quantidade = nova
	for i: int in range(produtos.size()): produtos[i].visible = i<mini(12,nova)
	rotulo.text = "%s · %d un." % [preload("res://scripts/crop.gd").NOMES[cultura],nova]
