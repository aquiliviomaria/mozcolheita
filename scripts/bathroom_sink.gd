extends Node3D
## Lavatório interactivo. Espelho pequeno actualizado apenas junto do lavatório.
const LOCAL: Vector3 = Vector3(4.2,5.64,-8.0)
const ACCOES: Array[String] = ["Lavar a cara","Escovar os dentes"]
var mundo: Node3D
var casa: Node3D
var lar: Node3D
var painel: PanelContainer
var texto: Label
var opcoes: HBoxContainer
var botoes: Array[Button] = []
var escolha: int = 0
var decorrido: float = 0
var escova: Node3D
var agua: CPUParticles3D
var espelho: SubViewport
var reflexo: Camera3D
var intervalo: float = 0
func bloco(p: Vector3,t: Vector3,cor: String) -> MeshInstance3D:
	var n: MeshInstance3D = mundo.caixa(casa,p,t,Color(cor),false); casa.piso_superior.append(n); return n
func _ready() -> void:
	name = "LavatorioHigiene"
	bloco(Vector3(4.2,7.55,-10.74),Vector3(2.05,1.7,0.12),"455257").name = "MolduraEspelho"
	bloco(Vector3(4.2,6.78,-9.7),Vector3(0.065,0.5,0.065),"b3c4c8")
	bloco(Vector3(4.2,7.01,-9.55),Vector3(0.065,0.065,0.36),"b3c4c8")
	bloco(Vector3(3.4,6.83,-9.45),Vector3(0.16,0.28,0.14),"b9d7d0").name = "Sabonete"
	bloco(Vector3(5.0,6.8,-9.45),Vector3(0.16,0.26,0.16),"d0a25b")
	bloco(Vector3(5.0,7.0,-9.45),Vector3(0.025,0.32,0.025),"5c9ba1")
	espelho = SubViewport.new(); espelho.name = "ReflexoLavatorio"; espelho.size = Vector2i(192,192); espelho.world_3d = get_world_3d(); espelho.render_target_update_mode = SubViewport.UPDATE_ONCE; add_child(espelho)
	reflexo = Camera3D.new(); reflexo.fov = 48; reflexo.far = 12; reflexo.cull_mask = 1; espelho.add_child(reflexo)
	reflexo.global_position = casa.to_global(Vector3(4.2,7.55,-10.6)); reflexo.look_at(casa.to_global(Vector3(4.2,7.25,-8.6)))
	var vidro: MeshInstance3D = MeshInstance3D.new(); vidro.name = "Espelho"; var quad: QuadMesh = QuadMesh.new(); quad.size = Vector2(1.85,1.5); vidro.mesh = quad; vidro.position = Vector3(4.2,7.55,-10.66); vidro.layers = 1<<19
	var mat: StandardMaterial3D = StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture = espelho.get_texture(); mat.albedo_color = Color("d6e7e8"); mat.uv1_scale = Vector3(-1,1,1); vidro.material_override = mat; vidro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; casa.add_child(vidro); casa.piso_superior.append(vidro)
	agua = CPUParticles3D.new(); agua.name = "AguaTorneira"; agua.position = Vector3(4.2,6.98,-9.38); agua.amount = 20; agua.lifetime = 0.23; agua.direction = Vector3.DOWN; agua.spread = 2; agua.initial_velocity_min = 1; agua.initial_velocity_max = 1.2; agua.gravity = Vector3(0,-3,0)
	var gota: BoxMesh = BoxMesh.new(); gota.size = Vector3(0.016,0.07,0.016); gota.material = mundo.material(Color("8fcbd9")); agua.mesh = gota; agua.emitting = false; casa.add_child(agua); casa.piso_superior.append(agua)
	var camada: CanvasLayer = CanvasLayer.new(); camada.layer = 24; add_child(camada)
	painel = PanelContainer.new(); camada.add_child(painel); painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); painel.offset_left = -240; painel.offset_right = 240; painel.offset_top = -170; painel.offset_bottom = -30
	var fundo: StyleBoxFlat = StyleBoxFlat.new(); fundo.bg_color = Color("142c26"); fundo.set_corner_radius_all(12); fundo.content_margin_left = 18; fundo.content_margin_right = 18; fundo.content_margin_top = 14; fundo.content_margin_bottom = 14; painel.add_theme_stylebox_override("panel",fundo)
	var coluna: VBoxContainer = VBoxContainer.new(); painel.add_child(coluna); texto = Label.new(); texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; coluna.add_child(texto); opcoes = HBoxContainer.new(); coluna.add_child(opcoes)
	for i: int in range(2):
		var b: Button = Button.new(); b.text = ACCOES[i]; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.custom_minimum_size.y = 40; b.pressed.connect(func() -> void: escolha = i; comecar()); opcoes.add_child(b); botoes.append(b)
	painel.hide()
