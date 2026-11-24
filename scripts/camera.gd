extends Node3D
## Órbita independente do corpo. Uma consulta física evita atravessar edifícios.
var mundo: Node3D
var alvo: Node3D
var camara: Camera3D
var giro: float = 0.0
var inclinacao: float = -0.55
var distancia: float = 7.5
var livre: bool = false
var enquadramento: bool = false
var ponto_fixo: Vector3 = Vector3.ZERO
var olhar_fixo: Vector3 = Vector3.ZERO

func _ready() -> void:
	camara = Camera3D.new()
	camara.fov = 65.0
	camara.far = 1100.0
	add_child(camara)
	camara.make_current()

func _unhandled_input(evento: InputEvent) -> void:
	if mundo.pausado(): return
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and (not enquadramento or no_elevador()):
		rodar_vista(evento.relative)
	if evento is InputEventMouseButton and evento.pressed and not evento.shift_pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP: distancia = maxf(3.0,distancia-0.6)
		if evento.button_index == MOUSE_BUTTON_WHEEL_DOWN: distancia = minf(15.0,distancia+0.6)
	if evento is InputEventKey and evento.pressed:
		if evento.physical_keycode in [KEY_PLUS,KEY_EQUAL,KEY_KP_ADD]: distancia = maxf(3.0,distancia-0.6)
		if evento.physical_keycode in [KEY_MINUS,KEY_KP_SUBTRACT]: distancia = minf(15.0,distancia+0.6)

func _process(delta: float) -> void:
	if not mundo.pausado() and (not enquadramento or no_elevador()):
		var controlo: GDScript = preload("res://scripts/input_drive.gd")
		giro -= controlo.eixo(JOY_AXIS_RIGHT_X)*delta*2
		inclinacao = clampf(inclinacao-controlo.eixo(JOY_AXIS_RIGHT_Y)*delta*1.5,-1.25,-0.12)
	if livre:
		var entrada: Vector3 = Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camara.rotation = Vector3(inclinacao,giro,0)
		if not mundo.pausado(): camara.position += camara.basis*entrada.limit_length(1)*(delta/maxf(1,Engine.time_scale))*(65 if Input.is_physical_key_pressed(KEY_SHIFT) else 24)
		return
	if no_elevador():
		actualizar_elevador(); return
	if enquadramento:
		camara.global_position = camara.global_position.lerp(ponto_fixo,minf(1.0,delta*8.0))
		camara.look_at(olhar_fixo)
		return
	if not is_instance_valid(alvo): return
	var centro: Vector3 = alvo.global_position+Vector3.UP*1.3
	var deslocamento: Vector3 = Basis.from_euler(Vector3(inclinacao,giro,0))*Vector3(0,0,distancia)
	var destino: Vector3 = centro+deslocamento
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(centro,destino,1)
	var obstaculo: Dictionary = get_world_3d().direct_space_state.intersect_ray(consulta)
	if not obstaculo.is_empty(): destino = obstaculo.position+obstaculo.normal*0.25
	camara.global_position = destino
	camara.look_at(centro)

func rodar_vista(movimento: Vector2) -> void:
	if mundo.pausado() or (enquadramento and not no_elevador()): return
	giro -= movimento.x*0.003
	inclinacao = clampf(inclinacao-movimento.y*0.003,-1.25,-0.12)

func no_elevador() -> bool:
	return mundo.casa!=null and mundo.casa.elevador!=null and mundo.casa.elevador.permite_andar()
func actualizar_elevador() -> void:
	var cabine: Node3D = mundo.casa.elevador
	var centro: Vector3 = mundo.jogador.global_position+Vector3.UP*1.35
	var p: Vector3 = cabine.to_local(centro+Basis.from_euler(Vector3(inclinacao,giro,0))*Vector3(0,0,1.35))
	# Órbita curta contida na cabine: o rato roda a vista sem atravessar as paredes.
	p.x = clampf(p.x,-1.6,1.6); p.z = clampf(p.z,-1.6,1.6); p.y = clampf(p.y,0.6,3.05)
	camara.global_position = cabine.to_global(p); camara.look_at(centro)

func alternar_livre() -> void:
	if mundo.contrato.activo or mundo.trator_actual!=null or mundo.drone_actual!=null: mundo.avisar("Saia do veículo antes de usar a câmara livre."); return
	livre = not livre
	mundo.avisar("Câmara livre · WASD · Q/E altura · V regressar" if livre else "Câmara do agricultor")
