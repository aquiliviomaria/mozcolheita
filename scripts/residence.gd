extends Node3D
## Porta deslizante e átrio acessível. Os pisos altos são cenário exterior.
var mundo: Node3D
var largura: float = 12
var profundidade: float = 11
var cor: Color = Color("dfc798")
var titulo: String = "CASA"
var porta: Node3D
var luz: OmniLight3D
var abertura: float = 0
var intervalo: float = 0
var abrir: bool = false
func _ready() -> void:
	for lado: float in [-1,1]:
		mundo.caixa(self,Vector3(lado*(largura/2-0.15),2,0),Vector3(0.3,4,profundidade),cor,true)
		mundo.caixa(self,Vector3(lado*(largura/4+0.7),2,profundidade/2),Vector3(largura/2-1.4,4,0.3),cor,true)
	mundo.caixa(self,Vector3(0,2,-profundidade/2),Vector3(largura,4,0.3),cor,true)
	mundo.caixa(self,Vector3(0,3.65,profundidade/2),Vector3(2.8,0.7,0.3),cor,true)
	preload("res://scripts/architecture.gd").piso(mundo,self,Rect2(-largura/2+0.3,-profundidade/2+0.3,largura-0.6,profundidade-0.6))
	porta = mundo.caixa(self,Vector3(0,1.55,profundidade/2+0.12),Vector3(2.6,3.1,0.12),Color("3b6e53"))
	mundo.caixa(porta,Vector3(0.85,0,0.1),Vector3(0.08,0.38,0.1),Color("d7ba64"))
	mundo.placa(self,Vector3(0,3.45,profundidade/2+0.35),titulo+" · ENTRADA").visibility_range_end = 22
	# Mobiliário fica nos lados, mantendo o corredor livre em toda a profundidade.
	mundo.caixa(self,Vector3(-largura/2+1.7,0.65,-1),Vector3(2.5,1.3,3),Color("aa7450"),true)
	mundo.caixa(self,Vector3(largura/2-1.7,0.6,-2),Vector3(2.3,1.2,3.2),Color("567f69"),true)
	mundo.caixa(self,Vector3(largura/2-1.7,1.4,-3.3),Vector3(2.3,0.6,0.45),Color("dfcba5"))
	luz = OmniLight3D.new(); luz.position = Vector3(0,3,0); luz.omni_range = maxf(largura,profundidade); luz.light_color = Color("ffdc99"); luz.light_energy = 0.7; luz.distance_fade_enabled = true; luz.distance_fade_begin = 50; add_child(luz)
func _process(delta: float) -> void:
	if mundo.jogador==null: return
	intervalo -= delta
	if intervalo<=0:
		intervalo = 0.25
		var centro: Vector3 = to_global(Vector3(0,0,profundidade/2))
		abrir = centro.distance_squared_to(mundo.jogador.position)<36
		if not abrir:
			for pessoa: Node3D in mundo.pessoas:
				if centro.distance_squared_to(pessoa.position)<25: abrir = true; break
		luz.visible = centro.distance_squared_to(mundo.jogador.position)<70*70
	abertura = move_toward(abertura,1.0 if abrir else 0.0,delta*2)
	porta.position.x = abertura*2.8
