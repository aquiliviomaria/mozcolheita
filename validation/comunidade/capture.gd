extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String) -> void:
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/moz-comunidade-"+nome+".png")
	print("CAPTURA ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo)
	await foto("menu-homem")
	mundo.hud.seleccionar_avatar(true); await foto("menu-mulher")
	mundo.hud.escolher(true); mundo.camera.giro = 2.7; mundo.camera.distancia = 4; mundo.camera.inclinacao = -0.16
	await foto("agricultora")
	mundo.hud.escolher(false); mundo.camera.giro = 3.3; await foto("agricultor")
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = Vector3(22,15,-15); mundo.camera.olhar_fixo = Vector3(-8,3,-51)
	for i: int in range(30): await process_frame
	await foto("casa")
	mundo.camera.ponto_fixo = Vector3(96,85,155); mundo.camera.olhar_fixo = Vector3(240,28,10)
	for i: int in range(30): await process_frame
	await foto("cidade")
	mundo.camera.ponto_fixo = Vector3(32,5,24); mundo.camera.olhar_fixo = Vector3(32,1,38)
	mundo.stock = {0:42,1:75,2:30,3:16}; mundo.armazem.actualizar(1)
	for i: int in range(30): await process_frame
	await foto("armazem")
	mundo.camera.enquadramento = false; mundo.caminhao.entrar(); mundo.caminhao.carregar({0:60,1:100}); mundo.camera.giro = -0.8; mundo.camera.distancia = 9; await foto("camiao")
	mundo.caminhao.rapidez = 0; mundo.caminhao.sair(); mundo.entregas.aceitar(1)
	mundo.hud.alternar(); mundo.hud.paginas.current_tab = 3; await foto("entregas")
	mundo.hud.paginas.current_tab = 4; mundo.hud.grupo_empresa.select(1); mundo.hud.actualizar_grupo(); await foto("grupo")
	mundo.hud.paginas.current_tab = 3; mundo.hud.urgencia_entrega.select(2); await foto("prazos")
	mundo.calendario.decorrido = float(mundo.entregas.activas[1].limite); mundo.entregas.verificar_prazos(); mundo.hud.paginas.current_tab = 5; await foto("historico")
	quit()
