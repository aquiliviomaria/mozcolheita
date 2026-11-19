extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,ponto: Vector3,alvo: Vector3) -> void:
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = ponto; mundo.camera.olhar_fixo = alvo
	for i: int in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/mundo_vivo/"+nome+".png")
	print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.calendario.set_process(false)
	if "--acabamentos" in OS.get_cmdline_user_args():
		mundo.calendario.decorrido = 150
		await foto("dia",Vector3(12,12,-8),Vector3(-8,2,-51))
		mundo.calendario.decorrido = 350
		await foto("noite",Vector3(12,12,-8),Vector3(-8,2,-51))
		mundo.calendario.decorrido = 150
		var primeira: Node3D = mundo.comunidade.casas[0]
		mundo.jogador.position = primeira.position+Vector3(0,0,6)
		await foto("entrada",primeira.position+Vector3(3,3,11),primeira.position+Vector3(0,1.7,0))
		mundo.caminhao.carga = {0:80}; mundo.caminhao.actualizar_carga(); mundo.caminhao.position = Vector3(-60,mundo.altura(Vector3(-60,0,90)),90); mundo.caminhao.entrar()
		mundo.guia_entrega.intervalo = 0
		await foto("garagem-seta",Vector3(-46,8,88),Vector3(-60,2,108))
		quit(); return
	mundo.calendario.decorrido = 150
	await foto("dia",Vector3(12,12,-8),Vector3(-8,2,-51))
	mundo.calendario.decorrido = 350
	await foto("noite",Vector3(12,12,-8),Vector3(-8,2,-51))
	mundo.calendario.decorrido = 150
	await foto("bairros",Vector3(-310,100,-70),Vector3(-170,4,-210))
	await foto("cidade",Vector3(95,95,150),Vector3(240,25,0))
	await foto("riacho",Vector3(-95,22,-287),Vector3(-125,0,-317))
	await foto("quintas",Vector3(-242,32,-79),Vector3(-190,1,-120))
	var casa: Node3D = mundo.comunidade.casas[0]
	mundo.jogador.position = casa.position+Vector3(0,0,6)
	await foto("entrada",casa.position+Vector3(3,3,11),casa.position+Vector3(0,1.7,0))
	mundo.jogador.position = Vector3(-8,mundo.altura(Vector3(-8,0,-37)),-37)
	mundo.caminhao.carga = {0:80}; mundo.caminhao.actualizar_carga(); mundo.caminhao.position = Vector3(-60,mundo.altura(Vector3(-60,0,90)),90); mundo.caminhao.entrar()
	await foto("garagem-seta",Vector3(-46,8,88),Vector3(-60,2,108))
	quit()
