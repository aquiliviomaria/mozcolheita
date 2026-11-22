extends SceneTree
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,descricao: String) -> void:
	if valor: print("OK · ",descricao)
	else: falhas += 1; push_error(descricao)
func tecla(codigo: int,pressionada: bool) -> void:
	var evento: InputEventKey = InputEventKey.new(); evento.physical_keycode = codigo; evento.keycode = codigo; evento.pressed = pressionada; Input.parse_input_event(evento)
func executar() -> void:
	var mundo: Node3D = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false)
	mundo.hud._process(0.3)
	exigir(not mundo.hud.dinheiro.text.contains("Dia") and not mundo.hud.dinheiro.text.contains(":"),"Topo sem dia/hora ou aceleração")
	var botoes_tempo: bool = false; var tem_l: bool = false
	for botao: Button in mundo.hud.raiz.find_children("*","Button",true,false):
		if botao.text.contains("+1 dia") or botao.text.contains("Tempo ×"): botoes_tempo = true
		if botao.text=="L": tem_l = true
	exigir(not botoes_tempo and not tem_l,"Atalho L funciona sem botão permanente")
	mundo.calendario.decorrido = 0
	var l: InputEventKey = InputEventKey.new(); l.physical_keycode = KEY_L; l.pressed = true
	mundo._unhandled_input(l); exigir(mundo.calendario.decorrido==300,"L passa de dia para noite")
	mundo._unhandled_input(l); exigir(mundo.calendario.decorrido==600,"L passa de noite para dia")
	mundo.painel_conducao._process(0)
	exigir(not mundo.painel_conducao.ferramentas.visible,"Ferramentas disponíveis em K, sem lista permanente")
	mundo.vitais.fome = 40; mundo.vitais.energia = 50; mundo.sacola = {0:2}
	exigir(mundo.vitais.comer() and mundo.sacola[0]==1 and mundo.vitais.fome==75 and mundo.vitais.energia==80,"J come um produto real e recupera necessidades")
	var d: Dictionary = mundo.partida.capturar(); mundo.vitais.fome = 0; mundo.partida.aplicar(d)
	exigir(mundo.vitais.fome==75,"Vida, fome e energia são guardadas")
	mundo.caminhao.entrar(); mundo.painel_conducao._process(0)
	exigir(mundo.painel_conducao.modo=="camião" and not mundo.painel_conducao.ferramentas.visible,"Ícones de controlo aparecem no veículo")
	var acoes: Array[Dictionary] = mundo.painel_conducao.acoes()
	exigir(acoes[0].tecla=="W" and acoes[0].icone=="acelerador" and acoes[2].tecla=="T" and acoes[2].icone=="turbo", "Teclas W e T ficam nos ícones de acelerador e turbo")
	var controlo: GDScript = load("res://scripts/input_drive.gd")
	tecla(KEY_W,true)
	Engine.time_scale = 4
	for i: int in range(8): await physics_frame
	exigir(mundo.caminhao.rapidez>1 and controlo.acelerador()==1,"Acelerador move veículo e acende o indicador real")
	tecla(KEY_CTRL,true); await physics_frame; exigir(controlo.travao(),"Travão Ctrl tem indicador real")
	Engine.time_scale = 4
	for i: int in range(8): await physics_frame
	exigir(absf(mundo.caminhao.rapidez)<0.1,"Travão segura veículo mesmo com acelerador premido")
	tecla(KEY_W,false); tecla(KEY_CTRL,false); mundo.caminhao.rapidez = 0; mundo.caminhao.sair(); Engine.time_scale = 1
	mundo.jogador.position = mundo.drones[0].position+Vector3(0,0,1.4); mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1
	exigir(mundo.drones[0].assumir(),"Assumir drone próximo")
	mundo.painel_conducao._process(0)
	exigir(mundo.painel_conducao.modo=="drone","Drone tem ícones de subir/descer/irrigar/regressar")
	var comando: InputEventJoypadButton = InputEventJoypadButton.new(); comando.pressed = true; comando.button_index = JOY_BUTTON_Y; mundo._unhandled_input(comando)
	exigir(mundo.drone_actual.irrigando,"Triângulo do comando activa irrigação")
	comando.button_index = JOY_BUTTON_X; mundo._unhandled_input(comando)
	exigir(mundo.drone_actual==null,"Quadrado do comando regressa do drone")
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop(); await create_timer(0.1).timeout
	print("HUD E CONTROLOS · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
