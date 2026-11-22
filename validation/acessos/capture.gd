extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = p; mundo.camera.olhar_fixo = alvo; mundo.camera._process(1); mundo.casa._process(0); mundo.hud._process(0.1)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/acessos/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-acessos.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	mundo.jogador.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.familia.set_physics_process(false)
	mundo.jogador.position = mundo.armazem.ENTREGA
	await foto("armazem-quinta",Vector3(100,35,-6),Vector3(48,3,40))
	await foto("estradas-niveladas",Vector3(-310,30,-170),Vector3(-300,0,-250))
	var lar: Node3D = mundo.casa.vida_domestica; var e: Node3D = mundo.casa.elevador
	lar.set_physics_process(false); e.set_physics_process(false); mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR); lar.interagir()
	for i: int in range(150): lar._physics_process(1.0/60)
	e.seleccionar(1)
	for i: int in range(40): lar._physics_process(1.0/60)
	await foto("elevador-vidro",mundo.casa.to_global(Vector3(-4.3,3.1,0.8)),mundo.casa.to_global(Vector3(-5,2.1,-4.5)))
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
