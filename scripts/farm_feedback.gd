extends Node3D
## Seis efeitos reutilizados; som e texto limitados por distância e frequência.
var mundo: Node3D
var particulas: Array[CPUParticles3D] = []
var textos: Array[Label3D] = []
var idades: Array[float] = []
var sons: Dictionary = {}
var audio: AudioStreamPlayer3D
var proximo: int = 0
var espera: float = 0
var emitidos: int = 0
func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true; material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var malha: BoxMesh = BoxMesh.new(); malha.size = Vector3.ONE*0.035; malha.material = material
	for i: int in range(6):
		var p: CPUParticles3D = CPUParticles3D.new(); p.emitting = false; p.one_shot = true; p.amount = 12; p.lifetime = 0.55; p.explosiveness = 0.95; p.direction = Vector3.UP; p.spread = 65; p.initial_velocity_min = 0.7; p.initial_velocity_max = 1.7; p.gravity = Vector3(0,-4,0); p.mesh = malha; add_child(p); particulas.append(p)
		var rotulo: Label3D = mundo.placa(self,Vector3.ZERO,""); rotulo.font_size = 30; rotulo.pixel_size = 0.008; rotulo.no_depth_test = true; rotulo.hide(); textos.append(rotulo); idades.append(2.0)
	audio = AudioStreamPlayer3D.new(); audio.max_distance = 24; audio.unit_size = 5; audio.volume_db = -12; add_child(audio)
	for acao: String in ["lavrar","semear","regar","colher"]: sons[acao] = som(acao)
func som(acao: String) -> AudioStreamWAV:
	const TAXA: int = 12000
	var tamanho: int = 3000 if acao=="regar" else 1800
	var dados: PackedByteArray = []; dados.resize(tamanho*2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = 927
	var ruido: float = 0
	for i: int in range(tamanho):
		var t: float = float(i)/TAXA; var fase: float = float(i)/tamanho
		ruido = lerpf(ruido,rng.randf_range(-1,1),0.35)
		var onda: float = 0
		match acao:
			"lavrar": onda = (sin(TAU*95*t)+ruido*1.6)*exp(-fase*7)*0.5
			"semear": onda = ruido*exp(-fase*12)*0.8+sin(TAU*410*t)*exp(-fase*16)*0.18
			"regar": onda = ruido*sin(fase*PI)*0.55
			"colher": onda = sin(TAU*(660+floorf(fase*3)*170)*t)*sin(fase*PI)*0.35
		dados.encode_s16(i*2,int(clampf(onda,-1,1)*24000))
	var wav: AudioStreamWAV = AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = TAXA; wav.data = dados; return wav
func mostrar(chave: Vector2i,acao: String,cultura: int,quantidade: int = 0) -> void:
	if mundo.hud==null or mundo.pausado() or espera>0: return
	var ponto: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5); ponto.y = mundo.altura(ponto)+0.12
	var observador: Vector3 = mundo.camera.camara.global_position
	if ponto.distance_squared_to(observador)>24*24: return
	espera = 0.12; emitidos += 1
	var p: CPUParticles3D = particulas[proximo]; p.position = ponto; p.speed_scale = 1/maxf(1,Engine.time_scale)
	p.color = {"lavrar":Color("99704a"),"semear":Color("d7ba6f"),"regar":Color("75cce7"),"colher":Color("ffda74")}[acao]
	p.scale_amount_min = 0.5; p.scale_amount_max = 1.4 if acao=="regar" else 2.5
	p.restart(); p.emitting = true
	var rotulo: Label3D = textos[proximo]; rotulo.position = ponto+Vector3.UP*0.55; rotulo.modulate.a = 1; rotulo.show(); idades[proximo] = 0
	rotulo.text = "+%d %s" % [quantidade,preload("res://scripts/crop.gd").NOMES[cultura]] if acao=="colher" else {"lavrar":"Terra preparada","semear":"Semente plantada","regar":"Rega concluída"}[acao]
	rotulo.modulate = p.color.lightened(0.35)
	audio.position = ponto; audio.stream = sons[acao]; audio.play()
	proximo = (proximo+1)%6
func _process(delta: float) -> void:
	var real_delta: float = delta/maxf(1,Engine.time_scale)
	espera = maxf(0,espera-real_delta)
	for i: int in range(6):
		particulas[i].speed_scale = 1/maxf(1,Engine.time_scale)
		if idades[i]>=1: continue
		idades[i] += real_delta; textos[i].position.y += real_delta*0.7; textos[i].modulate.a = clampf((1-idades[i])*2,0,1)
		if idades[i]>=1: textos[i].hide()
