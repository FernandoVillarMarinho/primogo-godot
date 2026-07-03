class_name DigitRenderer
extends Control
## Feature shared — renderizador de dígitos (BR-020), substituto do `Number` do legado.
## Por DEV-002 (aprovado), o mecanismo muda de sprites posicionados à mão para uma
## **fonte** (bitmap font convertida de numbers.png/OrangeFont.png/font_Select.png);
## o "layout por contagem" (1–4 dígitos com escala própria, ADR-002) vira ajuste do
## tamanho da fonte para caber na caixa do tile. A `font` é injetável: fica com a fonte
## padrão do tema até a bitmap font ser gerada na validação visual (swap-in, DEV-002).

const MAX_VALUE := 9999   # teto de 4 dígitos (BR-016; máx. real 2491)
const BASE_FONT_SIZE := 48
const MIN_FONT_SIZE := 8
const H_PADDING := 4.0

@export var font: Font
@export var box_size: Vector2 = Vector2(64, 64)

var value: int = 0
var _label: Label


func _ready() -> void:
	_build_label()
	_refresh()


func _build_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	if font != null:
		_label.add_theme_font_override("font", font)
	add_child(_label)


func set_value(v: int) -> void:
	value = clampi(v, 0, MAX_VALUE)
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	var text := str(value)
	_label.add_theme_font_size_override("font_size", fit_font_size(text))
	_label.text = text


## Reduz o tamanho da fonte até os dígitos caberem na largura da caixa (layout por
## contagem, BR-020): 1 dígito grande, 4 dígitos menores. Mede com a fonte efetiva.
func fit_font_size(text: String) -> int:
	var f := _effective_font()
	var max_w := box_size.x - H_PADDING * 2.0
	var size := BASE_FONT_SIZE
	while size > MIN_FONT_SIZE:
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if w <= max_w:
			break
		size -= 2
	return size


func _effective_font() -> Font:
	return font if font != null else ThemeDB.fallback_font
