extends Node3D
## Casa de dois pisos; arquitectura, interiores e actividades em módulos separados.
const LOCAL: Vector3 = Vector3(-8,0,-51)
const INICIO: Vector3 = Vector3(-8,0,-29)
var mundo: Node3D
var porta: Node3D
var abertura: float = 0
var telhado: Array[Node3D] = []
var piso_superior: Array[Node3D] = []
var vida_domestica: Node
var luz_interior: OmniLight3D
var luz_quarto: OmniLight3D
var elevador: Node3D
func _ready() -> void:
	position = LOCAL; position.y = mundo.altura(position)
	preload("res://scripts/house_architecture.gd").construir(self)
	preload("res://scripts/house_interior.gd").construir(self)
	vida_domestica = preload("res://scripts/home_life.gd").new(); vida_domestica.mundo = mundo; vida_domestica.casa = self; add_child(vida_domestica)
	luz_interior = lampada(Vector3(0,4,2)); luz_quarto = lampada(Vector3(8,9,4))
func lampada(p: Vector3) -> OmniLight3D:
	var l: OmniLight3D = OmniLight3D.new(); l.position = p; l.light_color = Color("ffe4b5"); l.omni_range = 18; l.light_energy = 0.1; l.distance_fade_enabled = true; l.distance_fade_begin = 45; add_child(l); return l
func dentro(p: Vector3) -> bool:
	var local: Vector3 = to_local(p)
	return absf(local.x)<15.8 and local.z>-10.8 and local.z<10.8 and local.y>0.4 and local.y<10.8
func _process(delta: float) -> void:
	if not is_instance_valid(mundo.jogador): return
	var local: Vector3 = to_local(mundo.jogador.global_position)
	var perto: bool = Vector2(local.x,local.z-11.22).length()<5 and local.y<4
	if mundo.familia!=null and mundo.familia.veiculo==null:
		var parceiro: Vector3 = to_local(mundo.familia.pessoa.global_position)
		perto = perto or (Vector2(parceiro.x,parceiro.z-11.22).length()<5 and parceiro.y<4)
	if not mundo.pausado(): abertura = move_toward(abertura,1.0 if perto else 0.0,delta*2.5)
	porta.rotation.y = -abertura*PI*0.6
	if mundo.luz_diaria!=null:
		luz_interior.light_energy = lerpf(0.9,0.08,mundo.luz_diaria.luminosidade); luz_quarto.light_energy = luz_interior.light_energy
	var interior: bool = dentro(mundo.jogador.global_position)
	var corte: bool = mundo.camera!=null and (mundo.camera.enquadramento or mundo.camera.livre)
	for n: Node3D in telhado: n.visible = not (interior and corte)
	for n: Node3D in piso_superior: n.visible = not (interior and corte) or local.y>4.6
func vidro(p: Vector3,tamanho: Vector3) -> Node3D:
	var janela: MeshInstance3D = mundo.caixa(self,p,tamanho,Color("a0cfdf"),true); janela.name = "JanelaTransparente"
	var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.albedo_color = Color(0.63,0.81,0.87,0.14); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.roughness = 0.15; mat.cull_mode = BaseMaterial3D.CULL_DISABLED; janela.material_override = mat; return janela
