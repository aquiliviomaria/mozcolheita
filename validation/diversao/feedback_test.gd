extends SceneTree
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,descricao: String) -> void:
	if valor: print("OK · ",descricao)
	else: falhas += 1; push_error(descricao)
func executar() -> void:
	var mundo: Node3D = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.jogador.position = Vector3(12,mundo.altura(Vector3(12,0,-7)),-7)
	await process_frame
	var chave: Vector2i = Vector2i(12,-4)
	var emitidos: int = mundo.feedback.emitidos
	for acao: String in ["lavrar","semear","regar"]:
		mundo.feedback.espera = 0
		exigir(mundo.terreno.trabalhar(chave,acao),"Acção válida com feedback: "+acao)
	mundo.terreno.avancar(mundo.terreno.DURACAO)
	mundo.feedback.espera = 0
	exigir(mundo.terreno.trabalhar(chave,"colher"),"Colheita real continua a produzir")
	exigir(mundo.feedback.emitidos==emitidos+4 and int(mundo.sacola.get(0,0))==3,"Efeitos acompanham as quatro acções sem duplicar produção")
	var anterior: int = mundo.feedback.emitidos
	mundo.feedback.espera = 0
	exigir(not mundo.terreno.trabalhar(chave,"colher") and mundo.feedback.emitidos==anterior,"Acção inválida não produz recompensa nem efeito")
	mundo.feedback.mostrar(chave,"lavrar",0); mundo.feedback.mostrar(chave,"semear",0)
	exigir(mundo.feedback.emitidos==anterior+1,"Limite de frequência impede ruído nas máquinas de várias linhas")
	exigir(mundo.feedback.particulas.size()==6 and mundo.feedback.textos.size()==6,"Efeitos reutilizam um conjunto limitado")
	mundo.feedback.espera = 0; mundo.feedback.mostrar(Vector2i(-80,60),"lavrar",0)
	exigir(mundo.feedback.emitidos==anterior+1,"Trabalho distante não cria sons nem texto junto ao jogador")
	mundo.feedback._process(2)
	var apagados: bool = true
	for rotulo: Label3D in mundo.feedback.textos:
		if rotulo.visible: apagados = false
	exigir(apagados,"Textos temporários desaparecem")
	mundo.feedback.audio.stop(); await create_timer(0.1).timeout
	print("FEEDBACK · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(0 if falhas==0 else 1)
