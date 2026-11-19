extends Node3D
## Kinematic three-point equipment avoids adding unstable rigid constraints to GEVP.
## Dock records, tank contents and selected tool live in PlayerData.guide, not visuals.
signal equipment_changed
const KINDS: Array[StringName] = [&"plow",&"seeder",&"irrigator"]
const COUPLING_DISTANCE := 7.0
const STOP_SPEED := 0.4
const NAMES := ["Charrua", "Semeadora", "Rega · tanque e aspersores"]
var guide: Node
var vehicle: Node3D
var selected := 0
var attached := false
var lowered := false
var active := false
var _views: Array[Node3D] = []
var _indicators: Array[Label3D] = []
var _timer := 0.0
var _last_sample := Vector3.INF
var _bound_data: PlayerData
func _ready() -> void:
	name = "TractorEquipment"
	vehicle = get_parent()
	for kind: StringName in KINDS:
		var view := EquipmentVisuals.build(kind)
		add_child(view)
		_views.append(view)
		var indicator := preload("res://Scripts/presentation/CouplingIndicator.gd").new()
		add_child(indicator)
		_indicators.append(indicator)
func _bind() -> void:
	if _bound_data == guide.data: return
	_bound_data = guide.data
	if not guide.data.guide.has("machinery"):
		var docks: Array = []
		for i: int in range(3): docks.append([132.0+i*4,guide._ground(Vector3(132+i*4,0,151)),151.0])
		guide.data.guide.machinery = {"selected":0,"attached":false,"tank":300.0,"docks":docks}
	selected = clampi(int(guide.data.guide.machinery.get("selected",0)),0,2)
	attached = bool(guide.data.guide.machinery.get("attached",false))
	lowered = false
	active = false
