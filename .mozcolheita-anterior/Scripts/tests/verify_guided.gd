extends Node
var failures: Array[String] = []
func check(condition: bool, text: String) -> void:
	if not condition:
		failures.append(text)
		push_error(text)
func _ready() -> void:
	var guide := preload("res://Scripts/guided/FarmGuide.gd").new()
	add_child(guide)
	guide.data = GameManager.session.entities.get_player()
	guide.farm = GameManager.session.farm
	var farm: FarmData = guide.farm
	var grid := Vector2i(103, 125)
	check(farm.can_plow_at(Vector3(103,0,125)), "Horta deve permitir cultivo")
	check(not farm.plant_crop(grid), "Semear na relva deve falhar")
	farm.set_tile_state(grid, FarmData.SoilState.PLOWED, 29)
	check(farm.plant_crop(grid, &"generic", FarmData.DEFAULT_CROP_GROWTH_MINUTES, 29), "Semear em terra preparada")
	check(farm.harvest_crop(grid).is_empty(), "Não colher antes de amadurecer")
	GameManager.session.time.fast_forward_minutes(240, true)
	check(farm.get_tile_data(grid).state == FarmData.SoilState.HARVESTABLE, "Crescimento ao descansar")
	check(not farm.harvest_crop(grid).is_empty(), "Colheita madura deve produzir alimento")
	check(farm.harvest_crop(grid).is_empty(), "Não duplicar colheita")
	farm.set_tile_state(Vector2i(104,125), FarmData.SoilState.PLOWED, 12.5)
	farm.plant_crop(Vector2i(104,125), &"generic", 300, 12.5)
	var exact: Dictionary = farm.export_exact_tiles()
	farm.clear_runtime_state()
	farm.import_exact_tiles(exact)
	check(farm.get_tile_data(Vector2i(104,125)).growth_minutes_required == 300, "Duração individual de crescimento preservada")
	check(farm.get_tile_data(Vector2i(104,125)).height == 12.5 and farm.get_tile_data(grid).state == FarmData.SoilState.PLOWED, "Parcelas vizinhas e altura preservadas")
	guide.data.calories = 300
	guide.data.guide.food = 1
	guide.data.guide.mission = 3
	guide.eat()
	check(guide.data.calories == 650 and guide.data.guide.food == 0, "Comer deve consumir alimento")
	check(guide.data.guide.mission == 4, "Missão avança ao comer")
	guide.eat()
	check(guide.data.calories == 650, "Sem alimento não recupera comida")
	guide._toggle_window(guide.map_panel)
	check(get_tree().paused and guide.blocks_gameplay(), "Mapa deve pausar e bloquear movimentos")
	guide._toggle_window(guide.map_panel)
	check(not get_tree().paused and not guide.blocks_gameplay(), "Fechar mapa retoma jogo")
	var metadata: Dictionary = SaveManager._build_metadata(98, {})
	check(metadata.player.guide.mission == 4, "Metadados incluem missões")
	guide.data.guide.mission = 0
	# Copy payload to avoid references affecting the snapshot.
	metadata.player.guide = {"mission": 4, "character": 2, "tractor": 1, "health": 73.0, "food": 5, "seeds": 20, "harvests": 7}
	SaveManager._restore_player(metadata)
	check(guide.data.guide.mission == 4 and guide.data.guide.character == 2 and guide.data.guide.health == 73.0, "Carregar restaura progresso e personalização")
	print("GUIDED_TESTS: ", "PASS" if failures.is_empty() else "FAIL: " + str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
