extends PanelContainer
@onready var help_text: Label = %HelpText
func _ready() -> void:
	hide()
	help_text.add_theme_font_size_override("font_size",14)
	_refresh_controls_text()
func _input(event: InputEvent) -> void:
	if GameInput.is_help_toggle_event(event):
		visible = not visible
		get_viewport().set_input_as_handled()
func _refresh_controls_text() -> void:
	var rows: Array[String] = [
		"MOZCOLHEITA · COMANDOS [F1]",
		"",
		"A PÉ  ·  WASD andar · Shift correr · Espaço saltar",
		"H preparar terra · 1–6 escolher cultura · I semear · R colher",
		"Roda / 7 Enxada · 8 Serrote · 9 Martelo · Clique usar",
		"Serrote: 3 cortes / árvore · Martelo + G: estufa (12 madeira)",
		"F conversar / contratar: 8 MT por tarefa · Tab cursor",
		"J comer · K beber no poço · T descansar / repor sementes",
		"F interagir / conduzir · L/U guardar / retirar alimentos",
		"",
		"TRACTOR  ·  WASD conduzir · Espaço travar · F sair",
		"7 charrua · 8 semeadora · 9 tanque de rega",
		"P acoplar (parado e perto) · V baixar · B ligar",
		"I liga a semeadora · 1–6 escolhem a cultura",
		"K abastece na estação / poço · Y faróis",
		"Z engate antigo · X elevar · C tomada de força · G engate",
		"",
		"DRONE  ·  F8 lançar / regressar (a pé)",
		"WASD voar · Q descer · E subir · Rato olhar",
		"Espaço ligar / desligar rega · K abastecer na estação",
		"",
		"CERCAS  ·  N construir / terminar (a pé)",
		"Clique marca postes (1,5–8 m) · Direito cancela",
		"Delete remove a secção para a qual está a olhar",
		"",
		"M mapa · O personagem / tractor · Esc pausa / guardar",
		"Ctrl+roda zoom · Q/E altura da câmara · F2 interface"
	]
	help_text.text = "\n".join(rows)
