extends Node3D
## Companhia adulta independente dos contratos agrícolas; navegação física na casa e no campo.
var mundo: Node3D
var pessoa: CharacterBody3D
var preferencia: int = -1
var actividade: String = "casa"
var veiculo: CharacterBody3D
var percurso: PackedVector3Array = []
var alvo_anterior: Vector3 = Vector3.INF
var destino: Vector3
var roupa_banho: int = 0
var banho_ativo: bool = false
var intervalo: float = 0
var pronta: bool = false
var comida_mao: MeshInstance3D
var grafo: AStar3D
var chamada_rapida: bool = false
var preso: float = 0
var balão: Label3D
func _ready() -> void:
	pessoa = preload("res://scripts/player.gd").new(); pessoa.mundo = mundo; pessoa.mulher = not mundo.jogador.mulher; pessoa.aparencia = 3; pessoa.perfil = 3; pessoa.roupa = 2; pessoa.bloqueado = true; add_child(pessoa); pessoa.set_physics_process(false); pessoa.collision_layer = 2; pessoa.collision_mask = 1|2|4|8|16
	pessoa.position = mundo.casa.to_global(Vector3(5,5.64,3)); balão = mundo.placa(pessoa,Vector3(0,2.4,0),"Companheira"); balão.visibility_range_end = 14; balão.font_size = 24; balão.pixel_size = 0.0025
	grafo = AStar3D.new()
	var pontos: Array[Vector3] = [Vector3(0,0.64,22),Vector3(0,0.64,13),Vector3(0,0.64,9),Vector3(0,0.64,5.5),Vector3(-7,0.64,5.5),Vector3(-12,0.64,5),Vector3(-12,5.64,-8.8),Vector3(0,5.64,-8.8),Vector3(0,5.64,-5.5),Vector3(0,5.64,3.5),Vector3(4.5,5.64,3.5),Vector3(4.8,5.64,6),Vector3(5,5.64,-5.5),Vector3(11,5.64,-7),Vector3(0,0.64,0),Vector3(5,0.64,0),Vector3(9.2,0.64,2),Vector3(5,0.64,3.3),Vector3(10.8,0.64,3.3),Vector3(6,0.64,-6),Vector3(11,0.64,-6)]
	for i: int in range(pontos.size()): grafo.add_point(i,mundo.casa.to_global(pontos[i]))
	for ligacao: Vector2i in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,6),Vector2i(6,7),Vector2i(7,8),Vector2i(8,9),Vector2i(9,10),Vector2i(10,11),Vector2i(8,12),Vector2i(12,13),Vector2i(3,14),Vector2i(14,15),Vector2i(15,17),Vector2i(17,18),Vector2i(18,16),Vector2i(15,19),Vector2i(19,20)]: grafo.connect_points(ligacao.x,ligacao.y)
	actualizar_genero()
func actualizar_genero() -> void:
	var mulher: bool = not mundo.jogador.mulher if preferencia<0 else preferencia==0
	if pessoa.mulher!=mulher:
		pessoa.mulher = mulher; pessoa.criar_avatar()
		if veiculo!=null: pessoa.visual.reparent(veiculo); pessoa.visual.transform = Transform3D(Basis.IDENTITY,veiculo.assento_passageiro)
	balão.text = "Ester · Companheira" if mulher else "Mateus · Companheiro"
func definir_preferencia(indice: int) -> void:
	preferencia = clampi(indice-1,-1,1); actualizar_genero()
func posicao_actividade(tipo: String) -> Vector3:
	if tipo=="cama": return mundo.casa.vida_domestica.posicao_cama(pessoa,-1)
	return mundo.casa.to_global({"cama":Vector3(9.2,6.85,7.1),"mesa":Vector3(9.2,0.64,2),"sofa":Vector3(-5.8,0.64,6.8),"banho":Vector3(11.8,5.7,-7),"cozinhar":Vector3(11,0.64,-6),"servir":Vector3(10.8,0.64,3.3)}.get(tipo,Vector3(5,5.64,3)))
func chamar(tipo: String = "seguir") -> void:
	if veiculo!=null: mundo.avisar("Companhia a bordo · sai consigo quando parar"); return
	if tipo==actividade and pronta: mundo.avisar("Companhia já está consigo."); return
	if actividade in ["cama","mesa","sofa","banho"]: terminar_actividade()
	pessoa.collision_layer = 2
	chamada_rapida = true
	actividade = "veiculo" if mundo.trator_actual!=null else tipo
	pronta = false; alvo_anterior = Vector3.INF
	mundo.avisar(("Ester" if pessoa.mulher else "Mateus")+" está a caminho · C volta a chamar")
