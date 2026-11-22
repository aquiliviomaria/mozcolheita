extends Node3D
## A semente seca não acumula tempo. Todas as ferramentas e máquinas usam trabalhar().
const AREA: Rect2i = Rect2i(-92,-74,184,148)
const DURACAO: float = preload("res://scripts/calendar.gd").CRESCIMENTO
const SOLO: int = 0
const LAVRADO: int = 1
const SEMEADO: int = 2
const REGADO: int = 3
const CRESCER: int = 4
const PRONTO: int = 5
var mundo: Node3D
var celulas: Dictionary = {}
var alvo: MeshInstance3D
var lote_sulcos: MultiMeshInstance3D
var lote_solo: MultiMeshInstance3D
var cultivos: Node3D
var pendente: bool = true
var intervalo: float = 0.0

func _ready() -> void:
	var lote: MultiMesh = MultiMesh.new()
	lote.transform_format = MultiMesh.TRANSFORM_3D
	lote.use_colors = true
	var cubo: BoxMesh = BoxMesh.new()
	cubo.size = Vector3(1.005,0.035,1.005)
	lote.mesh = cubo
	lote_solo = MultiMeshInstance3D.new()
	lote_solo.multimesh = lote
	var material_solo: StandardMaterial3D = StandardMaterial3D.new()
	material_solo.vertex_color_use_as_albedo = true
	material_solo.roughness = 1.0
	lote_solo.material_override = material_solo
	add_child(lote_solo)
	var sulcos: SurfaceTool = SurfaceTool.new()
	sulcos.begin(Mesh.PRIMITIVE_TRIANGLES)
	sulcos.set_material(mundo.material(Color("67442c")))
	for x_sulco: float in [-0.28,0.28]:
		var faixa: BoxMesh = BoxMesh.new()
		faixa.size = Vector3(0.13,0.045,0.98)
		sulcos.append_from(faixa,0,Transform3D(Basis.IDENTITY,Vector3(x_sulco,0.025,0)))
	lote_sulcos = MultiMeshInstance3D.new()
	lote_sulcos.multimesh = MultiMesh.new()
	lote_sulcos.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	lote_sulcos.multimesh.mesh = sulcos.commit()
	add_child(lote_sulcos)
	cultivos = mundo.sistema(preload("res://scripts/crop.gd")) as Node3D
	alvo = mundo.caixa(self,Vector3.ZERO,Vector3(0.98,0.025,0.98),Color(0.25,0.95,0.62,0.35))
	alvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func disponivel(chave: Vector2i) -> bool:
	var ponto: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5)
	if not AREA.has_point(chave) or preload("res://scripts/layout.gd").reservado(ponto): return false
	for arvore: Node3D in mundo.ferramentas.arvores if mundo.ferramentas!=null else []:
		if arvore.visible and preload("res://scripts/layout.gd").distancia(arvore.position,ponto)<2: return false
	return true

func superficie(chave: Vector2i, elevacao: float = 0.035) -> Transform3D:
	var centro: Vector3 = Vector3(chave.x+0.5,0,chave.y+0.5)
	var dx: float = mundo.altura(centro+Vector3(0.5,0,0))-mundo.altura(centro-Vector3(0.5,0,0))
	var dz: float = mundo.altura(centro+Vector3(0,0,0.5))-mundo.altura(centro-Vector3(0,0,0.5))
	centro.y = mundo.altura(centro)+elevacao
	# A base segue a inclinação local, evitando quadrados cortados pelo relevo.
	return Transform3D(Basis(Vector3(1,dx,0),Vector3.UP,Vector3(0,dz,1)),centro)

func chave_em(posicao: Vector3) -> Vector2i:
	return Vector2i(floori(posicao.x),floori(posicao.z))

