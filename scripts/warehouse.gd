extends Node3D
## Duas portas de passagem; cada entrada transfere carga apenas uma vez.
const CENTRO: Vector3 = Vector3(32,0,24)
const ENTREGA: Vector3 = Vector3(32,0,18)
const ZONA: Rect2 = Rect2(26,29,12,15)
var mundo: Node3D
var dentro: bool = false
var portas: Array[Node3D] = []
var visitas: Dictionary = {}
var caixas: Array[Node3D] = []
var letreiro: Label3D

func _ready() -> void:
	position.y = mundo.altura(Vector3(32,0,37))
	for x: float in [22,42]: mundo.caixa(self,Vector3(x,3.5,37),Vector3(0.35,7,26),Color("9c947f"),true)
	mundo.caixa(self,Vector3(32,7.2,37),Vector3(21,0.3,27),Color("516e68"),true)
	for z: float in [24,50]:
		for x: float in [24,40]: mundo.caixa(self,Vector3(x,3.5,z),Vector3(4,7,0.35),Color("9c947f"),true)
		var porta: Node3D = mundo.caixa(self,Vector3(32,3,z),Vector3(12,6,0.25),Color("45685d"),true)
		porta.set_meta("abertura",0.0)
		portas.append(porta)
		mundo.caixa(self,Vector3(32,6.4,z),Vector3(12.5,0.7,0.75),Color("324e45"))
		for x: float in [25.9,38.1]: mundo.caixa(self,Vector3(x,3,z),Vector3(0.12,6,0.5),Color("64766b"))
		for faixa: int in range(5): mundo.caixa(porta,Vector3(0,-2.4+faixa*1.2,-0.15),Vector3(11.8,0.04,0.03),Color("78968a"))
	for x: float in [24.7,39.3]:
		for z: float in [32,37,42]: caixas.append(mundo.caixa(self,Vector3(x,0.65,z),Vector3(2,1.3,2),Color("a88050")))
	letreiro = mundo.placa(self,Vector3(32,7.9,24),"GARAGEM · ARMAZÉM\nCom colheita: deposita · Carrinha vazia: carrega")
	letreiro.visibility_range_end = 50
	letreiro.font_size = 40; letreiro.pixel_size = 0.008

func perto() -> bool:
	return preload("res://scripts/layout.gd").distancia(mundo.jogador.global_position,CENTRO)<10

func receber(carga: Dictionary) -> void:
	for cultura: int in carga: mundo.stock[cultura] = int(mundo.stock.get(cultura,0))+int(carga[cultura])
	carga.clear()

func retirar() -> Dictionary:
	var carga: Dictionary = mundo.stock.duplicate()
	mundo.stock.clear()
	return carga

func actualizar(delta: float) -> void:
	var actores: Array[Node3D] = [mundo.jogador]
	actores.append_array(mundo.pessoas); actores.append_array(mundo.tratores); actores.append_array(mundo.carrinhas)
	for porta: Node3D in portas:
		var aberta: bool = false
		for actor: Node3D in actores:
			if actor is CharacterBody3D and actor.collision_layer==0: continue
			if absf(actor.global_position.x-32)<9 and absf(actor.global_position.z-porta.position.z)<15: aberta = true; break
		# A folha recolhe no rolo superior; não atravessa o telhado.
		var abertura: float = move_toward(float(porta.get_meta("abertura")),1.0 if aberta else 0.0,delta*1.5)
		porta.set_meta("abertura",abertura)
		var altura_folha: float = lerpf(6.0,0.12,abertura)
		porta.mesh.size.y = altura_folha; porta.position.y = 6-altura_folha/2
		var colisor: CollisionShape3D = porta.get_child(0).get_child(0)
		colisor.shape.size.y = altura_folha
		for i: int in range(1,porta.get_child_count()): porta.get_child(i).position.y = altura_folha*(-0.4+(i-1)*0.2)
	var agora: bool = (mundo.trator_actual==null or mundo.trator_actual.implemento==null or mundo.trator_actual.implemento.tipo!=4) and mundo.drone_actual==null and ZONA.has_point(Vector2(mundo.jogador.position.x,mundo.jogador.position.z))
	if agora and not dentro and not mundo.sacola.is_empty():
		receber(mundo.sacola); mundo.avisar("Colheita guardada. Saia e entre com uma carrinha para carregar.")
	dentro = agora
	for carrinha: Node3D in mundo.carrinhas:
		var id: int = carrinha.get_instance_id()
		var na_zona: bool = carrinha.tractor!=null and carrinha.tractor==mundo.trator_actual and ZONA.has_point(Vector2(carrinha.position.x,carrinha.position.z))
		if na_zona and not bool(visitas.get(id,false)):
			if carrinha.total()>0:
				var unidades: int = carrinha.total(); receber(carrinha.carga); carrinha.actualizar_carga()
				mundo.avisar("%d unidades guardadas. Saia e volte com a carrinha vazia para carregar." % unidades)
			else:
				var unidades: int = carrinha.carregar(mundo.stock)
				mundo.avisar("Carrinha carregada: %d unidades. C descarrega · Fábricas fora da quinta." % unidades)
		visitas[id] = na_zona
	var total: int = 0
	for quantidade: int in mundo.stock.values(): total += quantidade
	for i: int in range(caixas.size()): caixas[i].visible = total>i*20

func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	actualizar(delta)
