extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String) -> void:
	mundo.aviso_tempo = 0
	mundo.camera.enquadramento = true
	mundo.camera.ponto_fixo = mundo.casa.to_global(Vector3(4.5,9.7,5))
	mundo.camera.olhar_fixo = mundo.casa.to_global(Vector3(8,7,6.8))
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
	lar.comecar_intro(); lar._process(0.7); lar._process(0.8)
	await foto("quarto-casal")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
