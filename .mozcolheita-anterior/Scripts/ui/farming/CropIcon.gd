class_name CropIcon
extends Control
var crop_id: StringName = &"tomato":
	set(value): crop_id = value; queue_redraw()
var active := true:
	set(value): active = value; queue_redraw()
func _ready() -> void:
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var c: Color = CropCatalog.get_crop(crop_id).color
	if not active: c = c.darkened(0.4)
	var center := size*0.5
	var s := minf(size.x, size.y)/32.0
	draw_set_transform(center, 0, Vector2.ONE*s)
	match crop_id:
		&"tomato":
			draw_circle(Vector2(0,3), 9, c)
			for i: int in range(5):
				var point := Vector2.from_angle(i*TAU/5)*7
				draw_line(Vector2(0,-4), point+Vector2(0,-4), Color("75b97c"), 3, true)
		&"corn":
			draw_ellipse_shape(Vector2.ZERO, Vector2(6,12), c)
			for x: int in [-3,0,3]: draw_line(Vector2(x,-8),Vector2(x,8), c.darkened(0.2),1,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-2,11),Vector2(-11,-2),Vector2(-8,11)]),Color("67a56f"))
		&"lettuce":
			for i: int in range(6): draw_circle(Vector2.from_angle(i*TAU/6)*5,6,c.darkened(0.12 if i%2==0 else 0))
			draw_circle(Vector2.ZERO,5,c.lightened(0.14))
		&"carrot":
			draw_colored_polygon(PackedVector2Array([Vector2(-6,-4),Vector2(6,-4),Vector2(-2,13)]),c)
			for i: int in [-1,0,1]: draw_line(Vector2(0,-4),Vector2(i*6,-13),Color("78b57d"),3,true)
		&"potato":
			draw_ellipse_shape(Vector2.ZERO,Vector2(10,8),c)
			for point: Vector2 in [Vector2(-4,-2),Vector2(3,3),Vector2(5,-3)]: draw_circle(point,1.2,c.darkened(0.3))
		_:
			draw_line(Vector2(0,13),Vector2(0,-12),c,2,true)
			for y: int in [-7,-2,3]:
				draw_line(Vector2(0,y+4),Vector2(-6,y-1),c,4,true)
				draw_line(Vector2(0,y+2),Vector2(6,y-3),c,4,true)
func draw_ellipse_shape(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(20): points.append(center+Vector2.from_angle(i*TAU/20)*radius)
	draw_colored_polygon(points,color)
