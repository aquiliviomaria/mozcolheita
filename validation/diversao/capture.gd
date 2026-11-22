extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String) -> void:
	mundo.hud._process(0.3); mundo.painel_conducao._process(0)
	for i: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/diversao/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-diversao-isolada.mozsave"; mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	await foto("menu-gravacao")
	mundo.hud.escolher(false); mundo.jogador.position = Vector3(12,mundo.altura(Vector3(12,0,-7)),-7)
	await foto("campo-hud")
	mundo.hud.alternar(); mundo.hud.paginas.current_tab = 3; mundo.hud.perfil_entrega.select(0); await foto("entregas-pequenas")
	mundo.hud.perfil_entrega.select(2); mundo.hud.urgencia_entrega.select(2); await foto("entregas-grandes")
	mundo.hud.alternar()
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = Vector3(15,3,-8); mundo.camera.olhar_fixo = Vector3(12,0.6,-4)
	var chave: Vector2i = Vector2i(12,-4)
	mundo.terreno.trabalhar(chave,"lavrar"); mundo.terreno.trabalhar(chave,"semear"); mundo.terreno.trabalhar(chave,"regar"); mundo.terreno.avancar(mundo.terreno.DURACAO)
	mundo.feedback.espera = 0; mundo.terreno.trabalhar(chave,"colher")
	await foto("colheita-feedback")
	mundo.camera.enquadramento = false; mundo.tratores[0].entrar(); await foto("tractor-icones")
	mundo.tratores[0].rapidez = 0; mundo.tratores[0].sair()
	mundo.jogador.position = mundo.drones[0].position+Vector3(0,0,1.4); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1
	mundo.drones[0].assumir(); await foto("drone-icones")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
