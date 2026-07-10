extends SceneTree
## Smoke headless do CreditsView (o painel DJDE 2026 é construído no _ready, fora do
## caminho do load_check). Uso:
##   godot --headless --path . -s res://tools/ci/credits_check.gd

func _init() -> void:
	var view: Control = load("res://features/main_menu/credits.gd").new()
	root.add_child.call_deferred(view)
	await process_frame   # o _ready (que monta os painéis + DJDE) roda no 1º frame
	var labels := _count_labels(view)
	if labels < 10:
		push_error("CREDITS_CHECK: painel DJDE incompleto (%d labels)" % labels)
		quit(1)
		return
	print("CREDITS_CHECK OK (%d labels no painel DJDE)" % labels)
	quit(0)


func _count_labels(node: Node) -> int:
	var n := 1 if node is Label else 0
	for child in node.get_children():
		n += _count_labels(child)
	return n
