class_name ModernTractor
extends Node3D
## Visual kit only: the original drivetrain, seat and collision remain authoritative.
var paint := Color("6e9c91")
var lights_on := false
var _lamps: Array[SpotLight3D] = []
var _wheels: Array[Node3D] = []
var _front_wheels: Array[Node3D] = []
func _ready() -> void:
	_build()
func _build() -> void:
	var b := MeshWorkshop.new()
	var dark := Color("293b40")
	var steel := Color("8faaa8")
	b.box(Vector3(0,0.27,0),Vector3(1.35,0.24,3.65),dark)
	b.box(Vector3(0,0.77,-0.96),Vector3(1.25,0.76,1.65),paint)
	b.box(Vector3(0,1.16,-0.91),Vector3(1.27,0.1,1.62),paint.lightened(0.1),Vector3(0.04,0,0))
	b.box(Vector3(0,0.76,-1.8),Vector3(0.93,0.5,0.055),dark)
	for i: int in range(5): b.box(Vector3(0,0.56+i*0.085,-1.84),Vector3(0.8,0.025,0.035),steel)
	b.box(Vector3(0,0.3,-1.96),Vector3(1.47,0.14,0.14),dark)
	# Low footwell leaves room for adult legs below the seat and steering column.
	b.box(Vector3(0,0.58,0.65),Vector3(1.4,0.12,1.5),dark)
	for side: float in [-1,1]:
		b.box(Vector3(side*0.81,0.85,1.15),Vector3(0.5,0.12,1.52),paint)
		b.box(Vector3(side*0.64,1.58,-0.03),Vector3(0.065,1.42,0.065),dark)
		b.box(Vector3(side*0.64,1.58,1.42),Vector3(0.065,1.42,0.065),dark)
		b.box(Vector3(side*0.76,1.68,-0.12),Vector3(0.11,0.25,0.11),dark)
		b.box(Vector3(side*0.83,0.6,0.25),Vector3(0.35,0.07,0.7),steel)
	b.box(Vector3(0,2.31,0.68),Vector3(1.62,0.14,1.88),paint.lightened(0.14))
	b.box(Vector3(0,2.2,0.68),Vector3(1.42,0.06,1.6),dark)
	b.box(Vector3(0,1.62,-0.07),Vector3(1.18,0.94,0.025),Color(0.53,0.73,0.75,0.28),Vector3(-0.05,0,0))
	b.box(Vector3(0,1.65,1.45),Vector3(1.18,1.02,0.025),Color(0.53,0.73,0.75,0.22))
	b.box(Vector3(0,1.08,0.91),Vector3(0.48,0.16,0.55),dark)
	b.box(Vector3(0,1.35,1.13),Vector3(0.48,0.48,0.12),dark)
	b.rod(Vector3(-0.52,1.13,-0.32),Vector3(-0.52,2.04,-0.32),0.045,dark)
	b.rod(Vector3(0,1.03,0.4),Vector3(0,1.38,0.25),0.026,dark)
	# Rim and spokes meet the seated farmer's hands at shoulder width.
	var steering_center := Vector3(0,1.38,0.25)
	var steering_plane := Basis(Vector3.RIGHT,-0.6)
	for segment: int in range(32):
		var a := segment*TAU/32
		var next := (segment+1)*TAU/32
		b.rod(steering_center+steering_plane*Vector3(cos(a),sin(a),0)*0.24,steering_center+steering_plane*Vector3(cos(next),sin(next),0)*0.24,0.015,dark)
	for spoke: int in range(3):
		var a := spoke*TAU/3
		b.rod(steering_center,steering_center+steering_plane*Vector3(cos(a),sin(a),0)*0.23,0.012,steel)
	var body := MeshInstance3D.new()
	body.mesh = b.finish()
	add_child(body)
	for side: float in [-1,1]:
		for front: bool in [true,false]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side*0.9,0, -1.45 if front else 1.24)
			add_child(pivot)
			_wheels.append(pivot)
			if front: _front_wheels.append(pivot)
			var radius := 0.53 if front else 0.72
			var wheel := MeshWorkshop.new()
			wheel.rod(Vector3(-0.18,0,0),Vector3(0.18,0,0),radius,Color("273234"))
			wheel.rod(Vector3(side*0.185,0,0),Vector3(side*0.205,0,0),radius*0.57,Color("c7d1ca"))
			wheel.rod(Vector3(side*0.208,0,0),Vector3(side*0.22,0,0),radius*0.16,steel)
			for i: int in range(14):
				var angle := i*TAU/14
				wheel.box(Vector3(0,sin(angle)*radius,cos(angle)*radius),Vector3(0.38,0.085,0.11),Color("344144"),Vector3(-angle,0,0.15*side))
			var mesh := MeshInstance3D.new()
			mesh.mesh = wheel.finish()
			pivot.add_child(mesh)
	var lens := MeshWorkshop.new()
	for side: float in [-1,1]:
		lens.box(Vector3(side*0.46,0.92,-1.84),Vector3(0.21,0.12,0.04),Color("e0e9d4"))
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(side*0.46,0.94,-1.91)
		lamp.rotation_degrees.x = -8
		lamp.light_color = Color("fff0d4")
		lamp.light_energy = 3.0
		lamp.spot_range = 22
		lamp.spot_angle = 32
		lamp.shadow_enabled = false
		add_child(lamp)
		_lamps.append(lamp)
	var lenses := MeshInstance3D.new()
	lenses.mesh = lens.finish()
	add_child(lenses)
	set_headlights(lights_on)
func set_headlights(enabled: bool) -> void:
	lights_on = enabled
	for lamp: SpotLight3D in _lamps: lamp.visible = enabled
func animate_wheels(delta: float, speed: float, steering: float = 0) -> void:
	for wheel: Node3D in _wheels:
		wheel.get_child(0).rotate_x(speed*delta/0.6)
	for wheel: Node3D in _front_wheels: wheel.rotation.y = steering*0.45
