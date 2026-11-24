extends SceneTree
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,p: Vector3,alvo: Vector3) -> void:
	mundo.aviso_tempo = 0; mundo.camera.enquadramento = true; mundo.camera.camara.global_position = mundo.casa.to_global(p); mundo.camera.camara.look_at(mundo.casa.to_global(alvo)); mundo.hud._process(0.1)
	for i: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/casa_servicos/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.partida.caminho = "user://preview-servicos.mozsave"; mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100; mundo.camera.set_process(false); mundo.jogador.set_physics_process(false); mundo.familia.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	for v: Node3D in mundo.comunidade.trafego: v.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; lar.set_process(false); lar.set_physics_process(false); lar.servico_mesa.set_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.DUCHE); lar.interagir()
	for i: int in range(130): lar._process(1.0/60)
	await foto("banho-com-teto",Vector3(5.8,8.8,-2.8),Vector3(11,7.9,-7.8))
	lar.levantar(); mundo.jogador.position = mundo.casa.to_global(Vector3(11.3,5.64,6)); mundo.jogador.visual.rotation.y = PI
	await foto("roupao",Vector3(13,7.8,9.5),Vector3(11.3,6.8,6))
	lar.trocar_roupa(); mundo.jogador.position = mundo.casa.to_global(lar.MESA); lar.interagir(); lar._process(0)
	await foto("pratos-vazios",Vector3(4,3.7,3.5),Vector3(8,1.4,0.5))
	mundo.familia.colocar_actividade("servir"); lar.servico_mesa.criar_travessa()
	for i: int in range(2): mundo.familia.pessoa.bracos[i].rotation.x = 0.9; mundo.familia.pessoa.cotovelos[i].rotation.x = 1.1
	await foto("servir-refeicao",Vector3(4,3.7,3.5),Vector3(9,1.5,1.4))
	lar.servico_mesa.cancelar(); lar.comida.servir(true); mundo.familia.colocar_actividade("mesa"); mundo.vitais.fome = 10; lar.comer(); lar._process(0.4); mundo.familia.pose(0.1)
	await foto("comer-juntos",Vector3(4,3.7,3.5),Vector3(8,1.4,0.5)); lar.levantar()
	mundo.jogador.position = mundo.casa.to_global(Vector3(0,0.64,19))
	await foto("parque-maquinas",Vector3(-75,34,53),Vector3(-23,2,7))
	quit()
