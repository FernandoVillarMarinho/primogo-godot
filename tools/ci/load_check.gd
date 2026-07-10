extends SceneTree
## CI — carrega os scripts/cenas das features (parse + refs de assets), porque a suíte
## GUT cobre o domínio e não força o parse da casca. Uso:
##   godot --headless --path . -s tools/ci/load_check.gd

const PATHS: Array = [
	"res://features/board/board.gd",
	"res://features/board/game_board.tscn",
	"res://features/board/pause_overlay.gd",
	"res://features/level_select/level_select.tscn",
	"res://features/main_menu/main_menu.tscn",
	"res://features/main_menu/splash.tscn",
	"res://features/main_menu/options_overlay.gd",
	"res://features/main_menu/credits.gd",
	"res://features/tutorial/tutorial_overlay.gd",
	"res://features/shared/digit_renderer.gd",
]


func _init() -> void:
	var failures := 0
	for p in PATHS:
		var res: Resource = load(p)
		if res == null:
			push_error("load_check FALHOU: %s" % p)
			failures += 1
	print("LOAD_CHECK %s (%d/%d)" % ["OK" if failures == 0 else "FAIL", PATHS.size() - failures, PATHS.size()])
	quit(0 if failures == 0 else 1)
