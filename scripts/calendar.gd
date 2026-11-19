extends Node
## Um dia de jogo dura dez minutos reais. Crescimento mede três dias completos.
const SEGUNDOS_DIA: float = 600.0
const CRESCIMENTO: float = SEGUNDOS_DIA*3.0
var mundo: Node3D
var decorrido: float = 0.0
var velocidade: float = 1.0
var amanhecer: AudioStreamPlayer
var ultimo_dia: int = 1

func _ready() -> void:
	amanhecer = AudioStreamPlayer.new(); amanhecer.volume_db = -12
	amanhecer.stream = preload("res://scripts/daylight.gd").canto_galo()
	add_child(amanhecer)
func dia() -> int: return 1+floori(decorrido/SEGUNDOS_DIA)
func hora() -> String:
	var minutos: int = posmod(360+floori(decorrido/SEGUNDOS_DIA*1440),1440)
	return "Dia %d · %02d:%02d" % [dia(),minutos/60,minutos%60]
func saltar(dias: int = 1) -> void:
	if mundo.contrato.activo: return
	var segundos: float = clampi(dias,1,3)*SEGUNDOS_DIA
	avancar(segundos)
	mundo.terreno.avancar(segundos)
	mundo.avisar("%s · calendário e crescimento avançados." % hora())
	if mundo.entregas!=null: mundo.entregas.verificar_prazos()
	if mundo.contrato!=null: mundo.contrato.verificar_prazos()
func avancar(segundos: float) -> void:
	decorrido += segundos
	mundo.relogio += segundos
	verificar_amanhecer()

func verificar_amanhecer() -> void:
	if dia()>ultimo_dia and amanhecer!=null: amanhecer.play()
	ultimo_dia = dia()

func proximo_periodo() -> void:
	if mundo.contrato.activo: return
	# L alterna 18:00 e 06:00; nunca recua nem ignora prazos.
	var meio_dia: float = SEGUNDOS_DIA*0.5
	var segundos: float = (floorf(decorrido/meio_dia)+1)*meio_dia-decorrido
	avancar(segundos)
	mundo.terreno.avancar(segundos)
	mundo.entregas.verificar_prazos(); mundo.contrato.verificar_prazos()
	mundo.avisar("%s · %s" % [hora(),"Bom dia!" if fmod(decorrido,SEGUNDOS_DIA)<meio_dia else "Anoiteceu."])

func _process(delta: float) -> void:
	if not mundo.pausado():
		decorrido += delta
		verificar_amanhecer()

func alternar_velocidade() -> void:
	velocidade = 12.0 if velocidade==1.0 else 1.0
	Engine.time_scale = velocidade

func restante(segundos: float) -> String:
	var minutos: int = maxi(0,ceili(segundos/SEGUNDOS_DIA*1440))
	return "%dd %02dh %02dm" % [minutos/1440,(minutos%1440)/60,minutos%60]
