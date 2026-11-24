extends Node3D
## Pano de privacidade à altura do corpo, deixando visíveis as cabeças do duche: entra, fecha, liga água; abre para receber companhia/sair.
var lar: Node3D
var mundo: Node3D
var casa: Node3D
var esquerda: Node3D
var direita: Node3D
var abertura: float = 1
var fase: String = "inactivo"
var tempo: float = 0
var companhia_dentro: bool = false
var controla_companhia: bool = false
var origem_jogador: Vector3
var origem_companhia: Vector3
var camara_anterior: bool = false
var ponto_anterior: Vector3
var olhar_anterior: Vector3
func _ready() -> void:
	position = Vector3(11,5.64,-7)
	var pano: StandardMaterial3D = StandardMaterial3D.new(); pano.albedo_color = Color("5b8f89"); pano.roughness = 1; pano.cull_mode = BaseMaterial3D.CULL_DISABLED
	for lado: int in range(2):
		var metade: Node3D = Node3D.new(); metade.position = Vector3(-2 if lado==0 else 2,0,2.05); add_child(metade)
		if lado==0: esquerda = metade
		else: direita = metade
		for i: int in range(12):
			var p: Vector3 = Vector3((i+0.5)/6.0*(1 if lado==0 else -1),1.05,(0.035 if i%2==0 else -0.035))
			var painel: MeshInstance3D = mundo.caixa(metade,p,Vector3(0.18,1.8,0.07),Color.WHITE); painel.material_override = pano
	for spec: Vector3 in [Vector3(-2,1.05,0),Vector3(2,1.05,0),Vector3(0,1.05,-2)]:
		var n: MeshInstance3D = mundo.caixa(self,spec,Vector3(0.07,1.8,4) if spec.x!=0 else Vector3(4,1.8,0.07),Color.WHITE); n.material_override = pano
	mundo.caixa(self,Vector3(0,2.05,2.05),Vector3(4.3,0.06,0.06),Color("a2b3b6"))
	casa.piso_superior.append(self); aplicar_pano()
func aplicar_pano() -> void:
	esquerda.scale.x = lerpf(1,0.12,abertura); direita.scale.x = esquerda.scale.x
func iniciar() -> void:
	fase = "entrar"; tempo = 0; abertura = 1; companhia_dentro = false; controla_companhia = false; lar.agua.emitting = false
	origem_jogador = casa.to_local(mundo.jogador.position)
	camara_anterior = mundo.camera.enquadramento; ponto_anterior = mundo.camera.ponto_fixo; olhar_anterior = mundo.camera.olhar_fixo
	mundo.camera.enquadramento = true; mundo.camera.ponto_fixo = casa.to_global(Vector3(6.2,8.1,-2)); mundo.camera.olhar_fixo = casa.to_global(Vector3(11,7.2,-6.5)); aplicar_pano()
func pedir_saida() -> void:
	if fase in ["inactivo","abrir_saida","sair"]: return
	fase = "abrir_saida"; tempo = 0; lar.agua.emitting = false; controla_companhia = companhia_dentro
func cancelar() -> void:
	lar.agua.emitting = false; abertura = 1; fase = "inactivo"; companhia_dentro = false; controla_companhia = false; aplicar_pano()
	mundo.camera.enquadramento = camara_anterior; mundo.camera.ponto_fixo = ponto_anterior; mundo.camera.olhar_fixo = olhar_anterior
func actualizar(delta: float) -> void:
	if fase=="inactivo": return
	tempo += delta
	var abrir: bool = fase in ["entrar","abrir_saida","sair","abrir_companhia","entrar_companhia"]
	abertura = move_toward(abertura,1.0 if abrir else 0.0,delta*2.5); aplicar_pano()
	match fase:
		"entrar":
			mundo.jogador.position = casa.to_global(origem_jogador.lerp(Vector3(10.3,5.7,-7),minf(1,tempo/0.65))); mundo.jogador.animar(delta,1.5)
			if tempo>=0.65: fase = "fechar"; tempo = 0
		"fechar", "fechar_companhia":
			if abertura<=0.01: fase = "banho"; lar.agua.emitting = true
		"banho":
			var f: Node3D = mundo.familia
			if not companhia_dentro and f!=null and f.actividade=="banho" and f.pronta:
				lar.agua.emitting = false; fase = "abrir_companhia"; tempo = 0; controla_companhia = true; origem_companhia = casa.to_local(f.pessoa.position)
		"abrir_companhia":
			if abertura>=0.99: fase = "entrar_companhia"; tempo = 0
		"entrar_companhia":
			mundo.familia.pessoa.position = casa.to_global(origem_companhia.lerp(Vector3(11.8,5.7,-7),minf(1,tempo/0.65))); mundo.familia.pessoa.animar(delta,1.5)
			if tempo>=0.65: companhia_dentro = true; controla_companhia = false; fase = "fechar_companhia"; tempo = 0
		"abrir_saida":
			if abertura>=0.99: fase = "sair"; tempo = 0
		"sair":
			var t: float = minf(1,tempo/0.65)
			mundo.jogador.position = casa.to_global(Vector3(10.3,5.7,-7).lerp(Vector3(10.3,5.64,-4),t)); mundo.jogador.animar(delta,1.5)
			if companhia_dentro: mundo.familia.pessoa.position = casa.to_global(Vector3(11.8,5.7,-7).lerp(Vector3(12.2,5.64,-4),t)); mundo.familia.pessoa.animar(delta,1.5)
			if t>=1: lar.levantar()
