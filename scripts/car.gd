extends "res://scripts/tractor.gd"
## Automóvel familiar com cabine transparente e dois bancos utilizáveis.
func _ready() -> void:
	add_to_group("carros_jogaveis"); collision_layer = 4; collision_mask = 1|2|4|8|16
	assento_condutor = Vector3(-0.48,0.22,0.4); assento_passageiro = Vector3(0.48,0.22,0.4)
	var col: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new(); forma.size = Vector3(2.2,1.9,4.3); col.shape = forma; col.position.y = 1; add_child(col)
	var cor: Color = Color("397e98") if numero==0 else Color("d4b36c")
	mundo.caixa(self,Vector3(0,0.65,0),Vector3(2.1,0.55,4.2),cor)
	mundo.caixa(self,Vector3(0,1,-1.25),Vector3(2.05,0.25,1.5),cor)
	mundo.caixa(self,Vector3(0,1,1.65),Vector3(2.05,0.3,0.8),cor)
	mundo.caixa(self,Vector3(0,2.72,0.35),Vector3(2.2,0.15,2.6),cor)
	for lado: float in [-1,1]:
		mundo.caixa(self,Vector3(lado*1.04,1,0.35),Vector3(0.12,0.5,2.3),cor)
		for z: float in [-0.8,1.5]: mundo.caixa(self,Vector3(lado*1.02,1.98,z),Vector3(0.09,1.4,0.09),cor)
		mundo.caixa(self,Vector3(lado*0.48,0.98,0.4),Vector3(0.75,0.2,0.8),Color("263237"))
		mundo.caixa(self,Vector3(lado*0.48,1.35,0.8),Vector3(0.75,0.7,0.14),Color("263237"))
		for z: float in [-1.3,1.3]: rodas.append(preload("res://scripts/vehicle_art.gd").roda(self,Vector3(lado*1.03,0.42,z),0.42,0.25))
	for z: float in [-0.83,1.53]:
		var vidro: Node3D = mundo.caixa(self,Vector3(0,1.9,z),Vector3(1.94,1.4,0.03),Color.WHITE)
		var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.albedo_color = Color(0.6,0.8,0.85,0.14); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.cull_mode = BaseMaterial3D.CULL_DISABLED; vidro.material_override = mat
	preload("res://scripts/vehicle_lights.gd").instalar(self,mundo,"carro")
func candidato() -> Node3D: return null
func engatar() -> bool:
	mundo.avisar("Automóvel de dois lugares · C chama companhia"); return false
