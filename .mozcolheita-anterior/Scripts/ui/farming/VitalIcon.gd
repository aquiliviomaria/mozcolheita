extends Control
## Small vector icons remain sharp at any viewport scale; no font glyph dependency.
var kind := "health"
var value := 100.0:
	set(next):
		value = clampf(next,0,100)
		queue_redraw()
func _ready() -> void:
	custom_minimum_size = Vector2(30,30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var color := FarmTheme.DANGER if value<20 else FarmTheme.GOLD if value<40 else FarmTheme.ACCENT
	draw_arc(Vector2(15,15),13,-PI/2,TAU-PI/2,40,Color("34454b"),2,true)
	draw_arc(Vector2(15,15),13,-PI/2,-PI/2+TAU*maxf(value,0.1)/100,40,color,2,true)
	match kind:
		"health":
			draw_circle(Vector2(11,12),4,color)
			draw_circle(Vector2(19,12),4,color)
			draw_colored_polygon(PackedVector2Array([Vector2(7,13),Vector2(23,13),Vector2(15,23)]),color)
		"hunger":
			draw_line(Vector2(15,22),Vector2(15,8),color,2,true)
			for y: float in [11,15,19]:
				draw_line(Vector2(15,y),Vector2(10,y-3),color,3,true)
				draw_line(Vector2(15,y),Vector2(20,y-3),color,3,true)
		"water":
			draw_circle(Vector2(15,18),5,color)
			draw_colored_polygon(PackedVector2Array([Vector2(10,18),Vector2(15,6),Vector2(20,18)]),color)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(16,5),Vector2(9,16),Vector2(15,16),Vector2(13,25),Vector2(22,12),Vector2(16,12)]),color)
