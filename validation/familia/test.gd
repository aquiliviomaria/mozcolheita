extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	if v: print("OK · ",t)
	else: falhas += 1; push_error(t)
func tecla(k: int) -> void:
	var e: InputEventKey = InputEventKey.new(); e.physical_keycode = k; e.pressed = true; mundo._unhandled_input(e)
func colocar(p: Vector3) -> void: mundo.jogador.position = mundo.casa.to_global(p); mundo.jogador.velocity = Vector3.ZERO
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.jogador.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; lar.set_process(false)
	var familia: Node3D = mundo.familia
	lar.comecar_intro()
	exigir(lar.estado=="dormindo" and lar.noite() and mundo.jogador.visual.rotation.x>1,"Nova sessão começa deitado na cama à noite")
	exigir(familia.actividade=="cama" and familia.pronta,"Cônjuge já está na cama no início")
	exigir((mundo.jogador.visual.basis*Vector3.FORWARD).normalized().dot(Vector3.UP)>0.99,"Rosto deitado virado para cima")
	exigir(mundo.jogador.bracos[1].rotation.z>1 and familia.pessoa.bracos[0].rotation.z < -1,"Braços interiores em abraço")
	exigir(mundo.jogador.position.distance_to(familia.pessoa.position)<0.8,"Casal deitado próximo com cabeças na mesma cabeceira")
	lar._process(0.7); lar._process(0.8)
	exigir(lar.estado=="acordado","Início acorda na cama sem caminhar pela varanda")
	tecla(KEY_E)
	exigir(not lar.ocupado() and mundo.jogador.position.is_equal_approx(mundo.casa.to_global(lar.CAMA)),"E levanta ao lado da cama no piso superior")
	Engine.time_scale = 8
	# A escada exige deslocação real, sem teletransporte.
	colocar(Vector3(-12,0.7,5.8))
	for i: int in range(280):
		await physics_frame; mundo.jogador.velocity = Vector3(0,-4,-3); mundo.jogador.move_and_slide()
		if mundo.casa.to_local(mundo.jogador.position).z < -8.3: break
	print("ESCADA · ",mundo.casa.to_local(mundo.jogador.position))
	exigir(mundo.casa.to_local(mundo.jogador.position).y>5.5,"Escadas permitem chegar fisicamente ao segundo piso")
	Engine.time_scale = 1
	mundo.casa._process(0); exigir(mundo.casa.telhado[0].visible,"Tecto de betão presente na câmara normal")
	colocar(lar.ELEVADOR); tecla(KEY_E)
	for i: int in range(420):
		if mundo.casa.elevador.fase=="pronto": tecla(KEY_2 if mundo.casa.elevador.piso==0 else KEY_1)
		lar._physics_process(1.0/60)
	exigir(mundo.casa.elevador.fase=="sair","Elevador abre ao chegar e permite permanecer na cabine")
	mundo.jogador.position = mundo.casa.elevador.to_global(Vector3(0,0.03,2.1)); lar._physics_process(1.0/60)
	exigir(lar.estado=="" and absf(mundo.casa.to_local(mundo.jogador.position).y-5.64)<0.05,"Passageiro sai a pé no patamar superior")
	tecla(KEY_E)
	for i: int in range(420):
		if mundo.casa.elevador.fase=="pronto": tecla(KEY_2 if mundo.casa.elevador.piso==0 else KEY_1)
		lar._physics_process(1.0/60)
	mundo.jogador.position = mundo.casa.elevador.to_global(Vector3(0,0.03,2.1)); lar._physics_process(1.0/60)
	exigir(lar.estado=="" and absf(mundo.casa.to_local(mundo.jogador.position).y-0.64)<0.05,"Elevador desce e passageiro sai a pé no rés-do-chão")
	colocar(lar.CAMA); mundo.calendario.decorrido = 100; tecla(KEY_E)
	exigir(lar.estado=="cama_dia","De dia E senta na cama")
	tecla(KEY_W); exigir(lar.estado=="cama_dia","Cama mantém repouso até E")
	tecla(KEY_E); exigir(not lar.ocupado(),"E permite sair da cama de dia")
	colocar(lar.CAMA); mundo.calendario.decorrido = 410; tecla(KEY_E); lar._process(0.7); lar._process(0.8)
	exigir(lar.estado=="acordado" and mundo.calendario.decorrido==600,"Dorme de noite e acorda às 06:00 sem sair da cama")
	exigir(familia.actividade=="cama" and familia.pronta and familia.pessoa.visual.rotation.x>1,"Cônjuge acompanha obrigatoriamente o sono")
	tecla(KEY_E); exigir(not lar.ocupado() and not mundo.jogador.bloqueado,"E liberta jogador ao acordar")
	var porcoes: int = lar.refeicoes
	colocar(lar.MESA); tecla(KEY_E); mundo.vitais.fome = 20; tecla(KEY_C)
	familia.pessoa.position = mundo.casa.to_global(Vector3(5,5.7,3)); familia.alvo_anterior = Vector3.INF
	Engine.time_scale = 8
	for i: int in range(7200):
		await physics_frame
		if lar.refeicoes<porcoes: break
	Engine.time_scale = 1
	print("COMPANHIA MESA · ",familia.pronta," ",mundo.casa.to_local(familia.pessoa.position))
	exigir(familia.pronta and familia.actividade=="mesa","C faz companhia caminhar e sentar à mesa")
	lar._process(0.2); familia.pose(0.2)
	exigir(lar.refeicoes==porcoes-1 and lar.a_comer>0 and is_instance_valid(lar.alimento_mao),"Comida real e animação de levar alimento à boca")
	exigir(is_instance_valid(familia.comida_mao),"Companhia come em conjunto")
	lar.levantar(); colocar(lar.SOFA); tecla(KEY_E); lar._process(15)
	exigir(lar.estado=="televisao" and lar.televisao.ligada,"Televisão permanece ligada até interrupção")
	tecla(KEY_E); exigir(not lar.ocupado() and not lar.televisao.ligada,"E interrompe televisão")
	colocar(lar.ROUPEIRO); var roupa: int = mundo.jogador.roupa; tecla(KEY_E); exigir(mundo.jogador.roupa==(roupa+1)%4,"Roupeiro muda conjunto visível")
	colocar(lar.DUCHE); mundo.vitais.higiene = 10; tecla(KEY_E)
	for i: int in range(60): lar._process(0.1)
	exigir(lar.estado=="banho" and lar.agua.emitting and mundo.vitais.higiene>40,"Duche tem água e recupera higiene")
	exigir(lar.duche.abertura<0.01 and lar.duche.fase=="banho","Cortina opaca fecha antes de ligar a água")
	tecla(KEY_C); exigir(familia.actividade=="banho","C convida cônjuge para duche")
	familia.colocar_actividade("banho")
	for i: int in range(35): lar._process(0.1)
	exigir(lar.duche.companhia_dentro and lar.duche.abertura<0.01 and lar.agua.emitting,"Cortina abre para entrada da companhia e fecha durante banho conjunto")
	tecla(KEY_E)
	exigir(not lar.agua.emitting and lar.ocupado(),"Água pára antes de abrir cortina para saída")
	for i: int in range(30): lar._process(0.1)
	exigir(not lar.ocupado() and lar.duche.abertura>0.99,"Sai do duche e pano fica aberto")
	exigir(not lar.agua.emitting and mundo.jogador.roupa==4,"Terminar banho veste roupão")
	colocar(lar.SANITA); tecla(KEY_E); exigir(lar.estado=="sanita","Sanita utilizável"); tecla(KEY_E)
	# Chamada real do quarto até ao automóvel: escadas, porta e percurso exterior.
	mundo.carros[0].entrar(); familia.pessoa.position = mundo.casa.to_global(Vector3(5,5.7,3)); familia.pronta = false; tecla(KEY_C)
	Engine.time_scale = 8
	for i: int in range(1000):
		await physics_frame
		if familia.veiculo!=null: break
	Engine.time_scale = 1
	print("CASA ATÉ CARRO · ",familia.veiculo!=null," ",familia.pessoa.position," via ",familia.percurso[0] if not familia.percurso.is_empty() else Vector3.ZERO)
	exigir(familia.veiculo==mundo.carros[0],"C chama do segundo piso até ao automóvel com percurso físico")
	mundo.carros[0].rapidez = 0; mundo.carros[0].sair()
	for v: CharacterBody3D in mundo.tratores+[mundo.caminhao]+mundo.carros:
		exigir(v.entrar(),"Entrar em veículo de dois lugares")
		familia.pessoa.position = v.to_global(Vector3(2.6,0.1,0)); tecla(KEY_C); familia._physics_process(0.1)
		exigir(familia.veiculo==v and familia.pessoa.visual.get_parent()==v and v.passageiro==familia.pessoa,"C embarca companhia no banco de passageiro")
		mundo.hud.aplicar_corpo(1); mundo.jogador.animar(0,0,true)
		exigir(mundo.jogador.visual.get_parent()==v and mundo.jogador.visual.scale.y>1.1,"Corpo alto conserva pose e banco no veículo")
		v.rapidez = 0; exigir(v.sair() and familia.veiculo==null and familia.pessoa.visual.get_parent()==familia.pessoa,"Condutor e companhia desembarcam sem ficar presos")
	var criancas: int = 0; var idosos: int = 0; var perfis: Dictionary = {}
	for p: Node3D in mundo.pessoas:
		if p.idade=="crianca": criancas += 1; exigir(not mundo.equipa_grupo.livres().has(p),"Criança não entra em contratos de trabalho")
		if p.idade=="idoso": idosos += 1
		perfis[p.perfil] = true
	exigir(criancas>0 and idosos>0 and perfis.size()==5,"Comunidade tem idades, alturas e corpos variados")
	mundo.jogador.perfil = 3; mundo.jogador.criar_avatar(); exigir(mundo.jogador.visual.scale.x>1.2,"Opção robusta altera proporções")
	familia.definir_preferencia(1); exigir(familia.pessoa.mulher,"Opção de companheira")
	familia.definir_preferencia(2); exigir(not familia.pessoa.mulher,"Opção de companheiro")
	familia.preferencia = -1; mundo.jogador.mulher = true; familia.actualizar_genero(); exigir(not familia.pessoa.mulher,"Agricultora tem marido por predefinição")
	mundo.jogador.mulher = false; familia.actualizar_genero(); exigir(familia.pessoa.mulher,"Agricultor tem esposa por predefinição")
	mundo.partida.caminho = "user://teste-familia-isolada.mozsave"; familia.preferencia = 1
	exigir(mundo.partida.guardar(false),"Guarda nova família, roupa, corpo e automóveis")
	mundo.jogador.perfil = 0; mundo.jogador.roupa = 0; familia.preferencia = -1
	exigir(mundo.partida.carregar() and mundo.jogador.perfil==3 and mundo.jogador.roupa==4 and familia.preferencia==1,"Retoma conserva personalização e família")
	var legado: Dictionary = mundo.partida.capturar(); legado.erase("familia"); legado.erase("carros"); legado.jogador.erase("roupa"); legado.jogador.erase("perfil")
	exigir(mundo.partida.validar(legado),"Gravações anteriores continuam válidas")
	for sufixo: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(mundo.partida.caminho+sufixo): DirAccess.remove_absolute(ProjectSettings.globalize_path(mundo.partida.caminho+sufixo))
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop(); print("CASA E FAMÍLIA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
