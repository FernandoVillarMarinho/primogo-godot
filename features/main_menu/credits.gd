class_name CreditsView
extends Control
## Feature main_menu — créditos (S-04). Painéis em sequência com fade em TEMPO REAL
## (Tween, não frame-counter — D-005), com retorno automático ao menu (BR-044).
##
## Reforma do 4º teste em dispositivo (itens 2/3): TODOS os painéis agora são montados
## em Labels com o MESMO tratamento visual (título laranja + nomes brancos com sombra,
## centralizados) — os PNGs legados (creditos_*.png) tinham os nomes brancos SEM sombra
## e ilegíveis sobre o céu; botão "Voltar" visível o tempo todo permite PULAR os créditos
## e devolve o menu imediatamente; a própria view se esconde ao terminar (antes o
## TextureRect de tela cheia continuava bloqueando os cliques no botão Jogar); a logo
## do DJDE fica ancorada EMBAIXO, sobre o jardim verde, sem cobrir a logo do Primogo.

signal credits_finished()

const TEX_DJDE := preload("res://assets/images/menu/djde_logo.png")
const TEX_BACK := preload("res://assets/images/levelselect/bt_voltar.png")
const FONT_TEXT := preload("res://assets/fonts/katahdin_round.otf")

const FADE := 0.6   # tempo p/ LER os nomes dos responsáveis (2º teste em dispositivo:
const HOLD := 3.2   # 1.6s por painel era rápido demais) — canônico ainda 🟡 COD-001
const DJDE_HOLD := 7.0   # o painel da equipe 2026 tem mais nomes para ler

const HEAD_COLOR := Color(0.67, 0.36, 0.03)   # laranja dos títulos dos painéis originais
const SHADOW_COLOR := Color(0.15, 0.2, 0.3, 0.55)

## Conteúdo transcrito dos painéis originais (creditos_0/1new/2new.png) — agora texto
## vivo, com hierarquia visual uniforme em todas as seções (item 3.2 do 4º teste).
const PANELS: Array = [
	[
		["Idealização do Projeto", [
			"André Luiz Souza Silva",
			"Fernando Celso Villar Marinho",
			"Filipe Iorio da Silva",
			"Leonardo Rego Ferreira",
		]],
	],
	[
		["Ilustração", ["Ana Paula Moreira"]],
		["Design Gráfico", ["Juliana Nieri"]],
		["Programação", ["Matheus Felipe Corrêa Alves"]],
	],
	[
		["Game Design", ["André Luiz Souza Silva"]],
		["Coordenação e Produção", [
			"André Luiz Souza Silva",
			"Fernando Celso Villar Marinho",
			"Filipe Iorio da Silva",
		]],
	],
]

const DJDE_TITLE := "Projeto de Desenvolvimento de Jogos Digitais na Educação da UFRJ — 2026"
const DJDE_SECTIONS: Array = [
	["Coordenador-geral", [
		"Fernando Celso Villar Marinho",
	]],
	["Coordenadores dos núcleos", [
		"Carlos Augusto Gomes Soares",
		"Carla Elaine Oliveira de Moraes",
		"Guilherme Carvalho R. da Silveira",
		"Luiz Felipe Abreu Almeida",
		"Marcos Monte de Oliveira Alves",
		"Mariana Rodrigues Mattos",
		"Priscila Marques Dias Corrêa",
	]],
]

var _panels: Array = []      # um Control por painel, todos full-rect com alpha 0
var _tween: Tween = null     # tween do segmento corrente (o pulo o adianta até o fim)
var _run_id := 0             # invalida a corrida de play() quando o usuário pula


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sections in PANELS:
		_panels.append(_build_text_panel(sections, "", false))
	_panels.append(_build_text_panel(DJDE_SECTIONS, DJDE_TITLE, true))
	for p in _panels:
		add_child(p)
	_build_skip_button()
	visible = false   # só aparece durante o play(); escondida NÃO bloqueia o menu


## Roda a apresentação inteira; pode ser chamada de novo a cada visita aos créditos.
func play() -> void:
	visible = true
	_run_id += 1
	var id := _run_id
	for i in _panels.size():
		var hold: float = DJDE_HOLD if i == _panels.size() - 1 else HOLD
		await _run_segment(_panels[i], hold)
		if id != _run_id:
			return   # o usuário pulou: quem encerra é o skip
	_finish()


## Saída antecipada (item 2.1): adianta o tween corrente até o fim (o await do play()
## resolve e a corrida invalida) e devolve o menu imediatamente.
func skip() -> void:
	_run_id += 1
	if _tween != null and _tween.is_valid():
		_tween.custom_step(FADE + maxf(HOLD, DJDE_HOLD) + FADE + 1.0)
	for p in _panels:
		p.modulate.a = 0.0
	_finish()


func _finish() -> void:
	visible = false   # escondida, deixa de interceptar cliques (bug do Jogar travado)
	credits_finished.emit()   # restaura os botões do menu


## Fade-in → leitura → fade-out de um painel qualquer.
func _run_segment(ctrl: Control, hold: float) -> void:
	ctrl.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(ctrl, "modulate:a", 1.0, FADE)
	_tween.tween_interval(hold)
	_tween.tween_property(ctrl, "modulate:a", 0.0, FADE)
	await _tween.finished


## Painel de texto no estilo único dos créditos: título laranja e nomes brancos, TODOS
## com sombra e centralizados (item 3.2). O painel DJDE ganha a logomarca ancorada
## EMBAIXO, sobre o jardim verde — sem cobrir a logo do Primogo no topo (item 3.1).
func _build_text_panel(sections: Array, title: String, with_logo: bool) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 40.0
	col.offset_right = -40.0
	col.offset_top = 380.0      # abaixo da logo do Primogo do menu (composição do S-04)
	col.offset_bottom = -330.0  # acima do jardim (reservado à logo do DJDE)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)

	if title != "":
		col.add_child(_credits_label(title, 32, HEAD_COLOR))
		col.add_child(_spacer(10.0))
	for section in sections:
		col.add_child(_credits_label(str(section[0]), 30, HEAD_COLOR))
		for person in section[1]:
			col.add_child(_credits_label(str(person), 28, Color.WHITE))
		col.add_child(_spacer(10.0))

	if with_logo:
		var logo := TextureRect.new()   # djde_logo (900×261, fundo transparente)
		logo.texture = TEX_DJDE
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)   # sobre o jardim verde
		logo.offset_left = 110.0
		logo.offset_right = -110.0
		logo.offset_top = -210.0
		logo.offset_bottom = -60.0
		root.add_child(logo)
	return root


## Botão Voltar/Pular (item 2.1), sempre visível durante a exibição — mesma arte e
## geometria do voltar da seleção de fases (bt_voltar 175×184 → 88×92).
func _build_skip_button() -> void:
	var back := TextureButton.new()
	back.texture_normal = TEX_BACK
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.custom_minimum_size = Vector2(88, 92)
	back.size = Vector2(88, 92)
	back.position = Vector2(24, 24)
	back.pressed.connect(skip)
	add_child(back)


func _credits_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", FONT_TEXT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s
