extends AnimatableBody3D
## Autonomous local worker. Navigation/work state is separate from the articulated visual kit.
var guide: Node
var village: Node
var farm_index := 0
var driving := false
var phase := 0.0
var route: PackedVector3Array
var speed := 1.1
var _segment := 0
var _visual: Node3D
var _human: ModularHuman
var _tractor: ModernTractor
var _work_state: Label3D
var _bubble: Label3D
var _pause_timer := 0.0
var _talk_timer := 0.0
var _bubble_timer := 0.0
var _chat_timer := 12.0
var _height_timer := 0.0
var _target_height := 0.0
func _ready() -> void:
	sync_to_physics = false
	collision_layer = 1
	collision_mask = 1
	var bounds := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9,2,3.2) if driving else Vector3(0.55,1.8,0.55)
	bounds.shape = shape
	bounds.position.y = 1
	add_child(bounds)
	_visual = Node3D.new()
	add_child(_visual)
	_human = ModularHuman.new()
	_human.variant = farm_index
	if driving:
		_tractor = ModernTractor.new()
		_tractor.paint = [Color("719b87"),Color("bf8166"),Color("638caa")][farm_index]
		_visual.add_child(_tractor)
		_tractor.position.y = 0.65
		_visual.scale = Vector3.ONE*0.82
		_human.seated = true
		_human.position = Vector3(0,0.3,0.75)
		_tractor.add_child(_human)
		var implement := EquipmentVisuals.build(&"plow" if farm_index%2==0 else &"seeder")
		implement.position = Vector3(0,-0.38,2.15)
		_tractor.add_child(implement)
		speed = 2.7
	else:
		_visual.add_child(_human)
		_pause_timer = 1+farm_index*0.3
	_work_state = _label(2.6 if driving else 2.05,24,Color("eef1e1"))
	_bubble = _label(3.0 if driving else 2.45,28,Color("f0d89b"))
	_bubble.hide()
	_chat_timer += farm_index*4+(3 if driving else 0)
	_target_height = global_position.y
	add_to_group("farm_workers")
func _label(height: float, font_size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.position.y = height
	label.font_size = font_size
	label.pixel_size = 0.0025
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 5
	add_child(label)
	return label
func _physics_process(delta: float) -> void:
	if not is_instance_valid(guide) or not is_instance_valid(village) or route.size()<2: return
	if is_instance_valid(guide.employment) and guide.employment.process_employee(self,delta): return
	var player: Node3D = guide.player
	var player_distance := global_position.distance_to(player.global_position) if is_instance_valid(player) else 1000.0
	_talk_timer = maxf(0,_talk_timer-delta)
	_pause_timer = maxf(0,_pause_timer-delta)
	_bubble_timer = maxf(0,_bubble_timer-delta)
	_bubble.visible = _bubble_timer>0 and player_distance<24
	var stopped := _talk_timer>0 or _pause_timer>0 or player_distance<(2.2 if driving else 1.0)
	if not stopped:
		var next: Vector3 = route[(_segment+1)%route.size()]
		var here := Vector2(global_position.x,global_position.z)
		var there := Vector2(next.x,next.z)
		var moved := here.move_toward(there,delta*speed)
		var direction := there-here
		if direction.length()>0.1: rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.y),delta*4)
		_height_timer += delta
		if _height_timer>0.12:
			_height_timer = 0
			_target_height = guide._ground(Vector3(moved.x,0,moved.y))
		global_position = Vector3(moved.x,lerpf(global_position.y,_target_height,minf(1,delta*10)),moved.y)
		if moved.distance_to(there)<0.12:
			_segment = (_segment+1)%route.size()
			if not driving: _pause_timer = 3.2
	_human.movement_speed = 0 if stopped or driving else speed
	_human.has_look_target = player_distance<5 and not driving
	if _human.has_look_target: _human.look_target = player.global_position+Vector3.UP*1.6
	var state: String = village.production_phase(farm_index)
	if driving:
		_human.activity = &"drive"
		_tractor.animate_wheels(delta,0 if stopped else speed)
		var hour: int = GameManager.session.time.current_hour
		_tractor.set_headlights(hour>=18 or hour<6)
	elif _talk_timer>0: _human.activity = &"idle"
	elif stopped: _human.activity = &"hoe" if "preparar" in state else &"plant" if "semear" in state else &"harvest"
	else: _human.activity = &"walk"
	_work_state.visible = player_distance<22
	_work_state.text = "%s · %s" % [NeighborOrders.NAMES[farm_index],"a conduzir" if driving else "a conversar" if _talk_timer>0 else state.trim_prefix("A ")]
	_chat_timer -= delta
	if _chat_timer<=0:
		_chat_timer = 20+farm_index*3
		for colleague: Node3D in get_tree().get_nodes_in_group("farm_workers"):
			if colleague != self and global_position.distance_to(colleague.global_position)<14:
				say("A colheita está a ficar bonita!")
				colleague.say("Um bom dia de trabalho.")
				break
func say(text: String) -> void:
	_bubble.text = text
	_bubble_timer = 3
func get_interaction_prompt() -> String:
	return "F · Falar com %s%s" % [NeighborOrders.NAMES[farm_index]," (tractor parado)" if driving else ""]
func interact(_player: Node3D) -> void:
	if not driving and guide.employment.records().has(guide.employment.worker_id(self)):
		guide.employment.manage(self)
		return
	_talk_timer = 12
	say("Olá! Preciso de ajuda com uma entrega.")
	village.talk(farm_index)
