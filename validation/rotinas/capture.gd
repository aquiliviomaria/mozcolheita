extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = p; mundo.camera.olhar_fixo = alvo
	mundo.camera._process(1); mundo.casa._process(0); mundo.hud._process(0.3)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/rotinas/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-rotinas-isolada.mozsave"
	mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica
	mundo.jogador.position = mundo.casa.to_global(lar.SOFA); lar.interagir(); mundo.familia.colocar_actividade("sofa")
	lar.televisao.desenho.actual = 0; lar.televisao.desenho.queue_redraw()
	await foto("televisao-gta-vi",mundo.casa.to_global(Vector3(-7,3.1,4.5)),mundo.casa.to_global(Vector3(-7,3.1,0.4)))
	lar.televisao.desenho.actual = 6; lar.televisao.desenho.queue_redraw()
	await foto("televisao-comunidade",mundo.casa.to_global(Vector3(-7,3.1,4.5)),mundo.casa.to_global(Vector3(-7,3.1,0.4)))
	lar.levantar()
	var p: Node3D = mundo.pessoas[6]; var r: RefCounted = p.rotina
	r.fase_lavoura = 2; r.indice = 0; p.position = r.passos[0].p; p.visual.visible = true; r.actualizar(0.1)
	mundo.jogador.position = p.position+Vector3(2,0,3)
	await foto("vizinho-a-regar",p.position+Vector3(-3,3,4),p.position+Vector3.UP)
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
