extends RefCounted
## Notícias verificadas têm data/fonte; boletins locais usam o estado real da partida.
const VERIFICADO: String = "22/11/2026"
const NOTICIAS: Array[Dictionary] = [
	{"id":"recorde","tema":"JOGOS","painel":"GTA VI","titulo":"GTA VI BATE RECORDES","linha1":"Take-Two: 3,79 mil milhoes USD","linha2":"em vendas no primeiro dia","fonte":"Take-Two · 20/11/2026"},
	{"id":"critica","tema":"JOGOS","painel":"CRITICA","titulo":"RECONHECIMENTO DO GTA VI","linha1":"Take-Two destaca notas da critica","linha2":"no comunicado sobre os recordes","fonte":"Take-Two · 20/11/2026"},
	{"id":"musica","tema":"CULTURA","painel":"MUSICA","titulo":"AS MUSICAS DE GTA VI","linha1":"Album oficial ja pode ser ouvido","linha2":"nas plataformas de musica","fonte":"Rockstar Newswire · 20/11/2026"},
	{"id":"leonida","tema":"JOGOS","painel":"LEONIDA","titulo":"UM PASSEIO POR VICE CITY","linha1":"Rockstar apresenta lugares e pessoas","linha2":"do mundo de Leonida","fonte":"Rockstar Games · GTA VI"},
	{"id":"jason","tema":"JOGOS","painel":"HISTORIA","titulo":"JASON E LUCIA EM DESTAQUE","linha1":"Os protagonistas da historia de GTA VI","linha2":"no centro da cobertura da Rockstar","fonte":"Rockstar Games · GTA VI"},
	{"id":"radio","tema":"CULTURA","painel":"RADIO","titulo":"RADIOS E BANDA SONORA","linha1":"Musica faz parte do mundo de GTA VI","linha2":"Rockstar apresenta as suas estacoes","fonte":"Rockstar Newswire · 08/10/2026"},
	{"id":"colheita","tema":"QUINTA","painel":"COLHEITA","titulo":"PRODUCAO NA NOSSA REGIAO","dinamica":"stock"},
	{"id":"entregas","tema":"ECONOMIA","painel":"MERCADO","titulo":"ENCOMENDAS EM ANDAMENTO","dinamica":"entregas"},
	{"id":"emprego","tema":"COMUNIDADE","painel":"TRABALHO","titulo":"TRABALHO NAS MACHAMBAS","dinamica":"emprego"},
	{"id":"hora","tema":"COMUNIDADE","painel":"REGIAO","titulo":"O RITMO DA COMUNIDADE","dinamica":"hora"},
	{"id":"rotacao","tema":"AGRICULTURA","painel":"SOLO","titulo":"CUIDAR DA TERRA","linha1":"Alternar familias de culturas","linha2":"ajuda a preservar a saude do solo","fonte":"MOZTV · guia agricola do jogo"},
	{"id":"rega","tema":"AGRICULTURA","painel":"AGUA","titulo":"REGA ANTES DO CRESCIMENTO","linha1":"Na MozColheita, a rega inicia o ciclo","linha2":"Verifique a humidade da parcela","fonte":"MOZTV · guia agricola do jogo"}
]
static func actualizar(base: Dictionary,mundo: Node3D) -> Dictionary:
	var n: Dictionary = base.duplicate()
	if not n.has("dinamica"): return n
	n.fonte = "MOZTV · dados desta partida"
	if mundo==null:
		n.linha1 = "Noticias da comunidade agricola"; n.linha2 = "Acompanhe as actividades da regiao"; return n
	match str(n.dinamica):
		"stock":
			var total: int = 0
			for valor: Variant in mundo.stock.values(): total += int(valor)
			n.linha1 = str(total)+" produtos guardados no armazem"; n.linha2 = "A producao muda com cada colheita"
		"entregas":
			n.linha1 = str(mundo.entregas.activas.size())+" encomendas activas na quinta"
			n.linha2 = str(mundo.entregas.concluidas)+" entregas concluidas ate agora"
		"emprego":
			var total: int = 0
			for p: Node3D in mundo.pessoas:
				if p.contratado or p.grupo: total += 1
			n.linha1 = str(total)+" trabalhadores em contratos locais"; n.linha2 = "Vizinhos tambem cuidam das suas terras"
		"hora":
			var noite: bool = fmod(mundo.calendario.decorrido,600)>=300
			n.linha1 = "Moradores regressam as suas casas" if noite else "Machambas e quintais em actividade"
			n.linha2 = "Hora local: "+mundo.calendario.hora()
	return n
