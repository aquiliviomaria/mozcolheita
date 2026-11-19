class_name NeighborOrders
extends RefCounted
## Small persistent delivery quests. Rewards consume typed produce, so transfers cannot duplicate it.
const NAMES := ["Ana Mucavele", "Mateus Chissano", "Celina Mussa"]
const CROPS: Array[StringName] = [&"tomato", &"corn", &"wheat"]
const AMOUNTS := [3,4,6]
const REWARDS := [24,36,60]
static func offer(data: PlayerData, farm_index: int) -> Dictionary:
	var key := str(clampi(farm_index,0,2))
	var quests: Dictionary = data.guide.get("orders",{})
	var state: Dictionary = quests.get(key,{})
	var id: StringName = CROPS[int(key)]
	var amount: int = AMOUNTS[int(key)]
	var available: int = int(data.guide.get("produce",{}).get(String(id),0))
	if state.get("complete",false):
		return {"name": NAMES[int(key)], "text": "A entrega foi excelente, obrigado! Hoje vou continuar a cuidar da fazenda.\nPode visitar o armazém e conversar com os outros vizinhos.", "button":"Encomenda concluída", "action":"none", "enabled":false}
	var accepted: bool = state.get("accepted",false)
	return {"name": NAMES[int(key)] + " · Encomenda da fazenda", "text": "Preciso de %d %s para a próxima entrega.\nCultive na sua horta e traga os produtos no bolso. Pago %d MT.\nTem consigo: %d / %d." % [amount,CropCatalog.get_crop(id).plural,REWARDS[int(key)],available,amount], "button":"Entregar e receber %d MT" % REWARDS[int(key)] if accepted else "Aceitar encomenda", "action":"deliver" if accepted else "accept", "enabled":not accepted or available>=amount}
static func act(data: PlayerData, farm_index: int, action: String) -> bool:
	var key := str(clampi(farm_index,0,2))
	var quests: Dictionary = data.guide.get("orders",{})
	var state: Dictionary = quests.get(key,{})
	if state.get("complete",false): return false
	if action == "accept":
		state.accepted = true
	elif action == "deliver" and state.get("accepted",false):
		if not ProduceInventory.deliver(data,CROPS[int(key)],AMOUNTS[int(key)]): return false
		data.guide.money = int(data.guide.get("money",0))+REWARDS[int(key)]
		state.complete = true
	else: return false
	quests[key] = state
	data.guide.orders = quests
	return true
static func summary(data: PlayerData) -> String:
	var quests: Dictionary = data.guide.get("orders",{})
	for key: String in quests:
		var entry: Dictionary = quests[key]
		if entry.get("accepted",false) and not entry.get("complete",false):
			var id: StringName = CROPS[int(key)]
			var count := int(data.guide.get("produce",{}).get(String(id),0))
			return "ENCOMENDA · %s\n%s %d / %d · Recompensa %d MT" % [NAMES[int(key)],CropCatalog.get_crop(id).plural,count,AMOUNTS[int(key)],REWARDS[int(key)]]
	return ""
