extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = p; mundo.camera.olhar_fixo = alvo; mundo.camera._process(1)
	mundo.casa._process(1); mundo.hud._process(0.3); mundo.painel_conducao._process(0)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/casa_aberta/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-casa-isolada.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	await foto("varanda-sem-cobertura",Vector3(12,13,-19),Vector3(-8,3,-45))
	mundo.jogador.position = mundo.casa.to_global(Vector3(0,0.65,0))
	await foto("interior",mundo.casa.to_global(Vector3(0,5,6.5)),mundo.casa.to_global(Vector3(0,1,0)))
	mundo.tratores[0].entrar()
	await foto("tractor-sem-painel",mundo.tratores[0].position+Vector3(7,5,7),mundo.tratores[0].position+Vector3(0,1,0))
	mundo.tratores[0].rapidez = 0; mundo.tratores[0].sair()
	mundo.jogador.position = mundo.drones[0].position+Vector3(0,0,1.4); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1; mundo.drones[0].assumir()
	await foto("drone-sem-painel",mundo.drones[0].position+Vector3(6,4,6),mundo.drones[0].position)
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop(); quit()
