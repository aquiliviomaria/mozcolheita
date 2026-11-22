extends RefCounted
## Agrupa caixas estáticas por material; mantém os colisores e exclui portas móveis.
static func compactar(pai: Node3D,moveis: Array) -> void:
	var grupos: Dictionary = {}
	for filho: Node in pai.get_children():
		if not filho is MeshInstance3D or not filho.mesh is BoxMesh or filho in moveis: continue
		var chave: int = filho.material_override.get_instance_id()
		if not grupos.has(chave): grupos[chave] = {"material":filho.material_override,"transformacoes":[]}
		grupos[chave].transformacoes.append(Transform3D(filho.basis.scaled(filho.mesh.size),filho.position))
		filho.hide()
	for grupo: Dictionary in grupos.values():
		var lote: MultiMeshInstance3D = MultiMeshInstance3D.new(); lote.multimesh = MultiMesh.new(); lote.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var caixa: BoxMesh = BoxMesh.new(); caixa.size = Vector3.ONE; lote.multimesh.mesh = caixa; lote.material_override = grupo.material
		lote.multimesh.instance_count = grupo.transformacoes.size()
		for i: int in range(grupo.transformacoes.size()): lote.multimesh.set_instance_transform(i,grupo.transformacoes[i])
		pai.add_child(lote)
