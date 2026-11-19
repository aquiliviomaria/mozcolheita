class_name ModularHuman
extends Node3D
## Adult anatomy in metres; continuous skin surfaces, fitted clothing and articulated poses.
## The same model is used on foot and in the cab so appearance and hat stay consistent.
var variant := 0
var seated := false
var show_work_tool := true
var activity: StringName = &"idle"
var movement_speed := 0.0
var look_target := Vector3.ZERO
var has_look_target := false
var _part_index := 0
var _phase := 0.0
var _idle_clock := 0.0
var _torso: Node3D
var _head: Node3D
var _arms: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _eyes: Node3D
var _hoe: Node3D
static var _mesh_cache: Dictionary = {}
func _ready() -> void:
	_build()
func _part(parent: Node3D, builder: MeshWorkshop) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	# Farmers of the same appearance share immutable meshes (including the woven hat).
	var key := "%d:%d" % [posmod(variant,4),_part_index]
	if not _mesh_cache.has(key): _mesh_cache[key] = builder.finish()
	node.mesh = _mesh_cache[key]
	_part_index += 1
	parent.add_child(node)
	return node
func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	result.position = pos
	return result
func _kit() -> MeshWorkshop:
	var result := MeshWorkshop.new()
	result.detail = 2
	return result
func _build() -> void:
	var shirts := [Color("73978b"),Color("587f9f"),Color("ad7d64"),Color("8b7c9b")]
	var skins := [Color("80563f"),Color("a57453"),Color("573c30"),Color("916347")]
	var cloth: Color = shirts[posmod(variant,shirts.size())]
	var skin: Color = skins[posmod(variant,skins.size())]
	var trousers := Color("354e5a")
	var boots := Color("433e37")
	_torso = _pivot(self,Vector3(0,1.06,0))
	var body := _kit()
	# Adult silhouette: pelvis, waist, ribcage, shoulder slope and neck opening.
	body.contour([Vector4(-0.23,0.16,0.105,0),Vector4(-0.15,0.18,0.12,0),Vector4(-0.02,0.155,0.11,0),Vector4(0.12,0.178,0.114,0),Vector4(0.22,0.19,0.108,0),Vector4(0.265,0.174,0.095,0),Vector4(0.3,0.10,0.074,0),Vector4(0.33,0.057,0.056,0)],cloth)
	body.box(Vector3(0,-0.17,0),Vector3(0.36,0.06,0.245),Color("736249"))
	body.box(Vector3(0,-0.17,-0.131),Vector3(0.06,0.045,0.018),Color("c6b58b"))
	body.box(Vector3(0.095,0.15,-0.096),Vector3(0.078,0.082,0.006),cloth.lightened(0.12))
	body.rod(Vector3(0,0.29,0),Vector3(0,0.41,0),0.055,skin)
	body.box(Vector3(0,0.065,-0.119),Vector3(0.018,0.32,0.006),cloth.darkened(0.13))
	for button: int in range(4): body.ball(Vector3(0,-0.06+button*0.085,-0.124),Vector3.ONE*0.0045,Color("e4d9b9"))
	_part(_torso,body)
	_head = _pivot(_torso,Vector3(0,0.505,0))
	# About seven head lengths per adult; avoid the long doll-like face silhouette.
	_head.scale = Vector3(1,0.84,1)
	var face := _kit()
	# One continuous face volume: tapered chin/jaw, restrained cheek plane and cranium.
	face.contour([Vector4(-0.135,0.028,0.045,-0.025),Vector4(-0.115,0.061,0.072,-0.018),Vector4(-0.08,0.083,0.085,-0.008),Vector4(-0.035,0.096,0.094,0),Vector4(0.02,0.099,0.1,0.003),Vector4(0.075,0.098,0.098,0.005),Vector4(0.12,0.078,0.079,0.008),Vector4(0.148,0.035,0.035,0.008),Vector4(0.152,0.001,0.001,0.008)],skin)
	for side: float in [-1,1]:
		face.ball(Vector3(side*0.1,-0.005,0.005),Vector3(0.013,0.028,0.018),skin)
	# Tapered nose bridge and philtrum, with no separate cheek spheres.
	face.contour([Vector4(-0.038,0.008,0.007,-0.096),Vector4(-0.028,0.020,0.012,-0.104),Vector4(-0.018,0.018,0.016,-0.105),Vector4(0.008,0.010,0.011,-0.098),Vector4(0.038,0.009,0.005,-0.092)],skin,24)
	for side: float in [-1,1]:
		face.ball(Vector3(side*0.011,-0.031,-0.114),Vector3(0.004,0.002,0.002),skin.darkened(0.45))
	face.rod(Vector3(-0.023,-0.065,-0.085),Vector3(0,-0.068,-0.093),0.003,skin.darkened(0.18))
	face.rod(Vector3(0,-0.068,-0.093),Vector3(0.023,-0.065,-0.085),0.003,skin.darkened(0.18))
	face.rod(Vector3(-0.018,-0.073,-0.084),Vector3(0.018,-0.073,-0.084),0.0035,skin.lightened(0.08))
	face.contour([Vector4(0.072,0.096,0.094,0.009),Vector4(0.112,0.084,0.084,0.009),Vector4(0.145,0.046,0.046,0.009),Vector4(0.157,0.001,0.001,0.009)],Color("28231f"))
	_part(_head,face)
	_eyes = _pivot(_head,Vector3.ZERO)
	var eyes := _kit()
	for side: float in [-1,1]:
		eyes.ball(Vector3(side*0.04,0.019,-0.094),Vector3(0.012,0.004,0.004),Color("f4e8d6"))
		eyes.ball(Vector3(side*0.04,0.019,-0.1),Vector3(0.005,0.004,0.002),Color("2b3331"))
		eyes.rod(Vector3(side*0.04-0.02,0.044,-0.092),Vector3(side*0.04+0.02,0.046,-0.092),0.0035,Color("362b24"))
	_part(_eyes,eyes)
	var hat := _kit()
	hat.rod(Vector3(0,0.13,0),Vector3(0,0.16,0),0.205,Color("c9b382"))
	hat.rod(Vector3(0,0.16,0),Vector3(0,0.25,0),0.13,Color("d6c397"),0.115)
	hat.rod(Vector3(0,0.16,0),Vector3(0,0.18,0),0.132,Color("7b735c"))
	# Concentric straw fibres and a woven crown keep the permanent hat legible.
	for ring: int in range(5):
		var radius := 0.135+ring*0.016
		for segment: int in range(24):
			var a := segment*TAU/24
			var b := (segment+1)*TAU/24
			hat.rod(Vector3(cos(a)*radius,0.165,sin(a)*radius),Vector3(cos(b)*radius,0.165,sin(b)*radius),0.0025,Color("ae8b50"))
	for stripe: int in range(16):
		var angle := stripe*TAU/16
		hat.rod(Vector3(cos(angle)*0.13,0.182,sin(angle)*0.13),Vector3(cos(angle)*0.115,0.245,sin(angle)*0.115),0.002,Color("b69b62"))
	var straw_hat := _part(_head,hat)
	straw_hat.name = "ChapeuDePalha"
	for side: float in [-1,1]:
		var arm := _pivot(_torso,Vector3(side*0.205,0.225,0))
		_arms.append(arm)
		var upper := _kit()
		upper.contour([Vector4(-0.3,0.045,0.046,0),Vector4(-0.2,0.054,0.052,0),Vector4(-0.06,0.064,0.06,0),Vector4(0.015,0.058,0.055,0),Vector4(0.03,0.04,0.038,0)],cloth)
		_part(arm,upper)
		var elbow := _pivot(arm,Vector3(0,-0.28,0))
		_elbows.append(elbow)
		var forearm := _kit()
		forearm.contour([Vector4(-0.255,0.031,0.029,0),Vector4(-0.17,0.04,0.036,0),Vector4(-0.07,0.051,0.043,0),Vector4(0.015,0.05,0.045,0)],skin)
		forearm.ball(Vector3(0,-0.276,0),Vector3(0.034,0.046,0.024),skin)
		for finger: int in range(4):
			var x := -0.024+finger*0.016
			forearm.rod(Vector3(x,-0.303,-0.005),Vector3(x,-0.34+absf(finger-1.5)*0.008,-0.012),0.008,skin)
		forearm.rod(Vector3(side*0.03,-0.264,0),Vector3(side*0.047,-0.3,-0.012),0.012,skin)
		_part(elbow,forearm)
		var leg := _pivot(self,Vector3(side*0.105,0.87,0))
		_legs.append(leg)
		var thigh := _kit()
		thigh.contour([Vector4(-0.42,0.066,0.065,0),Vector4(-0.26,0.08,0.08,0),Vector4(-0.1,0.098,0.104,0),Vector4(0.065,0.1,0.108,0)],trousers)
		_part(leg,thigh)
		var knee := _pivot(leg,Vector3(0,-0.4,0))
		_knees.append(knee)
		var calf := _kit()
		calf.contour([Vector4(-0.37,0.047,0.05,0),Vector4(-0.22,0.058,0.061,0.008),Vector4(-0.1,0.067,0.067,0.008),Vector4(0.025,0.066,0.065,0)],trousers)
		calf.ball(Vector3(0,-0.37,-0.045),Vector3(0.073,0.07,0.135),boots)
		calf.box(Vector3(0,-0.417,-0.04),Vector3(0.14,0.018,0.23),boots.darkened(0.3))
		_part(knee,calf)
	_hoe = _pivot(_elbows[1],Vector3(0,-0.26,0))
	var tool := _kit()
	tool.rod(Vector3(0,-0.35,0),Vector3(0,0.65,0),0.018,Color("a88d65"))
	tool.box(Vector3(0,-0.37,-0.08),Vector3(0.23,0.035,0.22),Color("7b8989"))
	_part(_hoe,tool)
	_hoe.hide()
	# Mild stature/build variation, preserving adult head-to-body proportions.
	var builds := [Vector3(1,1,1),Vector3(0.96,1.035,0.96),Vector3(1.055,0.98,1.045),Vector3(0.94,1.01,0.96)]
	if not seated: scale = builds[posmod(variant,builds.size())]
