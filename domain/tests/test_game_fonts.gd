extends GutTest
## Tarefa 18 (Fase 3) — bitmap fonts originais (DEV-002): as 4 fontes convertidas dos
## .fnt do legado carregam como Font e medem os 10 dígitos com largura positiva.


func _fonts() -> Dictionary:
	return {
		"player (Fonts2/font)": GameFonts.PLAYER,
		"tile (Fonts2/OrangeFont)": GameFonts.TILE,
		"numbers (Fonts/numbers)": GameFonts.NUMBERS,
		"select (Fonts/font_Select)": GameFonts.SELECT,
	}


func test_fonts_load_as_font() -> void:
	for label in _fonts():
		var f: Variant = _fonts()[label]
		assert_true(f is Font, "%s importa como Font" % label)


func test_all_digits_have_positive_width() -> void:
	for label in _fonts():
		var f: Font = _fonts()[label]
		for d in 10:
			var size := f.get_string_size(str(d))
			assert_gt(size.x, 0.0, "%s: dígito %d tem largura > 0" % [label, d])


func test_digit_widths_follow_legacy_metrics() -> void:
	# nas fontes proporcionais o "1" é o glifo mais estreito (xadvance menor no .fnt);
	# numbers.png é monoespaçada por design (células uniformes de 56 px no .meta do legado)
	for label in ["player (Fonts2/font)", "tile (Fonts2/OrangeFont)", "select (Fonts/font_Select)"]:
		var f: Font = _fonts()[label]
		var one := f.get_string_size("1").x
		var zero := f.get_string_size("0").x
		assert_lt(one, zero, "%s: '1' mais estreito que '0' (métrica do .fnt)" % label)
	var mono: Font = GameFonts.NUMBERS
	assert_eq(mono.get_string_size("1").x, mono.get_string_size("0").x,
		"numbers: monoespaçada (células uniformes)")


func test_digit_renderer_accepts_original_font() -> void:
	var d := DigitRenderer.new()
	d.font = GameFonts.PLAYER
	add_child_autofree(d)
	d.set_value(42)
	assert_gt(d.fit_font_size("42"), 0, "DigitRenderer dimensiona com a fonte original")
