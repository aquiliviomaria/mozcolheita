extends Node
## Céu e iluminação partilham o relógio usado nas culturas e contratos.
var mundo: Node3D
var sol: DirectionalLight3D
var ambiente: Environment
var ceu: ProceduralSkyMaterial
var lua: DirectionalLight3D
var luminosidade: float = 1.0
var lampadas: Array[OmniLight3D] = []
func _ready() -> void:
	ceu.sun_angle_max = 2.0
	lua = DirectionalLight3D.new(); lua.light_color = Color("819bd3"); lua.light_energy = 0.12
	mundo.add_child.call_deferred(lua)
	criar_postes.call_deferred()
func _process(_delta: float) -> void:
	if mundo.calendario==null: return
	var fase: float = fmod(mundo.calendario.decorrido,600.0)/600.0
	var angulo: float = (fase+0.04)*TAU
	luminosidade = smoothstep(-0.12,0.22,sin(angulo))
	sol.rotation = Vector3(-angulo,deg_to_rad(-25),0)
	sol.light_energy = luminosidade*1.1
	sol.light_color = Color("ffc687").lerp(Color("fff2dc"),clampf(sin(angulo)*2,0,1))
	lua.rotation = Vector3(-angulo+PI,deg_to_rad(-25),0)
	lua.light_energy = (1-luminosidade)*0.18
	ceu.sky_top_color = Color("080f2c").lerp(Color("358bd0"),luminosidade)
	ceu.sky_horizon_color = Color("283348").lerp(Color("b4d9eb"),luminosidade)
	ceu.ground_horizon_color = ceu.sky_horizon_color
	ceu.ground_bottom_color = Color("141c25").lerp(Color("657654"),luminosidade)
	ambiente.ambient_light_color = Color("8a9dc9").lerp(Color("eef2df"),luminosidade)
	ambiente.ambient_light_energy = lerpf(0.27,0.65,luminosidade)
	for luz: OmniLight3D in lampadas: luz.light_energy = (1-luminosidade)*1.4
	for cor: Color in [Color("477a80"),Color("729a9b")]:
		var material: StandardMaterial3D = mundo.material(cor)
		material.emission_enabled = true; material.emission = Color("ffd69a").srgb_to_linear(); material.emission_energy_multiplier = (1-luminosidade)*0.65

func criar_postes() -> void:
	var locais: Array[Vector3] = [Vector3(-14,0,-41),Vector3(-2,0,-41),Vector3(44,0,24),Vector3(8,0,76),Vector3(68,0,76)]
	for x: float in [126,199,264,339]:
		for z: float in [-94,26,134]: locais.append(Vector3(x,0,z))
	for p: Vector3 in locais:
		p.y = mundo.altura(p)
		mundo.caixa(mundo,p+Vector3.UP*2.5,Vector3(0.12,5,0.12),Color("59665a"))
		var foco: Node3D = mundo.caixa(mundo,p+Vector3.UP*5,Vector3(0.65,0.16,0.5),Color("fff0bb"))
		var material: StandardMaterial3D = StandardMaterial3D.new(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.albedo_color = Color("ffe6aa"); foco.material_override = material
		var luz: OmniLight3D = OmniLight3D.new(); luz.position = p+Vector3.UP*4.5; luz.light_color = Color("ffdb9e"); luz.omni_range = 15; luz.distance_fade_enabled = true; luz.distance_fade_begin = 45; luz.distance_fade_length = 15; mundo.add_child(luz); lampadas.append(luz)


static func canto_galo() -> AudioStreamWAV:
	# Síntese determinista de quatro sílabas; não exige ficheiros externos.
	const TAXA: int = 22050
	var dados: PackedByteArray = []; dados.resize(TAXA*3*2)
	var fase: float = 0
	for i: int in range(TAXA*3):
		var t: float = float(i)/TAXA
		var inicio: float = 0.12 if t<0.45 else 0.5 if t<0.8 else 0.88 if t<1.2 else 1.28
		var duracao: float = 0.25 if t<1.28 else 1.25
		var local: float = (t-inicio)/duracao
		var envelope: float = sin(clampf(local,0,1)*PI) if local>0 and local<1 else 0
		var frequencia: float = (620+180*sin(clampf(local,0,1)*PI))*(1+0.035*sin(t*85))
		fase += TAU*frequencia/TAXA
		var amostra: float = (sin(fase)+0.45*sin(fase*2)+0.16*sin(fase*3))*envelope*0.38
		dados.encode_s16(i*2,int(amostra*32767))
	var audio: AudioStreamWAV = AudioStreamWAV.new(); audio.format = AudioStreamWAV.FORMAT_16_BITS; audio.mix_rate = TAXA; audio.data = dados
	return audio
