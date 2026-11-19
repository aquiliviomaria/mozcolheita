extends Node
## Counters and reward claims are persisted with PlayerData. Claims are idempotent.
const JOBS := [
	["Terra aberta", "plow", 12, 24],
	["Produção em linhas", "plant", 12, 30],
	["Água para a machamba", "irrigate", 12, 24],
	["Celeiro cheio", "harvest", 10, 40],
	["Uma equipa local", "hire", 1, 16]
]
var guide: Node
func record(kind: String, amount: int = 1) -> void:
	if guide.data == null or amount<=0: return
	var state: Dictionary = guide.data.guide.get("production_missions",{})
	state[kind] = int(state.get(kind,0))+amount
	guide.data.guide.production_missions = state
	for job: Array in JOBS:
		var claim := "paid_"+str(job[1])
		if int(state.get(job[1],0))>=int(job[2]) and not state.get(claim,false):
			state[claim] = true
			guide.data.guide.money = int(guide.data.guide.get("money",0))+int(job[3])
			guide.notify("Missão concluída: %s · +%d MT" % [job[0],job[3]])
func summary() -> String:
	var state: Dictionary = guide.data.guide.get("production_missions",{})
	var lines: PackedStringArray = []
	for job: Array in JOBS:
		if not state.get("paid_"+str(job[1]),false):
			lines.append("%s · %d/%d · %d MT" % [job[0],mini(int(state.get(job[1],0)),job[2]),job[2],job[3]])
			if lines.size()==2: break
	return "MISSÕES · " + "\n".join(lines) if not lines.is_empty() else "Todas as missões de produção concluídas!"
