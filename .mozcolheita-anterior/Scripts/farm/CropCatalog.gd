class_name CropCatalog
extends RefCounted
## Authoritative crop definitions. Visuals and UI consume this catalogue, never vice versa.
const IDS: Array[StringName] = [&"tomato", &"corn", &"lettuce", &"carrot", &"potato", &"wheat"]
const DEFINITIONS := {
	"tomato": {"name": "Tomate", "plural": "Tomates", "color": Color("e96f60"), "yield": 3, "minutes": 240, "height": 1.05},
	"corn": {"name": "Milho", "plural": "Espigas de milho", "color": Color("efc75e"), "yield": 2, "minutes": 240, "height": 1.85},
	"lettuce": {"name": "Alface", "plural": "Alfaces", "color": Color("9cc77b"), "yield": 2, "minutes": 240, "height": 0.4},
	"carrot": {"name": "Cenoura", "plural": "Cenouras", "color": Color("edab65"), "yield": 4, "minutes": 240, "height": 0.55},
	"potato": {"name": "Batata", "plural": "Batatas", "color": Color("c9ae84"), "yield": 3, "minutes": 240, "height": 0.65},
	"wheat": {"name": "Trigo", "plural": "Feixes de trigo", "color": Color("d9bc72"), "yield": 4, "minutes": 240, "height": 1.1}
}
static func normalize_id(id: StringName) -> StringName:
	return &"wheat" if id == &"generic" else id if IDS.has(id) else &"tomato"
static func get_crop(id: StringName) -> Dictionary:
	return DEFINITIONS[String(normalize_id(id))]
static func stage(progress: float, harvestable: bool = false) -> int:
	if harvestable: return 4
	if progress < 0.08: return 0
	if progress < 0.28: return 1
	if progress < 0.6: return 2
	return 3
static func stage_name(index: int) -> String:
	return ["Semente", "Broto", "Planta jovem", "A amadurecer", "Pronto para colher"][clampi(index, 0, 4)]
