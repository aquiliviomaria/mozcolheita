extends Node3D
## Cabine com portas de patamar interbloqueadas: só viaja com todas fechadas.
const PISOS: Array[float] = [0.64,5.64]
var mundo: Node3D
var casa: Node3D
var lar: Node3D
var portas: Array[Node3D] = []
var paineis: Array[Label3D] = []
var botoes: Array[MeshInstance3D] = []
var abertura: Array[float] = [0.0,0.0]
var porta_cabine: Node3D
var abre_cabine: float = 0
var fase: String = "inactivo"
var piso: int = 0
var origem: int = 0
var destino: int = 0
var tempo: float = 0
var inicio_passo: Vector3
var retorno_camara: bool = false
var ponto_camara: Vector3
var olhar_camara: Vector3
func bloco(pai: Node3D,p: Vector3,t: Vector3,cor: String,solido: bool = false) -> MeshInstance3D:
	var vista: MeshInstance3D = mundo.caixa(pai,p,t,Color(cor),solido)
	if cor in ["758f91","9ab0ac"]:
		var metal: StandardMaterial3D = vista.material_override.duplicate(); metal.metallic = 0.55; metal.roughness = 0.32; vista.material_override = metal
	return vista
func legenda(pai: Node3D,p: Vector3,t: String,tamanho: int = 24) -> Label3D:
	var l: Label3D = mundo.placa(pai,p,t); l.font_size = tamanho; l.pixel_size = 0.005; l.outline_size = 3; l.billboard = BaseMaterial3D.BILLBOARD_DISABLED; l.visibility_range_end = 16
	return l
func criar_portas(pai: Node3D,z: float) -> Node3D:
	var conjunto: Node3D = Node3D.new(); conjunto.position.z = z; pai.add_child(conjunto)
	for lado: float in [-1,1]:
		var folha: Node3D = Node3D.new(); conjunto.add_child(folha); folha.position.x = lado*0.49
		bloco(folha,Vector3(0,1.52,0),Vector3(0.98,3.02,0.09),"758f91",true)
		bloco(folha,Vector3(0,1.55,0.06),Vector3(0.79,2.75,0.015),"9ab0ac")
		bloco(folha,Vector3(-lado*0.39,1.55,0.08),Vector3(0.035,2.72,0.025),"d7bd76")
	return conjunto
func aplicar_portas() -> void:
	for i: int in range(2):
		for j: int in range(2): portas[i].get_child(j).position.x = (-1 if j==0 else 1)*(0.49+abertura[i]*0.99)
	for j: int in range(2): porta_cabine.get_child(j).position.x = (-1 if j==0 else 1)*(0.49+abre_cabine*0.99)
func _ready() -> void:
	name = "Elevador"; position = Vector3(-5,PISOS[0],-5)
	bloco(self,Vector3(0,-0.15,0),Vector3(3.8,0.3,3.8),"344d4d",true)
	bloco(self,Vector3(0,0.01,0),Vector3(3.5,0.025,3.5),"dfdbc5")
	for x: float in [-1.82,1.82]:
		bloco(self,Vector3(x,1.65,0),Vector3(0.09,3.3,3.6),"345b53")
		bloco(self,Vector3(x*0.95,1.2,0),Vector3(0.055,0.055,2.8),"d5bb76")
	bloco(self,Vector3(0,1.65,-1.82),Vector3(3.6,3.3,0.09),"345b53")
	bloco(self,Vector3(0,1.75,-1.75),Vector3(2.3,1.7,0.025),"a8bfc0")
	bloco(self,Vector3(0,3.35,0),Vector3(3.8,0.16,3.8),"263e3d")
	bloco(self,Vector3(0,3.25,0),Vector3(2.4,0.04,0.9),"fff1cb")
	var luz: OmniLight3D = OmniLight3D.new(); luz.position = Vector3(0,2.8,0); luz.light_color = Color("fff0ca"); luz.light_energy = 0.8; luz.omni_range = 5; luz.shadow_enabled = false; luz.distance_fade_enabled = true; luz.distance_fade_begin = 18; add_child(luz)
	porta_cabine = criar_portas(self,1.83)
	# Painel interior na parede traseira, com teclas funcionais e indicação do piso.
	bloco(self,Vector3(1.25,1.65,-1.73),Vector3(0.55,1.25,0.09),"172e32")
	for i: int in range(2):
		var botao: MeshInstance3D = bloco(self,Vector3(1.25,1.4+i*0.42,-1.66),Vector3(0.32,0.28,0.04),"d7bd76"); botoes.append(botao)
		legenda(self,Vector3(1.25,1.4+i*0.42,-1.62),str(i+1),36)
	legenda(self,Vector3(0,2.8,-1.7),"MOZ · ELEVADOR",28)
	paineis.append(legenda(self,Vector3(0,2.4,-1.69),"R/C",30))
	for i: int in range(2):
		var patamar: Node3D = Node3D.new(); patamar.position = Vector3(-5,PISOS[i],-2.92); casa.add_child(patamar)
		if i==1: casa.piso_superior.append(patamar)
		for x: float in [-1.55,1.55]: bloco(patamar,Vector3(x,1.65,0),Vector3(1.1,3.3,0.3),"345b53",true)
		bloco(patamar,Vector3(0,3.25,0),Vector3(4.2,0.45,0.35),"345b53",true)
		bloco(patamar,Vector3(0,0.035,0.12),Vector3(2.05,0.07,0.45),"d7bd76")
		portas.append(criar_portas(patamar,0.12))
		bloco(patamar,Vector3(1.65,1.5,0.21),Vector3(0.3,0.48,0.06),"172e32")
		bloco(patamar,Vector3(1.65,1.5,0.26),Vector3(0.18,0.18,0.04),"d7bd76")
		legenda(patamar,Vector3(1.65,1.5,0.3),"E",26)
		paineis.append(legenda(patamar,Vector3(0,3.25,0.22),"R/C" if i==0 else "1 · QUARTO",28))
	aplicar_portas()
