class_name ProduceInventory
extends RefCounted
## Typed produce is a subset of existing food totals, preserving older saves and rations.
static func pool_key(storage: String) -> String:
	return "produce" if storage == "food" else storage.trim_suffix("_food") + "_produce"
static func add_harvest(data: PlayerData, crop_id: StringName, amount: int) -> void:
	var produce: Dictionary = data.guide.get("produce", {})
	var key := String(CropCatalog.normalize_id(crop_id))
	produce[key] = int(produce.get(key, 0)) + amount
	data.guide.produce = produce
	data.guide.food = int(data.guide.food) + amount
static func take(data: PlayerData, storage: String, amount: int) -> Dictionary:
	var total: int = int(data.guide.get(storage, 0))
	var count: int = clampi(amount, 0, total)
	var pool: Dictionary = data.guide.get(pool_key(storage), {})
	var typed_total := 0
	for value: Variant in pool.values(): typed_total += int(value)
	var remaining := maxi(0, count - maxi(0, total - typed_total))
	var taken: Dictionary = {}
	for key: String in pool.keys():
		var removed: int = mini(remaining, int(pool[key]))
		if removed > 0:
			pool[key] = int(pool[key]) - removed
			taken[key] = removed
			remaining -= removed
	data.guide[pool_key(storage)] = pool
	data.guide[storage] = total - count
	return taken
static func transfer(data: PlayerData, source: String, destination: String, amount: int) -> void:
	var count := mini(amount, int(data.guide.get(source, 0)))
	var taken := take(data, source, count)
	var target: Dictionary = data.guide.get(pool_key(destination), {})
	for key: String in taken: target[key] = int(target.get(key, 0)) + int(taken[key])
	data.guide[pool_key(destination)] = target
	data.guide[destination] = int(data.guide.get(destination, 0)) + count
static func deliver(data: PlayerData, crop_id: StringName, amount: int) -> bool:
	var pool: Dictionary = data.guide.get("produce", {})
	var key := String(crop_id)
	if int(pool.get(key, 0)) < amount or int(data.guide.food) < amount: return false
	pool[key] = int(pool[key]) - amount
	data.guide.produce = pool
	data.guide.food = int(data.guide.food) - amount
	return true
