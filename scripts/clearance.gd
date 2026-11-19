extends RefCounted
## Verifica todo o volume rebocado antes do engate e depois de cada movimento.
static func livre(mundo: Node3D,veiculo: CharacterBody3D,maquina: Node3D) -> bool:
	var origem: Vector3 = veiculo.to_global(Vector3(0,0,maquina.distancia_engate))
	origem.y = mundo.altura(origem)
	var base: Basis = Basis(Vector3.UP,veiculo.rotation.y)
	var forma: BoxShape3D = BoxShape3D.new(); forma.size = maquina.volume*0.96
	var consulta: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma
	consulta.transform = Transform3D(base,origem+base*maquina.centro_colisao)
	consulta.collision_mask = 1|2|4|8
	var exclusoes: Array[RID] = [veiculo.get_rid(),maquina.corpo.get_rid(),mundo.relevo.corpo_chao.get_rid()]
	if mundo.trator_actual==veiculo: exclusoes.append(mundo.jogador.get_rid())
	consulta.exclude = exclusoes
	return mundo.get_world_3d().direct_space_state.intersect_shape(consulta,1).is_empty()