func handle_input(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo: return false
	_bind()
	var key: int = event.physical_keycode
	if key >= KEY_1 and key <= KEY_6:
		guide.select_seed(CropCatalog.IDS[key-KEY_1]); return true
	if key >= KEY_7 and key <= KEY_9:
		if attached: guide.notify("Desacople primeiro [P], com o tractor parado.")
		else:
			selected = key-KEY_7
			_save()
			guide.notify("%s seleccionado. Aproxime-se do equipamento e prima P." % NAMES[selected])
		return true
	match key:
		KEY_P: toggle_mount()
		KEY_V:
			if attached:
				lowered = not lowered
				if not lowered: active = false
			else: guide.notify("P · Acoplar primeiro o equipamento seleccionado.")
		KEY_B:
			if attached and lowered: active = not active
			else: guide.notify("Acople [P] e baixe [V] antes de ligar [B].")
		KEY_I:
			if attached and selected == 1 and lowered: active = not active
			else: guide.notify("7/8/9 escolhem charrua, semeadora ou rega. P acopla; V baixa; B liga.")
		KEY_K: refill()
		_: return false
	equipment_changed.emit()
	return true
func _save() -> void:
	guide.data.guide.machinery.selected = selected
	guide.data.guide.machinery.attached = attached
func _socket_occupied() -> bool:
	for socket: HitchSocket3D in vehicle._available_sockets:
		if socket.hitch_type == Implement3D.HitchType.HITCH_3_POINT and socket.has_attached_implement(): return true
	return false
func can_couple(index: int) -> bool:
	if attached or vehicle.linear_velocity.length()>STOP_SPEED or _socket_occupied(): return false
	var dock: Array = guide.data.guide.machinery.docks[index]
	return vehicle.global_position.distance_to(Vector3(dock[0],dock[1],dock[2]))<=COUPLING_DISTANCE
func toggle_mount() -> bool:
	_bind()
	if vehicle.linear_velocity.length()>STOP_SPEED:
		guide.notify("Pare o tractor para acoplar ou desacoplar."); return false
	if attached:
		var pos: Vector3 = vehicle.to_global(Vector3(0,0,4))
		pos.y = guide._ground(pos)
		guide.data.guide.machinery.docks[selected] = [pos.x,pos.y,pos.z]
		attached = false
		active = false
		lowered = false
	else:
		var dock: Array = guide.data.guide.machinery.docks[selected]
		if vehicle.global_position.distance_to(Vector3(dock[0],dock[1],dock[2]))>COUPLING_DISTANCE:
			guide.notify("Equipamento junto à garagem: x%.0f / z%.0f. Aproxime-se a menos de 7 m." % [dock[0],dock[2]]); return false
		if _socket_occupied():
			guide.notify("Desacople a charrua antiga [Z] antes de montar este equipamento."); return false
		attached = true
	_save()
	guide.notify("%s %s. V baixa / levanta; B liga / desliga." % [NAMES[selected],"acoplada" if attached else "desacoplada"])
	equipment_changed.emit()
	return true
func refill() -> bool:
	var p := vehicle.global_position
	if Vector2(p.x-132,p.z-151).length()>12 and Vector2(p.x-113,p.z-139).length()>9:
		guide.notify("Reabasteça a água junto ao poço ou à estação da garagem [K]."); return false
	guide.data.guide.machinery.tank = 300.0
	guide.notify("Depósito de rega cheio: 300 litros.")
	return true
func status() -> String:
	_bind()
	var text := "%s · %s" % [NAMES[selected],"a trabalhar" if active and lowered and attached else "baixado" if lowered else "acoplado" if attached else "na estação"]
	if selected == 2: text += " · %.0f L" % float(guide.data.guide.machinery.tank)
	return text+"\n7/8/9 · Equipamento   P · Acoplar\nV · Baixar   B · Ligar   K · Água"
func _process(delta: float) -> void:
	if not is_instance_valid(guide) or guide.data == null: return
	_bind()
	if not vehicle.is_driven: active = false
	for i: int in range(3):
		var view := _views[i]
		if attached and i == selected:
			view.transform = Transform3D(Basis.IDENTITY,Vector3(0,-0.38 if lowered else 0.4,2.15))
		else:
			var dock: Array = guide.data.guide.machinery.docks[i]
			view.global_transform = Transform3D(Basis.IDENTITY,Vector3(dock[0],dock[1]+0.32,dock[2]))
		var distance: float = vehicle.global_position.distance_to(view.global_position) if vehicle.is_driven else guide.player.global_position.distance_to(view.global_position)
		_indicators[i].global_position = view.global_position+Vector3.UP*2.6
		_indicators[i].text = "▼ %s · %d → P" % [NAMES[i],7+i]
		# A green beacon promises a valid coupling, using exactly the action's checks.
		_indicators[i].visible = distance<12 and can_couple(i)
		for child: Node in view.get_children():
			if child is CPUParticles3D:
				child.emitting = attached and i==selected and active and lowered and (float(guide.data.guide.machinery.tank)>0 if selected==2 else vehicle.linear_velocity.length()>0.25)
	if get_tree().paused or guide.blocks_gameplay(): return
	_timer += delta
	if _timer<0.08: return
	_timer = 0
	if not attached or not lowered or not active or not vehicle.is_driven:
		_last_sample = Vector3.INF
		return
	if selected != 2 and vehicle.linear_velocity.length()<0.25: return
	var center: Vector3 = vehicle.to_global(Vector3(0,0,3.3))
	if absf(center.y-float(guide._ground(center)))>2:
		_last_sample = Vector3.INF
		return
	# Half-metre samples fill swept rows even at the allowed working speed.
	if _last_sample.is_finite() and center.distance_to(_last_sample)>0.05 and center.distance_to(_last_sample)<5:
		var distance := center.distance_to(_last_sample)
		for step: int in range(1,ceili(distance/0.45)+1):
			work_at(_last_sample.lerp(center,minf(1,step*0.45/maxf(distance,0.01))),vehicle.global_basis.x)
	else: work_at(center,vehicle.global_basis.x)
	_last_sample = center
func work_at(center: Vector3, right: Vector3) -> int:
	var changed := 0
	var hydrated := 0
	var width := 2 if selected == 2 else 1
	for offset: int in range(-width,width+1):
		var sample := center+right.normalized()*offset
		var grid: Vector2i = guide.farm.world_to_grid(sample)
		if not guide.farm.can_plow_at(sample): continue
		var tile: FarmTileData = guide.farm.get_tile_data(grid)
		match selected:
			0:
				if tile.state != FarmData.SoilState.GRASS: continue
				sample.y = guide._ground(sample)
				guide.farm.set_tile_state(grid,FarmData.SoilState.PLOWED,sample.y)
				if int(guide.data.guide.mission)==0: guide.data.guide.mission = 1
				changed += 1
			1:
				if int(guide.data.guide.seeds)<=0:
					active = false
					guide.notify("Sem sementes. Reponha-as no armazém.")
					break
				var crop := CropCatalog.normalize_id(StringName(guide.data.guide.get("selected_seed","tomato")))
				if guide.farm.plant_crop(grid,crop,240,tile.height):
					guide.data.guide.seeds = int(guide.data.guide.seeds)-1
					if int(guide.data.guide.mission)<=1: guide.data.guide.mission = 2
					changed += 1
			2:
				var tank := float(guide.data.guide.machinery.tank)
				var moisture_before := tile.moisture
				var used: float = guide.farm.irrigate(grid,minf(tank,1.0))
				guide.data.guide.machinery.tank = maxf(0,tank-used)
				if used>0: changed += 1
				if moisture_before<80 and tile.moisture>=80: hydrated += 1
				if float(guide.data.guide.machinery.tank)<=0: active = false
	if changed>0: guide.missions.record(["plow","plant","irrigate"][selected],hydrated if selected==2 else changed)
	return changed
