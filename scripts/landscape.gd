extends Node3D
## O mapa mantém as alturas originais, extraídas uma vez; não carrega extensões nativas.
var mundo: Node3D
var tamanho: int = 0
var passo: float = 2.0
var inicio: float = -400.0
var dados: PackedFloat32Array = []
var base_original: float = 0.0
var amplitude: float = 0.0
var material_chao: ShaderMaterial
var corpo_chao: StaticBody3D

func _ready() -> void:
	var ficheiro: FileAccess = FileAccess.open("res://data/relevo_original.bin",FileAccess.READ)
	assert(ficheiro!=null,"Falta o relevo original do mapa.")
	assert(ficheiro.get_buffer(4).get_string_from_ascii()=="MOZH","Mapa de alturas inválido.")
	assert(ficheiro.get_32()==1,"Versão desconhecida do mapa de alturas.")
	tamanho = int(ficheiro.get_32())
	passo = ficheiro.get_float()
	inicio = ficheiro.get_float()
	base_original = ficheiro.get_float()
	ficheiro.get_float()
	ficheiro.get_float()
	dados = ficheiro.get_buffer(tamanho*tamanho*4).to_float32_array()
	assert(dados.size()==tamanho*tamanho,"Mapa de alturas incompleto.")
	var minimo: float = INF
	var maximo: float = -INF
	for valor: float in dados:
		minimo = minf(minimo,valor)
		maximo = maxf(maximo,valor)
	amplitude = maximo-minimo
	criar_material()
	criar_colisao()
	for z: int in range(8):
		for x: int in range(8): criar_bloco(x*50,z*50)
	criar_arvores()

func ruido_periodico(ruido: FastNoiseLite,x: float,z: float,escala: float) -> float:
	var u: float = x/255.0
	var v: float = z/255.0
	return lerpf(lerpf(ruido.get_noise_2d(x*escala,z*escala),ruido.get_noise_2d((x-255)*escala,z*escala),u),lerpf(ruido.get_noise_2d(x*escala,(z-255)*escala),ruido.get_noise_2d((x-255)*escala,(z-255)*escala),u),v)

func criar_material() -> void:
	# Textura repetível gerada no arranque; não depende de fotografias ou importações.
	var ruido: FastNoiseLite = FastNoiseLite.new()
	ruido.seed = 1989; ruido.frequency = 0.035
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.fractal_octaves = 4
	var imagem: Image = Image.create(256,256,false,Image.FORMAT_RGB8)
	for z: int in range(256):
		for x: int in range(256):
			var amplo: float = ruido_periodico(ruido,x,z,1.0)*0.5+0.5
			var fino: float = ruido_periodico(ruido,x,z,7.0)*0.5+0.5
			imagem.set_pixel(x,z,Color(amplo,fino,(amplo+fino)*0.5))
	imagem.generate_mipmaps()
	material_chao = ShaderMaterial.new()
	material_chao.shader = preload("res://shaders/ground.gdshader")
	material_chao.set_shader_parameter("detalhe",ImageTexture.create_from_image(imagem))

func amostra(x: int,z: int) -> float:
	return dados[clampi(z,0,tamanho-1)*tamanho+clampi(x,0,tamanho-1)]

func altura(ponto: Vector3) -> float:
	var x: float = clampf((ponto.x-inicio)/passo,0,tamanho-1.001)
	var z: float = clampf((ponto.z-inicio)/passo,0,tamanho-1.001)
	var ix: int = floori(x)
	var iz: int = floori(z)
	return lerpf(lerpf(amostra(ix,iz),amostra(ix+1,iz),x-ix),lerpf(amostra(ix,iz+1),amostra(ix+1,iz+1),x-ix),z-iz)

func criar_colisao() -> void:
	var corpo: StaticBody3D = StaticBody3D.new()
	corpo_chao = corpo
	var colisor: CollisionShape3D = CollisionShape3D.new()
	var forma: HeightMapShape3D = HeightMapShape3D.new()
	forma.map_width = tamanho
	forma.map_depth = tamanho
	var alturas_fisicas: PackedFloat32Array = dados.duplicate()
	for indice: int in range(alturas_fisicas.size()): alturas_fisicas[indice] /= passo
	forma.map_data = alturas_fisicas
	colisor.shape = forma
	# Escala uniforme conserva as alturas e evita escalas físicas não uniformes.
	colisor.scale = Vector3.ONE*passo
	corpo.add_child(colisor)
	add_child(corpo)

