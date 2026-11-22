extends RefCounted
## Uma leitura partilhada entre o controlador e os indicadores no HUD.
static func dispositivo() -> int:
	var ligados: Array[int] = Input.get_connected_joypads()
	return ligados[0] if not ligados.is_empty() else -1
static func eixo(codigo: int) -> float:
	var id: int = dispositivo()
	if id<0: return 0
	var valor: float = Input.get_joy_axis(id,codigo)
	return valor if absf(valor)>0.18 else 0
static func botao(codigo: int) -> bool:
	var id: int = dispositivo()
	return id>=0 and Input.is_joy_button_pressed(id,codigo)
static func acelerador() -> float:
	return maxf(float(Input.is_physical_key_pressed(KEY_W)),maxf(0,eixo(JOY_AXIS_TRIGGER_RIGHT)))
static func travao() -> bool:
	return Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL) or eixo(JOY_AXIS_TRIGGER_LEFT)>0.2
static func recuar() -> float:
	return maxf(float(Input.is_physical_key_pressed(KEY_S)),maxf(0,eixo(JOY_AXIS_LEFT_Y)))
static func direccao() -> float:
	return clampf(float(Input.is_physical_key_pressed(KEY_A))-float(Input.is_physical_key_pressed(KEY_D))-eixo(JOY_AXIS_LEFT_X),-1,1)
static func turbo() -> bool:
	return Input.is_physical_key_pressed(KEY_T) or botao(JOY_BUTTON_RIGHT_SHOULDER)
