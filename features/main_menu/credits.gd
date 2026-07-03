class_name CreditsView
extends Control
## Feature main_menu — créditos (S-04). 3 textos em sequência atravessando a tela em
## TEMPO REAL (Tween, não frame-counter — D-005), com retorno automático ao menu (BR-044).
## VISUAL/DURAÇÃO PLACEHOLDER: as texturas `Creditos_*` e as durações canônicas (COD-001;
## ⚠️ duas gerações de assets — COD-002) entram na validação visual.

signal credits_finished()

const TEXTS := ["PRIMOGO", "Desenvolvido por Villar", "Obrigado por jogar!"]
const SEG := 1.6   # placeholder (duração canônica = COD-001)

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 40)
	add_child(_label)


func play() -> void:
	for text in TEXTS:
		_label.text = text
		_label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_label, "modulate:a", 1.0, SEG * 0.35)
		tw.tween_interval(SEG * 0.3)
		tw.tween_property(_label, "modulate:a", 0.0, SEG * 0.35)
		await tw.finished
	credits_finished.emit()   # restaura os botões do menu
