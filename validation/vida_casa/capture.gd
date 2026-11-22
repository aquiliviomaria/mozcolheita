extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,ponto: Vector3,alvo: Vector3) -> void:
	if nome!="mesa-refeicao": mundo.aviso_tempo = 0
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = ponto; mundo.camera.olhar_fixo = alvo; mundo.camera._process(1)
	mundo.casa._process(0.1); mundo.hud._process(0.3)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/vida_casa/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-vida-casa-isolada.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	var lar: Node3D = mundo.casa.vida_domestica
	await foto("casa-janelas",Vector3(13,12,-19),Vector3(-8,3,-46))
	mundo.jogador.position = mundo.casa.to_global(lar.MESA); lar.interagir(); mundo.vitais.fome = 35
	await foto("mesa-refeicao",mundo.casa.to_global(Vector3(-2.5,4.6,1.5)),mundo.casa.to_global(Vector3(-6.4,1.3,-2.9)))
	lar.levantar(); mundo.jogador.position = mundo.casa.to_global(lar.CAMA)
	await foto("janela-cama",mundo.casa.to_global(Vector3(4,3,-3)),mundo.casa.to_global(Vector3(11.8,2.7,-2)))
	mundo.calendario.decorrido = 410; lar.interagir(); lar.set_process(false); mundo.casa._process(0)
	await foto("descanso-noite",mundo.casa.to_global(Vector3(1.5,5,3.5)),mundo.casa.to_global(Vector3(7,1.8,-2)))
	lar.levantar(); mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
