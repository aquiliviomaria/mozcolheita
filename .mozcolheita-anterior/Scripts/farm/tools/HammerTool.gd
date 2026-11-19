extends Tool
func _init() -> void:
	tool_name = "Martelo"
func use_tool(player: CharacterBody3D, _block_pos: Vector3, _normal: Vector3) -> void:
	var guide := player.get_tree().get_first_node_in_group("farm_guide")
	if guide != null: guide.use_action("hammer")
