extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String) -> void:
	mundo.aviso_tempo = 0
	mundo.camera.enquadramento = true
	mundo.camera.ponto_fixo = mundo.casa.to_global(Vector3(6.2,8.1,-2))
	mundo.camera.olhar_fixo = mundo.casa.to_global(Vector3(11,7.2,-6.5))
	mundo.camera._process(1); mundo.casa._process(0); mundo.hud._process(0.3)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/familia/"+nome+".png")
	print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo)
	mundo.partida.caminho = "user://preview-duche-isolada.mozsave"
	mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	mundo.hud.escolher(false)
	var lar: Node3D = mundo.casa.vida_domestica
	mundo.jogador.position = mundo.casa.to_global(lar.DUCHE)
	lar.interagir(); mundo.familia.colocar_actividade("banho")
	for i: int in range(80): lar._process(0.1)
	await foto("casa-banho")
	lar.duche.pedir_saida()
	for i: int in range(30): lar._process(0.1)
	await foto("duche-saida")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
