class_name CreditsView
extends Control
## Feature main_menu — créditos (S-04). 3 painéis em sequência com fade em TEMPO REAL
## (Tween, não frame-counter — D-005), com retorno automático ao menu (BR-044).
## Arte original (T20/Fase 3, fecha COD-002): usa a geração "New" dos assets
## (creditos_0 → creditos_1new → creditos_2new); a geração antiga (creditos_1/2,
## creditos1..3) fica no repo como referência. Durações canônicas = 🟡 COD-001.

signal credits_finished()

const PANELS: Array = [
	preload("res://assets/images/menu/creditos_0.png"),
	preload("res://assets/images/menu/creditos_1new.png"),
	preload("res://assets/images/menu/creditos_2new.png"),
]
const FADE := 0.6   # tempo p/ LER os nomes dos responsáveis (2º teste em dispositivo:
const HOLD := 3.2   # 1.6s por painel era rápido demais) — canônico ainda 🟡 COD-001

var _panel: TextureRect


func _ready() -> void:
	_panel = TextureRect.new()
	# painéis nativos (828–900px) estouram os 720 de largura: sem EXPAND_IGNORE_SIZE o
	# texto era CORTADO nas bordas e os nomes ficavam ilegíveis
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)


func play() -> void:
	for tex in PANELS:
		_panel.texture = tex
		_panel.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 1.0, FADE)
		tw.tween_interval(HOLD)
		tw.tween_property(_panel, "modulate:a", 0.0, FADE)
		await tw.finished
	credits_finished.emit()   # restaura os botões do menu
