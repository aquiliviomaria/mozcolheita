extends RefCounted
## Planeamento local apenas quando um peão perde progresso; o grafo mantém os portões.
static func contornar(pessoa: CharacterBody3D, alvo: Vector3) -> Array[Vector3]:
	const PASSO: float = 1.25
	const RAIO: int = 18
	var grelha: AStarGrid2D = AStarGrid2D.new()
	grelha.region = Rect2i(-RAIO,-RAIO,RAIO*2+1,RAIO*2+1)
	grelha.cell_size = Vector2.ONE*PASSO
	grelha.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grelha.update()
	var consulta: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var forma: CapsuleShape3D = CapsuleShape3D.new(); forma.radius = 0.46; forma.height = 1.65
	consulta.shape = forma; consulta.collision_mask = 1|2|4|8
	consulta.exclude = [pessoa.get_rid(),pessoa.mundo.relevo.corpo_chao.get_rid()]
	var espaco: PhysicsDirectSpaceState3D = pessoa.get_world_3d().direct_space_state
	for x: int in range(-RAIO,RAIO+1):
		for z: int in range(-RAIO,RAIO+1):
			var ponto: Vector3 = pessoa.global_position+Vector3(x*PASSO,0,z*PASSO)
			ponto.y = pessoa.mundo.altura(ponto)+0.95
			consulta.transform = Transform3D(Basis.IDENTITY,ponto)
			grelha.set_point_solid(Vector2i(x,z),not espaco.intersect_shape(consulta,1).is_empty())
	grelha.set_point_solid(Vector2i.ZERO,false)
	var direccao: Vector2 = Vector2(alvo.x-pessoa.position.x,alvo.z-pessoa.position.z)/PASSO
	if direccao.length()>RAIO-2: direccao = direccao.normalized()*(RAIO-2)
	var fim: Vector2i = Vector2i(direccao.round())
	var melhor: float = INF
	var destino: Vector2i = Vector2i.ZERO
	for x: int in range(-RAIO,RAIO+1):
		for z: int in range(-RAIO,RAIO+1):
			var chave: Vector2i = Vector2i(x,z)
			var custo: float = Vector2(chave-fim).length()
			if not grelha.is_point_solid(chave) and custo<melhor: destino = chave; melhor = custo
	var resultado: Array[Vector3] = []
	var ids: Array[Vector2i] = grelha.get_id_path(Vector2i.ZERO,destino)
	for i: int in range(1,ids.size()): resultado.append(pessoa.global_position+Vector3(ids[i].x*PASSO,0,ids[i].y*PASSO))
	return resultado
