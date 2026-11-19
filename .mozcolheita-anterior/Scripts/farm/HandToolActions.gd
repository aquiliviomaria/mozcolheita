extends Node3D
## Tool actions share authoritative saved wood, tree and greenhouse records.
var guide: Node
var _bound: PlayerData
var _greenhouses: Array[Node3D] = []
func _ready() -> void:
	EventBus.game_loaded_successfully.connect(func() -> void: _bound = null)
func cut_tree() -> bool:
	var nearest: Node3D
	var distance := 3.5
	for tree: Node3D in get_tree().get_nodes_in_group("harvestable_tree"):
		if not tree.visible: continue
		var d: float = guide.player.global_position.distance_to(tree.global_position)
		if d<distance: nearest = tree; distance = d
	if nearest == null:
		guide.notify("Serrote · aproxime-se do tronco de uma acácia (3,5 m).")
		return false
	var hits := int(nearest.get_meta("saw_hits",0))+1
	nearest.set_meta("saw_hits",hits)
	guide._swing = 1
	if hits<3:
		guide.notify("A cortar · %d/3" % hits)
		return true
	var cut: Array = guide.data.guide.get("cut_trees",[])
	cut.append(int(nearest.get_meta("tree_id")))
	guide.data.guide.cut_trees = cut
	guide.data.guide.wood = int(guide.data.guide.get("wood",0))+6
	nearest.hide()
	for shape: CollisionShape3D in nearest.find_children("*","CollisionShape3D",true,false): shape.set_deferred("disabled",true)
	guide.notify("+6 madeira · Martelo: cercas [clique] ou estufa [G].")
	return true
func build_greenhouse() -> bool:
	guide._update_target()
	if not guide.target_valid:
		guide.notify("Olhe para o chão a menos de 3,5 m."); return false
	var pos: Vector3 = guide.target
	if not Rect2(96,118,20,17).has_point(Vector2(pos.x,pos.z)):
		guide.notify("Construa a estufa na horta (deixe 3 m livres à volta)."); return false
	if int(guide.data.guide.get("wood",0))<12:
		guide.notify("Estufa: precisa de 12 madeira. Use o serrote nas acácias."); return false
	var records: Array = guide.data.guide.get("greenhouses",[])
	if records.size()>=8: guide.notify("Limite de 8 estufas."); return false
	for row: Array in records:
		if Vector2(pos.x-row[0],pos.z-row[2]).length()<6:
			guide.notify("Deixe espaço entre as estufas."); return false
	guide.data.guide.wood = int(guide.data.guide.wood)-12
	records.append([snappedf(pos.x,0.5),pos.y,snappedf(pos.z,0.5)])
	guide.data.guide.greenhouses = records
	_rebuild()
	guide.notify("Estufa construída · estrutura de madeira e cobertura translúcida.")
	return true
func _process(_delta: float) -> void:
	if guide.data != null and _bound != guide.data:
		_bound = guide.data
		_rebuild()
func _rebuild() -> void:
	for node: Node3D in _greenhouses: node.queue_free()
	_greenhouses.clear()
	for row: Array in guide.data.guide.get("greenhouses",[]):
		var root := Node3D.new()
		add_child(root)
		root.position = Vector3(row[0],row[1],row[2])
		_greenhouses.append(root)
		var kit := MeshWorkshop.new()
		for z: float in [-2,0,2]:
			for x: float in [-1.5,1.5]:
				kit.rod(Vector3(x,0,z),Vector3(x,2,z),0.055,Color("ac8b62"))
				kit.rod(Vector3(x,2,z),Vector3(0,2.8,z),0.045,Color("ac8b62"))
		for x: float in [-1.5,1.5]: kit.rod(Vector3(x,2,-2),Vector3(x,2,2),0.05,Color("ac8b62"))
		kit.rod(Vector3(0,2.8,-2),Vector3(0,2.8,2),0.05,Color("ac8b62"))
		for x: float in [-1,1]:
			kit.box(Vector3(x*0.75,2.4,0),Vector3(1.7,0.025,4.15),Color(0.68,0.84,0.78,0.22),Vector3(0,0,-x*0.49))
		for x: float in [-1.5,1.5]: kit.box(Vector3(x,1,0),Vector3(0.018,1.9,4),Color(0.68,0.84,0.78,0.16))
		kit.box(Vector3(0,1,2),Vector3(3,1.9,0.018),Color(0.68,0.84,0.78,0.16))
		var view := MeshInstance3D.new()
		view.mesh = kit.finish()
		root.add_child(view)
		# Physical posts leave the doorway and growing area accessible.
		for x: float in [-1.5,1.5]:
			for z: float in [-2,2]: guide._box(root,Vector3(x,1,z),Vector3(0.1,2,0.1),Color("ac8b62"),true)
