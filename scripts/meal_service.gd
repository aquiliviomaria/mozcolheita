extends Node
## Preparação, transporte e serviço antes de consumir uma única porção.
var lar: Node3D
var fase: String = ""
var tempo: float = 0
var travessa: Node3D
func activo() -> bool: return not fase.is_empty()
func iniciar() -> void:
	cancelar()
	if not lar.tem_comida(): lar.mundo.avisar("Sem comida na cozinha."); return
	fase = "cozinha"; tempo = 0; lar.familia().chamar("cozinhar")
func cancelar() -> void:
	fase = ""; tempo = 0
	if is_instance_valid(travessa): travessa.queue_free()
	if is_instance_valid(lar.comida): lar.comida.servir(false)
func criar_travessa() -> void:
	travessa = Node3D.new(); lar.familia().pessoa.visual.add_child(travessa); travessa.position = Vector3(0,1.0,-0.48)
	lar.comida.prato(travessa,Vector3.ZERO)
	travessa.scale = Vector3.ONE*0.65
	for i: int in range(4): lar.comida.oval(travessa,Vector3(-0.15+i*0.1,0.09,0),Vector3(0.15,0.13,0.2),"e2bd42")
func _process(delta: float) -> void:
	if not activo() or lar.mundo.pausado(): return
	if lar.estado!="sentado": cancelar(); return
	var f: Node3D = lar.familia()
	match fase:
		"cozinha":
			if f.actividade!="cozinhar": f.chamar("cozinhar")
			if not f.pronta: return
			tempo += delta/maxf(1,Engine.time_scale)
			f.pessoa.animacao("planting",0.3); f.pessoa.animar(delta,0)
			if tempo>=2.5: criar_travessa(); fase = "servir"; f.chamar("servir")
		"servir":
			if f.actividade!="servir": f.chamar("servir")
			if not f.pronta: return
			if is_instance_valid(travessa): travessa.queue_free()
			lar.comida.servir(true); fase = "sentar"; f.chamar("mesa")
		"sentar":
			if f.actividade=="mesa" and f.pronta:
				fase = "comer"; lar.comer(true)
