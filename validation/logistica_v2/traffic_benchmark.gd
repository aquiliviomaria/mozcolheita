extends SceneTree
func _initialize() -> void: executar.call_deferred()
func antigo(a: CharacterBody3D,delta: float) -> void:
	var d: Vector3 = a.rota[a.segmento]-a.position; d.y = 0
	if d.length()<0.4: a.segmento = (a.segmento+1)%a.rota.size(); return
	var dir: Vector3 = d.normalized()
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(a.position+Vector3.UP,a.position+Vector3.UP+dir*7,2|4|16); q.exclude = [a.get_rid()]
	var livre: bool = a.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	a.rotation.y = lerp_angle(a.rotation.y,atan2(-dir.x,-dir.z),minf(1,delta*4))
	a.velocity = dir*(minf(6,d.length()/delta) if livre else 0); a.velocity.y = -2; a.move_and_slide()
	for r: Node3D in a.rodas: r.rotate_object_local(Vector3.UP,delta*(6 if livre else 0))
func executar() -> void:
	var m: Node3D = load("res://scripts/main.gd").new(); root.add_child(m); m.hud.escolher(false)
	for p: Node3D in m.pessoas: p.set_physics_process(false)
	var actores: Array = m.comunidade.trafego; var estados: Array = []
	for a: CharacterBody3D in actores: a.set_physics_process(false); estados.append([a.transform,a.segmento])
	var resultados: Array[float] = []
	for versao: int in range(2):
		for i: int in range(actores.size()):
			actores[i].transform = estados[i][0]; actores[i].segmento = estados[i][1]; actores[i].collision_mask = 1|2|4|8|16 if versao==0 else 2|4|8|16
		var custo: int = 0
		for i: int in range(60):
			await physics_frame; var t: int = Time.get_ticks_usec()
			for a: CharacterBody3D in actores:
				if versao==0: antigo(a,1.0/60)
				else: a._physics_process(1.0/60)
			custo += Time.get_ticks_usec()-t
		resultados.append(custo/60000.0)
	print("TRÁFEGO · ",actores.size()," veículos · antes ",resultados[0]," ms/tick · depois ",resultados[1]," ms/tick · redução ",(1-resultados[1]/resultados[0])*100,"%")
	m.feedback.audio.stop(); m.calendario.amanhecer.stop(); quit()
