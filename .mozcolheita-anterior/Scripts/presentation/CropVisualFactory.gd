class_name CropVisualFactory
extends RefCounted
## One cached mesh per crop/stage, reusable by MeshInstance3D and MultiMesh.
static var _cache: Dictionary = {}
static var _produce_cache: Dictionary = {}
const GREEN := Color("528753")
const LIGHT := Color("88b568")
const STEM := Color("5d8150")
static func mesh_for(crop_id: StringName, stage: int) -> ArrayMesh:
	var id := CropCatalog.normalize_id(crop_id)
	var key := "%s:%d" % [id, stage]
	if _cache.has(key): return _cache[key]
	var b := MeshWorkshop.new()
	if stage == 0:
		for x: float in [-0.07, 0.0, 0.07]: b.ball(Vector3(x,0.018,0),Vector3(0.025,0.018,0.035),Color("d6b587"))
	elif stage == 1:
		b.rod(Vector3.ZERO,Vector3(0,0.16,0),0.012,STEM)
		b.leaf(Vector3(0,0.12,0),0.09,0.15,LIGHT,0,-0.3)
		b.leaf(Vector3(0,0.1,0),0.08,0.14,GREEN,PI,-0.4)
	else:
		var growth := 0.48 if stage == 2 else 0.84 if stage == 3 else 1.0
		match id:
			&"tomato": _tomato(b,growth,stage==4)
			&"corn": _corn(b,growth,stage==4)
			&"lettuce": _lettuce(b,growth)
			&"carrot": _carrot(b,growth,stage==4)
			&"potato": _potato(b,growth,stage==4)
			&"wheat": _wheat(b,growth,stage==4)
	var result := b.finish()
	_cache[key] = result
	return result
static func _tomato(b: MeshWorkshop, g: float, ripe: bool) -> void:
	b.rod(Vector3.ZERO,Vector3(0,1.02*g,0),0.024*g,STEM,0.012*g)
	b.rod(Vector3(-0.08,0,0.05),Vector3(-0.08,1.12*g,0.05),0.012,Color("ad9671"))
	for i: int in range(6):
		var yaw := i*2.35
		var stem := Vector3(0,(0.22+i*0.1)*g,0)
		var end := stem+Vector3(sin(yaw)*0.27,0.1,cos(yaw)*0.27)*g
		b.rod(stem,end,0.012*g,STEM)
		b.leaf(end,0.19*g,0.26*g,GREEN if i%2==0 else LIGHT,yaw,-0.15)
	if g > 0.6:
		for i: int in range(4):
			var yaw := i*2.2
			var fruit := Vector3(sin(yaw)*0.22,(0.42+i*0.1)*g,cos(yaw)*0.22)
			b.rod(Vector3(0,fruit.y+0.12,0),fruit+Vector3.UP*0.08,0.009,STEM)
			b.ball(fruit,Vector3(0.105,0.09,0.1)*g,Color("d9503c") if ripe else Color("94ad62"))
			for j: int in range(5): b.leaf(fruit+Vector3.UP*0.085*g,0.025,0.075,STEM,j*TAU/5)
static func _corn(b: MeshWorkshop, g: float, ripe: bool) -> void:
	b.rod(Vector3.ZERO,Vector3(0,1.7*g,0),0.032*g,STEM,0.018*g)
	for i: int in range(7):
		var yaw := i*2.4
		b.leaf(Vector3(0,(0.25+i*0.18)*g,0),0.16*g,0.65*g,LIGHT if i%2 else GREEN,yaw,-0.32)
	if g > 0.6:
		for side: float in [-1,1]:
			var ear := Vector3(side*0.12,0.86*g+side*0.14,0)
			b.ball(ear,Vector3(0.075,0.24,0.075)*g,Color("e4bc4e") if ripe else Color("aec279"))
			b.leaf(ear-Vector3.UP*0.18,0.14,0.35,GREEN,side*PI/2,-1.2)
	for i: int in range(5):
		b.rod(Vector3(0,1.65*g,0),Vector3((i-2)*0.045,1.9*g,0.02*(i%2)),0.008,Color("ccb677"))
