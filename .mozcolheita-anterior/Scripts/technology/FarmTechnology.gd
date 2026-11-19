extends Node3D
## Composition root for optional farming technologies. No authoritative simulation data here.
var guide: Node
var drone: Node3D
var fences: Node3D
var equipment: Node3D
var _timer := 0.0
func _ready() -> void:
	name = "TecnologiaDaMachamba"
	guide.technology = self
	drone = preload("res://Scripts/technology/IrrigationDrone.gd").new()
	drone.guide = guide
	add_child(drone)
	fences = preload("res://Scripts/technology/ModernFences.gd").new()
	fences.guide = guide
	add_child(fences)
	add_child(preload("res://Scripts/presentation/RuralVegetation.gd").new())
	_build_station()
	_build_production_field()
func _build_station() -> void:
	var pos := Vector3(136,guide._ground(Vector3(136,0,151)),151)
	guide._box(self,pos+Vector3(0,0.02,0),Vector3(17,0.06,7),Color("667c78"))
	var kit := MeshWorkshop.new()
	kit.rod(Vector3(8,0,-2),Vector3(8,2.5,-2),0.8,Color("d1ded7"))
	kit.box(Vector3(6.5,0.7,-2),Vector3(0.8,1.4,0.5),Color("517b77"))
	kit.box(Vector3(6.5,1.15,-2.27),Vector3(0.55,0.3,0.02),Color("91d6ba"))
	kit.rod(Vector3(6.5,1,-2),Vector3(7,0.25,-2.5),0.035,Color("3e5053"))
	kit.box(Vector3(-7,0.1,0),Vector3(1.8,0.12,1.8),Color("d4dcd3"))
	var view := MeshInstance3D.new()
	view.mesh = kit.finish()
	view.position = pos
	add_child(view)
	var label := Label3D.new()
	label.position = pos+Vector3(0,3.6,-1)
	label.text = "MOZCOLHEITA · ESTAÇÃO AGRÍCOLA\n7 Charrua · 8 Semeadora · 9 Rega\nP Acoplar · V Baixar · B Ligar · K Abastecer\nF8 Drone · N Cercas"
	label.font_size = 32
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 40
	add_child(label)
func _build_production_field() -> void:
	var label := Label3D.new()
	var pos := Vector3(95,guide._ground(Vector3(95,0,114)),114)
	label.position = pos+Vector3.UP*2.5
	label.text = "MACHAMBA DE PRODUÇÃO\n48 × 22 m · Utilize o tractor\nCharrua → Semeadora → Rega\nCultive dentro dos marcos brancos"
	label.font_size = 32
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 40
	add_child(label)
	for x: float in [72,120]:
		for z: float in [92,114]:
			var ground := Vector3(x,guide._ground(Vector3(x,0,z)),z)
			guide._box(self,ground+Vector3.UP*0.4,Vector3(0.12,0.8,0.12),Color("dddcca"))
func _process(delta: float) -> void:
	if not is_instance_valid(guide) or guide.data == null: return
	_timer += delta
	if _timer<0.3: return
	_timer = 0
	if not is_instance_valid(equipment):
		for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
			if vehicle.entity_data != null and vehicle.entity_data.definition_id == &"vehicle.truck":
				equipment = vehicle.get_node_or_null("TractorEquipment")
				if equipment == null:
					equipment = preload("res://Scripts/technology/TractorEquipment.gd").new()
					equipment.guide = guide
					vehicle.add_child(equipment)
				break
func _input(event: InputEvent) -> void:
	if not is_instance_valid(guide) or guide.data == null or get_tree().paused or guide.blocks_gameplay(): return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K and guide.data.active_vehicle_id.is_empty():
		if drone.refill(): get_viewport().set_input_as_handled()
func blocks_player() -> bool: return is_instance_valid(drone) and drone.flying
func contextual_hint() -> String:
	if drone.flying: return drone.status()
	if fences.building: return fences.status()
	return ""
