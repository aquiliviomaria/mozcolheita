extends "res://scripts/tractor.gd"
## Camião conduzível reutiliza o controlador, condutor e câmara dos tractores.
const CAPACIDADE: int = 500
var carga: Dictionary = {}
var caixas_carga: Array[Node3D] = []
func _ready() -> void:
	assento_condutor = Vector3(0,0.65,-1.5); assento_passageiro = Vector3(0.85,0.65,-1.5)
	add_to_group("camioes")
	preload("res://scripts/vehicle_lights.gd").instalar(self,mundo,"camião")
	collision_layer = 4; collision_mask = 1|2|4|8|16
	var col: CollisionShape3D = CollisionShape3D.new(); var forma: BoxShape3D = BoxShape3D.new(); forma.size = Vector3(2.8,2.8,7.3); col.shape = forma; col.position = Vector3(0,1.4,0.2); add_child(col)
	mundo.caixa(self,Vector3(0,0.8,0.2),Vector3(2.5,0.25,7.2),Color("2e4439"))
	preload("res://scripts/vehicle_art.gd").polir_caminhao(self)
	mundo.caixa(self,Vector3(0,1.2,-1.5),Vector3(2.6,0.15,1.8),Color("14532d"))
	mundo.caixa(self,Vector3(0,3.25,-1.7),Vector3(2.7,0.18,2.4),Color("238b45"))
	mundo.caixa(self,Vector3(0,1.8,-0.55),Vector3(2.6,1.8,0.10),Color("14532d"))
	for lado: float in [-1,1]:
		for z: float in [-2.8,-0.55]: mundo.caixa(self,Vector3(lado*1.22,2.2,z),Vector3(0.08,1.6,0.08),Color("d0d4b8"))
		mundo.caixa(self,Vector3(lado*1.25,1.4,-1.5),Vector3(0.1,0.6,2.2),Color("238b45"))
		mundo.caixa(self,Vector3(lado*1.2,1.5,1.65),Vector3(0.12,0.8,4.1),Color("467a4d"))
		mundo.caixa(self,Vector3(lado*0.85,1.45,-3.4),Vector3(0.4,0.23,0.06),Color("fff0ab"))
		for z: float in [-2.0,1.8,3.0]:
			rodas.append(preload("res://scripts/vehicle_art.gd").roda(self,Vector3(lado*1.25,0.58,z),0.58,0.35))
	mundo.caixa(self,Vector3(0,1.02,1.7),Vector3(2.4,0.18,4.2),Color("a88a56"))
	mundo.caixa(self,Vector3(0,1.65,-1.35),Vector3(0.5,0.4,0.5),Color("314338"))
	var volante: MeshInstance3D = MeshInstance3D.new(); var aro: TorusMesh = TorusMesh.new(); aro.inner_radius = 0.21; aro.outer_radius = 0.25; volante.mesh = aro; volante.position = Vector3(0,2.15,-2.1); volante.rotation.x = 0.6; volante.material_override = mundo.material(Color("27352a")); add_child(volante)
	for i: int in range(4):
		var caixa: Node3D = preload("res://scripts/produce_crate.gd").new(); caixa.mundo = mundo; caixa.cultura = i; caixa.position = Vector3(-0.57+(i%2)*1.14,1.1,0.8+(i/2)*1.8); caixa.scale = Vector3.ONE*0.55; add_child(caixa); caixas_carga.append(caixa)
	mundo.placa(self,Vector3(0,3.7,-1.8),"MOZCOLHEITA · CAMIÃO 500 un.").visibility_range_end = 24
func entrar() -> bool:
	if not super.entrar(): return false
	mundo.jogador.visual.position = assento_condutor; return true
func candidato() -> Node3D: return null
func engatar() -> bool:
	mundo.avisar("Camião transporta carga própria · X carregar/entregar"); return false
func total() -> int:
	var resultado: int = 0
	for quantidade: int in carga.values(): resultado += quantidade
	return resultado
func carregar(origem: Dictionary) -> int:
	var movidas: int = 0
	for cultura: int in origem.keys():
		var quantidade: int = mini(maxi(0,CAPACIDADE-total()),int(origem[cultura]))
		if quantidade<=0: continue
		carga[cultura] = int(carga.get(cultura,0))+quantidade; origem[cultura] = int(origem[cultura])-quantidade; movidas += quantidade
		if int(origem[cultura])==0: origem.erase(cultura)
	actualizar_carga(); return movidas
func actualizar_carga() -> void:
	for i: int in range(caixas_carga.size()): caixas_carga[i].actualizar(int(carga.get(i,0)))
func transferir() -> int:
	if absf(rapidez)>0.4: mundo.avisar("Pare o camião para carregar/entregar."); return 0
	for fabrica: Node3D in mundo.fabricas:
		if fabrica.na_garagem(self) or preload("res://scripts/layout.gd").distancia(position,fabrica.position+Vector3(0,0,-42))<15:
			if not fabrica.encomendar_descarga(self): mundo.avisar("Entre na garagem, pare e aguarde o funcionário")
			return 0
	if mundo.armazem.perto():
		if not carga.is_empty(): mundo.armazem.encomendar_descarga(self)
		else: mundo.armazem.solicitar_carga(self)
		return 0
	return carregar(mundo.sacola)
