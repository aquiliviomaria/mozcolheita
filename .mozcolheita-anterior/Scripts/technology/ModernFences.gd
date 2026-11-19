extends Node3D
## Persisted endpoints are independent from the meshes and collision bodies.
signal fence_changed(count: int)
var guide: Node
var building := false
var anchor := Vector3.INF
var aim := Vector3.ZERO
var aim_valid := false
var _ghost: MeshInstance3D
var _records: Array = []
var _views: Array[Node3D] = []
var _bound: PlayerData
var _reason := ""
var _ghost_key := ""
func _ready() -> void:
	EventBus.game_loaded_successfully.connect(func() -> void: _bound = null)
	_ghost = MeshInstance3D.new()
	add_child(_ghost)
	_ghost.hide()
func _bind() -> void:
	if _bound == guide.data: return
	_bound = guide.data
	for view: Node3D in _views: view.queue_free()
	_views.clear()
	_records = guide.data.guide.get("modern_fences",[])
	for row: Array in _records: _views.append(_make_view(_vec(row[0]),_vec(row[1])))
func _vec(row: Array) -> Vector3: return Vector3(row[0],row[1],row[2])
func _pack(pos: Vector3) -> Array: return [pos.x,pos.y,pos.z]
func _mesh(a: Vector3,b: Vector3,color: Color) -> ArrayMesh:
	var kit := MeshWorkshop.new()
	for pos: Vector3 in [a,b]:
		kit.box(pos+Vector3.UP*0.65,Vector3(0.09,1.3,0.09),color)
		kit.box(pos+Vector3.UP*1.32,Vector3(0.13,0.04,0.13),Color("b3c3c5"))
	if a.distance_to(b)>0.1:
		for y: float in [0.35,0.75,1.12]: kit.rod(a+Vector3.UP*y,b+Vector3.UP*y,0.022,color.lightened(0.12))
	return kit.finish()
func _make_view(a: Vector3,b: Vector3) -> Node3D:
	var body := StaticBody3D.new()
	body.name = "CercaModerna"
	add_child(body)
	body.position = a
	var mesh := MeshInstance3D.new()
	mesh.mesh = _mesh(Vector3.ZERO,b-a,Color("56777b"))
	body.add_child(mesh)
	var bounds := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.14,1.35,a.distance_to(b))
	bounds.shape = shape
	bounds.position = (b-a)*0.5+Vector3.UP*0.6
	bounds.rotation.y = atan2(b.x-a.x,b.z-a.z)
	body.add_child(bounds)
	return body
func valid_segment(a: Vector3,b: Vector3) -> bool:
	_reason = ""
	if _records.size()>=256: _reason = "Limite: 256 secções."
	elif a.distance_to(b)<1.5 or a.distance_to(b)>8: _reason = "Cada secção precisa de 1,5 a 8 metros."
	for pos: Vector3 in [a,a.lerp(b,0.5),b]:
		if Vector2(pos.x-105,pos.z-126).length()>52: _reason = "Construa dentro da sua machamba."
		for exclusion: Rect2 in [Rect2(99,139,11,12),Rect2(116,143,13,16),Rect2(81,139,13,13),Rect2(126,146,20,12),Rect2(110,136,6,6)]:
			if exclusion.has_point(Vector2(pos.x,pos.z)): _reason = "Mantenha livres a casa, o poço e os acessos da garagem."
		if is_instance_valid(guide.player) and Vector2(pos.x-guide.player.global_position.x,pos.z-guide.player.global_position.z).length()<0.7: _reason = "Afaste-se para não ficar dentro da cerca."
		for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
			if Vector2(pos.x-vehicle.global_position.x,pos.z-vehicle.global_position.z).length()<2.5: _reason = "Afaste a cerca do veículo."
	for row: Array in _records:
		var c := _vec(row[0])
		var d := _vec(row[1])
		if (a.distance_to(c)<0.3 and b.distance_to(d)<0.3) or (a.distance_to(d)<0.3 and b.distance_to(c)<0.3): _reason = "Essa secção já existe."
	return _reason.is_empty()
func place(a: Vector3,b: Vector3) -> bool:
	_bind()
	if not valid_segment(a,b): return false
	_records.append([_pack(a),_pack(b)])
	_views.append(_make_view(a,b))
	guide.data.guide.modern_fences = _records
	fence_changed.emit(_records.size())
	return true
func remove_near(pos: Vector3) -> bool:
	_bind()
	var best := -1
	var distance := 1.6
	for i: int in range(_records.size()):
		var closest := Geometry3D.get_closest_point_to_segment(pos,_vec(_records[i][0]),_vec(_records[i][1]))
		var d := Vector2(closest.x-pos.x,closest.z-pos.z).length()
		if d<distance: best = i; distance = d
	if best<0: return false
	_views[best].queue_free()
	_views.remove_at(best)
	_records.remove_at(best)
	guide.data.guide.modern_fences = _records
	fence_changed.emit(_records.size())
	return true
func _input(event: InputEvent) -> void:
	if not is_instance_valid(guide) or guide.data == null or get_tree().paused: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_N:
		if guide.blocks_gameplay() or not guide.data.active_vehicle_id.is_empty(): return
		building = not building
		anchor = Vector3.INF
		guide.notify("CERCAS · Clique marca postes · Botão direito cancela · Delete remove · N termina" if building else "Construção terminada.")
		get_viewport().set_input_as_handled()
	if not building: return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: anchor = Vector3.INF
		elif event.button_index == MOUSE_BUTTON_LEFT and aim_valid:
			if not anchor.is_finite(): anchor = aim
			elif place(anchor,aim): anchor = aim; guide.notify("Secção construída. Continue ou cancele com o botão direito.")
			else: guide.notify(_reason)
		else: return
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_DELETE:
		if aim_valid: guide.notify("Secção removida." if remove_near(aim) else "Olhe para uma cerca a menos de 10 metros.")
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	if not is_instance_valid(guide) or guide.data == null: return
	_bind()
	if building and (guide.blocks_gameplay() or not guide.data.active_vehicle_id.is_empty()):
		building = false
		anchor = Vector3.INF
	_ghost.visible = building
	if not building: return
	var camera: Camera3D = guide.player.camera
	var center := camera.get_viewport().get_visible_rect().size*0.5
	var start := camera.project_ray_origin(center)
	var ray := PhysicsRayQueryParameters3D.create(start,start+camera.project_ray_normal(center)*25,1,[guide.player.get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	aim_valid = not hit.is_empty()
	if not aim_valid: _ghost.hide(); return
	aim = hit.position
	aim.x = snappedf(aim.x,0.5)
	aim.z = snappedf(aim.z,0.5)
	aim.y = guide._ground(aim)
	if aim.distance_to(guide.player.global_position)>10: aim_valid = false
	var a := anchor if anchor.is_finite() else aim
	var valid := aim_valid and (valid_segment(a,aim) if anchor.is_finite() else true)
	_ghost.position = a
	var key := "%s/%s/%s" % [a,aim,valid]
	if key != _ghost_key:
		_ghost_key = key
		_ghost.mesh = _mesh(Vector3.ZERO,aim-a,Color(0.2,0.9,0.65,0.55) if valid else Color(1,0.3,0.2,0.55))
func status() -> String:
	return "CERCAS · %d/256 secções\nClique · %s\nBotão direito · Cancelar\nDelete · Remover   N · Terminar" % [_records.size(),"Primeiro poste" if not anchor.is_finite() else "Poste seguinte (1,5–8 m)"]
