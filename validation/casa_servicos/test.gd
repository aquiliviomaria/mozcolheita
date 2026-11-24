extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.jogador.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	for v: Node3D in mundo.comunidade.trafego: v.set_physics_process(false)
	var lar: Node3D = mundo.casa.vida_domestica; var f: Node3D = mundo.familia
	mundo.jogador.position = mundo.casa.to_global(lar.SANITA); lar.interagir(); lar._process(0)
	exigir(lar.estado=="sanita" and absf(mundo.jogador.visual.to_global(Vector3(0,0.8,0)).y-mundo.casa.to_global(Vector3(0,6.65,0)).y)<0.001,"Sanita usa postura sentada no assento")
	lar.levantar(); exigir(lar.descarga.descargas==1 and lar.descarga.som.playing and lar.descarga.som.stream.get_length()>2,"Levantar da sanita acciona água e som de descarga uma vez")
	lar.levantar(); exigir(lar.descarga.descargas==1,"Levantar novamente não repete descarga")
	mundo.jogador.position = mundo.casa.to_global(lar.DUCHE); lar.interagir()
	for i: int in range(130): lar._process(1.0/60)
	exigir(lar.agua.emitting and lar.duche.esquerda.get_child(0).mesh.size.y<2,"Banho tem água e pano baixo que deixa chuveiros visíveis")
	mundo.casa._process(0)
	var solida: bool = true
	for n: Node3D in mundo.casa.telhado+mundo.casa.piso_superior: solida = solida and n.visible
	exigir(solida,"Banho conserva teto e todos os elementos da casa")
	lar.duche.pedir_saida()
	for i: int in range(130): lar._process(1.0/60)
	exigir(not lar.ocupado() and mundo.jogador.roupa==4 and not lar.agua.emitting,"Sai do banho com roupão e água desligada")
	mundo.jogador.position = mundo.casa.to_global(lar.ROUPEIRO); lar.interagir(); exigir(mundo.jogador.roupa==0,"Só o roupeiro troca o roupão por roupa de trabalho")
	mundo.jogador.position = mundo.casa.to_global(lar.MESA); mundo.vitais.fome = 10; var porcoes: int = lar.refeicoes; lar.interagir()
	exigir(not lar.comida.servida and lar.a_comer==0 and not lar.comer(),"Mesa tem pratos vazios e não se come antes do serviço")
	Engine.time_scale = 4
	var trouxe: bool = false; var cozinhou: bool = false
	for i: int in range(7200):
		await physics_frame
		cozinhou = cozinhou or lar.servico_mesa.fase=="cozinha" and f.pronta
		trouxe = trouxe or is_instance_valid(lar.servico_mesa.travessa) and lar.servico_mesa.fase=="servir"
		if lar.refeicoes<porcoes: break
	print("SERVIÇO · ",lar.servico_mesa.fase," · ",f.actividade," · ",mundo.casa.to_local(f.pessoa.position)," · percurso ",f.percurso)
	exigir(cozinhou and trouxe and lar.comida.servida and f.actividade=="mesa" and f.pronta and lar.refeicoes==porcoes-1,"Companhia vem do andar superior, cozinha, traz comida e senta antes da refeição partilhada")
	lar.levantar(); exigir(not lar.comida.servida,"Levantar deixa pratos vazios e cancela o serviço")
	Engine.time_scale = 1
	mundo.jogador.position = Vector3(20,0.1,8); f.pessoa.position = Vector3(60,0.1,8); f.actividade = "casa"; f.chamar(); f._physics_process(1.0/60)
	exigir(f.actividade=="seguir" and f.pessoa.velocity.length()>5,"Chamada C faz a companhia correr até ao jogador")
	exigir(mundo.tratores.size()==3 and mundo.implementos.size()==4 and mundo.drones.size()==2 and mundo.carrinhas.size()==3,"Frota tem três tractores, quatro implementos únicos, dois drones e três carrinhas")
	for v: Node3D in mundo.tratores+mundo.implementos+mundo.drones:
		exigir(v.position.x< -30 and v.position.z< -25 and not preload("res://scripts/layout.gd").junto_portao(v.position),"Equipamento ao lado da casa e longe dos portões")
	mundo.jogador.roupa = 4; var d: Dictionary = mundo.partida.capturar()
	exigir(mundo.partida.validar(d),"Gravação aceita roupão e frota reduzida")
	var deslocado: Dictionary = d.duplicate(true); deslocado.erase("parque_versao"); deslocado.maquinas[0].posicao = Vector3(80,0,60)
	exigir(mundo.partida.adaptar_frota(deslocado).maquinas[0].posicao.x< -30,"Gravação anterior muda o parque para o outro lado da casa")
	var antigas: Array = d.maquinas.duplicate(true); d.maquinas = []
	for fila: int in range(3):
		for i: int in range(4): d.maquinas.append(antigas[i].duplicate(true))
	for i: int in range(4,7): d.maquinas.append(antigas[i].duplicate(true))
	d.drones.append(Vector3.ZERO); d.veiculos[0].maquina = 5; d.veiculos[1].maquina = 9; d.veiculos[2].maquina = 12; d.maquinas[12].carga = {0:33}
	exigir(mundo.partida.validar(d),"Gravação antiga com quinze máquinas continua válida")
	var novo: Dictionary = mundo.partida.adaptar_frota(d)
	exigir(novo.maquinas.size()==7 and novo.drones.size()==2 and novo.maquinas[4].carga.get(0)==33 and novo.veiculos[0].maquina==1 and novo.veiculos[1].maquina==-1 and novo.veiculos[2].maquina==4,"Migração conserva cargas e remove engates duplicados")
	print("SERVIÇOS DA CASA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(falhas)
