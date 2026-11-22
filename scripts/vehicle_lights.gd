extends Node3D
## Faróis locais automáticos; sem sombras e com corte por distância para limitar custo.
var mundo: Node3D
var focos: Array[Light3D] = []
var lentes: Array[StandardMaterial3D] = []
static func instalar(pai: Node3D,origem: Node3D,tipo: String) -> Node3D:
	var sistema: Node3D = load("res://scripts/vehicle_lights.gd").new()
	sistema.mundo = origem; sistema.name = "IluminacaoNocturna"; pai.add_child(sistema)
	if tipo=="drone":
		for lado: float in [-1,1]:
			sistema.lente(Vector3(lado*0.9,0.13,-0.8),Color("f55746") if lado<0 else Color("67ff9d"),0.1)
			sistema.lente(Vector3(lado*0.9,0.13,0.8),Color("fff1d1"),0.1)
		var luz: SpotLight3D = sistema.foco(Vector3(0,-0.3,0),Color("d6edff"),16,52)
		luz.rotation_degrees.x = -90
	else:
		var frente: float = -1.72; var tras: float = 1.55; var altura: float = 1.3; var largura: float = 0.48
		if tipo=="carro": frente = -1.91; tras = 1.91; altura = 0.84; largura = 0.61
		elif tipo=="carga": frente = -2.98; tras = 3.16; altura = 1.11; largura = 0.64
		elif tipo=="agricola": frente = -2.12; tras = 1.85; altura = 1.45; largura = 0.43
		elif tipo=="camião": frente = -3.48; tras = 3.84; altura = 1.45; largura = 0.91
		for lado: float in [-1,1]:
			sistema.lente(Vector3(lado*largura,altura,frente),Color("fff2ca"),0.14)
			sistema.lente(Vector3(lado*largura,altura,tras),Color("ff4739"),0.1)
		var farol: SpotLight3D = sistema.foco(Vector3(0,altura,frente-0.05),Color("fff0cd"),32,38)
		farol.rotation_degrees.x = -12
	return sistema
func lente(p: Vector3,cor: Color,raio: float) -> void:
	var n: MeshInstance3D = MeshInstance3D.new(); var esfera: SphereMesh = SphereMesh.new(); esfera.radius = raio; esfera.height = raio*2; esfera.radial_segments = 8; esfera.rings = 4
	var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.albedo_color = cor; mat.emission_enabled = true; mat.emission = cor; mat.emission_energy_multiplier = 0
	n.mesh = esfera; n.material_override = mat; n.position = p; add_child(n); lentes.append(mat)
func foco(p: Vector3,cor: Color,alcance: float,angulo: float) -> SpotLight3D:
	var luz: SpotLight3D = SpotLight3D.new(); luz.position = p; luz.light_color = cor; luz.spot_range = alcance; luz.spot_angle = angulo; luz.spot_attenuation = 0.6; luz.shadow_enabled = false
	luz.distance_fade_enabled = true; luz.distance_fade_begin = 60; luz.distance_fade_length = 20; luz.visible = false; add_child(luz); focos.append(luz); return luz
func _process(_delta: float) -> void:
	if mundo.luz_diaria==null: return
	var noite: float = 1.0-mundo.luz_diaria.luminosidade
	for luz: Light3D in focos:
		luz.visible = noite>0.1; luz.light_energy = noite*3.2
	for mat: StandardMaterial3D in lentes: mat.emission_energy_multiplier = noite*2.5
