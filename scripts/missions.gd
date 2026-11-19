extends Node
## A produção conta apenas colheitas efectivas, independentemente de quem trabalha.
const PRODUTOS: Array[String] = ["tomates","espigas de milho","couves","cenouras"]
const METAS: Array[int] = [500,400,300,350]
const PREMIOS: Array[int] = [15000,18000,16000,17500]
var mundo: Node3D
var indice: int = 0
var produzido: int = 0
var a_finalizar: bool = false
var historico: int = 0

func cultura() -> int: return indice%4
func identificador() -> int: return indice+1
func restante() -> int: return maxi(0,METAS[cultura()]-produzido)
func titulo() -> String:
	return "Produzir %d %s" % [METAS[cultura()],PRODUTOS[cultura()]]
func resumo() -> String: return "%s · %d/%d" % [titulo(),produzido,METAS[cultura()]]

func registar(tipo: int,quantidade: int) -> void:
	if tipo!=cultura() or quantidade<=0 or a_finalizar: return
	produzido = mini(METAS[cultura()],produzido+quantidade)
	if restante()==0:
		a_finalizar = true; finalizar.call_deferred()

func finalizar() -> void:
	if not a_finalizar: return
	var premio: int = PREMIOS[cultura()]
	var anterior: int = identificador()
	# A chamada diferida deixa a tarefa de colheita contabilizar o seu trabalho primeiro.
	for pessoa: Node3D in mundo.pessoas:
		if not pessoa.servico.is_empty() and int(pessoa.servico.missao)==anterior:
			if mundo.contrato.activo and mundo.contrato.pessoa==pessoa: mundo.contrato.terminar(false)
			else: mundo.contrato.encerrar(pessoa,"Missão concluída")
	mundo.saldo += premio; historico += 1; indice += 1; produzido = 0; a_finalizar = false
	mundo.avisar("Missão concluída! +%d MT. %s" % [premio,titulo()])
