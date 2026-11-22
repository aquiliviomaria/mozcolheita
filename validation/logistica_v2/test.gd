extends SceneTree
var mundo: Node3D
var falhas: int = 0
func _initialize() -> void: executar.call_deferred()
func exigir(v: bool,t: String) -> void:
	print(("OK · " if v else "FALHA · ")+t)
	if not v: falhas += 1
func tecla(k: int) -> void:
	var e: InputEventKey = InputEventKey.new(); e.physical_keycode = k; e.pressed = true; mundo._unhandled_input(e)
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false)
	mundo.calendario.set_process(false); mundo.jogador.set_physics_process(false)
	for p: Node3D in mundo.pessoas: p.set_physics_process(false)
	mundo.familia.set_physics_process(false)
	exigir(mundo.pessoas.size()==46 and mundo.fabricas.size()==6,"Comunidade e seis fábricas preservadas")
	exigir(mundo.armazem.position.distance_to(mundo.casa.position)>180,"Armazém afastado da quinta e da casa")
	for f: Node3D in mundo.fabricas: exigir(not preload("res://scripts/layout.gd").dentro(f.position) and f.position.distance_to(mundo.casa.position)>120,"Fábrica industrial afastada")
	# A escolha de carga é atómica, respeita stock, produto e capacidade.
	var ui: CanvasLayer = mundo.central_logistica
	mundo.stock = {0:700,1:90}; mundo.caminhao.carga.clear(); mundo.caminhao.position = mundo.armazem.CENTRO
	mundo.jogador.position = mundo.caminhao.position
	exigir(ui.carregar_escolha(1,30,mundo.caminhao)==30 and mundo.caminhao.carga=={1:30} and int(mundo.stock[0])==700,"Carrega apenas produto e quantidade escolhidos")
	exigir(ui.carregar_escolha(0,999,mundo.caminhao)==470 and mundo.caminhao.total()==500 and int(mundo.stock[0])==230,"Respeita a capacidade do camião sem perder excedente")
	exigir(ui.carregar_escolha(0,10,mundo.caminhao)==0 and int(mundo.stock[0])==230,"Transporte cheio não retira stock")
	ui.abrir_destinos(1); exigir(ui.aberto,"Notificação abre escolha de destino depois da carga")
	mundo.guia_entrega.empresa_escolhida = 1
	var f: Node3D = mundo.guia_entrega.escolher_destino(mundo.caminhao.carga,mundo.caminhao.position)
	exigir(f!=null and f.numero==1,"Navegação respeita empresa escolhida")
	ui.fechar(); tecla(KEY_M); exigir(ui.aberto and ui.valor.item_count==5,"M abre painel com cinco valores de encomenda"); ui.fechar()
	# Aceitar/cancelar através do diálogo explicita o valor da sanção.
	ui.propor(0,0,0); exigir(ui.confirmacao.visible and ui.confirmacao.dialog_text.contains("20000"),"Confirmação mostra multa em dobro antes de aceitar")
	ui.confirmador.call(); ui.fechar(); var saldo: int = mundo.saldo
	exigir(int(mundo.entregas.activas[0].recompensa)==10000,"Contrato de 10.000 MT")
	exigir(mundo.entregas.cancelar(0) and mundo.saldo==saldo-20000,"Cancelamento desconta duas vezes o contrato")
	exigir(not mundo.entregas.cancelar(0) and mundo.saldo==saldo-20000,"Cancelar repetidamente não duplica multa")
	mundo.entregas.aceitar(1,0,1); saldo = mundo.saldo
	mundo.calendario.decorrido = float(mundo.entregas.activas[1].limite)+1; mundo.entregas.verificar_prazos()
	exigir(mundo.saldo==saldo-100000,"Atraso de contrato de 50.000 MT desconta 100.000 MT")
	mundo.entregas.verificar_prazos(); exigir(mundo.saldo==saldo-100000,"Atraso é debitado uma única vez")
	for i: int in range(5):
		var oferta: Dictionary = mundo.entregas.oferta(2,0,i)
		exigir(int(oferta.recompensa)==mundo.entregas.VALORES[i] and int(oferta.penalidade)==2*int(oferta.recompensa),"Valores e multa são consistentes")
	mundo.entregas.aceitar(2,0,2); var p: Dictionary = mundo.entregas.activas[2]; saldo = mundo.saldo
	var carga: Dictionary = {int(p.cultura):int(p.quantidade)}; mundo.entregas.entregar(carga,2)
	exigir(mundo.saldo==saldo+100000 and bool(p.concluida),"Sucesso paga exactamente os 100.000 MT aprovados")
	# Cancela física abre com aproximação; segurança não aumenta lista de contratáveis.
	var cancela: Node3D
	for n: Node in mundo.armazem.get_children():
		if n.get_script()==load("res://scripts/industrial_gate.gd"): cancela = n
	mundo.jogador.position = cancela.global_position+Vector3(0,0,-12); mundo.camera._process(1)
	for i: int in range(100): cancela._physics_process(1.0/60)
	exigir(cancela.abertura>0.95 and cancela.guarda.visible,"Segurança e cancela funcional na entrada")
	# Operador fica no chão a segurar comando visível.
	var d: Node3D = mundo.drones[0]; mundo.jogador.position = d.position+Vector3(0,0,2); var operador: Vector3 = mundo.jogador.position
	exigir(d.assumir() and mundo.jogador.pilotar_drone and mundo.jogador.comando_drone.visible,"Pilotar drone mostra comando nas mãos")
	exigir(mundo.jogador.position==operador,"Operador mantém-se no ponto de pilotagem")
	d.devolver(); exigir(not mundo.jogador.pilotar_drone and not mundo.jogador.comando_drone.visible,"Devolver drone recolhe comando e repõe ferramenta")
	exigir(not preload("res://scripts/avatar.gd").new().has_method("bandeira"),"Avatares sem distintivo da bandeira")
	# O novo mapa continua a ser gravável no mesmo formato.
	var snapshot: Dictionary = mundo.partida.capturar()
	exigir(mundo.partida.validar(snapshot),"Gravação mantém formato compatível")
	print("LOGÍSTICA V2 · ","PASSOU" if falhas==0 else "FALHOU"," · ",falhas," falhas")
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit(falhas)