func terminar_actividade() -> void:
	if actividade=="casa": return
	if banho_ativo: pessoa.roupa = 4; pessoa.criar_avatar(); banho_ativo = false
	if veiculo!=null: return
	var saida: Dictionary = {"cama":Vector3(4.8,5.64,7.5),"mesa":Vector3(10.8,0.64,3.3),"sofa":Vector3(-5.8,0.64,5.1),"banho":Vector3(12.2,5.64,-4.1)}
	if saida.has(actividade): pessoa.position = mundo.casa.to_global(saida[actividade])
	pessoa.repor_pose()
	actividade = "seguir"; pronta = false; pessoa.collision_layer = 2; pessoa.visual.transform = Transform3D.IDENTITY; alvo_anterior = Vector3.INF
func colocar_actividade(tipo: String) -> void:
	if veiculo!=null: desembarcar()
	if tipo=="banho": roupa_banho = pessoa.roupa; pessoa.roupa = 3; pessoa.criar_avatar(); banho_ativo = true
	actividade = tipo; pessoa.position = posicao_actividade(tipo); pronta = true; pose(0)
func destino_actual() -> Vector3:
	if actividade=="veiculo" and mundo.trator_actual!=null: return mundo.trator_actual.to_global(Vector3(2.6,0,0))
	if actividade=="seguir": return mundo.jogador.position+mundo.jogador.visual.global_basis.x*1.6
	if actividade=="casa": return mundo.casa.to_global(Vector3(5,5.64,3))
	if actividade=="banho": return mundo.casa.to_global(Vector3(11.8,5.64,-4.2))
	var alvo: Vector3 = posicao_actividade(actividade)
	# Aproximação no chão; só depois assume a pose deitada/sentada.
	if actividade=="cama": alvo = mundo.casa.to_global(Vector3(5,5.64,6))
	return alvo
func planear(alvo: Vector3) -> void:
	alvo_anterior = alvo; percurso.clear()
	var origem_dentro: bool = mundo.casa.dentro(pessoa.position); var alvo_dentro: bool = mundo.casa.dentro(alvo)
	var exterior: Vector3 = mundo.casa.to_global(Vector3(0,0.08,26)); exterior.y = mundo.altura(exterior)+0.08
	if origem_dentro or alvo_dentro:
		if not origem_dentro: anexar_exterior(pessoa.position,exterior)
		var inicio: int = grafo.get_closest_point(pessoa.position) if origem_dentro else 0
		var fim: int = grafo.get_closest_point(alvo) if alvo_dentro else 0
		percurso.append_array(grafo.get_point_path(inicio,fim))
		if not alvo_dentro: percurso.append(exterior); anexar_exterior(exterior,alvo)
	else: anexar_exterior(pessoa.position,alvo)
	percurso.append(alvo)
func anexar_exterior(inicio: Vector3,fim: Vector3) -> void:
	var rota: Array[Vector3] = preload("res://scripts/layout.gd").caminho(inicio,fim,1)
	for p: Vector3 in rota: p.y = mundo.altura(p)+0.08; percurso.append(p)
func pose(delta: float) -> void:
	pessoa.collision_layer = 0
	pessoa.visual.transform = Transform3D.IDENTITY
	if actividade=="cama": pessoa.position = posicao_actividade("cama"); pessoa.deitar(-1)
	elif actividade in ["mesa","sofa"]:
		pessoa.position = posicao_actividade(actividade); pessoa.visual.position.y = 0.3; pessoa.animar(delta,0,true)
		if actividade=="mesa": pessoa.sentar_no_assento(mundo.casa.to_global(Vector3(9.2,1.08,2)).y,delta)
		if actividade=="sofa":
			for i: int in range(2): pessoa.bracos[i].rotation.x = 0.15; pessoa.cotovelos[i].rotation.x = 0.4
		if actividade=="mesa" and mundo.casa.vida_domestica.a_comer>0:
			pessoa.bracos[1].rotation.x = 1.4; pessoa.cotovelos[1].rotation.x = 1.8
			if not is_instance_valid(comida_mao): comida_mao = MeshInstance3D.new(); comida_mao.mesh = preload("res://scripts/meal_table.gd").bocado(mundo.casa.vida_domestica.ementa_refeicao); comida_mao.scale = Vector3.ONE*0.6; pessoa.maos[1].add_child(comida_mao)
		elif is_instance_valid(comida_mao): comida_mao.queue_free()
	elif actividade=="banho":
		pessoa.position = posicao_actividade("banho") if mundo.casa.vida_domestica.duche.companhia_dentro else mundo.casa.to_global(Vector3(11.8,5.64,-4.2)); pessoa.animar(delta,0)
	else: pessoa.animar(delta,0)
