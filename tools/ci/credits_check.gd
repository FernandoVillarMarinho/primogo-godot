extends SceneTree
## Smoke headless do CreditsView (os 4 painéis de texto + botão de pular são construídos
## no _ready, fora do caminho do load_check). Uso:
##   godot --headless --path . -s res://tools/ci/credits_check.gd

func _init() -> void:
	var view: Control = load("res://features/main_menu/credits.gd").new()
	root.add_child.call_deferred(view)
	await process_frame   # o _ready (que monta os 4 painéis + skip) roda no 1º frame
	var labels := _count(view, "Label")
	var buttons := _count(view, "TextureButton")
	if labels < 20:
		push_error("CREDITS_CHECK: painéis incompletos (%d labels; esperados ≥20)" % labels)
		quit(1)
		return
	if buttons < 1:
		push_error("CREDITS_CHECK: botão de pular ausente")
		quit(1)
		return
	if view.visible:
		push_error("CREDITS_CHECK: a view deveria iniciar escondida (não bloquear o menu)")
		quit(1)
		return
	print("CREDITS_CHECK OK (%d labels, %d botão(ões), inicia escondida)" % [labels, buttons])
	quit(0)


func _count(node: Node, klass: String) -> int:
	var n := 1 if node.is_class(klass) else 0
	for child in node.get_children():
		n += _count(child, klass)
	return n