func _process(delta: float) -> void:
	if _torso == null: return
	_idle_clock += delta
	_phase += delta*(5.0 if movement_speed>0.1 else 1.5)
	var stride := minf(movement_speed/2.0,1.0)*0.6
	var work := activity in [&"hoe",&"plant",&"harvest",&"saw",&"hammer",&"irrigate"]
	_torso.position.y = 1.06+(0.0 if seated else sin(_phase*2)*0.012*minf(movement_speed,1))
	_torso.rotation.x = lerpf(_torso.rotation.x,(-0.6 if activity == &"plant" else -0.32) if work else 0.0,minf(1,delta*5))
	for i: int in range(2):
		var wave := sin(_phase+(PI if i==0 else 0))
		_legs[i].rotation.x = 1.25 if seated else wave*stride
		_knees[i].rotation.x = -1.35 if seated else -maxf(0,-wave)*stride*0.8
		_arms[i].rotation.x = 0.95 if seated else 0.6+sin(_phase*1.8)*0.5 if work else -wave*stride*0.65
		_elbows[i].rotation.x = 0.6 if seated else 0.45 if work else 0.12
		_arms[i].rotation.z = (0.035 if i==0 else -0.035) if seated else (0.045 if i==0 else -0.045)
		# Hands turn inward toward the steering wheel; knees remain below the dash.
		_arms[i].rotation.y = (-0.12 if i==0 else 0.12) if seated else 0.0
	_hoe.visible = show_work_tool and activity == &"hoe" and not seated
	_torso.scale.y = 1.0+sin(_idle_clock*1.5)*0.006
	_eyes.scale.y = 0.08 if fmod(_idle_clock,4.3)>4.15 else 1.0
	if has_look_target:
		var local_target := to_local(look_target)
		var yaw := clampf(atan2(-local_target.x,-local_target.z),-0.65,0.65)
		_head.rotation.y = lerp_angle(_head.rotation.y,yaw,minf(1,delta*5))
	else: _head.rotation.y = lerp_angle(_head.rotation.y,0,minf(1,delta*3))
