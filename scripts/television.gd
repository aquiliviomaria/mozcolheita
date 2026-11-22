extends Node3D
## Telejornal animado com notícias verificadas e boletins da partida.
var mundo: Node3D
var ligada: bool = false
var tela: MeshInstance3D
var visor: SubViewport
var desenho: Control
func _ready() -> void:
	visor = SubViewport.new(); visor.size = Vector2i(320,180); visor.disable_3d = true; add_child(visor)
	desenho = preload("res://scripts/tv_program.gd").new(); desenho.mundo = mundo; visor.add_child(desenho)
	var q: QuadMesh = QuadMesh.new(); q.size = Vector2(3.9,2.1)
	tela = MeshInstance3D.new(); tela.mesh = q; add_child(tela)
	var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture = visor.get_texture(); tela.material_override = mat
func _process(_delta: float) -> void:
	tela.visible = ligada
	visor.render_target_update_mode = SubViewport.UPDATE_ALWAYS if ligada else SubViewport.UPDATE_DISABLED
	desenho.set_process(ligada and not mundo.pausado())
