extends Node3D
## Machambas afastadas com culturas em lotes e trabalhadores independentes da grelha principal.
const CENTROS: Array[Vector3] = preload("res://scripts/road_network.gd").QUINTAS
const NOMES: Array[String] = ["Aurora","Vale Verde","Boa Colheita","Do Rio","Da Acácia","Do Planalto"]
var mundo: Node3D
var campos: Array[MultiMeshInstance3D] = []

func _ready() -> void:
	for rua: Dictionary in preload("res://scripts/road_network.gd").quintas(): mundo.relevo.estrada(rua.pontos,rua.largura)
	for indice: int in range(CENTROS.size()): criar_fazenda(indice)

func criar_fazenda(indice: int) -> void:
	var centro: Vector3 = CENTROS[indice]
	centro.y = mundo.altura(centro)
	var plantas: MultiMeshInstance3D = MultiMeshInstance3D.new()
	plantas.multimesh = MultiMesh.new()
	plantas.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	plantas.multimesh.mesh = mundo.terreno.cultivos.modelo(indice%4,3,true)
	plantas.multimesh.instance_count = 24*18
	for z: int in range(18):
		for x: int in range(24):
			var ponto: Vector3 = centro+Vector3(-18+x*1.5,0,-16+z*1.5)
			ponto.y = mundo.altura(ponto)+0.025
			plantas.multimesh.set_instance_transform(z*24+x,Transform3D(Basis.IDENTITY,ponto))
	add_child(plantas)
	campos.append(plantas)
	plantas.visibility_range_end = 135; plantas.visibility_range_end_margin = 12
	plantas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Uma silhueta simples de duas folhas por planta mantém a machamba visível à distância.
	var longe: MultiMeshInstance3D = MultiMeshInstance3D.new(); longe.multimesh = MultiMesh.new(); longe.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var g: GDScript = preload("res://scripts/geometry.gd"); var s: SurfaceTool = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lado: float in [-1,1]: g.folha(s,Vector3.ZERO,Vector3(lado*0.3,0.7,0),0.22,Color("42823e"),0.08,false)
	longe.multimesh.mesh = g.terminar(s); longe.multimesh.instance_count = plantas.multimesh.instance_count
	for i: int in range(longe.multimesh.instance_count): longe.multimesh.set_instance_transform(i,plantas.multimesh.get_instance_transform(i))
	longe.visibility_range_begin = 125; longe.visibility_range_end = 350; longe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(longe)
	var galpao: Vector3 = centro+Vector3(26,0,4)
	galpao.y = mundo.altura(galpao)
	mundo.caixa(self,galpao+Vector3(0,2,0),Vector3(10,4,12),Color("a88b63"),true)
	mundo.caixa(self,galpao+Vector3(0,4.2,0),Vector3(11,0.25,13),Color("526f66"))
	for fardo: int in range(5):
		var ponto: Vector3 = galpao+Vector3(-8,0,-4+fardo*2)
		ponto.y = mundo.altura(ponto)+0.5
		mundo.caixa(self,ponto,Vector3(2,1,1.3),Color("b39c54"))
	var placa: Label3D = mundo.placa(self,galpao+Vector3(0,5.5,-6),"FAZENDA "+NOMES[indice])
	placa.visibility_range_end = 95
	for pessoa_indice: int in range(2):
		var pessoa: Node3D = preload("res://scripts/npc.gd").new()
		pessoa.mundo = mundo
		pessoa.numero = 6+indice*2+pessoa_indice
		pessoa.nome = NOMES[indice]+" · "+("João" if pessoa_indice==0 else "Maria")
		pessoa.mulher = pessoa_indice==1
		pessoa.vizinho = true
		pessoa.position = centro+Vector3(-13+pessoa_indice*18,0,-12)
		pessoa.position.y = mundo.altura(pessoa.position)+0.1
		pessoa.rota.assign([centro+Vector3(-13,0,-12),centro+Vector3(13,0,-12),centro+Vector3(13,0,9),centro+Vector3(-13,0,9)])
		mundo.add_child(pessoa)
		mundo.pessoas.append(pessoa)
