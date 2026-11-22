extends Node3D
## Rotinas domésticas. Estados de repouso só terminam por decisão do jogador.
const DIA: float = preload("res://scripts/calendar.gd").SEGUNDOS_DIA
const CAMA: Vector3 = Vector3(4.8,5.64,6)
const MESA: Vector3 = Vector3(8,0.64,2.8)
const SOFA: Vector3 = Vector3(-7,0.64,5.6)
const ROUPEIRO: Vector3 = Vector3(11.7,5.64,2)
const DUCHE: Vector3 = Vector3(11,5.64,-5.1)
const SANITA: Vector3 = Vector3(6,5.64,-5.5)
const ELEVADOR: Vector3 = Vector3(-5,0.64,-1.8)
var mundo: Node3D
var casa: Node3D
var estado: String = ""
var refeicoes: int = 4
var retorno: Vector3
var visual_anterior: Transform3D
var camada_anterior: int = 2
var ferramenta_visivel: bool = true
var tempo: float = 0
var manha: float = 0
var avancou: bool = false
var recado_sono: String = ""
var introduzido: bool = false
var roupa_anterior: int = 0
var comida: Node3D
var alimento_mao: Node3D
var avisos: Array[Label3D] = []
var cortina: ColorRect
var agua: CPUParticles3D
var duche: Node3D
var televisao: Node3D
var a_comer: float = 0
var elevador_destino: float = 0
var aviso_cama: Label3D
var aviso_mesa: Label3D
func _ready() -> void:
	comida = Node3D.new(); comida.name = "RefeicaoNaMesa"; comida.position = Vector3(8,1.76,0); casa.add_child(comida)
	for x: float in [-1.2,1.2]:
		mundo.caixa(comida,Vector3(x,0.025,0),Vector3(1.1,0.045,0.8),Color("f8e9cb"))
		for i: int in range(3):
			var fruto: MeshInstance3D = MeshInstance3D.new(); fruto.mesh = preload("res://scripts/produce_mesh.gd").modelo(0 if i==0 else 3); fruto.position = Vector3(x-0.3+i*0.3,0.15,0); comida.add_child(fruto)
		mundo.caixa(comida,Vector3(x,0.14,-0.65),Vector3(0.18,0.28,0.18),Color("729a9b"))
	for spec: Dictionary in [{"p":CAMA,"t":"E · Cama"},{"p":MESA,"t":"E · Sentar / comer"},{"p":SOFA,"t":"E · Sofá e televisão"},{"p":ROUPEIRO,"t":"E · Trocar roupa"},{"p":DUCHE,"t":"E · Tomar banho"},{"p":SANITA,"t":"E · Usar sanita"},{"p":ELEVADOR,"t":"E · Subir no elevador"},{"p":ELEVADOR+Vector3.UP*5,"t":"E · Descer no elevador"}]:
		var l: Label3D = mundo.placa(casa,spec.p+Vector3.UP*1.8,spec.t); l.visibility_range_end = 16; l.set_meta("ponto",spec.p); avisos.append(l)
	aviso_cama = avisos[0]; aviso_mesa = avisos[1]
	var camada: CanvasLayer = CanvasLayer.new(); camada.layer = 30; add_child(camada)
	cortina = ColorRect.new(); cortina.color = Color(0,0,0,0); cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE; camada.add_child(cortina); cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	agua = CPUParticles3D.new(); agua.name = "AguaDuche"; agua.position = Vector3(11,8.8,-7); agua.amount = 64; agua.lifetime = 0.7; agua.direction = Vector3.DOWN; agua.spread = 8; agua.initial_velocity_min = 3; agua.initial_velocity_max = 4; agua.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; agua.emission_box_extents = Vector3(1.2,0,0.6); agua.gravity = Vector3(0,-5,0)
	var gota: BoxMesh = BoxMesh.new(); gota.size = Vector3(0.025,0.16,0.025); gota.material = mundo.material(Color("83c9dd")); agua.mesh = gota; agua.emitting = false; casa.add_child(agua); casa.piso_superior.append(agua)
	duche = preload("res://scripts/shower_curtain.gd").new(); duche.lar = self; duche.mundo = mundo; duche.casa = casa; casa.add_child(duche)
	televisao = preload("res://scripts/television.gd").new(); televisao.mundo = mundo; televisao.position = Vector3(-7,3.1,0.4); casa.add_child(televisao)
func ocupado() -> bool: return not estado.is_empty()
func noite() -> bool: return fmod(mundo.calendario.decorrido,DIA)>=DIA/2
func perto(p: Vector3) -> bool:
	return mundo.trator_actual==null and mundo.drone_actual==null and not mundo.camera.livre and mundo.jogador.global_position.distance_to(casa.to_global(p))<2.2
