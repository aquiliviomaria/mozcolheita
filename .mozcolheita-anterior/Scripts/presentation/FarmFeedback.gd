extends Node3D
## Local effects only; gameplay inventory is updated before this signal reaches the view.
static var _sounds: Dictionary = {}
func _ready() -> void:
	EventBus.farm_action_feedback.connect(_on_action)
func _on_action(action: StringName, world_position: Vector3, crop_id: StringName, amount: int) -> void:
	var color := Color("b9936c") if action == &"hoe" else Color(CropCatalog.get_crop(crop_id).color)
	var particles := CPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 0.65
	particles.one_shot = true
	particles.explosiveness = 1
	particles.direction = Vector3.UP
	particles.spread = 70
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.3
	particles.gravity = Vector3(0,-2,0)
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.0
	var speck := SphereMesh.new()
	speck.radius = 0.025
	speck.height = 0.05
	speck.radial_segments = 6
	speck.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	speck.material = material
	particles.mesh = speck
	add_child(particles)
	particles.global_position = world_position+Vector3.UP*0.1
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	if action == &"harvest":
		var label := Label3D.new()
		label.text = "+%d %s" % [amount,CropCatalog.get_crop(crop_id).plural]
		label.modulate = color.lightened(0.2)
		label.font_size = 36
		label.pixel_size = 0.004
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 6
		add_child(label)
		label.global_position = world_position+Vector3.UP*0.8
		var produce := MeshInstance3D.new()
		produce.mesh = CropVisualFactory.produce_mesh(crop_id)
		add_child(produce)
		produce.global_position = world_position+Vector3.UP*0.3
		var tween := create_tween().set_parallel(true)
		tween.tween_property(label,"position:y",label.position.y+0.9,1.1).set_trans(Tween.TRANS_SINE)
		tween.tween_property(label,"modulate:a",0.0,0.5).set_delay(0.7)
		tween.tween_property(produce,"position:y",produce.position.y+0.6,0.8)
		tween.tween_property(produce,"rotation:y",2.5,0.8)
		tween.tween_property(produce,"transparency",1.0,0.45).set_delay(0.5)
		tween.chain().tween_callback(func() -> void: label.queue_free(); produce.queue_free())
	_play_sound(action,world_position)
func _play_sound(action: StringName, pos: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	if not _sounds.has(action):
		var rate := 22050
		var duration := 0.16
		var count := int(rate*duration)
		var bytes := PackedByteArray()
		bytes.resize(count*2)
		var frequency := 620.0 if action == &"harvest" else 420.0 if action == &"plant" else 160.0
		for i: int in range(count):
			var t := float(i)/rate
			var envelope := sin(PI*t/duration)*pow(1-t/duration,2)
			var sample := sin(TAU*(frequency+(180 if action == &"harvest" else -40)*t/duration)*t)*envelope
			bytes.encode_s16(i*2,int(sample*5000))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = bytes
		_sounds[action] = stream
	var sound := AudioStreamPlayer3D.new()
	sound.stream = _sounds[action]
	sound.volume_db = -12
	sound.max_distance = 15
	add_child(sound)
	sound.global_position = pos
	sound.finished.connect(sound.queue_free)
	sound.play()
