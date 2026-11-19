class_name FarmTheme
extends RefCounted
const INK := Color("101d27ed")
const BORDER := Color("344750")
const TEXT := Color("edf2ed")
const MUTED := Color("a3b4b4")
const ACCENT := Color("7bdbb1")
const GOLD := Color("e9cb82")
const DANGER := Color("e87972")
static func panel(color: Color = INK, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = BORDER
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
static func bar(color: Color) -> StyleBoxFlat:
	var style := panel(color,3)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
static func compact_button(color: Color) -> StyleBoxFlat:
	var style := panel(color,7)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
static func build() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	result.set_color("font_color", "Label", TEXT)
	result.set_color("font_color", "Button", TEXT)
	result.set_color("font_hover_color", "Button", ACCENT)
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_stylebox("normal", "Button", panel(Color("20323a"), 8))
	result.set_stylebox("hover", "Button", panel(Color("2f4549"), 8))
	result.set_stylebox("pressed", "Button", panel(Color("385b51"), 8))
	result.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	result.set_stylebox("normal", "OptionButton", panel(Color("20323a"), 8))
	result.set_stylebox("hover", "OptionButton", panel(Color("2f4549"), 8))
	result.set_stylebox("background", "ProgressBar", bar(Color("31434a")))
	var fill := bar(ACCENT)
	fill.set_border_width_all(0)
	result.set_stylebox("fill", "ProgressBar", fill)
	return result

## Portuguese grouping keeps large farm balances readable without abbreviating value.
static func money(amount: int) -> String:
	var digits := str(absi(amount))
	var groups: PackedStringArray = []
	while digits.length()>3:
		groups.insert(0,digits.right(3))
		digits = digits.left(digits.length()-3)
	groups.insert(0,digits)
	return ("-" if amount<0 else "")+".".join(groups)+" MT"