func familia() -> Node3D: return mundo.familia
func interagir() -> bool:
	if mundo.pausado() or mundo.contrato.activo: return false
	if estado=="sentado": comer(); return true
	if ocupado():
		if estado not in ["dormindo","elevador"]: levantar()
		return true
	if perto(CAMA):
		iniciar("dormindo" if noite() else "cama_dia"); tempo = 0; avancou = false; recado_sono = ""
		if estado=="dormindo":
			manha = (floorf(mundo.calendario.decorrido/DIA)+1)*DIA
			mundo.jogador.position = posicao_cama(mundo.jogador,1); mundo.jogador.deitar(1)
			if familia()!=null: familia().chamar("cama")
		else: posar(Vector3(6,5.64,4.3),false); mundo.avisar("Sentado na cama · E para levantar")
		return true
	if perto(MESA): iniciar("sentado"); posar(Vector3(6.8,0.64,2),false); mundo.avisar("E comer · E durante a refeição não gasta outra porção · WASD/Esc levantar · C chamar companhia"); return true
	if perto(SOFA): iniciar("televisao"); posar(Vector3(-8.2,0.64,6.8),false); televisao.ligada = true; mundo.avisar("E/WASD levantar · Espaço televisão · C chamar companhia"); return true
	if perto(ROUPEIRO): trocar_roupa(); return true
	if perto(DUCHE):
		iniciar("banho"); roupa_anterior = mundo.jogador.roupa; mudar_roupa(3); mundo.jogador.visual.rotation = Vector3.ZERO; duche.iniciar(); mundo.avisar("Banho · E terminar · C chamar companhia"); return true
	if perto(SANITA): iniciar("sanita"); posar(Vector3(6,5.64,-7),true); mundo.avisar("E terminar"); return true
	for piso: int in range(2):
		if perto(ELEVADOR+Vector3.UP*piso*5):
			iniciar("elevador"); elevador_destino = 5.64 if piso==0 else 0.64; casa.elevador.position.y = 0.64+piso*5; mundo.jogador.position = casa.to_global(Vector3(-5,casa.elevador.position.y,-5)); return true
	return false
func iniciar(novo: String) -> void:
	retorno = mundo.jogador.global_position; visual_anterior = mundo.jogador.visual.transform; camada_anterior = mundo.jogador.collision_layer; ferramenta_visivel = mundo.ferramentas.vista.visible
	estado = novo; mundo.jogador.bloqueado = true; mundo.jogador.collision_layer = 0; mundo.jogador.velocity = Vector3.ZERO; mundo.ferramentas.vista.hide()
func posicao_cama(actor: Node3D,lado: int) -> Vector3:
	# Cabeças alinhadas com as almofadas mesmo em corpos altos/baixos.
	return casa.to_global(Vector3(8-lado*0.36,7.04,7.65-1.73*actor.escala_corpo().y))
func posar(p: Vector3,virar: bool) -> void:
	mundo.jogador.position = casa.to_global(p); mundo.jogador.visual.position = Vector3(0,0.3,0); mundo.jogador.visual.rotation = Vector3(0,PI if virar else 0,0)
func levantar() -> void:
	if not ocupado(): return
	var anterior: String = estado
	if anterior=="banho": duche.cancelar(); mudar_roupa(roupa_anterior)
	estado = ""; cortina.color.a = 0; a_comer = 0; agua.emitting = false; televisao.ligada = false
	if is_instance_valid(alimento_mao): alimento_mao.queue_free()
	mundo.jogador.position = retorno; mundo.jogador.visual.transform = visual_anterior; mundo.jogador.collision_layer = camada_anterior; mundo.jogador.bloqueado = false; mundo.jogador.velocity = Vector3.ZERO; mundo.jogador.repor_pose(); mundo.ferramentas.vista.visible = ferramenta_visivel
	if familia()!=null: familia().terminar_actividade()
func mudar_roupa(indice: int) -> void:
	mundo.jogador.roupa = indice; mundo.jogador.criar_avatar(); mundo.ferramentas.seleccionar(mundo.ferramentas.actual)
	if ocupado(): mundo.ferramentas.vista.hide()
func trocar_roupa() -> void:
	mudar_roupa((mundo.jogador.roupa+1)%4); mundo.avisar("Roupa: "+["Trabalho verde","Camisa azul","Capulana e terra","Conjunto de lazer"][mundo.jogador.roupa])
func origem_refeicao() -> Dictionary:
	for origem: Dictionary in [mundo.sacola,mundo.stock]:
		for cultura: int in [0,3,2,1]:
			if int(origem.get(cultura,0))>0: return origem
	return {}
func tem_comida() -> bool: return refeicoes>0 or not origem_refeicao().is_empty()
func comer() -> bool:
	if estado!="sentado" or a_comer>0: return false
	if mundo.vitais.fome>=99 and mundo.vitais.energia>=99 and mundo.vitais.vida>=99: mundo.avisar("Já está alimentado e descansado."); return false
	if refeicoes>0: refeicoes -= 1
	else:
		var origem: Dictionary = origem_refeicao(); var cultura: int = -1
		for i: int in [0,3,2,1]:
			if int(origem.get(i,0))>0: cultura = i; break
		if cultura<0: mundo.avisar("Sem comida · traga um produto ou guarde colheita."); return false
		origem[cultura] = int(origem[cultura])-1
		if origem[cultura]==0: origem.erase(cultura)
	mundo.vitais.alimentar(); mundo.armazem.actualizar(1); a_comer = 2.8
	alimento_mao = MeshInstance3D.new(); alimento_mao.mesh = preload("res://scripts/produce_mesh.gd").modelo(0); alimento_mao.scale = Vector3.ONE*0.65; mundo.jogador.maos[1].add_child(alimento_mao)
	mundo.avisar("A comer · refeição +35 alimentação · C convida companhia"); return true
