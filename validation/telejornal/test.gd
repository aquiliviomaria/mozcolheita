extends SceneTree
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func executar() -> void:
	var tv: Control = load("res://scripts/tv_program.gd").new(); root.add_child(tv); tv.set_process(false)
	var vistos: Dictionary = {}; var temas: Dictionary = {}
	for i: int in range(tv.NOTICIAS.size()):
		var n: Dictionary = tv.noticia_actual(); vistos[n.id] = true; temas[n.tema] = true
		exigir(not str(n.titulo).contains("LANCAMENTO"),"Sem anúncio de lançamento futuro")
		tv.proxima()
	exigir(vistos.size()==12 and temas.size()>=5,"Doze notícias variadas sem repetição na edição")
	var anterior: int = tv.actual
	tv._process(tv.DURACAO+0.01)
	exigir(tv.actual!=anterior,"Mudança automática ao fim de sete segundos")
	var sem_repeticao: bool = true
	for i: int in range(100):
		anterior = tv.actual; tv.proxima()
		sem_repeticao = sem_repeticao and tv.actual!=anterior
	exigir(sem_repeticao,"Cem transições sem repetição imediata entre edições")
	var dados: Node3D = Node3D.new(); dados.set_script(load("res://scripts/main.gd"))
	# Verifica actualização dos boletins com dados que mudam na própria partida.
	dados.stock = {0:12,1:8}
	var base: Dictionary = {"dinamica":"stock"}
	var a: Dictionary = tv.CATALOGO.actualizar(base,dados)
	dados.stock[0] = 99
	var b: Dictionary = tv.CATALOGO.actualizar(base,dados)
	exigir(a.linha1!=b.linha1 and str(b.linha1).contains("107"),"Boletim acompanha os produtos reais sem reiniciar a TV")
	dados.free()
	print("TELEJORNAL · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas"); quit(falhas)
