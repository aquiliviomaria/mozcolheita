extends CanvasLayer
## Navegação a 1 Hz, sobre a rede de ruas; seta 3D e indicação fixa no HUD.
var mundo: Node3D
var local_escolhido: Node3D
var empresa_escolhida: int = -1
var destino: Node3D
var rota: Array[Vector3] = []
var seta: Node3D
var texto: Label
var intervalo: float = 0.0
func _ready() -> void:
	layer = 2
	texto = Label.new(); texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); texto.position = Vector2(410,96); texto.size = Vector2(460,60)
	texto.add_theme_color_override("font_color",Color("fff2ac")); texto.add_theme_color_override("font_shadow_color",Color.BLACK); texto.add_theme_constant_override("shadow_outline_size",5); add_child(texto)
	seta = Node3D.new(); seta.scale = Vector3.ONE*0.45; mundo.add_child.call_deferred(seta)
	mundo.caixa(seta,Vector3(0,0,0.3),Vector3(0.3,0.14,1.5),Color("fbd64c"))
	for lado: float in [-1,1]:
		var asa: Node3D = mundo.caixa(seta,Vector3(lado*0.35,0,-0.25),Vector3(0.22,0.14,1.05),Color("fbd64c")); asa.rotation.y = lado*0.75
	for filho: MeshInstance3D in seta.get_children():
		var material: StandardMaterial3D = filho.material_override.duplicate(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; filho.material_override = material

func carga_actual() -> Dictionary:
	if mundo.trator_actual==mundo.caminhao: return mundo.caminhao.carga
	if mundo.trator_actual!=null and mundo.trator_actual.implemento!=null and mundo.trator_actual.implemento.is_in_group("reboques"): return mundo.trator_actual.implemento.carga
	return mundo.sacola

func escolher_destino(carga: Dictionary,origem: Vector3) -> Node3D:
	if is_instance_valid(local_escolhido):
		for c: int in carga:
			if int(carga[c])>0 and mundo.economia.aceita(local_escolhido.numero,c): return local_escolhido
		local_escolhido = null
	var melhor: Node3D; var custo: float = INF
	for fabrica: Node3D in mundo.fabricas:
		if empresa_escolhida>=0 and fabrica.numero!=empresa_escolhida: continue
		for cultura: int in carga:
			if int(carga[cultura])<=0 or not mundo.economia.aceita(fabrica.numero,cultura): continue
			var prioridade: float = 10000
			if mundo.entregas.activas.has(fabrica.numero):
				var p: Dictionary = mundo.entregas.activas[fabrica.numero]
				if not bool(p.concluida) and not bool(p.falhou) and int(p.cultura)==cultura: prioridade = 0
			var distancia: float = prioridade+origem.distance_to(fabrica.position)
			if distancia<custo: melhor = fabrica; custo = distancia
	if melhor==null and empresa_escolhida>=0:
		empresa_escolhida = -1; return escolher_destino(carga,origem)
	return melhor

func projectar(ponto: Vector3) -> Vector3:
	var melhor: Vector3 = ponto; var distancia: float = INF
	for trecho: Dictionary in mundo.comunidade.trocos:
		var a: Vector3 = trecho.a; var b: Vector3 = trecho.b
		var p: Vector3 = a+(b-a)*clampf((ponto-a).dot(b-a)/(b-a).length_squared(),0,1)
		if p.distance_squared_to(ponto)<distancia: melhor = p; distancia = p.distance_squared_to(ponto)
	return melhor

func caminho_ruas(inicio: Vector3,fim: Vector3) -> Array[Vector3]:
	var pontos: Array[Vector3] = [projectar(inicio),projectar(fim)]
	var trocos: Array[Dictionary] = mundo.comunidade.trocos
	for trecho: Dictionary in trocos:
		pontos.append(trecho.a); pontos.append(trecho.b)
	for i: int in range(trocos.size()):
		for j: int in range(i+1,trocos.size()):
			var a: Vector3 = trocos[i].a; var b: Vector3 = trocos[i].b; var c: Vector3 = trocos[j].a; var d: Vector3 = trocos[j].b
			var cruzamento: Variant = Geometry2D.segment_intersects_segment(Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z),Vector2(d.x,d.z))
			if cruzamento!=null: pontos.append(Vector3(cruzamento.x,0,cruzamento.y))
	var grafo: AStar3D = AStar3D.new(); var ids: Dictionary = {}
	for p: Vector3 in pontos:
		var chave: Vector2i = Vector2i(roundi(p.x*10),roundi(p.z*10))
		if not ids.has(chave): ids[chave] = grafo.get_point_count(); grafo.add_point(ids[chave],Vector3(p.x,0,p.z))
	for trecho: Dictionary in trocos:
		var a: Vector3 = trecho.a; var b: Vector3 = trecho.b; var lista: Array[int] = []
		for id: int in grafo.get_point_ids():
			var p: Vector3 = grafo.get_point_position(id); var t: float = (p-a).dot(b-a)/(b-a).length_squared()
			if t>=-0.001 and t<=1.001 and p.distance_to(a+(b-a)*t)<0.1: lista.append(id)
		lista.sort_custom(func(i: int,j: int) -> bool: return grafo.get_point_position(i).distance_squared_to(a)<grafo.get_point_position(j).distance_squared_to(a))
		for i: int in range(lista.size()-1):
			if not grafo.are_points_connected(lista[i],lista[i+1]): grafo.connect_points(lista[i],lista[i+1])
	var resultado: Array[Vector3] = []
	var id_inicio: int = grafo.get_closest_point(pontos[0]); var id_fim: int = grafo.get_closest_point(pontos[1])
	for p: Vector3 in grafo.get_point_path(id_inicio,id_fim): resultado.append(p)
	return resultado

