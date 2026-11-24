extends Node3D
## Água e áudio espacial reutilizados; descarga apenas ao terminar a utilização.
var mundo: Node3D
var som: AudioStreamPlayer3D
var agua: MeshInstance3D
var restante: float = 0
var descargas: int = 0
func _ready() -> void:
	var botao: Node3D = mundo.caixa(self,Vector3(0,1.79,-0.8),Vector3(0.2,0.035,0.12),Color("a2b3b6")); botao.name = "BotaoDescarga"
	agua = MeshInstance3D.new(); var m: CylinderMesh = CylinderMesh.new(); m.top_radius = 0.3; m.bottom_radius = 0.3; m.height = 0.025; m.radial_segments = 20; agua.mesh = m; agua.position.y = 0.85; agua.scale.z = 1.3; agua.material_override = mundo.material(Color("9ac9d2")); add_child(agua)
	som = AudioStreamPlayer3D.new(); som.max_distance = 16; som.unit_size = 3; som.volume_db = -8; add_child(som)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = 3401
	var dados: PackedByteArray = []; dados.resize(36000*2); var filtrado: float = 0
	for i: int in range(36000):
		var t: float = float(i)/12000; var envelope: float = sin(PI*t/3)
		filtrado = lerpf(filtrado,rng.randf_range(-1,1),0.22)
		var onda: float = filtrado*envelope*0.8+sin(TAU*(90-15*t)*t)*envelope*0.12*(0.5+0.5*sin(t*14))
		dados.encode_s16(i*2,int(clampf(onda,-1,1)*26000))
	var wav: AudioStreamWAV = AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = 12000; wav.data = dados; som.stream = wav
func accionar() -> void:
	descargas += 1; restante = 3; som.play()
func _process(delta: float) -> void:
	if mundo.pausado(): som.stream_paused = true; return
	som.stream_paused = false
	if restante<=0: return
	restante = maxf(0,restante-delta/maxf(1,Engine.time_scale))
	agua.rotation.y += delta*8; agua.position.y = 0.85-0.13*sin(PI*restante/3); agua.scale.x = 1-0.35*sin(PI*restante/3)
