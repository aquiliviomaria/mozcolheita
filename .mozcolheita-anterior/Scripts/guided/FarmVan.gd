extends Vehicle3D
## The van reuses the tested vehicle drivetrain with a separate cargo body.
var van_wheels: Array[MeshInstance3D] = []
var cargo_boxes: Array[MeshInstance3D] = []
func _ready() -> void:
	super._ready()
	$Main_tractor.hide()
	var visual := Node3D.new()
	visual.name = "CarrocariaCarrinha"
	add_child(visual)
	_box(visual, Vector3(0, 0.3, 0), Vector3(1.9,0.3,4.4), Color("334047"))
	_box(visual, Vector3(0, 1.15, -1.25), Vector3(1.9,1.5,1.6), Color("e7d4a8"))
	_box(visual, Vector3(0, 1.45, -2.06), Vector3(1.65,0.6,0.03), Color("76a9bd"))
	_box(visual, Vector3(0, 0.62, 0.85), Vector3(1.85,0.25,2.6), Color("a7825f"))
	for side: float in [-1,1]:
		_box(visual, Vector3(side*0.92,1,0.85), Vector3(0.12,0.7,2.6), Color("c8ac7c"))
		for z: float in [-1.5,1.6]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.48
			cylinder.bottom_radius = 0.48
			cylinder.height = 0.25
			wheel.mesh = cylinder
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color("292c2d")
			wheel.material_override = rubber
			visual.add_child(wheel)
			wheel.position = Vector3(side,0,z)
			wheel.rotation.z = PI/2
			van_wheels.append(wheel)
	_box(visual, Vector3(0,1,2.15), Vector3(1.85,0.7,0.12), Color("c8ac7c"))
	for i: int in range(6):
		var crate := _box(visual,Vector3((i%2)*0.7-0.35,0.96+(i/4)*0.5,0.1+(i%4/2)*0.9),Vector3(0.6,0.45,0.7),Color("b7864b"))
		cargo_boxes.append(crate)
	var label := Label3D.new()
	label.text = "CARRINHA DE ALIMENTOS\nF · Conduzir | L · Carregar | U · Retirar"
	label.position.y = 3.2
	label.font_size = 26
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	return mesh
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Engine.is_editor_hint(): return
	var food: int = int(GameManager.session.entities.get_player().guide.get("van_food",0))
	for i: int in range(cargo_boxes.size()): cargo_boxes[i].visible = i*5 < food
	for wheel: MeshInstance3D in van_wheels: wheel.rotate_object_local(Vector3.UP,linear_velocity.length()*delta/0.48)
func get_interaction_prompt() -> String:
	return "Conduzir carrinha [F] — alimentos: %d/30" % int(GameManager.session.entities.get_player().guide.get("van_food",0))
