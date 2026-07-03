extends GutTest
## Tarefa 10 — features/shared: overlay base (BR-043/D-006), efeitos de escala
## (BR-045/BR-042) e renderizador de dígitos (BR-020/BR-016/DEV-002).

# ---------------------------------------------------------------- overlay base (BR-043)

func test_overlay_dim_is_half_black() -> void:
	var ov := OverlayBase.new()
	add_child_autofree(ov)
	assert_eq(ov._dim.color, Color(0, 0, 0, OverlayBase.DIM_ALPHA), "dim = preto @ alpha 0,5")
	assert_eq(ov._dim.mouse_filter, Control.MOUSE_FILTER_STOP, "dim engole cliques da cena de trás")
	assert_false(ov.is_open(), "começa fechado")


func test_overlay_open_close_signals() -> void:
	var ov := OverlayBase.new()
	add_child_autofree(ov)
	watch_signals(ov)
	ov.open()
	assert_true(ov.is_open(), "abre")
	assert_true(ov.visible, "fica visível")
	assert_signal_emitted(ov, "overlay_opened")
	ov.open()  # reabrir já aberto é no-op
	assert_signal_emit_count(ov, "overlay_opened", 1, "não reemite ao reabrir")
	ov.close()
	assert_false(ov.is_open(), "fecha")
	assert_signal_emitted(ov, "overlay_closed")


func test_overlay_anti_double_click_lock() -> void:
	var ov := OverlayBase.new()
	add_child_autofree(ov)
	ov.open()
	assert_true(ov.is_input_locked(), "trava anti-clique-duplo ativa logo após abrir (1s)")


# ---------------------------------------------------------------- efeitos de escala (BR-045)

func test_logo_oscillation_damps_to_base() -> void:
	# 0.4 + e^(−0.8t)·cos(15t+11): em t grande converge à assíntota 0.4.
	assert_almost_eq(ScaleEffects.logo_osc_value(100.0), 0.4, 0.001, "amortece para 0.4")
	# em t=0 o termo amortecido é máximo → afasta-se de 0.4.
	assert_ne(ScaleEffects.logo_osc_value(0.0), 0.4, "em t=0 oscila fora da base")


func test_scale_effects_return_tweens() -> void:
	var n := Node2D.new()
	add_child_autofree(n)
	assert_true(ScaleEffects.press(n) is Tween, "press devolve um Tween")
	assert_true(ScaleEffects.swing_refuse(n) is Tween, "swing_refuse devolve um Tween")


# ---------------------------------------------------------------- dígitos (BR-020/016)

func test_digit_value_clamped_to_four_digits() -> void:
	var d := DigitRenderer.new()
	add_child_autofree(d)
	d.set_value(12000)
	assert_eq(d.value, DigitRenderer.MAX_VALUE, "valor > 9999 é limitado ao teto (BR-016)")
	d.set_value(5)
	assert_eq(d.value, 5, "valor normal preservado")


func test_digit_font_shrinks_with_more_digits() -> void:
	var d := DigitRenderer.new()
	add_child_autofree(d)
	var one := d.fit_font_size("1")
	var four := d.fit_font_size("9999")
	assert_gt(one, four, "4 dígitos usam fonte menor que 1 dígito (layout por contagem, BR-020)")
	assert_lte(one, DigitRenderer.BASE_FONT_SIZE, "não passa do tamanho base")
