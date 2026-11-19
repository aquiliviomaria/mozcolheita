extends Control
var world_position := Vector3.ZERO
func _draw() -> void:
	var center := size*0.5
	draw_line(Vector2(12,center.y),Vector2(size.x-12,center.y),Color("3a5056"))
	draw_line(Vector2(center.x,5),Vector2(center.x,size.y-5),Color("3a5056"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(center.x-4,12),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("a3b4b4"))
	for entry: Array in [[Vector3(104,0,145),"Casa"],[Vector3(87,0,145),"Armazém"],[Vector3(122,0,151),"Garagem"],[Vector3(38,0,75),"Vizinho"],[Vector3(210,0,60),"Vizinho"],[Vector3(212,0,208),"Vizinho"],[Vector3(136,0,151),"Equipamento"]]:
		var delta: Vector2 = Vector2(entry[0].x-world_position.x,entry[0].z-world_position.z)*1.5
		var pos: Vector2 = center+delta.limit_length(65)
		pos.x = clampf(pos.x,22,size.x-40)
		pos.y = clampf(pos.y,22,size.y-15)
		draw_circle(pos,5,Color("405957"))
		draw_string(font,pos+Vector2(-3,3),entry[1].substr(0,1),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e9cb82"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-6),center+Vector2(-4,4),center+Vector2(4,4)]),Color("7bdbb1"))
