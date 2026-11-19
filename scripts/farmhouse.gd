extends Node3D
## Casa principal com alpendre, logótipo e ponto de partida à frente da porta.
const LOCAL: Vector3 = Vector3(-8,0,-51)
const INICIO: Vector3 = Vector3(-8,0,-37)
var mundo: Node3D
func _ready() -> void:
	position = LOCAL; position.y = mundo.altura(position)
	mundo.caixa(self,Vector3(0,0.18,0),Vector3(25,0.36,19),Color("b3a080"),true)
	mundo.caixa(self,Vector3(0,3.4,1),Vector3(22,6.4,14),Color("f2dfb4"),true)
	# Telhado de duas águas com beirais e varanda orientada para o campo.
	for lado: float in [-1,1]:
		var telha: Node3D = mundo.caixa(self,Vector3(lado*5.8,7.1,1),Vector3(12.2,0.24,16),Color("b95836")); telha.rotation.z = -lado*0.22
	mundo.caixa(self,Vector3(0,4.5,9),Vector3(24,0.18,5),Color("c66d42"))
	for x: float in [-10,-5,5,10]: mundo.caixa(self,Vector3(x,2.4,10.7),Vector3(0.27,4.5,0.27),Color("f8e9cb"),true)
	mundo.caixa(self,Vector3(0,1.8,8.06),Vector3(2.5,3.2,0.08),Color("14532d"))
	mundo.caixa(self,Vector3(0.85,1.7,8.15),Vector3(0.1,0.1,0.08),Color("e0b55c"))
	for x: float in [-7,-3.7,3.7,7]:
		mundo.caixa(self,Vector3(x,2.8,8.06),Vector3(2.2,2.3,0.10),Color("568b91"))
		for lado: float in [-1,1]: mundo.caixa(self,Vector3(x+lado*1.26,2.8,8.1),Vector3(0.34,2.5,0.08),Color("238b45"))
		mundo.caixa(self,Vector3(x,2.8,8.16),Vector3(0.06,2.3,0.05),Color("f8e9cb"))
	var logo: Sprite3D = Sprite3D.new(); logo.texture = preload("res://MozColheita-icon.png"); logo.pixel_size = 0.0026; logo.position = Vector3(0,5.45,8.2); add_child(logo)
	mundo.placa(self,Vector3(0,8.5,8),"MOZCOLHEITA · CASA PRINCIPAL").visibility_range_end = 60
	for x: float in [-12,12]:
		mundo.caixa(self,Vector3(x,0.7,9),Vector3(1.3,1.1,1.3),Color("b3633d"))
		var folhas: SphereMesh = SphereMesh.new(); folhas.radius = 0.8; folhas.height = 1.3
		var vista: MeshInstance3D = MeshInstance3D.new(); vista.mesh = folhas; vista.position = Vector3(x,1.6,9); vista.material_override = mundo.material(Color("238b45")); add_child(vista)
