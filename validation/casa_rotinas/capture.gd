extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func guardar(nome: String) -> void:
	mundo.aviso_tempo = 0; mundo.casa._process(0); mundo.hud._process(0.1)
	for i: int in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/casa_rotinas/"+nome+".png"); print("FOTO · ",nome)
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.camera.enquadramento = true; mundo.camera.camara.global_position = mundo.casa.to_global(p); mundo.camera.camara.look_at(mundo.casa.to_global(alvo)); await guardar(nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-rotinas.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	mundo.camera.set_process(false); mundo.jogador.set_physics_process(false); mundo.familia.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; lar.set_process(false); lar.set_physics_process(false); mundo.casa.elevador.set_physics_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.MESA); lar.interagir(); mundo.familia.colocar_actividade("mesa"); lar._process(0)
	await foto("sentados-mesa",Vector3(3.3,2.7,3.6),Vector3(7.6,1.3,1.7))
	for i: int in range(4):
		lar.comida.mostrar(i); await foto("ementa-%d" % i,Vector3(8,4.4,-2.2),Vector3(8,1.4,0.2))
	mundo.vitais.fome = 20; lar.comer(); lar._process(0.5); mundo.familia.pose(0.1)
	await foto("comer-juntos",Vector3(3.3,2.7,3.6),Vector3(7.6,1.5,1.5)); lar.levantar()
	mundo.jogador.position = mundo.casa.to_global(Vector3(-8,5.64,-8.8))
	await foto("guarda-corpo-ferro",Vector3(-5,12,0),Vector3(-12,5.8,-2))
	mundo.jogador.position = mundo.casa.to_global(lar.lavatorio.LOCAL); lar.interagir(); lar.lavatorio.comecar(); lar._process(1)
	await foto("lavar-cara",Vector3(2.9,8.2,-5.3),Vector3(4.2,7.1,-9)); lar.levantar()
	lar.interagir(); lar.lavatorio.escolha = 1; lar.lavatorio.comecar(); lar._process(1)
	await foto("escovar-dentes",Vector3(2.9,8.2,-5.3),Vector3(4.2,7.1,-9)); lar.levantar()
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR); lar.interagir()
	for i: int in range(150): lar._physics_process(1.0/60)
	mundo.camera.giro = 0.7; mundo.camera.inclinacao = -0.3; mundo.camera._process(0.1); await guardar("elevador-camera-rato")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