func actualizar_rota(origem: Vector3) -> void:
	rota.clear()
	if destino==null: return
	var entrada: Vector3 = destino.position+Vector3(0,0,-46); entrada.y = 0
	var inicio: Vector3 = origem; inicio.y = 0
	var plano: GDScript = preload("res://scripts/layout.gd")
	if plano.dentro(inicio):
		var portao: Vector3 = plano.PORTOES[0]; var custo: float = INF
		for p: Vector3 in plano.PORTOES:
			var valor: float = inicio.distance_to(p)+p.distance_to(entrada)
			if valor<custo: portao = p; custo = valor
		var fora: Vector3 = plano.exterior(portao)
		rota = plano.caminho(inicio,fora,6)
		inicio = fora
	rota.append_array(caminho_ruas(inicio,entrada)); rota.append(entrada); rota.append(destino.position)
	while not rota.is_empty() and Vector2(rota[0].x-origem.x,rota[0].z-origem.z).length()<5: rota.pop_front()

func _process(delta: float) -> void:
	if mundo.hud==null or not seta.is_inside_tree(): return
	if mundo.pausado(): texto.hide(); seta.hide(); return
	var origem: Vector3 = mundo.trator_actual.position if mundo.trator_actual!=null else mundo.jogador.position
	intervalo -= delta/maxf(1,Engine.time_scale)
	if intervalo<=0:
		intervalo = 1
		destino = escolher_destino(carga_actual(),origem)
		actualizar_rota(origem)
	var activo: bool = destino!=null and mundo.drone_actual==null and not mundo.camera.livre and not mundo.hud.selecao.visible and not mundo.hud.aberto
	texto.visible = activo; seta.visible = activo and not mundo.camera.livre
	if not activo: return
	var proximo: Vector3 = rota[0] if not rota.is_empty() else destino.position
	var direccao: Vector3 = proximo-origem; direccao.y = 0
	seta.position = origem+Vector3.UP*(4.3 if mundo.trator_actual!=null else 2.6)
	if direccao.length()>0.1: seta.rotation.y = atan2(-direccao.x,-direccao.z)
	var relativo: float = wrapf(atan2(-direccao.x,-direccao.z)-mundo.camera.camara.rotation.y,-PI,PI)
	var simbolo: String = "↑" if absf(relativo)<0.65 else "↓" if absf(relativo)>2.5 else "←" if relativo>0 else "→"
	texto.position.x = (get_viewport().get_visible_rect().size.x-460)*0.5
	texto.text = "%s  %s · %d m\nSiga a seta · entre na garagem e pare" % [simbolo,preload("res://scripts/deliveries.gd").EMPRESAS[destino.numero],roundi(origem.distance_to(destino.position))]
