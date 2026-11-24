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
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; var e: Node3D = mundo.casa.elevador
	mundo.jogador.set_physics_process(false)
	lar.set_physics_process(false); e.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR); tecla(KEY_E)
	for i: int in range(150): lar._physics_process(1.0/60)
	exigir(e.fase=="pronto" and lar.estado=="elevador","Chamada abre portas, entra e espera pelo botão")
	exigir(e.abertura[0]>0.99 and e.abertura[1]<0.01,"Só abre o patamar com cabine presente")
	exigir(e.botoes.size()==2 and e.portas.size()==2,"Botões interiores e portas em ambos os pisos")
	exigir(e.permite_andar() and not mundo.jogador.bloqueado and mundo.jogador.collision_layer==2,"Movimento e colisão activos dentro da cabine")
	var antes: Vector3 = mundo.jogador.position
	var andar: InputEventKey = InputEventKey.new(); andar.physical_keycode = KEY_D; andar.pressed = true; Input.parse_input_event(andar); Input.flush_buffered_events()
	await physics_frame
	for i: int in range(12): mundo.jogador._physics_process(1.0/60)
	var parar: InputEventKey = andar.duplicate(); parar.pressed = false; Input.parse_input_event(parar); Input.flush_buffered_events()
	exigir(mundo.jogador.position.distance_to(antes)>0.1,"WASD move fisicamente o jogador na cabine")
	var folha: MeshInstance3D = e.porta_cabine.get_child(0).get_node("PortaDeVidro")
	exigir(folha.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and folha.material_override.albedo_color.a<0.3,"Portas em vidro transparente com colisão")
	tecla(KEY_2); var y: float = e.position.y
	lar._physics_process(0.1)
	exigir(is_equal_approx(y,e.position.y) and e.fase=="fechar","Portas fecham antes da subida")
	# A presença no limiar impede fechar e partir.
	mundo.jogador.position = mundo.casa.to_global(Vector3(-5,0.64,-2.8))
	for i: int in range(30): lar._physics_process(1.0/60)
	exigir(e.abertura[0]>0.95 and is_equal_approx(y,e.position.y),"Sensor impede fechar sobre uma pessoa")
	mundo.jogador.position = mundo.casa.to_global(Vector3(-4.5,0.64,-5))
	var fechado_em_viagem: bool = true
	var estrutura_visivel: bool = true
	for i: int in range(360):
		lar._physics_process(1.0/60)
		mundo.casa._process(0)
		for n: Node3D in mundo.casa.telhado+mundo.casa.piso_superior: estrutura_visivel = estrutura_visivel and n.visible
		if e.fase=="mover": fechado_em_viagem = fechado_em_viagem and e.abertura[0]<0.001 and e.abertura[1]<0.001 and e.abre_cabine<0.001
	exigir(estrutura_visivel,"Teto, lajes e paredes não desaparecem durante a subida")
	exigir(fechado_em_viagem,"Todos os acessos fechados durante a viagem")
	exigir(lar.ocupado() and e.fase=="sair" and e.piso==1,"Ao chegar abre e deixa o jogador permanecer na cabine")
	exigir(absf(mundo.casa.to_local(mundo.jogador.position).x+4.5)<0.01,"Viagem conserva posição horizontal")
	mundo.jogador.position = e.to_global(Vector3(0,0.03,2.1)); lar._physics_process(0.016)
	exigir(not lar.ocupado() and not mundo.jogador.bloqueado and mundo.jogador.collision_layer==2,"Caminhar pela porta termina a viagem sem prender o jogador")
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR+Vector3.UP*5); tecla(KEY_E)
	for i: int in range(150): lar._physics_process(1.0/60)
	tecla(KEY_1)
	for i: int in range(360): lar._physics_process(1.0/60)
	exigir(e.piso==0 and e.fase=="sair","Botão 1 permite regressar ao rés-do-chão")
	mundo.jogador.position = e.to_global(Vector3(0,0.03,2.1)); lar._physics_process(0.016)
	# Cabine distante: a chamada movimenta-a vazia antes de receber passageiro.
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR+Vector3.UP*5); tecla(KEY_E)
	var espera: Vector3 = mundo.jogador.position
	for i: int in range(60): lar._physics_process(1.0/60)
	exigir(mundo.jogador.position.is_equal_approx(espera),"Espera no patamar enquanto cabine vem vazia")
	for i: int in range(300): lar._physics_process(1.0/60)
	exigir(e.fase=="pronto" and e.piso==1,"Cabine chamada ao outro piso chega e recebe jogador")
	tecla(KEY_E)
	for i: int in range(120): lar._physics_process(1.0/60)
	mundo.jogador.position = e.to_global(Vector3(0,0.03,2.1)); lar._physics_process(0.016)
	exigir(not lar.ocupado(),"E abre a porta e permite sair sem viajar")
	# Entrar a pé na cabine também activa o painel sem agarrar a personagem.
	mundo.jogador.position = e.to_global(Vector3(0,0.03,0)); e._physics_process(0.016)
	exigir(e.permite_andar() and not mundo.jogador.bloqueado,"Entrada a pé activa botões e conserva movimento")
	print("ELEVADOR · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit(falhas)
