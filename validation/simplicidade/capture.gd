extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,ponto: Vector3,alvo: Vector3) -> void:
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = ponto; mundo.camera.olhar_fixo = alvo
	mundo.hud._process(0.3); mundo.painel_conducao._process(0)
	for i: int in range(45): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/simplicidade/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-simplicidade-isolada.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	await foto("casa-varanda",Vector3(12,13,-19),Vector3(-8,3,-45))
	mundo.calendario.decorrido = 400
	var tractor: Node3D = mundo.tratores[0]; tractor.entrar()
	await foto("tractor-noite",tractor.position+Vector3(7,5,7),tractor.position+Vector3(0,0,-8))
	tractor.rapidez = 0; tractor.sair()
	mundo.jogador.position = mundo.drones[0].position+Vector3(0,0,1.4); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1; mundo.drones[0].assumir()
	await foto("drone-noite",mundo.drones[0].position+Vector3(6,4,6),mundo.drones[0].position+Vector3(0,-1,0))
	mundo.drones[0].devolver(); mundo.calendario.decorrido = 100
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
