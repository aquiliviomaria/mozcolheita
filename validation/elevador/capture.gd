extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = mundo.casa.to_global(p); mundo.camera.olhar_fixo = mundo.casa.to_global(alvo); mundo.camera._process(1); mundo.casa._process(0); mundo.hud._process(0.1)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/elevador/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-elevador-isolada.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	var lar: Node3D = mundo.casa.vida_domestica; var e: Node3D = mundo.casa.elevador
	lar.set_physics_process(false); e.set_physics_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR)
	await foto("portas-fechadas",Vector3(-3.6,3.2,1),Vector3(-5,2.3,-3))
	lar.interagir()
	for i: int in range(150): lar._physics_process(1.0/60)
	await foto("cabine-aberta",Vector3(-4.3,2.9,0.6),Vector3(-5,2.2,-4.5))
	e.seleccionar(1)
	for i: int in range(40): lar._physics_process(1.0/60)
	await foto("painel-interior",Vector3(-3.7,e.position.y+2.5,-3.7),Vector3(-4.7,e.position.y+1.6,-6.7))
	for i: int in range(360): lar._physics_process(1.0/60)
	await foto("chegada-quarto",Vector3(-3.3,8.8,1),Vector3(-5,7.4,-3.5))
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
