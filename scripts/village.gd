extends Node3D
## Machambas afastadas com culturas em lotes e trabalhadores independentes da grelha principal.
const CENTROS: Array[Vector3] = [Vector3(-190,0,-120),Vector3(205,0,-155),Vector3(210,0,175),Vector3(-215,0,165),Vector3(-40,0,-260),Vector3(35,0,275)]
const NOMES: Array[String] = ["Aurora","Vale Verde","Boa Colheita","Do Rio","Da Acácia","Do Planalto"]
var mundo: Node3D
var campos: Array[MultiMeshInstance3D] = []

func _ready() -> void:
	var estrada_principal: Array[Vector3] = [Vector3(-250,0,92),Vector3(250,0,92)]
	mundo.relevo.estrada(estrada_principal)
	var acesso: Array[Vector3] = [Vector3(0,0,77),Vector3(0,0,92)]
	mundo.relevo.estrada(acesso)
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
	var caminho: Array[Vector3]
	if centro.x>96: caminho = [Vector3(122,0,centro.z),centro+Vector3(23,0,20)]
	elif centro.x<-96: caminho = [Vector3(-122,0,centro.z),centro+Vector3(23,0,20)]
	else: caminho = [Vector3(centro.x,0,-102 if centro.z<0 else 140),centro+Vector3(23,0,20)]
	mundo.relevo.estrada(caminho)
