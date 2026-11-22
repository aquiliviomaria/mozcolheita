extends SceneTree
var falhas: int = 0
var mundo: Node3D
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.calendario.set_process(false); mundo.calendario.decorrido = 100
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	var moradores: int = 0; var agricultores: int = 0
	var casas: Dictionary = {}
	for p: Node3D in mundo.pessoas:
		if p.rotina!=null:
			moradores += 1
			var chave: Vector2 = Vector2(p.rotina.casa.x,p.rotina.casa.z)
			casas[chave] = int(casas.get(chave,0))+1
			if p.rotina.agricultor: agricultores += 1
	exigir(moradores==40 and agricultores==12,"40 moradores com rotinas, 12 agricultores nas seis quintas")
	exigir(casas.size()==34,"Residências distintas para 28 moradores e seis casais agricultores")
	var p: Node3D = mundo.pessoas[6]; var r: RefCounted = p.rotina
	var saldo: int = mundo.saldo; var stock: Dictionary = mundo.stock.duplicate()
	var vistos: Dictionary = {}
	for i: int in range(16):
		p.position = r.passos[r.indice].p; p.destino_actual = Vector3.INF
		r.actualizar(0.01); vistos[r.tipo_actual()] = true; r.actualizar(10)
	exigir(vistos.size()==4 and r.trabalhos>=16,"Ciclo de preparar, semear, regar e colher com avanço entre pontos")
	exigir(mundo.saldo==saldo and mundo.stock==stock,"Vizinhos não alteram saldo nem produtos do jogador")
	r.fase_lavoura = 2; r.restante = -1; p.position = r.passos[r.indice].p; r.actualizar(0.01)
	exigir(r.regador.visible and r.gotas.emitting,"Regador com água durante tarefa de rega")
	r.suspender(); exigir(not r.ferramenta.visible and not r.gotas.emitting,"Rotina suspende ferramentas e água para contrato/conversa")
	# Movimento real num corredor de cultura livre, sem reposicionar a cada frame.
	p.position = r.passos[0].p+Vector3(0,0,5); var inicio: Vector3 = p.position; r.indice = 0; r.restante = -1
	for i: int in range(240):
		await physics_frame; r.actualizar(1.0/60)
	exigir(p.position.distance_to(inicio)>2,"Agricultor desloca-se fisicamente na machamba")
	var residente: Node3D = mundo.pessoas[26]; var rotina: RefCounted = residente.rotina
	mundo.calendario.decorrido = 410; residente.position = rotina.ponto(rotina.casa+Vector3(0,0,9)); rotina.actualizar(0.1)
	for i: int in range(360):
		await physics_frame; rotina.actualizar(1.0/60)
	exigir(residente.position.distance_to(rotina.ponto(rotina.casa+Vector3(0,0,3)))<1.2,"Morador entra pela porta e descansa em casa à noite")
	mundo.calendario.decorrido = 100; rotina.actualizar(0.1)
	exigir(rotina.indice==0 and not rotina.noite_anterior,"Amanhecer retoma percurso pelo acesso frontal")
	var tv: Control = mundo.casa.vida_domestica.televisao.desenho
	exigir(tv.NOTICIAS.size()>=12 and str(tv.NOTICIAS[0].titulo).contains("GTA VI"),"Televisão tem boletim GTA VI com fonte e data")
	print("ROTINAS E TV · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit(0 if falhas==0 else 1)