func entrada(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo: return
	if evento.physical_keycode==KEY_C and familia()!=null: familia().chamar(actividade()); return
	if evento.physical_keycode==KEY_F9: mundo.partida.carregar(); return
	if evento.physical_keycode==KEY_F5: mundo.partida.guardar(); return
	if estado in ["dormindo","elevador"]: return
	if estado=="banho" and evento.physical_keycode in [KEY_E,KEY_W,KEY_A,KEY_S,KEY_D,KEY_ESCAPE]: duche.pedir_saida(); return
	if evento.physical_keycode==KEY_SPACE and estado=="televisao": televisao.ligada = not televisao.ligada; return
	if evento.physical_keycode==KEY_E:
		if estado=="sentado" and a_comer<=0 and (mundo.vitais.fome<99 or mundo.vitais.energia<99 or mundo.vitais.vida<99): comer()
		else: levantar()
	elif estado not in ["acordado","cama_dia"] and evento.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_ESCAPE]: levantar()
func actividade() -> String:
	return "cama" if estado in ["dormindo","acordado","cama_dia"] else "mesa" if estado=="sentado" else "banho" if estado=="banho" else "sofa" if estado=="televisao" else "seguir"
func comecar_intro() -> void:
	if introduzido: return
	# Começa directamente na cama; o retorno fica no chão ao lado dela.
	introduzido = true; mundo.calendario.decorrido = 410
	mundo.jogador.position = casa.to_global(CAMA); mundo.jogador.visual.rotation = Vector3.ZERO
	interagir()
	if familia()!=null: familia().colocar_actividade("cama")
func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	if estado=="elevador":
		casa.elevador.position.y = move_toward(casa.elevador.position.y,elevador_destino,delta*2.5)
		mundo.jogador.position = casa.to_global(Vector3(-5,casa.elevador.position.y,-5))
		if is_equal_approx(casa.elevador.position.y,elevador_destino): retorno = casa.to_global(Vector3(-5,elevador_destino,-1.8)); levantar()
func _process(delta: float) -> void:
	if mundo.jogador==null or mundo.hud==null: return
	for l: Label3D in avisos: l.visible = not ocupado() and not mundo.pausado() and perto(l.get_meta("ponto"))
	aviso_cama.text = "E · Dormir até amanhecer" if noite() else "E · Sentar na cama"
	comida.visible = tem_comida()
	if mundo.pausado(): return
	var real_delta: float = delta/maxf(1,Engine.time_scale)
	if estado in ["sentado","televisao","cama_dia","sanita"]: mundo.jogador.animar(0,0,true)
	if estado in ["televisao","cama_dia","sanita"]:
		for i: int in range(2): mundo.jogador.bracos[i].rotation.x = 0.15; mundo.jogador.cotovelos[i].rotation.x = 0.4
	if estado=="sanita": mundo.vitais.higiene = minf(100,mundo.vitais.higiene+real_delta*5)
	if estado=="banho":
		duche.actualizar(real_delta)
		if agua.emitting: mundo.vitais.higiene = minf(100,mundo.vitais.higiene+real_delta*18); mundo.jogador.animar(delta,0)
	if a_comer>0:
		a_comer = maxf(0,a_comer-real_delta); mundo.jogador.bracos[1].rotation.x = 1.3+sin(a_comer*5)*0.2; mundo.jogador.cotovelos[1].rotation.x = 1.8
		if a_comer<=0 and is_instance_valid(alimento_mao): alimento_mao.queue_free()
	if estado!="dormindo": return
	mundo.jogador.animar(0,0); mundo.jogador.cesto.hide(); tempo += real_delta
	cortina.color.a = clampf(tempo/0.5,0,1) if tempo<0.85 else clampf((1.4-tempo)/0.55,0,1)
	if tempo>=0.6 and not avancou:
		avancou = true; mundo.calendario.avancar_simulacao(maxf(0,manha-mundo.calendario.decorrido)); mundo.vitais.energia = 100; mundo.vitais.vida = minf(100,mundo.vitais.vida+15); mundo.vitais.fome = maxf(0,mundo.vitais.fome-8)
		if mundo.aviso.contains("QUEBRA DE CONTRATO"): recado_sono = mundo.aviso
		if familia()!=null: familia().colocar_actividade("cama")
	if tempo>=1.4: estado = "acordado"; cortina.color.a = 0; mundo.avisar("Bom dia · E para sair da cama"+("\n"+recado_sono if not recado_sono.is_empty() else ""))
