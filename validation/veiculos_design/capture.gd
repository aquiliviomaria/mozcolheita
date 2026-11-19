extends SceneTree
## Inspecção de arte com as mesmas malhas usadas no jogo, em iluminação neutra.
var mundo: Node3D
var camara: Camera3D
func _initialize() -> void: executar.call_deferred()
func foto(nome: String,ponto: Vector3,alvo: Vector3) -> void:
	camara.position = ponto; camara.look_at(alvo)
	for i: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview/veiculos_design/"+nome+".png"); print("FOTO · ",nome)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new()
	var palco: Node3D = Node3D.new(); root.add_child(palco)
	var ambiente: WorldEnvironment = WorldEnvironment.new(); ambiente.environment = Environment.new(); ambiente.environment.background_mode = Environment.BG_COLOR; ambiente.environment.background_color = Color("9abfc4"); ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; ambiente.environment.ambient_light_color = Color("dce7ec"); ambiente.environment.ambient_light_energy = 0.75; palco.add_child(ambiente)
	var sol: DirectionalLight3D = DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-48,-30,0); sol.light_energy = 1.1; sol.shadow_enabled = true; palco.add_child(sol)
	mundo.caixa(palco,Vector3(8,-0.12,15),Vector3(90,0.2,80),Color("7e9777"))
	camara = Camera3D.new(); camara.fov = 48; palco.add_child(camara); camara.make_current()
	for i: int in range(3):
		var carro: Node3D = Node3D.new(); carro.position = Vector3(i*5,0,15); carro.rotation.y = -0.25; palco.add_child(carro)
		preload("res://scripts/vehicle_art.gd").criar_trafego(carro,i,i)
	var caminhao: CharacterBody3D = load("res://scripts/truck.gd").new(); caminhao.mundo = mundo; caminhao.set_physics_process(false); caminhao.position = Vector3(18,0,15); caminhao.rotation.y = -0.25; palco.add_child(caminhao); caminhao.process_mode = Node.PROCESS_MODE_DISABLED
	var jogador: CharacterBody3D = load("res://scripts/player.gd").new(); jogador.mundo = mundo; jogador.set_physics_process(false); palco.add_child(jogador); jogador.process_mode = Node.PROCESS_MODE_DISABLED; mundo.jogador = jogador
	jogador.visual.reparent(caminhao); jogador.visual.position = Vector3(0,0.65,-1.5); jogador.animar(0.1,0,true)
	await foto("frota",Vector3(22,12,-11),Vector3(8,1,15))
	await foto("carro",Vector3(3.7,2.6,10.8),Vector3(0,0.9,15))
	await foto("camiao-trafego",Vector3(9,3.5,9),Vector3(5,1.2,15))
	await foto("camiao-jogador",Vector3(24,4.1,8),Vector3(18,1.6,15))
	mundo.free(); quit()
