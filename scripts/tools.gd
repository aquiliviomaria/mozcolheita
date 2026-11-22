extends Node3D
## A selecção visual e a acção usam o mesmo índice, evitando ferramentas divergentes.
const NOMES: Array[String] = ["Mãos livres","Martelo","Serrote","Enxada","Regador","Semeadora"]
const ICONES: Array[String] = ["maos","martelo","serrote","enxada","regador","semeadora"]
var mundo: Node3D
var actual: int = 0
var cultura: int = 0
var sementes: int = 200
var madeira: int = 12
var vista: Node3D
var arvores: Array[Node3D] = []

func _ready() -> void:
	for indice: int in range(8):
		var arvore: Node3D = Node3D.new()
		add_child(arvore)
		arvore.position = Vector3(72 if indice%2==0 else -74,0,-50+indice*12)
		# Mantém as árvores cortáveis fora do novo armazém e da sua entrada.
		if preload("res://scripts/industrial_sites.gd").AREA_ARMAZEM.grow(5).has_point(Vector2(arvore.position.x,arvore.position.z)): arvore.position.x = 88
		arvore.position.y = mundo.altura(arvore.position)
		arvore.set_meta("golpes",0)
		mundo.caixa(arvore,Vector3(0,1.3,0),Vector3(0.28,2.6,0.28),Color("795737"),true)
		var copa: MeshInstance3D = MeshInstance3D.new()
		var folhas: SphereMesh = SphereMesh.new()
		folhas.radial_segments = 16
		folhas.rings = 8
		copa.mesh = folhas
		copa.scale = Vector3(3.4,1.2,2.8)
		copa.position.y = 2.9
		copa.material_override = mundo.material(Color("527b46"))
		arvore.add_child(copa)
		arvores.append(arvore)
	seleccionar(0)

func seleccionar(indice: int) -> void:
	actual = posmod(indice,6)
	if is_instance_valid(vista):
		vista.get_parent().remove_child(vista)
		vista.queue_free()
	vista = Node3D.new()
	mundo.jogador.mao_direita.add_child(vista)
	if actual==0: return
	var cabo: float = 0.9 if actual==3 else 0.4
	mundo.caixa(vista,Vector3(0,-cabo*0.35,0),Vector3(0.035,cabo,0.035),Color("ac865a"))
	var tamanho: Vector3 = [Vector3.ZERO,Vector3(0.1,0.12,0.26),Vector3(0.04,0.43,0.18),Vector3(0.26,0.04,0.2),Vector3(0.2,0.23,0.24),Vector3(0.15,0.22,0.2)][actual]
	mundo.caixa(vista,Vector3(0,-cabo*0.8,-0.06),tamanho,Color("8fa8a1"))

func chave_alvo() -> Vector2i:
	return mundo.terreno.chave_em(mundo.jogador.global_position-mundo.jogador.visual.global_basis.z*1.5)

func usar() -> bool:
	mundo.jogador.gesto = 1.0
	mundo.jogador.animacao("watering" if actual==4 else "harvesting" if actual==0 else "planting")
	var chave: Vector2i = chave_alvo()
	match actual:
		0: return mundo.terreno.trabalhar(chave,"colher",cultura)
		1: return martelar()
		2: return cortar()
		3: return mundo.terreno.trabalhar(chave,"lavrar",cultura)
		4: return mundo.terreno.trabalhar(chave,"regar",cultura)
		5: return mundo.terreno.trabalhar(chave,"semear",cultura)
	return false

func cortar() -> bool:
	for arvore: Node3D in arvores:
		if not arvore.visible or arvore.global_position.distance_to(mundo.jogador.global_position)>3: continue
		var golpes: int = int(arvore.get_meta("golpes"))+1
		arvore.set_meta("golpes",golpes)
		if golpes>=3:
			madeira += 6
			arvore.hide()
			for forma: Node in arvore.find_children("*","CollisionShape3D",true,false): forma.set_deferred("disabled",true)
		mundo.avisar("Madeira +6" if golpes>=3 else "A cortar · %d/3" % golpes)
		return true
	mundo.avisar("Aproxime-se de uma árvore com o serrote.")
	return false

func martelar() -> bool:
	return mundo.cerca.construir_ou_reparar(mundo.jogador.global_position)
