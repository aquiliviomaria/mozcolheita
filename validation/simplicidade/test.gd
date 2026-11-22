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
	exigir(not botoes_tempo and not tem_l,"Sem botões de calendário na tela")
	mundo.calendario.decorrido = 0
	var l: InputEventKey = InputEventKey.new(); l.physical_keycode = KEY_L; l.pressed = true
	mundo._unhandled_input(l); exigir(mundo.calendario.decorrido==300,"L passa de dia para noite")
	mundo._unhandled_input(l); exigir(mundo.calendario.decorrido==600,"L passa de noite para dia")
	mundo.painel_conducao._process(0)
	exigir(not mundo.painel_conducao.ferramentas.visible and not mundo.hud.ferramenta.visible and not mundo.hud.missao_hud.visible and not mundo.hud.comandos.get_parent().visible,"Tela sem ferramentas, missões ou legendas permanentes")
	mundo.hud.alternar(); exigir(mundo.hud.aberto,"H continua a abrir a gestão"); mundo.hud.alternar()
	mundo.hud.alternar_kit(); exigir(mundo.hud.kit_aberto,"K continua a abrir ferramentas"); mundo.hud.alternar_kit()
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
	# Confere cada metro de todas as rotas, incluindo a ligação do fim ao início.
	var desvio_maximo: float = 0
	for carro: CharacterBody3D in mundo.comunidade.trafego:
		for indice: int in range(carro.rota.size()):
			var inicio: Vector3 = carro.rota[indice]; var fim: Vector3 = carro.rota[(indice+1)%carro.rota.size()]
			for metro: int in range(ceili(inicio.distance_to(fim))+1):
				var p: Vector3 = inicio.move_toward(fim,metro); var perto: float = INF
				for troco: Dictionary in mundo.comunidade.trocos:
					var eixo: Vector3 = troco.b-troco.a; var t: float = clampf((p-troco.a).dot(eixo)/eixo.length_squared(),0,1)
					perto = minf(perto,p.distance_to(troco.a+eixo*t))
				desvio_maximo = maxf(desvio_maximo,perto)
	exigir(desvio_maximo<0.01,"As 20 rotas seguem o centro das estradas, sem atalhos pelo terreno")
	var sistemas: Array[Node] = mundo.find_children("IluminacaoNocturna","Node3D",true,false)
	exigir(sistemas.size()==27,"Luzes nos 20 veículos de trânsito, três tractores, camião e três drones")
	mundo.calendario.decorrido = 400; mundo.luz_diaria._process(0)
	for luzes: Node in sistemas:
		luzes._process(0); exigir(luzes.focos[0].visible and luzes.focos[0].light_energy>2,"Farol nocturno activo")
	mundo.calendario.decorrido = 100; mundo.luz_diaria._process(0)
	for luzes: Node in sistemas:
		luzes._process(0); exigir(not luzes.focos[0].visible and luzes.focos[0].light_energy<0.01,"Farol diurno desligado")
	mundo.camera.livre = false; mundo.jogador.set_physics_process(false); mundo.jogador.position = load("res://scripts/farmhouse.gd").INICIO; mundo.jogador.position.y = mundo.altura(mundo.jogador.position)+0.1
	Engine.time_scale = 8
	for passo: int in range(140):
		await physics_frame
		mundo.jogador.velocity = Vector3(0,-3,-4.5); mundo.jogador.move_and_slide()
		if mundo.jogador.position.z < -40: break
	exigir(mundo.jogador.position.z < -40 and mundo.jogador.position.y > mundo.casa.position.y+0.5,"Acesso à varanda pela rampa sem saltar ou ficar preso")
	Engine.time_scale = 1
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop(); await create_timer(0.1).timeout
	print("SIMPLICIDADE E MUNDO · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