func trabalhar(chave: Vector2i, acao: String, cultura: int = 0, destinatario: Node3D = null, fonte_sementes: Node = null) -> bool:
	if not celulas.has(chave):
		if acao!="lavrar" or not disponivel(chave): return false
		celulas[chave] = {"estado":SOLO,"cultura":0,"tempo":0.0,"humidade":0.0,"saude":60.0,"familia":""}
	var dados: Dictionary = celulas[chave]
	var recolhido: int = 0
	match acao:
		"lavrar":
			if int(dados.estado)!=SOLO: return false
			dados.estado = LAVRADO
		"semear":
			var fonte: Node = fonte_sementes if fonte_sementes!=null else mundo.ferramentas
			if int(dados.estado)!=LAVRADO or fonte.sementes<=0: return false
			dados.estado = SEMEADO
			dados.cultura = clampi(cultura,0,3)
			dados.tempo = 0.0
			dados.humidade = 0.0
			fonte.sementes -= 1
		"regar":
			if int(dados.estado) not in [SEMEADO,REGADO,CRESCER]: return false
			dados.humidade = 100.0
			if int(dados.estado)==SEMEADO: dados.estado = REGADO
		"colher":
			if int(dados.estado)!=PRONTO: return false
			var familia: String = preload("res://scripts/crop.gd").FAMILIAS[int(dados.cultura)]
			var repetida: bool = str(dados.familia)==familia
			var quantidade: int = 3+(-1 if repetida else 1 if not str(dados.familia).is_empty() and float(dados.saude)>=35 else 0)
			recolhido = maxi(1,quantidade)
			mundo.missoes.registar(int(dados.cultura),maxi(1,quantidade))
			if destinatario==null: mundo.receber_colheita(int(dados.cultura),maxi(1,quantidade))
			else: destinatario.carga[int(dados.cultura)] = int(destinatario.carga.get(int(dados.cultura),0))+maxi(1,quantidade)
			dados.familia = familia
			dados.saude = clampf(float(dados.saude)+(-12 if repetida else 8),0,100)
			dados.estado = LAVRADO
			dados.tempo = 0.0
		_: return false
	pendente = true
	if mundo.feedback!=null: mundo.feedback.mostrar(chave,acao,int(dados.cultura),recolhido)
	return true

func avancar(delta: float) -> void:
	for chave: Vector2i in celulas:
		var dados: Dictionary = celulas[chave]
		if int(dados.estado) not in [REGADO,CRESCER]: continue
		var etapa_anterior: int = int(float(dados.tempo)/(DURACAO/2.0))
		dados.tempo = float(dados.tempo)+delta
		dados.estado = PRONTO if float(dados.tempo)>=DURACAO else CRESCER
		if int(float(dados.tempo)/(DURACAO/2.0))!=etapa_anterior or int(dados.estado)==PRONTO: pendente = true

func _process(delta: float) -> void:
	if not mundo.pausado(): avancar(delta)
	intervalo += delta
	if pendente and intervalo>0.2:
		intervalo = 0.0
		pendente = false
		cultivos.actualizar()
		var posicoes: Array[Vector2i] = []
		for chave_sulco: Vector2i in celulas:
			if int(celulas[chave_sulco].estado)>SOLO: posicoes.append(chave_sulco)
		lote_solo.multimesh.instance_count = posicoes.size()
		lote_sulcos.multimesh.instance_count = posicoes.size()
		for indice_sulco: int in range(posicoes.size()):
			var chave_sulco: Vector2i = posicoes[indice_sulco]
			lote_sulcos.multimesh.set_instance_transform(indice_sulco,superficie(chave_sulco,0.045))
			lote_solo.multimesh.set_instance_transform(indice_sulco,superficie(chave_sulco))
			lote_solo.multimesh.set_instance_color(indice_sulco,(Color("49362a") if float(celulas[chave_sulco].humidade)>0 else Color("72523a")).srgb_to_linear())
	if not is_instance_valid(mundo.jogador): return
	var ponto: Vector3 = mundo.jogador.global_position-mundo.jogador.visual.global_basis.z*1.5
	var chave: Vector2i = chave_em(ponto)
	alvo.visible = (celulas.has(chave) or (mundo.ferramentas.actual==3 and disponivel(chave))) and not mundo.bloqueia_jogador() and mundo.ferramentas.actual in [0,3,4,5]
	alvo.transform = superficie(chave,0.065)
