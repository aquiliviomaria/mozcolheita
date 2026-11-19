extends Control
var guide: Node
const ORIGIN := Vector2(-10, -5)
const SCALE := 1.7
func map_pos(world: Vector3) -> Vector2:
	return Vector2((world.x - ORIGIN.x) * SCALE, (world.z - ORIGIN.y) * SCALE)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("314a36"))
	for x: int in range(0, 501, 42): draw_line(Vector2(x, 0), Vector2(x, 420), Color("48604a"))
	for y: int in range(0, 421, 42): draw_line(Vector2(0, y), Vector2(500, y), Color("48604a"))
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(map_pos(Vector3(72,0,92)), Vector2(48,22)*SCALE),Color("63754d"))
	draw_string(font,map_pos(Vector3(72,0,90)),"Produção",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
	draw_circle(map_pos(Vector3(136,0,151)),5,Color("79e3be"))
	draw_rect(Rect2(map_pos(Vector3(98,0,119)), Vector2(14,14) * SCALE), Color("93764c"))
	draw_string(font, map_pos(Vector3(98,0,118)), "Horta", HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	if guide.farm != null:
		for grid: Vector2i in guide.farm._grid:
			var pos := map_pos(Vector3(grid.x, 0, grid.y))
			if not Rect2(Vector2.ZERO, size).has_point(pos): continue
			var state: int = guide.farm.get_tile_data(grid).state
			var color := Color("b49a71") if state == 1 else Color("f6d465") if state == 3 else Color("78b762")
			draw_rect(Rect2(pos, Vector2(SCALE, SCALE)), color)
	for entry: Array in [[Vector3(25,0,210), "Do Rio"], [Vector3(235,0,130), "Da Acácia"], [Vector3(90,0,35), "Do Planalto"], [Vector3(104,0,145), "Casa"], [Vector3(38,0,75), "Aurora"], [Vector3(210,0,60), "Vale Verde"], [Vector3(212,0,208), "Boa Colheita"], [Vector3(113,0,139), "Poço"], [Vector3(122,0,151), "Garagem"], [Vector3(87,0,145), "Armazém"]]:
		var pos := map_pos(entry[0])
		draw_rect(Rect2(pos - Vector2(7, 7), Vector2(14, 14)), Color("e5c095"))
		draw_string(font, pos + Vector2(10, -5), entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	for vehicle: Node3D in get_tree().get_nodes_in_group("vehicle"):
		draw_circle(map_pos(vehicle.global_position), 6, Color("ee9e48"))
	for worker: Node3D in get_tree().get_nodes_in_group("farm_workers"):
		draw_circle(map_pos(worker.global_position), 3, Color("dadadb"))
	if is_instance_valid(guide.player):
		var pos := map_pos(guide.player.global_position)
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0,-9), pos + Vector2(-6,6), pos + Vector2(6,6)]), Color("72ecdf"))
		if not Rect2(Vector2.ZERO, size).has_point(pos):
			draw_string(font, Vector2(15,400), "Está fora da área local. Casa: x105 / z145", HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
