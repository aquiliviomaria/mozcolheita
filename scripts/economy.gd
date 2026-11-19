extends Node
## A venda transfere todos os produtos de uma carga numa única operação, sem duplicação.
const BASE: Array[float] = [18.0,12.0,9.0,14.0]
const FACTORES: Array[Vector4] = [Vector4(1.2,0.92,1.0,0.95),Vector4(0.94,1.24,0.96,1.02),Vector4(1.0,1.02,1.23,1.18)]
var mundo: Node3D
var vendas: int = 0

func preco(fabrica: int, cultura: int) -> int:
	var variacao: float = 1.0+sin(mundo.relogio/90.0+fabrica*1.7+cultura)*0.045
	return maxi(1,roundi(BASE[cultura]*FACTORES[fabrica][cultura]*variacao))

func vender(carga: Dictionary, fabrica: int) -> int:
	if fabrica<0 or fabrica>2: return 0
	var total: int = 0
	for cultura: int in carga.keys():
		if not aceita(fabrica,cultura): continue
		total += maxi(0,int(carga[cultura]))*preco(fabrica,cultura); carga.erase(cultura)
	if total<=0: return 0
	mundo.saldo += total
	vendas += 1
	mundo.avisar("Venda concluída · +%s" % formatar(total))
	return total

func sementes(quantidade: int = 20) -> bool:
	var custo: int = quantidade*2
	if quantidade<=0 or mundo.saldo<custo or not mundo.armazem.perto(): return false
	mundo.saldo -= custo
	mundo.ferramentas.sementes += quantidade
	return true

static func formatar(valor: int) -> String:
	var algarismos: String = str(absi(valor))
	var partes: PackedStringArray = []
	while algarismos.length()>3:
		partes.insert(0,algarismos.right(3))
		algarismos = algarismos.left(algarismos.length()-3)
	partes.insert(0,algarismos)
	return ("-" if valor<0 else "")+".".join(partes)+" MT"

static func aceita(fabrica: int,cultura: int) -> bool:
	return cultura==fabrica or (fabrica==2 and cultura==3)
