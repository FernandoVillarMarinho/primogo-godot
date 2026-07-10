class_name CreditsView
extends Control
## Feature main_menu — créditos (S-04). Painéis em sequência com fade em TEMPO REAL
## (Tween, não frame-counter — D-005), com retorno automático ao menu (BR-044).
## Arte original (T20/Fase 3, fecha COD-002): geração "New" dos assets (creditos_0 →
## creditos_1new → creditos_2new). Versão 2026: 4º painel com a logomarca do DJDE e a
## equipe do Projeto de Desenvolvimento de Jogos Digitais na Educação da UFRJ (item 9
## do 3º teste em dispositivo). Durações canônicas = 🟡 COD-001.

signal credits_finished()

const PANELS: Array = [
	preload("res://assets/images/menu/creditos_0.png"),
	preload("res://assets/images/menu/creditos_1new.png"),
	preload("res://assets/images/menu/creditos_2new.png"),
]
const TEX_DJDE := preload("res://assets/images/menu/djde_logo.png")
const FONT_TEXT := preload("res://assets/fonts/katahdin_round.otf")

const FADE := 0.6   # tempo p/ LER os nomes dos responsáveis (2º teste em dispositivo:
const HOLD := 3.2   # 1.6s por painel era rápido demais) — canônico ainda 🟡 COD-001
const DJDE_HOLD := 7.0   # o painel da equipe 2026 tem mais nomes para ler

const HEAD_COLOR := Color(0.67, 0.36, 0.03)   # laranja dos títulos dos painéis originais
const SHADOW_COLOR := Color(0.15, 0.2, 0.3, 0.55)

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

var _panel: TextureRect
var _djde: Control


func _ready() -> void:
	_panel = TextureRect.new()
	# painéis nativos (828–900px) estouram os 720 de largura: sem EXPAND_IGNORE_SIZE o
	# texto era CORTADO nas bordas e os nomes ficavam ilegíveis
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	_djde = _build_djde_panel()
	add_child(_djde)


func play() -> void:
	_djde.modulate.a = 0.0
	for tex in PANELS:
		_panel.texture = tex
		await _run_segment(_panel, HOLD)
	_panel.texture = null
	await _run_segment(_djde, DJDE_HOLD)   # painel da equipe 2026 (DJDE-UFRJ)
	credits_finished.emit()   # restaura os botões do menu


## Fade-in → leitura → fade-out de um painel qualquer.
func _run_segment(ctrl: Control, hold: float) -> void:
	ctrl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(ctrl, "modulate:a", 1.0, FADE)
	tw.tween_interval(hold)
	tw.tween_property(ctrl, "modulate:a", 0.0, FADE)
	await tw.finished


## Painel DJDE 2026: logomarca + título e nomes no estilo dos painéis originais
## (título laranja, nomes brancos com sombra suave para leitura sobre o céu).
func _build_djde_panel() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 40.0
	col.offset_right = -40.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	root.add_child(col)

	var logo := TextureRect.new()   # djde_logo (900×261, fundo transparente)
	logo.texture = TEX_DJDE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(560, 162)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(logo)
	col.add_child(_spacer(18.0))

	col.add_child(_credits_label(DJDE_TITLE, 32, HEAD_COLOR))
	col.add_child(_spacer(10.0))
	for section in DJDE_SECTIONS:
		col.add_child(_credits_label(str(section[0]), 30, HEAD_COLOR))
		for person in section[1]:
			col.add_child(_credits_label(str(person), 28, Color.WHITE))
		col.add_child(_spacer(10.0))
	return root


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
	return l


func _spacer(h: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
