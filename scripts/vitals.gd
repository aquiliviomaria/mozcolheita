extends Node
## Ritmo suave: necessidades avançam com a simulação e são guardadas na quinta.
var mundo: Node3D
var vida: float = 100
var fome: float = 100
var energia: float = 100
var higiene: float = 100
func _process(delta: float) -> void:
	if mundo.pausado(): return
	fome = maxf(0,fome-delta*0.018)
	higiene = maxf(0,higiene-delta*0.008)
	var correr: bool = mundo.trator_actual==null and mundo.drone_actual==null and mundo.jogador.velocity.length()>5
	energia = clampf(energia+delta*(-0.12 if correr else 0.08),0,100)
	if fome<=0: vida = maxf(20,vida-delta*0.015)
	elif fome>60: vida = minf(100,vida+delta*0.04)
func comer() -> bool:
	if mundo.pausado() or mundo.trator_actual!=null or mundo.drone_actual!=null: return false
	if fome>=99 and vida>=99 and energia>=99: mundo.avisar("Já está alimentado e descansado."); return false
	var origem: Dictionary = mundo.sacola
	if origem.is_empty() and mundo.armazem.perto(): origem = mundo.stock
	for cultura: int in [0,3,2,1]:
		if int(origem.get(cultura,0))<=0: continue
		origem[cultura] = int(origem[cultura])-1
		if origem[cultura]==0: origem.erase(cultura)
		alimentar()
		mundo.armazem.actualizar(1); mundo.avisar("Refeição · alimentação +35 · energia +30"); return true
	mundo.avisar("J · Tenha um produto consigo ou aproxime-se do armazém."); return false

func alimentar() -> void:
	fome = minf(100,fome+35); energia = minf(100,energia+30); vida = minf(100,vida+10)
