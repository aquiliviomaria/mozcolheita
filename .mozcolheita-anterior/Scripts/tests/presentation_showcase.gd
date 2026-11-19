extends Node3D
## Isolated studio for visual QA, not a gameplay scene.
func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b7cac3")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e8f2e8")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30,30)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c3d1c2")
	ground.material_override = material
	add_child(ground)
	for i: int in range(6):
		var crop := MeshInstance3D.new()
		crop.mesh = CropVisualFactory.mesh_for(CropCatalog.IDS[i],4)
		crop.position = Vector3((i%3)*1.5-2,0,(i/3)*1.9-0.4)
		add_child(crop)
		var label := Label3D.new()
		label.text = CropCatalog.get_crop(CropCatalog.IDS[i]).name
		label.font_size = 32
		label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("314e4c")
		label.position = crop.position+Vector3(0,0.08,0.48)
		add_child(label)
	for i: int in range(3):
		var human := ModularHuman.new()
		human.variant = i
		human.position = Vector3(-3.4+i*0.9,0,-2.4)
		human.rotation.y = -0.25
		add_child(human)
	var tractor := ModernTractor.new()
	tractor.position = Vector3(3,0.75,-1.2)
	tractor.rotation.y = -0.7
	add_child(tractor)
	var driver := ModularHuman.new()
	driver.seated = true
	driver.position = Vector3(0,0.3,0.75)
	tractor.add_child(driver)
	var camera := Camera3D.new()
	camera.position = Vector3(7.5,5.6,-9)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.8
	add_child(camera)
	camera.look_at(Vector3(0,0.75,-0.5))
	for i: int in range(6): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/openacre-overhaul-estudio.png")
	camera.position = Vector3(-2.4,1.45,-5.4)
	camera.size = 2.8
	camera.look_at(Vector3(-2.5,1,-2.4))
	for i: int in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/mozcolheita-character-review.png")
	camera.position = tractor.to_global(Vector3(-4,2.5,-4))
	camera.size = 4.0
	camera.look_at(tractor.to_global(Vector3(0,1.25,0.4)))
	for i: int in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/mozcolheita-driver-review.png")
	camera.position = Vector3(7.5,5.6,-9)
	camera.size = 7.8
	camera.look_at(Vector3(0,0.75,-0.5))
	var hud := preload("res://Scripts/ui/farming/ModernFarmHUD.gd").new()
	add_child(hud)
	var snapshot := {"health":94,"hunger":72,"water":83,"energy":61,"day":3,"hour":8,"minute":24,"money":500_000,"seeds":22,"food":8,"stored":15,"cargo":6,"produce":{"tomato":3,"corn":2},"objective":"3. Fazer a primeira colheita\nAs culturas crescem em quatro minutos. Aproxime-se de uma planta com [R] e prima R para colher.","mission":2,"quest":"ENCOMENDA · Ana\nTomates 3 / 3 · Recompensa 24 MT","hint":"[R] R · Colher Tomates","tool":"seed","driving":false,"position":Vector3(105,29,130),"location":"A SUA FAZENDA"}
	EventBus.farm_hud_updated.emit(snapshot)
	hud.toast_label.text = "+3 Tomates · +2 sementes"
	for i: int in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/openacre-overhaul-interface.png")
	snapshot.driving = true
	snapshot.tractor = true
	snapshot.vehicle = "TRACTOR · 0 km/h · Mudança 1\nCombustível 100%\nSemeadora · acoplada\n7/8/9 · Equipamento   P · Acoplar\nV · Baixar   B · Ligar   K · Água"
	snapshot.hint = "WASD · Conduzir   Espaço · Travar\nF · Sair   Y · Faróis"
	snapshot.production = "MISSÕES · Terra aberta · 8/12 · 24 MT\nProdução em linhas · 2/12 · 30 MT"
	EventBus.farm_hud_updated.emit(snapshot)
	for i: int in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/mozcolheita-controls-review.png")
	get_tree().quit()
