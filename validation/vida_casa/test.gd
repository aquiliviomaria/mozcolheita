extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,texto: String) -> void:
	if valor: print("OK · ",texto)
	else: falhas += 1; push_error(texto)
func tecla(codigo: int) -> void:
	var evento: InputEventKey = InputEventKey.new(); evento.physical_keycode = codigo; evento.pressed = true; mundo._unhandled_input(evento)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false)
	var lar: Node3D = mundo.casa.vida_domestica
	lar.set_process(false); mundo.jogador.set_physics_process(false)
	mundo.jogador.position = mundo.casa.to_global(lar.CAMA); mundo.calendario.decorrido = 100
	tecla(KEY_E); exigir(not lar.ocupado() and mundo.calendario.decorrido==100,"Cama não salta o dia quando ainda é dia")
	var chave: Vector2i = Vector2i(12,10)
	exigir(mundo.terreno.trabalhar(chave,"lavrar") and mundo.terreno.trabalhar(chave,"semear") and mundo.terreno.trabalhar(chave,"regar"),"Cultura regada preparada para testar sono")
	mundo.terreno.celulas[chave].tempo = 1750
	mundo.calendario.decorrido = 500; mundo.entregas.aceitar(0); mundo.entregas.activas[0].limite = 550
	var saldo: int = mundo.saldo; var multa: int = mundo.entregas.activas[0].penalidade
	mundo.vitais.energia = 20; mundo.vitais.fome = 70
	var anterior: Vector3 = mundo.jogador.position
	tecla(KEY_E); exigir(lar.estado=="dormindo" and mundo.jogador.bloqueado,"E na cama inicia sono à noite")
	exigir(not mundo.partida.guardar(false),"Gravação aguarda fim do sono")
	lar._process(0.7)
	exigir(mundo.calendario.decorrido==600 and mundo.calendario.hora().contains("06:00"),"Acorda exactamente às 06:00 do dia seguinte")
	exigir(mundo.terreno.celulas[chave].estado==mundo.terreno.PRONTO,"Culturas avançam durante o sono")
	exigir(mundo.saldo==saldo-multa and mundo.entregas.activas[0].falhou,"Sono respeita prazos e multa contratual")
	lar._process(0.1); exigir(mundo.saldo==saldo-multa and mundo.calendario.decorrido==600,"Sono não duplica tempo nem multa")
	lar._process(0.8)
	exigir(not lar.ocupado() and not mundo.jogador.bloqueado and mundo.jogador.position.is_equal_approx(anterior) and mundo.jogador.visual.rotation.z==0,"Acordar repõe posição, pose e movimento")
	exigir(mundo.vitais.energia==100 and mundo.vitais.fome==62,"Sono recupera energia e consome alimentação")
	mundo.jogador.position = mundo.casa.to_global(lar.MESA); tecla(KEY_E)
	exigir(lar.estado=="sentado" and mundo.jogador.bloqueado,"E senta à mesa")
	mundo.vitais.fome = 30; mundo.vitais.energia = 30; var porcoes: int = lar.refeicoes
	tecla(KEY_E); exigir(lar.refeicoes==porcoes-1 and mundo.vitais.fome==65 and mundo.vitais.energia==60,"E come uma refeição real à mesa")
	mundo.vitais.fome = 100; mundo.vitais.energia = 100; mundo.vitais.vida = 100
	tecla(KEY_E); exigir(lar.refeicoes==porcoes-1,"Não desperdiça comida quando está saciado")
	mundo.partida.caminho = "user://teste-vida-casa-isolado.mozsave"
	exigir(mundo.partida.guardar(false),"Guarda refeições e posição segura enquanto sentado")
	lar.refeicoes = 0; exigir(mundo.partida.carregar(),"Retoma gravação doméstica")
	exigir(lar.refeicoes==porcoes-1 and not lar.ocupado() and not mundo.jogador.bloqueado,"Retoma a pé sem ficar preso na cadeira")
	var legado: Dictionary = mundo.partida.capturar(); legado.erase("casa"); exigir(mundo.partida.validar(legado),"Gravação antiga continua compatível")
	lar.refeicoes = 0; mundo.sacola = {}; mundo.stock = {0:2}; mundo.vitais.fome = 10
	mundo.jogador.position = mundo.casa.to_global(lar.MESA); tecla(KEY_E); tecla(KEY_E)
	exigir(mundo.stock[0]==1 and mundo.vitais.fome==45,"Depois das refeições iniciais usa um produto do armazém")
	tecla(KEY_W); exigir(not lar.ocupado() and mundo.jogador.collision_layer==2,"W levanta e repõe colisão")
	mundo.stock = {}; lar._process(0); exigir(not lar.comida.visible,"Mesa fica sem comida quando os recursos acabam")
	await physics_frame
	var origem: Vector3 = mundo.casa.to_global(Vector3(8,2.7,-2)); var fim: Vector3 = mundo.casa.to_global(Vector3(12,2.7,-2))
	var raio: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origem,fim,1)
	var impacto: Dictionary = mundo.get_world_3d().direct_space_state.intersect_ray(raio)
	exigir(not impacto.is_empty() and str(impacto.collider.get_parent().name).begins_with("JanelaTransparente"),"Junto à cama há vidro em vez de parede opaca")
	var janelas: Array[Node] = mundo.casa.find_children("JanelaTransparente*","MeshInstance3D",true,false)
	exigir(janelas.size()==5,"Cinco janelas transparentes com vãos reais")
	for sufixo: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(mundo.partida.caminho+sufixo): DirAccess.remove_absolute(ProjectSettings.globalize_path(mundo.partida.caminho+sufixo))
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop()
	print("VIDA NA CASA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
