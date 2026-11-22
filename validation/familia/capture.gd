extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = p; mundo.camera.olhar_fixo = alvo; mundo.camera._process(1); mundo.casa._process(0); mundo.hud._process(0.3); mundo.casa.vida_domestica._process(0)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/familia/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-familia-isolada.mozsave"; mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	await foto("menu-corpos",Vector3(20,17,-12),Vector3(-8,5,-47))
	mundo.hud.escolher(false)
	await foto("casa-dois-pisos",Vector3(20,17,-12),Vector3(-8,5,-47))
	var c: Node3D = mundo.casa; var lar: Node3D = c.vida_domestica
	mundo.jogador.position = c.to_global(lar.SOFA); lar.interagir(); mundo.familia.colocar_actividade("sofa")
	await foto("sala-televisao",c.to_global(Vector3(-13,4.5,10)),c.to_global(Vector3(-7,2.2,3)))
	lar.levantar(); mundo.jogador.position = c.to_global(lar.MESA); lar.interagir(); mundo.familia.colocar_actividade("mesa"); mundo.vitais.fome = 30; lar.comer()
	await foto("cozinha-refeicao",c.to_global(Vector3(12,4.5,4.1)),c.to_global(Vector3(8,1.6,0.5)))
	lar.levantar(); mundo.calendario.decorrido = 410; mundo.jogador.position = c.to_global(lar.CAMA); lar.interagir(); mundo.familia.colocar_actividade("cama"); lar.set_process(false)
	await foto("quarto-casal",c.to_global(Vector3(3,9.9,9.5)),c.to_global(Vector3(8,6.8,6)))
	lar.levantar(); lar.set_process(true); mundo.calendario.decorrido = 100
	mundo.jogador.position = c.to_global(lar.DUCHE); lar.interagir(); mundo.familia.colocar_actividade("banho")
	for i: int in range(80): lar._process(0.1)
	await foto("casa-banho",c.to_global(Vector3(6.2,8.1,-2)),c.to_global(Vector3(11,7.2,-6.5)))
	lar.levantar(); mundo.carros[0].entrar(); mundo.familia.embarcar(mundo.carros[0])
	await foto("automovel-dois-lugares",mundo.carros[0].position+Vector3(4,3,-4),mundo.carros[0].position+Vector3.UP)
	mundo.carros[0].rapidez = 0; mundo.carros[0].sair(); mundo.tratores[0].entrar(); mundo.familia.embarcar(mundo.tratores[0])
	await foto("tractor-dois-lugares",mundo.tratores[0].position+Vector3(4,3,-4),mundo.tratores[0].position+Vector3.UP*1.6)
	mundo.tratores[0].rapidez = 0; mundo.tratores[0].sair()
	var modelos: Array[Node3D] = []; modelos.assign(mundo.pessoas.slice(0,5))
	for idade: String in ["idoso","crianca"]:
		for p: Node3D in mundo.pessoas:
			if p.idade==idade: modelos.append(p); break
	for i: int in range(modelos.size()):
		modelos[i].set_physics_process(false); modelos[i].position = Vector3(30+i*1.8,mundo.altura(Vector3(30+i*1.8,0,5)),5); modelos[i].visual.rotation.y = PI; modelos[i].visual.visible = true; modelos[i].animar(0,0)
	await foto("idades-e-corpos",Vector3(36,3,17),Vector3(36,1.1,5))
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
