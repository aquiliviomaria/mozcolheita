extends Node3D
## Cancela física com sensor de aproximação, sinalização e segurança de serviço.
var mundo: Node3D
var braco: Node3D
var sinal: MeshInstance3D
var abertura: float = 0
var intervalo: float = 0
var autorizado: bool = false
var verde: StandardMaterial3D
var vermelho: StandardMaterial3D
var guarda: CharacterBody3D
func _ready() -> void:
	mundo.caixa(self,Vector3(-4.4,0.7,0),Vector3(0.6,1.4,0.6),Color("345b53"),true)
	braco = Node3D.new(); braco.position = Vector3(-4.2,1.2,0); add_child(braco)
	mundo.caixa(braco,Vector3(4,0,0),Vector3(8,0.18,0.18),Color("eee6ce"),true)
	for i: int in range(6): mundo.caixa(braco,Vector3(0.65+i*1.3,0,0),Vector3(0.6,0.19,0.2),Color("c74d35"))
	mundo.caixa(self,Vector3(6.8,1.4,1),Vector3(3.1,2.8,2.8),Color("c3ccba"),true)
	mundo.caixa(self,Vector3(6.8,1.8,-0.43),Vector3(2.6,1,0.04),Color("517f84"))
	mundo.caixa(self,Vector3(6.8,2.9,1),Vector3(3.5,0.2,3.2),Color("345b53"))
	guarda = preload("res://scripts/player.gd").new(); guarda.mundo = mundo; guarda.aparencia = absi(roundi(global_position.x+global_position.z))%6; guarda.mulher = guarda.aparencia%2==0; guarda.roupa = 1; guarda.perfil = 0; guarda.bloqueado = true; guarda.position = Vector3(10,0,0); add_child(guarda); guarda.set_physics_process(false)
	mundo.placa(guarda,Vector3(0,2.3,0),"SEGURANÇA").visibility_range_end = 15
	sinal = mundo.caixa(self,Vector3(-4.4,1.6,0),Vector3(0.22,0.22,0.22),Color("e85d49"))
	verde = mundo.material(Color("69d68b")).duplicate(); vermelho = mundo.material(Color("e85d49")).duplicate()
	verde.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; vermelho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
func _physics_process(delta: float) -> void:
	if mundo.hud==null or mundo.pausado(): return
	intervalo -= delta
	if intervalo<=0:
		intervalo = 0.2
		var alvo: Node3D = mundo.trator_actual if mundo.trator_actual!=null else mundo.jogador
		autorizado = global_position.distance_squared_to(alvo.global_position)<24*24
		if not autorizado:
			for p: Node3D in mundo.pessoas:
				if (p.contratado or p.grupo) and global_position.distance_squared_to(p.global_position)<16*16: autorizado = true; break
		guarda.visible = global_position.distance_squared_to(mundo.camera.camara.global_position)<110*110
	abertura = move_toward(abertura,1.0 if autorizado else 0.0,delta*0.8)
	braco.rotation.z = abertura*PI*0.48
	sinal.material_override = verde if abertura>0.95 else vermelho