func iniciar(chamada: int) -> void:
	origem = chamada; destino = chamada; tempo = 0; fase = "chamar_fechar"
	inicio_passo = mundo.jogador.position
	retorno_camara = mundo.camera.enquadramento; ponto_camara = mundo.camera.ponto_fixo; olhar_camara = mundo.camera.olhar_fixo
func seleccionar(p: int) -> void:
	if fase!="pronto": return
	if p==piso: fase = "abrir"; return
	destino = p; fase = "fechar"; tempo = 0
func sair() -> void:
	if fase=="pronto": fase = "abrir"; tempo = 0
func terminar() -> void:
	if fase!="sair":
		position.y = PISOS[piso]; abertura = [0.0,0.0]; abre_cabine = 0; aplicar_portas()
	fase = "inactivo"; mundo.camera.enquadramento = retorno_camara; mundo.camera.ponto_fixo = ponto_camara; mundo.camera.olhar_fixo = olhar_camara
func entrada_ocupada(i: int) -> bool:
	var actores: Array[Node3D] = [mundo.jogador]
	if mundo.familia!=null: actores.append(mundo.familia.pessoa)
	actores.append_array(mundo.pessoas)
	for actor: Node3D in actores:
		var p: Vector3 = casa.to_local(actor.global_position)
		if absf(p.x+5)<1.25 and absf(p.z+2.8)<0.55 and absf(p.y-PISOS[i])<2.3: return true
	return false
func actualizar(delta: float) -> void:
	if fase=="inactivo": return
	tempo += delta
	var abrir: bool = fase in ["chamar_abrir","entrar","pronto","abrir","sair"]
	var obstruida: bool = abertura[piso]>0.01 and entrada_ocupada(piso) and fase in ["fechar","chamar_fechar"]
	for i: int in range(2): abertura[i] = move_toward(abertura[i],1.0 if (abrir or obstruida) and i==piso else 0.0,delta*1.8)
	abre_cabine = move_toward(abre_cabine,1.0 if abrir or obstruida else 0.0,delta*1.8); aplicar_portas()
	if fase in ["pronto","fechar","mover","abrir","sair"]:
		mundo.camera.enquadramento = true
		mundo.camera.ponto_fixo = casa.to_global(Vector3(-3.7,position.y+2.5,-3.7))
		mundo.camera.olhar_fixo = casa.to_global(Vector3(-4.6,position.y+1.5,-6.6))
	var fechadas: bool = abertura[0]<=0.001 and abertura[1]<=0.001 and abre_cabine<=0.001
	match fase:
		"chamar_fechar":
			if fechadas: fase = "chamar_mover"
		"chamar_mover", "mover":
			if not fechadas: return
			position.y = move_toward(position.y,PISOS[destino],delta*2.2)
			if fase=="mover": mundo.jogador.position = casa.to_global(Vector3(-5,position.y,-5))
			if is_equal_approx(position.y,PISOS[destino]):
				piso = destino; fase = "chamar_abrir" if fase=="chamar_mover" else "abrir"; tempo = 0
		"chamar_abrir":
			if abre_cabine>=0.99: fase = "entrar"; tempo = 0
		"entrar":
			mundo.jogador.position = inicio_passo.lerp(casa.to_global(Vector3(-5,position.y,-5)),minf(1,tempo/0.85)); mundo.jogador.animar(delta,1.5)
			if tempo>=0.85:
				fase = "pronto"; mundo.jogador.animar(0,0)
				mundo.avisar("Elevador · 1 rés-do-chão · 2 quarto · E sair")
		"fechar":
			if fechadas: fase = "mover"
		"abrir":
			if abre_cabine>=0.99: fase = "sair"; tempo = 0
		"sair":
			mundo.jogador.position = casa.to_global(Vector3(-5,position.y,-5).lerp(Vector3(-5,position.y,-1.8),minf(1,tempo/0.85))); mundo.jogador.animar(delta,1.5)
			if tempo>=0.85:
				lar.retorno = casa.to_global(Vector3(-5,position.y,-1.8)); lar.levantar()
	var indicacao: String = "R/C" if piso==0 else "1 · QUARTO"
	if fase in ["mover","chamar_mover"]: indicacao = "A SUBIR" if destino==1 else "A DESCER"
	paineis[0].text = indicacao
	for i: int in range(2): botoes[i].material_override = mundo.material(Color("71cf86") if i==destino else Color("d7bd76"))
func _physics_process(delta: float) -> void:
	# Depois da saída, fecha apenas quando a entrada estiver desimpedida.
	if fase!="inactivo" or mundo.hud==null or mundo.pausado(): return
	for i: int in range(2):
		var centro: Vector3 = casa.to_global(Vector3(-5,PISOS[i],-2.6))
		var ocupado: bool = mundo.jogador.position.distance_to(centro)<1.5 or entrada_ocupada(i)
		if mundo.familia!=null: ocupado = ocupado or mundo.familia.pessoa.position.distance_to(centro)<1.5
		abertura[i] = move_toward(abertura[i],1.0 if ocupado and i==piso else 0.0,delta*1.8)
	abre_cabine = abertura[piso]; aplicar_portas()
