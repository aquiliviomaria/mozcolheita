extends SceneTree
func _initialize() -> void: executar.call_deferred()
func executar() -> void:
	var m: Node3D = load("res://scripts/main.gd").new(); root.add_child(m); m.hud.escolher(false); m.jogador.position = Vector3.ZERO
	var actores: Array[Node3D] = []; actores.append_array(m.pessoas); actores.append_array(m.comunidade.trafego); actores.append(m.familia)
	for a: Node3D in actores: a.set_physics_process(false)
	var tempos: Dictionary = {}
	for i: int in range(30):
		await physics_frame
		for a: Node3D in actores:
			var t: int = Time.get_ticks_usec(); a._physics_process(1.0/60); tempos[a] = int(tempos.get(a,0))+Time.get_ticks_usec()-t
	var ordem: Array = tempos.keys(); ordem.sort_custom(func(a: Node3D,b: Node3D) -> bool: return tempos[a]>tempos[b])
	for i: int in range(10):
		var a: Node3D = ordem[i]; print("CUSTO · ",a.get_script().resource_path," ",a.get("nome")," · ",tempos[a]/30.0," us/tick")
	print("INTERNO · fisica ",Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	m.feedback.audio.stop(); m.calendario.amanhecer.stop(); quit()
