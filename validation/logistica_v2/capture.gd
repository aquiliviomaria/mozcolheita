extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = p; mundo.camera.olhar_fixo = alvo; mundo.camera._process(1); mundo.hud._process(0.3)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/logistica_v2/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-logistica-v2.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.jogador.set_physics_process(false)
	mundo.jogador.position = mundo.armazem.ENTREGA
	await foto("centro-logistico",mundo.armazem.position+Vector3(50,27,-76),mundo.armazem.position+Vector3(0,5,0))
	mundo.central_logistica.abrir_missoes()
	await foto("missoes-m",mundo.armazem.position+Vector3(50,27,-76),mundo.armazem.position+Vector3(0,5,0))
	mundo.central_logistica.fechar(); mundo.stock = {0:700,1:140,2:90}; mundo.central_logistica.abrir_carga(mundo.caminhao)
	await foto("escolher-carga",mundo.armazem.position+Vector3(50,27,-76),mundo.armazem.position+Vector3(0,5,0))
	mundo.central_logistica.abrir_destinos(0)
	await foto("escolher-destino",mundo.armazem.position+Vector3(50,27,-76),mundo.armazem.position+Vector3(0,5,0))
	mundo.central_logistica.fechar()
	var f: Node3D = mundo.fabricas[0]; mundo.jogador.position = f.position+Vector3(0,0,-46)
	await foto("fabrica-industrial",f.position+Vector3(42,23,-69),f.position+Vector3(0,5,0))
	var d: Node3D = mundo.drones[0]; mundo.jogador.position = d.position+Vector3(0,0,2); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.08; d.assumir(); mundo.jogador.animar(0,0)
	await foto("comando-drone",mundo.jogador.position+Vector3(2.3,1.9,-2.5),mundo.jogador.position+Vector3.UP*1.25)
	d.devolver(); mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