func criar_bloco(ox: int,oz: int) -> void:
	var vertices: PackedVector3Array = []
	var normais: PackedVector3Array = []
	var cores: PackedColorArray = []
	var indices: PackedInt32Array = []
	for z: int in range(51):
		for x: int in range(51):
			var gx: int = ox+x
			var gz: int = oz+z
			var ponto: Vector3 = Vector3(inicio+gx*passo,amostra(gx,gz),inicio+gz*passo)
			var normal: Vector3 = Vector3(amostra(gx-1,gz)-amostra(gx+1,gz),2*passo,amostra(gx,gz-1)-amostra(gx,gz+1)).normalized()
			vertices.append(ponto)
			normais.append(normal)
			var cor: Color = Color("687a49").lerp(Color("8a8963"),clampf((1-normal.y)*2.0,0,1))
			cor = cor.lightened((sin(ponto.x*0.027)+sin(ponto.z*0.033))*0.035)
			cores.append(cor.srgb_to_linear())
	for z: int in range(50):
		for x: int in range(50):
			var indice: int = z*51+x
			indices.append_array(PackedInt32Array([indice,indice+1,indice+52,indice,indice+52,indice+51]))
	var atributos: Array = []
	atributos.resize(Mesh.ARRAY_MAX)
	atributos[Mesh.ARRAY_VERTEX] = vertices
	atributos[Mesh.ARRAY_NORMAL] = normais
	atributos[Mesh.ARRAY_COLOR] = cores
	atributos[Mesh.ARRAY_INDEX] = indices
	var malha: ArrayMesh = ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,atributos)
	var vista: MeshInstance3D = MeshInstance3D.new()
	vista.mesh = malha
	vista.material_override = material_chao
	add_child(vista)

func estrada(pontos: Array[Vector3], largura: float = 4.5) -> void:
	var superficie: SurfaceTool = SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	superficie.set_material(mundo.material(Color("726549")))
	for trecho: int in range(pontos.size()-1):
		var a: Vector3 = pontos[trecho]
		var b: Vector3 = pontos[trecho+1]
		var direita: Vector3 = Vector3(-(b-a).z,0,(b-a).x).normalized()*largura*0.5
		var passos: int = maxi(1,ceili(a.distance_to(b)/2.0))
		for etapa: int in range(passos):
			var inicio_trecho: Vector3 = a.lerp(b,float(etapa)/passos)
			var fim_trecho: Vector3 = a.lerp(b,float(etapa+1)/passos)
			for canto: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var ponto: Vector3 = (inicio_trecho if canto.y==0 else fim_trecho)+direita*(-1 if canto.x==0 else 1)
				ponto.y = altura(ponto)+0.035
				superficie.add_vertex(ponto)
	superficie.generate_normals()
	var vista: MeshInstance3D = MeshInstance3D.new()
	vista.mesh = superficie.commit()
	add_child(vista)

func criar_arvores() -> void:
	var aleatorio: RandomNumberGenerator = RandomNumberGenerator.new()
	aleatorio.seed = 1772026
	var posicoes: Array[Vector3] = []
	for indice: int in range(110):
		var ponto: Vector3 = Vector3(aleatorio.randf_range(-360,360),0,aleatorio.randf_range(-360,360))
		if absf(ponto.x)<110 and absf(ponto.z)<100: continue
		var ocupado: bool = false
		for centro: Vector3 in preload("res://scripts/village.gd").CENTROS:
			if preload("res://scripts/layout.gd").distancia(ponto,centro)<52: ocupado = true
		if ocupado: continue
		ponto.y = altura(ponto)
		posicoes.append(ponto)
	for copa: bool in [false,true]:
		var lote: MultiMeshInstance3D = MultiMeshInstance3D.new()
		lote.multimesh = MultiMesh.new()
		lote.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		if copa:
			var folhas: SphereMesh = SphereMesh.new()
			folhas.radius = 1
			folhas.height = 2
			folhas.radial_segments = 12
			folhas.rings = 6
			lote.multimesh.mesh = folhas
		else:
			var tronco: CylinderMesh = CylinderMesh.new()
			tronco.top_radius = 0.12
			tronco.bottom_radius = 0.2
			tronco.height = 3.5
			tronco.radial_segments = 8
			lote.multimesh.mesh = tronco
		lote.material_override = mundo.material(Color("52693c") if copa else Color("6b5137"))
		lote.multimesh.instance_count = posicoes.size()
		for indice: int in range(posicoes.size()):
			var escala: Vector3 = Vector3(3.4,0.9,2.8) if copa else Vector3.ONE
			lote.multimesh.set_instance_transform(indice,Transform3D(Basis.IDENTITY.scaled(escala),posicoes[indice]+Vector3.UP*(3.5 if copa else 1.75)))
		add_child(lote)
