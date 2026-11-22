extends SceneTree
func _initialize() -> void: executar.call_deferred()
func executar() -> void:
	var mundo: Node3D = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.jogador.position = Vector3(0,0,0)
	# Aquece por tempo real para não misturar a construção inicial com a medição.
	var aquecimento: int = Time.get_ticks_msec()
	while Time.get_ticks_msec()-aquecimento<2000: await process_frame
	var inicio: int = Time.get_ticks_usec(); var quadros: int = 0
	while Time.get_ticks_usec()-inicio<2000000:
		await process_frame; quadros += 1
	print("PERF ESTÁVEL · ",quadros," frames · ms/frame ",float(Time.get_ticks_usec()-inicio)/quadros/1000.0)
	mundo.feedback.audio.stop(); mundo.calendario.amanhecer.stop(); quit()