func abrir() -> void:
	lar.iniciar("lavatorio"); mundo.jogador.position = casa.to_global(Vector3(4.2,5.64,-8.6)); mundo.jogador.visual.position = Vector3.ZERO; mundo.jogador.visual.rotation = Vector3.ZERO; escolha = 0; decorrido = 0; painel.show(); opcoes.show(); Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; actualizar_texto()
func actualizar_texto() -> void:
	texto.text = "LAVATÓRIO · " + ACCOES[escolha]+"\n← → escolher · E começar · Esc sair"
	for i: int in range(2): botoes[i].modulate = Color("a3efb1") if i==escolha else Color.WHITE
func comecar() -> void:
	if lar.estado!="lavatorio": return
	lar.estado = "lavar_rosto" if escolha==0 else "escovar_dentes"; decorrido = 0; agua.emitting = true; opcoes.hide(); Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if escolha==1:
		escova = Node3D.new(); escova.name = "EscovaDeDentes"; mundo.jogador.maos[1].add_child(escova)
		mundo.caixa(escova,Vector3(0,-0.05,0),Vector3(0.025,0.19,0.025),Color("4c9ea7"))
		mundo.caixa(escova,Vector3(0,-0.15,-0.01),Vector3(0.045,0.065,0.03),Color("f1ead7"))
func entrada(evento: InputEventKey) -> void:
	if evento.physical_keycode in [KEY_ESCAPE,KEY_W,KEY_A,KEY_S,KEY_D]: lar.levantar(); return
	if lar.estado=="lavatorio":
		if evento.physical_keycode in [KEY_LEFT,KEY_RIGHT,KEY_1,KEY_2]:
			escolha = 1-escolha if evento.physical_keycode in [KEY_LEFT,KEY_RIGHT] else evento.physical_keycode-KEY_1; actualizar_texto()
		elif evento.physical_keycode==KEY_E: comecar()
	elif evento.physical_keycode==KEY_E: lar.levantar()
func cancelar() -> void:
	agua.emitting = false; painel.hide(); espelho.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(escova): escova.get_parent().remove_child(escova); escova.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func actualizar(delta: float) -> void:
	if lar.estado=="lavatorio": return
	decorrido += delta
	var dentes: bool = lar.estado=="escovar_dentes"; var duracao: float = 7 if dentes else 4
	mundo.jogador.animar(delta,0)
	for i: int in range(2):
		if dentes and i==0: continue
		mundo.jogador.bracos[i].rotation.x = 1.1+sin(decorrido*(14 if dentes else 4))*0.07
		mundo.jogador.cotovelos[i].rotation.x = 2.2+sin(decorrido*5)*0.08
	mundo.jogador.rosto.rotation.x = 0.08
	texto.text = ("A escovar os dentes" if dentes else "A lavar a cara")+" · %d s\nE / Esc terminar" % ceili(maxf(0,duracao-decorrido))
	if decorrido>=duracao:
		mundo.vitais.higiene = minf(100,mundo.vitais.higiene+(18 if dentes else 12)); lar.levantar(); mundo.avisar("Dentes escovados" if dentes else "Cara lavada")

func _process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	if mundo.jogador.global_position.distance_to(casa.to_global(LOCAL))>3.5: return
	intervalo -= delta
	if intervalo<=0: espelho.render_target_update_mode = SubViewport.UPDATE_ONCE; intervalo = 0.15
