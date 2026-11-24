extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false)
	mundo.jogador.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.familia.set_physics_process(false)
	var rede: GDScript = preload("res://scripts/road_network.gd")
	var vias: Array[Dictionary] = rede.cidade(); vias.append_array(rede.exterior()); vias.append_array(rede.quintas())
	var maior: float = 0; var amostras: int = 0
	for via: Dictionary in vias:
		var pontos: Array[Vector3] = via.pontos
		for i: int in range(pontos.size()-1):
			var a: Vector3 = pontos[i]; var b: Vector3 = pontos[i+1]; var lado: Vector3 = Vector3(-(b-a).z,0,(b-a).x).normalized()*float(via.largura)/2
			var passos: int = maxi(1,ceili(a.distance_to(b)))
			for j: int in range(passos+1):
				for desvio: float in [-1,0,1]:
					maior = maxf(maior,absf(mundo.altura(a.lerp(b,float(j)/passos)+lado*desvio))); amostras += 1
	exigir(maior<0.001,"Todas as vias e bordas sem montanhas: %d amostras; desnível %.5f m" % [amostras,maior])
	var w: Node3D = mundo.armazem
	exigir(preload("res://scripts/layout.gd").dentro(w.position) and not preload("res://scripts/layout.gd").junto_portao(w.position,25),"Armazém dentro da quinta com espaço junto dos portões")
	for n: Node in w.get_children(): exigir(n.get_script()!=load("res://scripts/industrial_gate.gd"),"Armazém sem segurança ou cancela")
	var sacola: Dictionary = {0:24,1:13}; w.receber(sacola)
	exigir(sacola.is_empty() and mundo.stock.get(0)==24 and mundo.stock.get(1)==13,"Produção depositada no stock da quinta")
	Engine.time_scale = 4
	mundo.sacola = {2:9}; mundo.jogador.position = w.CENTRO; w.dentro = false; w.actualizar(1)
	for i: int in range(3600):
		await physics_frame
		if not w.funcionario.ocupado(): break
	exigir(mundo.sacola.is_empty() and mundo.stock.get(2)==9,"Entrada a pé guarda a colheita")
	mundo.jogador.position = w.ENTREGA
	mundo.caminhao.position = w.CENTRO; mundo.caminhao.carga = {3:18}; mundo.caminhao.entrar(); w.actualizar(1)
	for i: int in range(3600):
		await physics_frame
		if not w.funcionario.ocupado(): break
	exigir(mundo.caminhao.carga.is_empty() and mundo.stock.get(3)==18,"Transporte descarrega dentro do armazém")
	mundo.central_logistica.fechar()
	exigir(mundo.central_logistica.carregar_escolha(1,7,mundo.caminhao)==7 and mundo.stock.get(1)==6,"Carregamento escolhido preserva stock excedente")
	mundo.caminhao.sair(); mundo.caminhao.position = w.ENTREGA; mundo.jogador.position = w.ENTREGA; mundo.interagir()
	exigir(mundo.trator_actual==mundo.caminhao and not mundo.central_logistica.aberto,"E permite embarcar no camião estacionado junto ao armazém")
	mundo.caminhao.sair()
	for f: Node3D in mundo.fabricas:
		var seguranca: bool = false
		for n: Node in f.get_children():
			if n.get_script()==load("res://scripts/industrial_gate.gd"): seguranca = true
		exigir(seguranca,"Fábrica de venda mantém segurança e cancela")
	Engine.time_scale = 1
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); print("ACESSOS · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(falhas)
