extends Node3D
## Shared acacia mesh: broad shade trees at parcel edges, clear of player/vehicle access.
func _ready() -> void:
	EventBus.game_loaded_successfully.connect(func() -> void: _bound = null)
	var guide: Node = get_tree().get_first_node_in_group("farm_guide")
	if guide == null: return
	var kit := MeshWorkshop.new()
	var bark := Color("75654d")
	kit.rod(Vector3.ZERO,Vector3(0.15,2.8,0),0.17,bark,0.1)
	for side: float in [-1,1]:
		kit.rod(Vector3(0.1,1.6,0),Vector3(side*1.25,3.1,0.15),0.09,bark,0.035)
		kit.rod(Vector3(0.1,2.1,0),Vector3(side*0.55,3.25,1),0.065,bark,0.025)
		kit.ball(Vector3(side*1.15,3.3,0.15),Vector3(1.7,0.48,1.35),Color("72825c"))
		kit.ball(Vector3(side*0.45,3.55,0.7),Vector3(1.35,0.42,1.3),Color("839067"))
	var shared_mesh := kit.finish()
	var points: Array[Vector2] = [Vector2(67,90),Vector2(67,111),Vector2(124,90),Vector2(122,117),Vector2(79,158),Vector2(148,166),Vector2(45,82),Vector2(20,76),Vector2(192,75),Vector2(226,58),Vector2(197,211),Vector2(227,212),Vector2(13,213),Vector2(42,212),Vector2(219,135),Vector2(251,132),Vector2(76,38),Vector2(106,35)]
	for i: int in range(points.size()):
		var sample := Vector3(points[i].x,0,points[i].y)
		sample.y = guide._ground(sample)
		var tree := StaticBody3D.new()
		add_child(tree)
		tree.position = sample
		tree.set_meta("tree_id",i)
		tree.add_to_group("harvestable_tree")
		var view := MeshInstance3D.new()
		view.mesh = shared_mesh
		view.visibility_range_end = 240
		tree.add_child(view)
		var collision := CollisionShape3D.new()
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.2
		trunk.height = 2.8
		collision.shape = trunk
		collision.position.y = 1.4
		tree.add_child(collision)
		_trees.append(tree)
var _trees: Array[Node3D] = []
var _bound: PlayerData
func _process(_delta: float) -> void:
	if GameManager.session == null: return
	var data: PlayerData = GameManager.session.entities.get_player()
	if _bound == data: return
	_bound = data
	for tree: Node3D in _trees:
		var cut := false
		# JSON restores numeric array values as floats; compare stable integer IDs.
		for saved_id: Variant in data.guide.get("cut_trees",[]):
			if int(saved_id)==int(tree.get_meta("tree_id")): cut = true
		tree.visible = not cut
		tree.set_meta("saw_hits",0)
		for shape: CollisionShape3D in tree.find_children("*","CollisionShape3D",true,false): shape.disabled = cut
