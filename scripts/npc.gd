extends "res://scripts/player.gd"
## Peão com percursos pelo portão; tarefas e contratação ficam em módulos próprios.
var numero: int = 0
var servico: Dictionary = {}
var ultimo_servico: String = "Sem contrato"
var vizinho: bool = false
var pausa_trabalho: float = 0.0
var nome: String = ""
var rota: Array[Vector3] = []
var percurso: Array[Vector3] = []
var destino_actual: Vector3 = Vector3.INF
var segmento: int = 0
var fila: Array[Dictionary] = []
var carga: Dictionary = {}
var estado: String = "A passear"
var balão: Label3D
var tempo_fala: float = 0.0
var em_conversa: bool = false
var veiculo: CharacterBody3D
var concluido: int = 0
var pago: int = 0
var ultima_posicao: Vector3 = Vector3.INF
var tempo_preso: float = 0.0
var intervalo_desvio: float = 0.0
var ferramenta_servico: Node3D

func _ready() -> void:
	aparencia = numero+1
	super._ready()
	add_to_group("pessoas")
	balão = mundo.placa(self,Vector3(0,2.25,0),nome)
	balão.font_size = 26
	balão.pixel_size = 0.003
	balão.visibility_range_end = 15

func dizer(texto: String) -> void:
	balão.text = nome+"\n"+texto
	tempo_fala = 4.0

func planear(destino: Vector3) -> void:
	destino_actual = destino
	percurso = preload("res://scripts/layout.gd").caminho(global_position,destino)

func caminhar(destino: Vector3, delta: float, alcance: float = 0.7) -> bool:
	if not destino_actual.is_equal_approx(destino): planear(destino)
	if percurso.is_empty(): return preload("res://scripts/layout.gd").distancia(global_position,destino)<alcance
	var proximo: Vector3 = percurso[0]
	var diferenca: Vector3 = proximo-global_position
	diferenca.y = 0
	if diferenca.length()<(alcance if percurso.size()==1 else 0.7):
		percurso.pop_front()
		velocity = Vector3.ZERO
		return percurso.is_empty()
	var direccao: Vector3 = diferenca.normalized()
	var desvio: Vector3 = Vector3.ZERO
	for outra: Node3D in mundo.pessoas:
		if outra==self or outra.veiculo!=null: continue
		var afastamento: Vector3 = global_position-outra.global_position; afastamento.y = 0
		var distancia: float = afastamento.length()
		if distancia>0.01 and distancia<1.2: desvio += afastamento.normalized()*(1.2-distancia)*1.8
	velocity = (direccao*2.0+desvio).limit_length(2.1)
	velocity.y = -2.0
	# Procura uma direcção livre antes de encostar ao obstáculo.
	var contacto: KinematicCollision3D = KinematicCollision3D.new()
	if test_move(global_transform,direccao*0.85,contacto) and contacto.get_normal().dot(Vector3.UP)<cos(floor_max_angle):
		for angulo: float in [0.52,-0.52,1.05,-1.05,1.57,-1.57,2.1,-2.1]:
			var alternativa: Vector3 = direccao.rotated(Vector3.UP,angulo)
			if not test_move(global_transform,alternativa*0.85):
				velocity = alternativa*1.8; velocity.y = -2; break
	intervalo_desvio = maxf(0,intervalo_desvio-delta)
	if ultima_posicao.is_finite() and global_position.distance_to(ultima_posicao)<0.35: tempo_preso += delta
	else: ultima_posicao = global_position; tempo_preso = 0
	if tempo_preso>1.4 and intervalo_desvio<=0:
		var desvio_local: Array[Vector3] = preload("res://scripts/navigation.gd").contornar(self,proximo)
		if not desvio_local.is_empty(): desvio_local.append_array(percurso); percurso = desvio_local
		tempo_preso = 0; intervalo_desvio = 3.0
	move_and_slide()
	visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direccao.x,-direccao.z),minf(1,delta*8))
	animar(delta,2.0)
	return false

func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	tempo_fala = maxf(0,tempo_fala-delta)
	balão.visible = global_position.distance_to(mundo.jogador.global_position)<15
	if tempo_fala<=0: balão.text = nome+(" · "+estado if contratado else "")
	if em_conversa: return
	if contratado:
		mundo.tarefas.actualizar(self,delta)
	elif not rota.is_empty():
		if vizinho and pausa_trabalho>0:
			pausa_trabalho -= delta
			gesto = 0.65+sin(fase)*0.2
			animar(delta,0)
			return
		if caminhar(rota[segmento],delta):
			segmento = (segmento+1)%rota.size()
			if vizinho: pausa_trabalho = 4.0
