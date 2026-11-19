extends Node3D
var guide: Node
const FARM_CENTERS := [Vector3(38,0,75),Vector3(210,0,60),Vector3(212,0,208)]
const FARM_NAMES := ["Aurora · pequena", "Vale Verde · média", "Boa Colheita · grande"]
const WAREHOUSE := Vector3(87,0,145)
const GARAGE := Vector3(122,0,151)
var _timer := 0.0
var _stock_labels: Array[Label3D] = []
var _cargo_boxes: Array[Node3D] = []

func _ready() -> void:
	_build_garage()
	_build_warehouse()
	for i: int in range(3): _build_neighbor(i)
	for i: int in range(3): _build_satellite(i,[Vector3(25,0,210),Vector3(235,0,130),Vector3(90,0,35)][i])
func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	return guide._box(parent,pos,size,color,collision)
func ground(pos: Vector3) -> Vector3:
	pos.y = guide._ground(pos)
	return pos
func add_sign(pos: Vector3, text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 30
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	return label
func _build_garage() -> void:
	var pos := ground(GARAGE)
	box(self,pos+Vector3(0,0.04,0),Vector3(9,0.1,12),Color("777a70"))
	box(self,pos+Vector3(0,4.2,0),Vector3(10,0.3,13),Color("734e3a"),true)
	for side: float in [-1,1]: box(self,pos+Vector3(side*4.4,2,0),Vector3(0.25,4,12),Color("b3ac8d"),true)
	box(self,pos+Vector3(0,2,5.9),Vector3(9,4,0.25),Color("b3ac8d"),true)
	add_sign(pos+Vector3(0,5,-5),"GARAGEM DO TRACTOR\nEntre pela frente, trave e saia com F")
func _build_warehouse() -> void:
	var pos := ground(WAREHOUSE)
	box(self,pos+Vector3(0,0.02,0),Vector3(8,0.1,9),Color("8b8170"))
	box(self,pos+Vector3(0,3.7,0),Vector3(9,0.3,10),Color("7e624c"),true)
	for side: float in [-1,1]: box(self,pos+Vector3(side*3.9,1.8,0),Vector3(0.2,3.6,9),Color("b4c09a"),true)
	box(self,pos+Vector3(0,1.8,4.4),Vector3(8,3.6,0.2),Color("b4c09a"),true)
	for i: int in range(6):
		var crate := box(self,pos+Vector3((i%3)*1.5-1.5,0.5+(i/3)*0.9,2.8),Vector3(1.2,0.8,1),Color("ad8150"))
		_cargo_boxes.append(crate)
	add_sign(pos+Vector3(0,4.6,-3),"ARMAZÉM DE ALIMENTOS\nL · Guardar | U · Retirar (5 por vez)")
func _build_neighbor(index: int) -> void:
	var pos: Vector3 = ground(FARM_CENTERS[index])
	var width := 8.0 + index*5
	var length := 9.0 + index*4
	var mesh: ArrayMesh = CropVisualFactory.mesh_for([&"wheat",&"corn",&"potato"][index],4)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	var columns := 7+index*4
	var rows := 7+index*3
	multi.instance_count = columns*rows
	for row: int in range(rows):
		for col: int in range(columns):
			var sample := Vector3(pos.x-width/2+0.6+col*(width-1)/columns,0,pos.z-10-row*(length-1)/rows)
			sample.y = guide._ground(sample)
			multi.set_instance_transform(row*columns+col,Transform3D(Basis.IDENTITY,sample))
	var plants := MultiMeshInstance3D.new()
	plants.multimesh = multi
	add_child(plants)
	# Barn, hay bales, water tanks and timber distinguish the resources of each farm.
	box(self,pos+Vector3(width/2+4,1.6,-4),Vector3(5+index*2,3.2,7),Color("93634c"),true)
	box(self,pos+Vector3(width/2+4,3.5,-4),Vector3(6+index*2,0.3,8),Color("4c5e53"))
	for i: int in range(2+index*3):
		box(self,pos+Vector3(-width/2-3,0.5,i*1.1-4),Vector3(1.8,0.9,0.9),Color("cbb25b"))
	_stock_labels.append(add_sign(pos+Vector3(0,6,0),""))
	for driving: bool in [false,true]:
		var worker := preload("res://Scripts/guided/FarmWorker.gd").new()
		worker.guide = guide
		worker.village = self
		worker.farm_index = index
		worker.driving = driving
		var half_width := width/2+2
		var back := -length-12
		worker.route = PackedVector3Array([pos+Vector3(-half_width,0,-8),pos+Vector3(-half_width,0,back),pos+Vector3(half_width,0,back),pos+Vector3(half_width,0,-8)]) if driving else PackedVector3Array([pos+Vector3(-3,0,-4),pos+Vector3(3,0,-4),pos+Vector3(3,0,-8),pos+Vector3(-3,0,-8)])
		add_child(worker)
		worker.global_position = ground(worker.route[0])
func production_phase(index: int) -> String:
	var minute: int = GameManager.session.time.get_total_minutes()%240
	var offset: int = (minute+index*60)%240
	if offset < 60:return "A preparar a terra"
	if offset < 120:return "A semear"
	if offset < 200:return "A cuidar das culturas"
	return "A colher e guardar alimentos"
func _process(delta: float) -> void:
	if not is_instance_valid(guide) or guide.data == null: return
	_timer += delta
	if _timer < 1: return
	_timer = 0
	if not guide.data.guide.has("village_stocks"):
		guide.data.guide.village_stocks = [{"food":12,"seeds":30,"cycle":0},{"food":35,"seeds":80,"cycle":0},{"food":80,"seeds":160,"cycle":0}]
	var cycle: int = GameManager.session.time.get_total_minutes()/240
	for i: int in range(3):
		var stock: Dictionary = guide.data.guide.village_stocks[i]
		if int(stock.cycle) == 0: stock.cycle = cycle
		if cycle > int(stock.cycle):
			stock.food = mini(999,int(stock.food)+(cycle-int(stock.cycle))*(6+i*8))
			stock.seeds = mini(999,int(stock.seeds)+(cycle-int(stock.cycle))*(12+i*10))
			stock.cycle = cycle
		_stock_labels[i].text = "FAZENDA %s\nAlimentos: %d · Sementes: %d\n%s · F para falar com os trabalhadores" % [FARM_NAMES[i],int(stock.food),int(stock.seeds),production_phase(i)]
	var vehicle: Node3D = null
	for candidate: Node3D in get_tree().get_nodes_in_group("vehicle"):
		if candidate.entity_data != null and candidate.entity_data.definition_id == &"vehicle.truck":
			vehicle = candidate
			break
	if vehicle != null and vehicle.entity_data != null and vehicle.entity_data.definition_id == &"vehicle.truck":
		var distance := Vector2(vehicle.global_position.x-GARAGE.x,vehicle.global_position.z-GARAGE.z)
		guide.data.guide["tractor_parked"] = absf(distance.x)<4 and absf(distance.y)<6 and vehicle.linear_velocity.length()<1
	if guide.data.guide.get("tractor_parked",false) and int(guide.data.guide.mission) == 7:
		guide.data.guide.mission = 8
		guide.notify("Tractor estacionado! Visite uma fazenda vizinha e fale com um trabalhador [F].")
	for i: int in range(_cargo_boxes.size()): _cargo_boxes[i].visible = i < mini(6,int(guide.data.guide.get("warehouse_food",0)))
func transfer(deposit: bool) -> void:
	var here: Vector3 = guide.player.global_position
	var storage := ""
	var capacity := 200
	if Vector2(here.x-WAREHOUSE.x,here.z-WAREHOUSE.z).length() < 7:
		storage = "warehouse_food"
	else:
		for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
			if vehicle.entity_data != null and vehicle.entity_data.definition_id == &"vehicle.van" and vehicle.global_position.distance_to(here)<6:
				storage = "van_food"
				capacity = 30
	if storage.is_empty():
		guide.notify("Aproxime-se do armazém ou da carrinha. L guarda; U retira alimentos.");return
	var available := int(guide.data.guide.get("food",0)) if deposit else int(guide.data.guide.get(storage,0))
	var amount := mini(5,available)
	if deposit: amount = mini(amount,capacity-int(guide.data.guide.get(storage,0)))
	if amount <= 0:
		guide.notify("Sem alimentos para transferir, ou o destino está cheio.");return
	ProduceInventory.transfer(guide.data,"food" if deposit else storage,storage if deposit else "food",amount)
	if deposit and storage == "warehouse_food" and int(guide.data.guide.mission) == 5: guide.data.guide.mission = 6
	if deposit and storage == "van_food" and int(guide.data.guide.mission) == 6: guide.data.guide.mission = 7
	guide.notify("%s %d alimentos %s. Guardados: %d/%d." % ["Guardou" if deposit else "Retirou",amount,"no armazém" if storage=="warehouse_food" else "na carrinha",int(guide.data.guide[storage]),capacity])
func talk(index: int) -> void:
	EventBus.neighbor_dialogue_requested.emit(index)
	if not guide.data.guide.has("village_stocks"): return
	if int(guide.data.guide.mission) == 8: guide.data.guide.mission = 9
	var stock: Dictionary = guide.data.guide.village_stocks[index]
	var day: int = GameManager.session.time.current_day
	var key := "neighbor_gift_%d" % index
	if int(guide.data.guide.get(key,0)) == day:
		guide.notify("%s: estamos a trabalhar. Volte amanhã para receber mais provisões." % FARM_NAMES[index]);return
	var food := mini(2+index,int(stock.food))
	var seeds := mini(5+index*3,int(stock.seeds))
	stock.food = int(stock.food)-food
	stock.seeds = int(stock.seeds)-seeds
	guide.data.guide.food = int(guide.data.guide.food)+food
	guide.data.guide.seeds = int(guide.data.guide.seeds)+seeds
	guide.data.guide[key] = day
	guide.notify("%s: bem-vindo! Aqui tem %d alimentos e %d sementes. Produzimos a cada 4 minutos." % [FARM_NAMES[index],food,seeds])

func _build_satellite(owner: int, center: Vector3) -> void:
	var pos := ground(center)
	var kit := MeshWorkshop.new()
	kit.box(Vector3(0,1.3,0),Vector3(6,2.6,5),Color("b99a78"))
	kit.box(Vector3(0,2.75,0),Vector3(7,0.18,6),Color("5d7771"))
	kit.box(Vector3(0,0.9,-2.52),Vector3(1.3,1.8,0.08),Color("465855"))
	kit.rod(Vector3(6,0,0),Vector3(6,2.5,0),0.9,Color("aabcb3"))
	var shed := MeshInstance3D.new()
	shed.mesh = kit.finish()
	shed.position = pos
	add_child(shed)
	add_sign(pos+Vector3.UP*4,"MACHAMBA %s\nParcela de %s · regadio comunitário" % [["DO RIO","DA ACÁCIA","DO PLANALTO"][owner],NeighborOrders.NAMES[owner]])
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = CropVisualFactory.mesh_for([&"tomato",&"corn",&"lettuce"][owner],4)
	multi.instance_count = 144
	for row: int in range(12):
		for col: int in range(12):
			var sample := ground(pos+Vector3(col*1.1-6,0,-8-row*1.1))
			multi.set_instance_transform(row*12+col,Transform3D(Basis.IDENTITY,sample))
	var plants := MultiMeshInstance3D.new()
	plants.multimesh = multi
	add_child(plants)
	for driving: bool in [false,true]:
		var worker := preload("res://Scripts/guided/FarmWorker.gd").new()
		worker.guide = guide
		worker.village = self
		worker.farm_index = owner
		worker.driving = driving
		worker.route = PackedVector3Array([pos+Vector3(-9,0,-6),pos+Vector3(-9,0,-24),pos+Vector3(9,0,-24),pos+Vector3(9,0,-6)]) if driving else PackedVector3Array([pos+Vector3(-4,0,-7),pos+Vector3(-4,0,-13),pos+Vector3(4,0,-13),pos+Vector3(4,0,-7)])
		add_child(worker)
		worker.global_position = ground(worker.route[0])
