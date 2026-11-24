extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func tecla(k: int) -> void:
	var e: InputEventKey = InputEventKey.new(); e.physical_keycode = k; e.pressed = true; mundo._unhandled_input(e)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.jogador.set_physics_process(false); mundo.familia.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; lar.set_process(false); lar.set_physics_process(false); mundo.casa.elevador.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	await physics_frame
	var guardas: int = 0
	for n: Node in mundo.casa.get_children():
		if str(n.name).begins_with("GuardaCorpoFerro"): guardas += 1
	exigir(guardas==2,"Escadas têm guarda-corpo de ferro no vão do piso superior")
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(mundo.casa.to_global(Vector3(-8.5,6.1,0)),mundo.casa.to_global(Vector3(-10.1,6.1,0)),1)
	var barreira: Dictionary = mundo.get_world_3d().direct_space_state.intersect_ray(consulta)
	exigir(not barreira.is_empty() and absf(mundo.casa.to_local(barreira.position).x+9.3)<0.15,"Guarda-corpo tem barreira física contínua contra quedas")
	# Todos os perfis apoiam a bacia no assento, com coxas horizontais.
	for perfil: int in range(5):
		mundo.jogador.perfil = perfil; mundo.jogador.criar_avatar(); mundo.jogador.position = mundo.casa.to_global(lar.MESA); tecla(KEY_E); lar._process(0)
		var bacia: Vector3 = mundo.jogador.visual.to_global(Vector3(0,0.8,0))
		exigir(absf(bacia.y-mundo.casa.to_global(Vector3(0,1.08,0)).y)<0.001 and absf(mundo.jogador.pernas[0].rotation.x-PI/2)<0.001 and absf(mundo.jogador.joelhos[0].rotation.x+PI/2)<0.001,"Perfil %d sentado no assento, sem ajoelhar" % perfil)
		lar.levantar()
	mundo.jogador.perfil = 0; mundo.jogador.criar_avatar(); mundo.jogador.position = mundo.casa.to_global(lar.MESA); tecla(KEY_E)
	mundo.familia.colocar_actividade("mesa")
	exigir(absf(mundo.familia.pessoa.visual.to_global(Vector3(0,0.8,0)).y-mundo.casa.to_global(Vector3(0,1.08,0)).y)<0.001,"Companhia usa a mesma postura correcta")
	lar.servico_mesa.cancelar(); lar.comida.servir(true); lar._process(0); var menu: int = lar.comida.indice; mundo.vitais.fome = 10; var porcoes: int = lar.refeicoes; tecla(KEY_E)
	exigir(lar.a_comer>0 and is_instance_valid(lar.alimento_mao) and lar.refeicoes==porcoes-1,"Come porção da ementa visível")
	tecla(KEY_E); exigir(lar.refeicoes==porcoes-1,"E repetido não duplica consumo durante a animação")
	lar._process(3); lar.comida.servir(false); lar._process(0)
	exigir(lar.comida.indice!=menu and lar.comida.menus.size()==4,"Ementa roda depois de comer; existem quatro menus distintos")
	menu = lar.comida.indice; mundo.calendario.decorrido += lar.DIA; lar._process(0); exigir(menu!=lar.comida.indice,"Novo dia também roda os alimentos na mesa")
	lar.levantar()
	# Lavatório com escolha por setas e E; cancelamento liberta tudo.
	mundo.jogador.position = mundo.casa.to_global(lar.lavatorio.LOCAL); tecla(KEY_E)
	exigir(lar.estado=="lavatorio" and lar.lavatorio.painel.visible,"E abre lavatório com espelho e escolha de higiene")
	mundo.vitais.higiene = 20; tecla(KEY_E); lar._process(4.1)
	exigir(not lar.ocupado() and mundo.vitais.higiene==32 and not lar.lavatorio.agua.emitting,"Lavar cara tem água, termina e recupera higiene")
	tecla(KEY_E); tecla(KEY_RIGHT); tecla(KEY_E)
	exigir(lar.estado=="escovar_dentes" and is_instance_valid(lar.lavatorio.escova),"Seta e E escolhem escovar dentes; escova aparece na mão")
	lar._process(7.1); exigir(not lar.ocupado() and mundo.vitais.higiene==50 and not lar.lavatorio.painel.visible,"Escovar termina, recupera higiene e remove interface")
	tecla(KEY_E); tecla(KEY_2); tecla(KEY_E); tecla(KEY_ESCAPE)
	exigir(not lar.ocupado() and not mundo.jogador.bloqueado and not lar.lavatorio.agua.emitting,"Cancelar higiene restaura movimento, colisão e torneira")
	# O rato controla a órbita mesmo quando o enquadramento do elevador está activo.
	var elev: Node3D = mundo.casa.elevador; mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR); tecla(KEY_E)
	for i: int in range(150): lar._physics_process(1.0/60)
	mundo.camera.enquadramento = true; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var giro: float = mundo.camera.giro; var inclinacao: float = mundo.camera.inclinacao
	var rato: InputEventMouseMotion = InputEventMouseMotion.new(); rato.relative = Vector2(70,30); 
	# O servidor headless não captura o rato; exercita o mesmo controlador de órbita.
	if DisplayServer.get_name()=="headless": mundo.camera.rodar_vista(rato.relative)
	else: mundo.camera._unhandled_input(rato)
	mundo.camera._process(0.1)
	exigir(not is_equal_approx(giro,mundo.camera.giro) and not is_equal_approx(inclinacao,mundo.camera.inclinacao),"Rato gira horizontal e verticalmente dentro do elevador")
	var local: Vector3 = elev.to_local(mundo.camera.camara.global_position)
	exigir(absf(local.x)<=1.61 and absf(local.z)<=1.61 and local.y<=3.06,"Câmara permanece dentro da cabine")
	mundo.jogador.position = elev.to_global(Vector3(0,0.03,2.1)); lar._physics_process(0.1)
	var dados: Dictionary = mundo.partida.capturar(); exigir(mundo.partida.validar(dados) and dados.casa.refeicoes_consumidas==1,"Gravação conserva rotação de refeições")
	dados.casa.erase("refeicoes_consumidas"); exigir(mundo.partida.validar(dados),"Gravações antigas sem rotação continuam válidas")
	dados.casa["refeicoes_consumidas"] = -1; exigir(not mundo.partida.validar(dados),"Gravação rejeita contador de refeições inválido")
	print("ROTINAS DA CASA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit(falhas)
