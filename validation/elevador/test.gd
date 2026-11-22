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
	lar.set_physics_process(false); e.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR); tecla(KEY_E)
	for i: int in range(150): lar._physics_process(1.0/60)
	exigir(e.fase=="pronto" and lar.estado=="elevador","Chamada abre portas, entra e espera pelo botão")
	exigir(e.abertura[0]>0.99 and e.abertura[1]<0.01,"Só abre o patamar com cabine presente")
	exigir(e.botoes.size()==2 and e.portas.size()==2,"Botões interiores e portas em ambos os pisos")
	tecla(KEY_2); var y: float = e.position.y
	lar._physics_process(0.1)
	exigir(is_equal_approx(y,e.position.y) and e.fase=="fechar","Portas fecham antes da subida")
	# A presença no limiar impede fechar e partir.
	mundo.jogador.position = mundo.casa.to_global(Vector3(-5,0.64,-2.8))
	for i: int in range(30): lar._physics_process(1.0/60)
	exigir(e.abertura[0]>0.95 and is_equal_approx(y,e.position.y),"Sensor impede fechar sobre uma pessoa")
	mundo.jogador.position = mundo.casa.to_global(Vector3(-5,0.64,-5))
	var fechado_em_viagem: bool = true
	for i: int in range(360):
		lar._physics_process(1.0/60)
		if e.fase=="mover": fechado_em_viagem = fechado_em_viagem and e.abertura[0]<0.001 and e.abertura[1]<0.001 and e.abre_cabine<0.001
	exigir(fechado_em_viagem,"Todos os acessos fechados durante a viagem")
	exigir(not lar.ocupado() and e.piso==1 and absf(mundo.casa.to_local(mundo.jogador.position).y-5.64)<0.01,"Abre ao chegar e sai no segundo piso")
	exigir(not mundo.jogador.bloqueado and mundo.jogador.collision_layer==2,"Saída repõe movimento e colisão")
	tecla(KEY_E)
	for i: int in range(150): lar._physics_process(1.0/60)
	tecla(KEY_1)
	for i: int in range(360): lar._physics_process(1.0/60)
	exigir(not lar.ocupado() and e.piso==0,"Botão 1 permite regressar ao rés-do-chão")
	# Cabine distante: a chamada movimenta-a vazia antes de receber passageiro.
	mundo.jogador.position = mundo.casa.to_global(lar.ELEVADOR+Vector3.UP*5); tecla(KEY_E)
	var espera: Vector3 = mundo.jogador.position
	for i: int in range(60): lar._physics_process(1.0/60)
	exigir(mundo.jogador.position.is_equal_approx(espera),"Espera no patamar enquanto cabine vem vazia")
	for i: int in range(300): lar._physics_process(1.0/60)
	exigir(e.fase=="pronto" and e.piso==1,"Cabine chamada ao outro piso chega e recebe jogador")
	tecla(KEY_E)
	for i: int in range(120): lar._physics_process(1.0/60)
	exigir(not lar.ocupado(),"E permite sair sem viajar")
	print("ELEVADOR · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit(falhas)
