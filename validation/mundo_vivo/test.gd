extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(valor: bool,texto: String) -> void:
	if not valor: falhas += 1; push_error(texto)
	else: print("OK · ",texto)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.calendario.set_process(false)
	for pessoa: Node3D in mundo.pessoas: pessoa.set_physics_process(false)
	for carro: Node3D in mundo.comunidade.trafego: carro.set_physics_process(false)
	mundo.jogador.set_physics_process(false)
	await physics_frame
	mundo.calendario.decorrido = 0
	var tecla: InputEventKey = InputEventKey.new(); tecla.physical_keycode = KEY_L; tecla.keycode = KEY_L; tecla.pressed = true
	mundo._unhandled_input(tecla)
	mundo.luz_diaria._process(0)
	exigir(is_equal_approx(mundo.calendario.decorrido,300) and mundo.calendario.dia()==1,"L muda para 18:00 sem criar novo dia")
	exigir(mundo.luz_diaria.luminosidade<0.05 and mundo.luz_diaria.sol.light_energy<0.1,"Noite escura e sol apagado")
	mundo._unhandled_input(tecla); mundo.luz_diaria._process(0)
	exigir(is_equal_approx(mundo.calendario.decorrido,600) and mundo.calendario.dia()==2,"Segundo L passa para manhã do dia seguinte")
	exigir(mundo.luz_diaria.luminosidade>0.9 and mundo.calendario.amanhecer.playing,"Novo dia com céu azul, sol e canto de galo")
	mundo.camera.alternar_livre(); mundo._unhandled_input(tecla)
	exigir(is_equal_approx(mundo.calendario.decorrido,900),"L funciona também na câmara livre")
	mundo.camera.alternar_livre()
	mundo.entregas.aceitar(1)
	mundo.entregas.activas[1].limite = 1000.0
	var saldo: int = mundo.saldo; var multa: int = mundo.entregas.activas[1].penalidade
	mundo._unhandled_input(tecla)
	exigir(bool(mundo.entregas.activas[1].falhou) and mundo.saldo==saldo-multa,"Avançar com L respeita multa e prazo de contrato")
	print("CONTAGENS · casas ",mundo.comunidade.casas.size()," · prédios ",mundo.comunidade.edificios.size()," · pessoas ",mundo.pessoas.size())
	exigir(mundo.fabricas.size()==6,"Seis garagens de fábricas fora da quinta")
	exigir(mundo.comunidade.casas.size()>=45 and mundo.comunidade.edificios.size()>=10,"Mais casas e prédios distribuídos")
	exigir(mundo.pessoas.size()>=46 and mundo.comunidade.trafego.size()==20,"Mais moradores, camiões e tractores nas ruas")
	exigir(mundo.mundo_vivo.arvores==280 and mundo.mundo_vivo.pedras==150 and mundo.mundo_vivo.pontes==4,"Árvores, pedras e riacho com quatro pontes")
	mundo.sacola = {0:10}
	mundo.guia_entrega.destino = mundo.guia_entrega.escolher_destino(mundo.sacola,mundo.jogador.position)
	exigir(mundo.guia_entrega.destino.numero==0,"Seta escolhe fábrica compatível com tomate")
	mundo.guia_entrega.actualizar_rota(mundo.jogador.position)
	exigir(mundo.guia_entrega.rota.size()>2,"Rota inclui portão e ruas até à garagem")
	for fabrica: Node3D in mundo.fabricas:
		var rota: Array[Vector3] = mundo.guia_entrega.caminho_ruas(Vector3(0,0,92),fabrica.position)
		exigir(not rota.is_empty(),"Rede de ruas ligada à fábrica %s" % fabrica.position)
	mundo.entregas.aceitar(1)
	var preferida: Node3D = mundo.guia_entrega.escolher_destino({0:5,1:8},Vector3(-60,0,110))
	exigir(preferida.numero==1,"Encomenda activa tem prioridade sobre venda mais próxima")
	mundo.sacola.clear(); exigir(mundo.guia_entrega.escolher_destino(mundo.sacola,mundo.jogador.position)==null,"Sem mercadoria não há seta de entrega")
	# O corredor real da casa tem de estar livre de colisões, incluindo a soleira.
	var casa: Node3D = mundo.comunidade.casas[0]
	var consulta: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new(); var capsula: CapsuleShape3D = CapsuleShape3D.new(); capsula.radius = 0.4; capsula.height = 1.7; consulta.shape = capsula; consulta.collision_mask = 1; consulta.exclude = [mundo.relevo.corpo_chao.get_rid()]
	var corredor_livre: bool = true
	for z: int in range(-3,9):
		var p: Vector3 = casa.position+Vector3(0,0,z); p.y = mundo.altura(p)+1
		consulta.transform = Transform3D(Basis.IDENTITY,p)
		if not mundo.get_world_3d().direct_space_state.intersect_shape(consulta,1).is_empty(): corredor_livre = false
	exigir(corredor_livre,"Porta da casa e corredor deixam entrar fisicamente")
	var filial: Node3D = mundo.fabricas[3]
	mundo.caminhao.carga = {0:12,1:8}; mundo.caminhao.position = filial.position; mundo.caminhao.position.y += 0.1; mundo.caminhao.rapidez = 0
	mundo.trator_actual = mundo.caminhao
	var antes: int = mundo.saldo
	filial._process(1)
	exigir(mundo.saldo>antes and not mundo.caminhao.carga.has(0) and int(mundo.caminhao.carga[1])==8,"Parar na filial vende produto correcto e preserva os restantes")
	exigir(filial.abertura>0.99,"Portão da fábrica abre ao camião")
	mundo.trator_actual = null
	print("MUNDO VIVO · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas")
	mundo.calendario.amanhecer.stop(); mundo.contrato.som.stop()
	await create_timer(0.1).timeout
	quit(0 if falhas==0 else 1)
