extends RefCounted
## Plano partilhado: o terreno é nivelado antes de construir vias, edifícios e colisões.
const QUINTAS: Array[Vector3] = [Vector3(-190,0,-120),Vector3(205,0,-155),Vector3(210,0,175),Vector3(-215,0,165),Vector3(-40,0,-260),Vector3(35,0,275)]
static func adicionar(lista: Array[Dictionary],pontos: Array[Vector3],largura: float = 9,asfalto: bool = true) -> void:
	lista.append({"pontos":pontos,"largura":largura,"asfalto":asfalto})
static func cidade() -> Array[Dictionary]:
	var vias: Array[Dictionary] = []
	adicionar(vias,[Vector3(-122,0,-102),Vector3(122,0,-102),Vector3(122,0,140),Vector3(-122,0,140),Vector3(-122,0,-102)])
	for x: float in [132,205,270,345]: adicionar(vias,[Vector3(x,0,-100),Vector3(x,0,140)])
	for z: float in [-100,20,140]: adicionar(vias,[Vector3(122,0,z),Vector3(350,0,z)])
	adicionar(vias,[Vector3(-325,0,92),Vector3(350,0,92)])
	adicionar(vias,[Vector3(-300,0,-70),Vector3(-300,0,140),Vector3(-122,0,140)])
	var locais: Array[Vector3] = []; locais.append_array(preload("res://scripts/industrial_sites.gd").FABRICAS); locais.append_array(preload("res://scripts/industrial_sites.gd").FILIAIS)
	for p: Vector3 in locais:
		var x: float = -300 if p.x < -180 else -122 if p.x<0 else 270 if p.x<270 else 345
		var z: float = -102 if p.z<0 else 140
		adicionar(vias,[Vector3(x,0,z),Vector3(x,0,p.z-46),Vector3(p.x,0,p.z-46),Vector3(p.x,0,p.z)],10)
	for portao: Vector3 in preload("res://scripts/layout.gd").PORTOES:
		var fora: Vector3 = Vector3(portao.x,0,140 if portao.z>0 else -102) if portao.z!=0 else Vector3(signf(portao.x)*122,0,portao.z)
		adicionar(vias,[portao,fora],10)
	adicionar(vias,[Vector3(96,0,0),Vector3(82,0,0),Vector3(82,0,18),Vector3(52,0,18),Vector3(52,0,40)],8,false)
	adicionar(vias,[Vector3(52,0,40),Vector3(52,0,65),Vector3(60,0,65),Vector3(60,0,78)],8,false)
	return vias
static func exterior() -> Array[Dictionary]:
	var vias: Array[Dictionary] = []
	adicionar(vias,[Vector3(-350,0,-240),Vector3(350,0,-240)],9)
	adicionar(vias,[Vector3(-350,0,245),Vector3(350,0,245)],9)
	adicionar(vias,[Vector3(-350,0,-240),Vector3(-350,0,245)],8)
	adicionar(vias,[Vector3(350,0,-240),Vector3(350,0,245)],8)
	for x: float in [-300,-122,132,270]:
		adicionar(vias,[Vector3(x,0,-350),Vector3(x,0,-102)],8)
		adicionar(vias,[Vector3(x,0,140),Vector3(x,0,350)],7,false)
	return vias
static func quintas() -> Array[Dictionary]:
	var vias: Array[Dictionary] = []
	adicionar(vias,[Vector3(-250,0,92),Vector3(250,0,92)],4.5,false)
	adicionar(vias,[Vector3(0,0,77),Vector3(0,0,92)],4.5,false)
	for centro: Vector3 in QUINTAS:
		adicionar(vias,acesso_quinta(centro),4.5,false)
	return vias
static func acesso_quinta(centro: Vector3) -> Array[Vector3]:
	if centro.x>96: return [Vector3(122,0,centro.z),centro+Vector3(23,0,20)]
	if centro.x<-96: return [Vector3(-122,0,centro.z),centro+Vector3(23,0,20)]
	return [Vector3(centro.x,0,-102 if centro.z<0 else 140),centro+Vector3(23,0,20)]
