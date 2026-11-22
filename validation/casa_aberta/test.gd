extends SceneTree
var falhas: int = 0
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,texto: String) -> void:
	if valor: print("OK · ",texto)
	else: falhas += 1; push_error(texto)
func caminhar(destino_z: float,direccao: float) -> void:
	for passo: int in range(500):
		await physics_frame
		mundo.jogador.velocity = Vector3(0,-3,direccao*4.5); mundo.jogador.move_and_slide()
		if (direccao<0 and mundo.jogador.position.z<destino_z) or (direccao>0 and mundo.jogador.position.z>destino_z): return
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.jogador.set_physics_process(false); mundo.calendario.set_process(false)
	var casa: Node3D = mundo.casa
	exigir(casa.porta.visible and casa.porta.get_node("Folha")!=null,"Porta principal visível e independente das paredes")
	var cobertura: bool = false
	for mesh: MeshInstance3D in casa.find_children("*","MeshInstance3D",true,false):
		if mesh.position.distance_to(Vector3(0,4.5,9))<0.1: cobertura = true
	exigir(not cobertura,"Sem cobertura sobre a varanda")
	Engine.time_scale = 8
	await caminhar(-51,-1)
	exigir(mundo.jogador.position.z < -51 and mundo.jogador.position.y>casa.position.y+0.5,"Entrada física pela rampa e porta até ao centro da casa")
	casa._process(0.1)
	exigir(not casa.telhado[0].visible and not casa.telhado[1].visible,"Interior visível com ocultação do telhado principal")
	await caminhar(-33,1)
	casa._process(0.1)
	exigir(mundo.jogador.position.z > -33,"Saída física da casa pela mesma porta sem ficar preso")
	exigir(casa.telhado[0].visible and casa.telhado[1].visible,"Telhado principal regressa no exterior")
	mundo.jogador.position = casa.to_global(Vector3(0,0.65,3))
	for passo: int in range(110):
		await physics_frame
		mundo.jogador.velocity = Vector3(6,-3,0); mundo.jogador.move_and_slide()
	exigir(casa.to_local(mundo.jogador.position).x<10.7,"Paredes laterais mantêm colisão")
	Engine.time_scale = 1
	exigir(not FileAccess.get_file_as_string("res://scripts/driving_hud.gd").contains("Sem equipamento") and not FileAccess.get_file_as_string("res://scripts/driving_hud.gd").contains("IRRIGAÇÃO"),"Sem painéis auxiliares de estado junto ao mapa")
	mundo.tratores[0].entrar(); mundo.painel_conducao._process(0)
	exigir(mundo.painel_conducao.modo=="tractor" and mundo.painel_conducao.acoes()[0].tecla=="W","Condução e ícones do tractor preservados")
	mundo.tratores[0].rapidez = 0; mundo.tratores[0].sair()
	mundo.jogador.position = mundo.drones[0].position+Vector3(0,0,1.4); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1
	exigir(mundo.drones[0].assumir(),"Drone continua acessível")
	mundo.painel_conducao._process(0); exigir(mundo.painel_conducao.modo=="drone" and mundo.painel_conducao.acoes()[3].tecla=="R","Ícones e lógica de rega preservados")
	mundo.drones[0].devolver(); mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop()
	print("CASA ABERTA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