func embarcar(v: CharacterBody3D) -> bool:
	if absf(v.rapidez)>0.3 or v.passageiro!=null or v.trabalhador!=null: return false
	veiculo = v; v.passageiro = pessoa; pessoa.collision_layer = 0; pessoa.visual.reparent(v); pessoa.visual.transform = Transform3D(Basis.IDENTITY,v.assento_passageiro); pessoa.hide(); pessoa.animar(0,0,true); return true
func desembarcar() -> void:
	if veiculo==null: return
	var v: CharacterBody3D = veiculo; pessoa.visual.reparent(pessoa); pessoa.visual.transform = Transform3D.IDENTITY; pessoa.show(); v.passageiro = null; veiculo = null
	pessoa.position = mundo.partida.posicao_segura(pessoa,v); pessoa.collision_layer = 2; actividade = "seguir"; pronta = false; alvo_anterior = Vector3.INF
func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	if mundo.casa.vida_domestica.estado=="banho" and mundo.casa.vida_domestica.duche.controla_companhia: return
	if veiculo!=null: pessoa.position = veiculo.position; pessoa.animar(delta,0,true); return
	if actividade=="veiculo" and mundo.trator_actual==null: actividade = "seguir"
	var alvo: Vector3 = destino_actual()
	if pronta and actividade in ["cama","mesa","sofa","banho"]: pose(delta); return
	if pronta and actividade in ["cozinhar","servir"]: pessoa.animar(delta,0); return
	if pessoa.position.distance_to(alvo)<(1.3 if actividade=="seguir" else 1.15 if actividade in ["mesa","sofa"] else 0.65):
		pessoa.velocity = Vector3.ZERO
		if actividade=="veiculo": embarcar(mundo.trator_actual)
		elif actividade in ["cama","mesa","sofa","banho","cozinhar","servir"]:
			pronta = true
			if actividade=="banho": roupa_banho = pessoa.roupa; pessoa.roupa = 3; pessoa.criar_avatar(); banho_ativo = true
			pose(delta)
		else: pessoa.animar(delta,0)
		return
	intervalo -= delta
	if alvo_anterior.distance_to(alvo)>3 and intervalo<=0: planear(alvo); intervalo = 1
	while not percurso.is_empty() and pessoa.position.distance_to(percurso[0])<0.7: percurso.remove_at(0)
	if percurso.is_empty(): planear(alvo)
	if percurso.is_empty(): return
	var d: Vector3 = percurso[0]-pessoa.position; d.y = 0; d = d.normalized()
	var contacto: KinematicCollision3D = KinematicCollision3D.new()
	if pessoa.test_move(pessoa.global_transform,d*0.6,contacto) and contacto.get_normal().y<0.7:
		for angulo: float in [0.6,-0.6,1.2,-1.2,1.6,-1.6]:
			var alternativa: Vector3 = d.rotated(Vector3.UP,angulo)
			if not pessoa.test_move(pessoa.global_transform,alternativa*0.6): d = alternativa; break
	var velocidade: float = 6.0 if chamada_rapida else 2.8
	var antes: Vector3 = pessoa.position
	velocidade = minf(velocidade,pessoa.position.distance_to(percurso[0])/maxf(delta,0.001))
	pessoa.velocity = d*velocidade; pessoa.velocity.y = -4; pessoa.move_and_slide(); pessoa.visual.rotation.y = lerp_angle(pessoa.visual.rotation.y,atan2(-d.x,-d.z),minf(1,delta*8)); pessoa.animar(delta,velocidade)
	if actividade=="servir":
		for i: int in range(2): pessoa.bracos[i].rotation.x = 0.9; pessoa.cotovelos[i].rotation.x = 1.1
	preso = preso+delta if pessoa.position.distance_to(antes)<delta*0.2 else 0
	if preso>1.2:
		# Recalcula sem teletransportar; navegação local contorna objectos móveis.
		preso = 0; planear(alvo)
		if not percurso.is_empty() and absf(percurso[0].y-pessoa.position.y)<0.5:
			var desvio: Array[Vector3] = preload("res://scripts/navigation.gd").contornar(pessoa,percurso[0])
			if not desvio.is_empty():
				percurso.remove_at(0)
				for i: int in range(desvio.size()-1,-1,-1): percurso.insert(0,desvio[i])
