class_name OptionsOverlay
extends OverlayBase
## Feature main_menu — overlay de opções (S-03). Estende OverlayBase (dim @0,5, trava
## anti-clique-duplo de 1s, sinais que substituem o static optionsActive — BR-043).
## Toggles de música/efeitos independentes e persistentes (BR-038): escrevem no
## ProgressionStore (única porta do save, AD-04), que reemite p/ o AudioBus aplicar o
## mute — fonte única, sem checagem espalhada.
## Arte original (T20/Fase 3): opcoes-box, toggles pause-bt-on/off com ícones
## pause-musica/pause-efeitos, opcoes-bt-creditos, opcoes-bt-fechar (+base).

signal credits_requested()

const TEX_BOX := preload("res://assets/images/menu/opcoes-box.png")
const TEX_BT_ON := preload("res://assets/images/menu/pause-bt-on.png")
const TEX_BT_OFF := preload("res://assets/images/menu/pause-bt-off.png")
const TEX_MUSIC := preload("res://assets/images/menu/pause-musica.png")
const TEX_FX := preload("res://assets/images/menu/pause-efeitos.png")
const TEX_CREDITS := preload("res://assets/images/menu/opcoes-bt-creditos.png")
const TEX_CLOSE := preload("res://assets/images/menu/opcoes-bt-fechar.png")
const TEX_CLOSE_BASE := preload("res://assets/images/menu/opcoes-bt-fechar-base.png")


func _ready() -> void:
	super()   # OverlayBase: monta o dim e esconde
	_build_panel()


func _build_panel() -> void:
	# CenterContainer garante o painel no CENTRO (PRESET_CENTER + min size desloca — bug
	# do teste em dispositivo); as artes são maiores que o alvo → tamanhos explícitos.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(560, 500)
	center.add_child(holder)

	var box := TextureRect.new()   # opcoes-box 959×856
	box.texture = TEX_BOX
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(box)

	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 60.0
	panel.offset_bottom = -40.0
	panel.add_theme_constant_override("separation", 20)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.add_child(panel)

	panel.add_child(_toggle_row(TEX_MUSIC, not AudioBus.is_music_muted(),
		func(on: bool) -> void: ProgressionStore.set_audio_pref("music", not on)))
	panel.add_child(_toggle_row(TEX_FX, not AudioBus.is_effects_muted(),
		func(on: bool) -> void: ProgressionStore.set_audio_pref("effects", not on)))

	var credits := TextureButton.new()   # opcoes-bt-creditos 591×110
	credits.texture_normal = TEX_CREDITS
	credits.ignore_texture_size = true
	credits.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	credits.custom_minimum_size = Vector2(380, 71)
	credits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits.pressed.connect(func() -> void: credits_requested.emit())
	panel.add_child(credits)

	var close_holder := Control.new()   # opcoes-bt-fechar 131×137 sobre a base
	close_holder.custom_minimum_size = Vector2(90, 94)
	close_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var close_base := TextureRect.new()
	close_base.texture = TEX_CLOSE_BASE
	close_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_base.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_holder.add_child(close_base)
	var close_btn := TextureButton.new()
	close_btn.texture_normal = TEX_CLOSE
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_btn.pressed.connect(_on_close_pressed)
	close_holder.add_child(close_btn)
	panel.add_child(close_holder)


## Linha ícone + botão liga/desliga (bases pause-bt-on/off, mesma linguagem do pause S-07).
func _toggle_row(icon: Texture2D, initially_on: bool, on_toggle: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 20)
	var ic := TextureRect.new()
	ic.texture = icon
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(170, 50)
	row.add_child(ic)
	var bt := TextureButton.new()
	bt.toggle_mode = true
	bt.button_pressed = initially_on
	bt.texture_normal = TEX_BT_ON if initially_on else TEX_BT_OFF
	bt.ignore_texture_size = true
	bt.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	bt.custom_minimum_size = Vector2(140, 51)
	bt.toggled.connect(func(on: bool) -> void:
		bt.texture_normal = TEX_BT_ON if on else TEX_BT_OFF
		on_toggle.call(on))
	row.add_child(bt)
	return row


## Fechar ignora cliques durante a trava de 1s pós-abertura (BR-043).
func _on_close_pressed() -> void:
	if not is_input_locked():
		close()
