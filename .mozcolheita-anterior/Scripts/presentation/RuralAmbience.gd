extends AudioStreamPlayer
## Original procedural rural soundscape, streamed as a single looping mono asset.
func _ready() -> void:
	stream = preload("res://Assets/Audio/rural_day.wav")
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = 529200
	volume_db = -5
	play()
func _process(delta: float) -> void:
	if GameManager.session == null: return
	var hour: int = GameManager.session.time.current_hour
	volume_db = move_toward(volume_db,-12 if hour>=18 or hour<6 else -5,delta)
