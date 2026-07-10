class_name PauseOverlay
extends OverlayBase
## Feature board — modal de pausa (S-07) com a arte original (`gameplay/pause-*`).
## Estende OverlayBase (dim @0,5, trava anti-clique-duplo 1s, sinais — BR-043).
## Toggles de música/efeitos persistem via ProgressionStore (BR-038, mesma fonte única
## do OptionsOverlay); "SELEÇÃO DE FASES"/"SAIR DO JOGO" sinalizam — a navegação é do dono.

signal level_select_requested()
signal quit_requested()

const TEX_BOX := preload("res://assets/images/gameplay/pause-box.png")
const TEX_BT_ON := preload("res://assets/images/gameplay/pause-bt-on.png")
const TEX_BT_OFF := preload("res://assets/images/gameplay/pause-bt-off.png")
const TEX_MUSIC := preload("res://assets/images/gameplay/pause-musica.png")
const TEX_FX := preload("res://assets/images/gameplay/pause-efeitos.png")
const TEX_SELECT := preload("res://assets/images/gameplay/pause-bt-selecaodefases.png")
const TEX_QUIT := preload("res://assets/images/gameplay/pause-bt-sairdojogo.png")
const TEX_CLOSE := preload("res://assets/images/menu/opcoes-bt-fechar.png")


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

	var panel := Control.new()
	panel.custom_minimum_size = Vector2(560, 500)
	center.add_child(panel)

	var box := TextureRect.new()   # pause-box 959×856
	box.texture = TEX_BOX
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(box)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 60.0
	col.offset_bottom = -40.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)

	col.add_child(_toggle_row(TEX_MUSIC, not AudioBus.is_music_muted(),
		func(on: bool) -> void: ProgressionStore.set_audio_pref("music", not on)))
	col.add_child(_toggle_row(TEX_FX, not AudioBus.is_effects_muted(),
		func(on: bool) -> void: ProgressionStore.set_audio_pref("effects", not on)))
	col.add_child(_texture_button(TEX_SELECT, Vector2(380, 71), func() -> void:
		if not is_input_locked():
			level_select_requested.emit()))
	col.add_child(_texture_button(TEX_QUIT, Vector2(380, 71), func() -> void:
		if not is_input_locked():
			quit_requested.emit()))
	col.add_child(_texture_button(TEX_CLOSE, Vector2(70, 73), _on_close_pressed))


## Linha ícone + botão liga/desliga (bases pause-bt-on/off do legado).
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


func _texture_button(tex: Texture2D, target: Vector2, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = target
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


func _on_close_pressed() -> void:
	if not is_input_locked():
		close()
