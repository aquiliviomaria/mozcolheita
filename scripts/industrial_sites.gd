extends RefCounted
## Coordenadas partilhadas por edifícios, trabalhadores, navegação e reserva do terreno.
const GALPAO: Vector3 = Vector3(-250,0,41)
const ARMAZEM: Vector3 = Vector3(-205,0,25)
const AREA_ARMAZEM: Rect2 = Rect2(-230,-7,50,64)
const FABRICAS: Array[Vector3] = [Vector3(-235,0,315),Vector3(-20,0,-175),Vector3(235,0,315)]
const FILIAIS: Array[Vector3] = [Vector3(-245,0,-45),Vector3(-70,0,225),Vector3(300,0,225)]
static func entrada(numero: int) -> Vector3: return FABRICAS[numero]+Vector3(0,0,-42)
