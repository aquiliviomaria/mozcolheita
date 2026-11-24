extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.camara.global_position = p; mundo.camera.camara.look_at(alvo); mundo.hud._process(0.1)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/funcionarios/"+nome+".png"); print("FOTO · ",nome)
func ate(f: Node3D,fase: String) -> void:
	for i: int in range(1200):
		await physics_frame
		if f.fase==fase or not f.ocupado():
			await physics_frame; break
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-funcionarios.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100; mundo.camera.set_process(false); mundo.jogador.set_physics_process(false); mundo.familia.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	for v: Node3D in mundo.comunidade.trafego: v.set_physics_process(false)
	var w: Node3D = mundo.armazem; var a: Node3D = w.funcionario; var camiao: Node3D = mundo.caminhao
	w.set_physics_process(false); camiao.set_physics_process(false); camiao.position = w.CENTRO; camiao.rotation.y = 0; mundo.jogador.position = w.ENTREGA; mundo.stock = {0:100}; a.set_physics_process(false)
	w.actualizar(1)
	await foto("atendente-sentado",w.to_global(Vector3(8,2.4,-15.3)),w.to_global(Vector3(11,1,-13.5)))
	a.set_physics_process(true); Engine.time_scale = 4; w.encomendar_carga(0,30,camiao); await ate(a,"ir_entregar"); a.set_physics_process(false)
	await foto("buscar-caixa",a.pessoa.global_position+Vector3(3.6,2.3,3.6),a.pessoa.global_position+Vector3.UP)
	a.set_physics_process(true); await ate(a,"colocar"); a.set_physics_process(false)
	await foto("carregar-camiao",a.pessoa.global_position+Vector3(4.5,3,4.5),a.pessoa.global_position+Vector3.UP)
	a.cancelar(false,true); camiao.carga = {0:35}; var f: Node3D = mundo.fabricas[0]; f.set_process(false); camiao.position = f.position; mundo.jogador.position = f.position+Vector3(0,0,-42)
	f.encomendar_descarga(camiao); await ate(f.funcionario,"ir_entregar"); f.funcionario.set_physics_process(false)
	await foto("recepcao-fabrica",f.funcionario.pessoa.global_position+Vector3(4,2.8,4),f.funcionario.pessoa.global_position+Vector3.UP)
	Engine.time_scale = 1; mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