static func _lettuce(b: MeshWorkshop, g: float) -> void:
	for ring: int in range(3):
		var radius := (0.27-ring*0.08)*g
		var count := 8-ring*2
		for i: int in range(count):
			var yaw := i*TAU/count+ring*0.7
			var center := Vector3(sin(yaw)*radius,(0.07+ring*0.07)*g,cos(yaw)*radius)
			b.ball(center,Vector3(0.18,0.07+ring*0.025,0.18)*g,LIGHT.lightened(ring*0.05) if i%2 else GREEN.lightened(ring*0.15))
	b.ball(Vector3(0,0.24*g,0),Vector3(0.15,0.13,0.15)*g,Color("a6c97b"))
static func _carrot(b: MeshWorkshop, g: float, ripe: bool) -> void:
	var orange := Color("e48e3d") if ripe else Color("c4a071")
	b.rod(Vector3(0,-0.23*g,0),Vector3(0,0.075*g,0),0.008,orange,0.075*g)
	b.ball(Vector3(0,0.055*g,0),Vector3(0.075,0.04,0.075)*g,orange)
	for i: int in range(7):
		var yaw := i*2.4
		var top := Vector3(sin(yaw)*0.12,(0.36+(i%3)*0.07)*g,cos(yaw)*0.12)
		b.rod(Vector3.ZERO,top,0.008,STEM)
		for j: int in range(3): b.leaf(top*float(j+1)/4,0.08*g,0.19*g,GREEN if i%2 else LIGHT,yaw+j*PI/2,-0.45)
static func _potato(b: MeshWorkshop, g: float, ripe: bool) -> void:
	for i: int in range(3):
		var yaw := i*TAU/3
		var top := Vector3(sin(yaw)*0.14,0.55*g,cos(yaw)*0.14)
		b.rod(Vector3.ZERO,top,0.017,STEM)
		for j: int in range(4):
			var point := top*(0.3+j*0.16)
			b.leaf(point,0.19*g,0.22*g,GREEN if j%2 else LIGHT,yaw+j*2.2,-0.25)
		if g > 0.6:
			b.ball(top,Vector3(0.035,0.025,0.035),Color("d6b8dd"))
	if ripe:
		b.ball(Vector3(0.1,0.03,0.09),Vector3(0.1,0.06,0.075),Color("b9956c"))
		b.ball(Vector3(-0.08,0.025,-0.06),Vector3(0.09,0.05,0.07),Color("c3a47a"))
static func _wheat(b: MeshWorkshop, g: float, ripe: bool) -> void:
	var straw := Color("c4ad67") if ripe else Color("81a55b")
	for i: int in range(5):
		var pos := Vector3(sin(i*2.4)*0.1,0,cos(i*2.4)*0.1)
		var h := (0.74+(i%3)*0.07)*g
		b.rod(pos,pos+Vector3.UP*h,0.012,straw)
		b.leaf(pos+Vector3.UP*h*0.42,0.045,0.34,straw,i*1.8,-0.5)
		if g > 0.6:
			for j: int in range(5):
				var side := -1.0 if j%2 else 1.0
				b.ball(pos+Vector3(side*0.025,h+j*0.035,0),Vector3(0.03,0.045,0.025)*g,Color("dfc375") if ripe else Color("a4b76a"))
static func produce_mesh(crop_id: StringName) -> ArrayMesh:
	var id := CropCatalog.normalize_id(crop_id)
	if _produce_cache.has(id): return _produce_cache[id]
	var b := MeshWorkshop.new()
	match id:
		&"tomato":
			b.ball(Vector3.ZERO,Vector3(0.13,0.11,0.13),Color("da5544"))
			for i: int in range(5): b.leaf(Vector3(0,0.1,0),0.04,0.1,STEM,i*TAU/5)
		&"corn": b.ball(Vector3.ZERO,Vector3(0.075,0.25,0.075),Color("e2bf62"))
		&"lettuce": _lettuce(b,0.65)
		&"carrot": _carrot(b,0.75,true)
		&"potato": b.ball(Vector3.ZERO,Vector3(0.14,0.09,0.1),Color("bea17d"))
		&"wheat": _wheat(b,0.45,true)
	var result := b.finish()
	_produce_cache[id] = result
	return result
