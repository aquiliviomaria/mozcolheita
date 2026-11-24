extends "res://validation/casa_servicos/capture.gd"
## Captura isolada do parque para rever alterações de implantação.
func executar() -> void:
	mundo = load("res://scripts/main.gd").new(); root.add_child(mundo); mundo.hud.escolher(false); mundo.calendario.set_process(false); mundo.calendario.decorrido = 100; mundo.camera.set_process(false); mundo.jogador.set_physics_process(false)
	await foto("parque-maquinas",Vector3(-75,34,53),Vector3(-23,2,7))
	quit()
