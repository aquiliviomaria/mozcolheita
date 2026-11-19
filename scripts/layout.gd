extends RefCounted
## Fonte única das dimensões, acessos e áreas que não podem ser cultivadas.
const METADE: Vector2 = Vector2(96,78)
const PORTOES: Array[Vector3] = [Vector3(0,0,78),Vector3(60,0,78),Vector3(0,0,-78),Vector3(-60,0,-78),Vector3(96,0,0),Vector3(-96,0,0)]
const LARGURA_PORTAO: float = 12.0
const GALPAO: Rect2 = Rect2(-57,29,30,22)
const ARMAZEM: Rect2 = Rect2(22,24,20,26)

static func distancia(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))

static func dentro(p: Vector3) -> bool:
	return absf(p.x)<METADE.x and absf(p.z)<METADE.y

static func junto_portao(p: Vector3, margem: float = 18.0) -> bool:
	for centro: Vector3 in PORTOES:
		if distancia(p,centro)<margem: return true
	return false

static func reservado(p: Vector3) -> bool:
	var ponto: Vector2 = Vector2(p.x,p.z)
	if not dentro(p) or absf(p.x)>92 or absf(p.z)>74 or junto_portao(p): return true
	for area: Rect2 in [GALPAO.grow(3),ARMAZEM.grow(3),Rect2(-58,14,32,52),Rect2(-75,-45,30,24),Rect2(-5,-23,30,10),Rect2(-23,49,28,13)]:
		if area.has_point(ponto): return true
	return false

static func exterior(portao: Vector3) -> Vector3:
	return portao+Vector3(signf(portao.x)*7 if absf(portao.x)==METADE.x else 0,0,signf(portao.z)*7 if absf(portao.z)==METADE.y else 0)

static func livre(a: Vector3,b: Vector3) -> bool:
	# Cada intersecção com a vedação tem de passar pela abertura de um portão.
	var inicio: Vector2 = Vector2(a.x,a.z)
	var fim: Vector2 = Vector2(b.x,b.z)
	for lado: int in range(4):
		var horizontal: bool = lado<2
		var limite: float = (-METADE.y if lado==0 else METADE.y) if horizontal else (-METADE.x if lado==2 else METADE.x)
		var divisor: float = (fim.y-inicio.y) if horizontal else (fim.x-inicio.x)
		if absf(divisor)<0.001: continue
		var t: float = (limite-(inicio.y if horizontal else inicio.x))/divisor
		if t<=0 or t>=1: continue
		var ponto: Vector2 = inicio.lerp(fim,t)
		if (absf(ponto.x)>METADE.x if horizontal else absf(ponto.y)>METADE.y): continue
		var permitido: bool = false
		for portao: Vector3 in PORTOES:
			if ponto.distance_to(Vector2(portao.x,portao.z))<LARGURA_PORTAO*0.5-1: permitido = true
		if not permitido: return false
	for obstaculo: Rect2 in [GALPAO.grow(1),ARMAZEM.grow(1)]:
		if obstaculo.has_point(inicio) or obstaculo.has_point(fim): continue
		for passo: int in range(1,17):
			if obstaculo.has_point(inicio.lerp(fim,float(passo)/17.0)): return false
	return true

static func caminho(a: Vector3,b: Vector3) -> Array[Vector3]:
	var pontos: Array[Vector3] = [a,b]
	for portao: Vector3 in PORTOES:
		pontos.append(exterior(portao))
		pontos.append(portao-(exterior(portao)-portao))
	for x: float in [-103.0,103.0]:
		for z: float in [-85.0,85.0]: pontos.append(Vector3(x,0,z))
	for area: Rect2 in [GALPAO.grow(2),ARMAZEM.grow(2)]:
		for canto: Vector2 in [area.position,area.end,Vector2(area.position.x,area.end.y),Vector2(area.end.x,area.position.y)]: pontos.append(Vector3(canto.x,0,canto.y))
	var custos: PackedFloat32Array = []
	var anteriores: PackedInt32Array = []
	var visitados: PackedByteArray = []
	custos.resize(pontos.size()); custos.fill(INF)
	anteriores.resize(pontos.size()); anteriores.fill(-1)
	visitados.resize(pontos.size())
	custos[0] = 0
	for iteracao: int in range(pontos.size()):
		var actual: int = -1
		for i: int in range(pontos.size()):
			if visitados[i]==0 and (actual==-1 or custos[i]<custos[actual]): actual = i
		if actual==-1 or custos[actual]==INF or actual==1: break
		visitados[actual] = 1
		for i: int in range(pontos.size()):
			if visitados[i]!=0 or i==actual: continue
			var custo: float = custos[actual]+distancia(pontos[actual],pontos[i])
			if custo<custos[i] and livre(pontos[actual],pontos[i]): custos[i] = custo; anteriores[i] = actual
	var resultado: Array[Vector3] = []
	var indice: int = 1
	while indice>0 and anteriores[indice]>=0:
		resultado.push_front(pontos[indice]); indice = anteriores[indice]
	return resultado
