extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,descricao: String) -> void:
	if valor: print("OK · ",descricao)
	else: falhas += 1; push_error(descricao)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.partida.caminho = "user://teste-retoma-equipa.mozsave"
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	for carro: Node3D in mundo.comunidade.trafego: carro.set_physics_process(false)
	for tractor: Node3D in mundo.tratores: tractor.ocupado = true
	mundo.entregas.aceitar(1,0,0)
	var quantidade: int = mundo.entregas.activas[1].quantidade
	var proposta: Dictionary = mundo.equipa_grupo.orcamento(1,5)
	exigir(mundo.equipa_grupo.confirmar(proposta),"Equipa para encomenda pequena confirmada")
	for i: int in range(5):
		var pessoa: Node3D = mundo.equipa_grupo.trabalhadores[i]; pessoa.position = Vector3(2+i*3,mundo.altura(Vector3(2+i*3,0,-12))+0.1,-12); pessoa.set_physics_process(true)
	Engine.time_scale = 8
	for i: int in range(400):
		await physics_frame
		if mundo.equipa_grupo.fase>=1: break
	exigir(not mundo.terreno.celulas.is_empty(),"Trabalhadores executam trabalho físico antes de guardar")
	var antes: int = mundo.saldo; var gasto: int = mundo.equipa_grupo.gasto
	exigir(mundo.partida.guardar(false),"Guardar a meio do trabalho")
	exigir(mundo.partida.carregar() and mundo.saldo==antes and mundo.equipa_grupo.gasto==gasto,"Retomar a meio não repete pagamento nem perde progresso")
	Engine.time_scale = 8; var saltou: bool = false
	for i: int in range(6000):
		await physics_frame
		if mundo.equipa_grupo.fase==3 and not saltou: mundo.calendario.saltar(3); saltou = true
		if mundo.equipa_grupo.plano.is_empty(): break
	exigir(mundo.equipa_grupo.plano.is_empty() and int(mundo.caminhao.carga.get(1,0))==quantidade,"Após retomar, equipa conclui cultivo e carrega o pedido real")
	exigir(not bool(mundo.entregas.activas[1].falhou),"Trabalho retomado respeita prazo da encomenda")
	mundo.calendario.amanhecer.stop(); mundo.feedback.audio.stop(); mundo.contrato.som.stop(); Engine.time_scale = 1
	await create_timer(0.1).timeout
	for sufixo: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(mundo.partida.caminho+sufixo): DirAccess.remove_absolute(mundo.partida.caminho+sufixo)
	print("RETOMA EQUIPA · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
