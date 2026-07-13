extends SceneTree
## Auditoria dos números das fases (item 4 do 4º teste em dispositivo): todo congelado
## precisa exibir um número divisível por ao menos um primo OBTENÍVEL na fase (o valor
## do jogador, os fatores de fallback dos congelados ou os quocientes coletáveis) —
## senão a fase trava (como o 142 da 1-6 antes da correção do truncamento float32).
## Uso:
##   godot --headless --path . -s res://tools/ci/levels_check.gd

func _init() -> void:
	var dir := DirAccess.open("res://resources/levels")
	var files := dir.get_files()
	files.sort()
	var cells := 0
	var bad := 0
	for f in files:
		if not f.ends_with(".tres"):
			continue
		var res := load("res://resources/levels/" + String(f)) as LevelResource
		if res == null:
			continue
		var data := LevelFactory.from_resource(res)
		var frozen := data.generate_frozen()
		# Fixpoint dos valores OBTENÍVEIS: começa com o valor do jogador; um congelado
		# consumível por v (exibido % v == 0) concede o quociente real (true ÷ v) ou o
		# primo de fallback (BR-001) — inclusive o valor 1 ("mecânica do 1" das fases
		# altas: primo=1 concede 1, e com o fogo em 1 qualquer número é divisível).
		var obtainable := {data.player_true_value(): true}
		var changed := true
		while changed:
			changed = false
			for fr in frozen:
				for v in obtainable.keys():
					if int(v) >= 1 and int(fr["displayed_value"]) % int(v) == 0:
						var got: int = int(fr["true_value"]) / int(v) \
							if int(fr["true_value"]) % int(v) == 0 else int(fr["primo"])
						if not obtainable.has(got):
							obtainable[got] = true
							changed = true
		for fr in frozen:
			cells += 1
			var d := int(fr["displayed_value"])
			var divisible := false
			for v in obtainable.keys():
				if int(v) >= 1 and d % int(v) == 0:
					divisible = true
					break
			if not divisible:
				bad += 1
				push_error("LEVELS_CHECK: %s (%d,%d) exibe %d — indivisível pelos obteníveis %s"
					% [String(f), int(fr["x"]), int(fr["y"]), d, str(obtainable.keys())])
	if bad > 0:
		push_error("LEVELS_CHECK FALHOU: %d de %d células indivisíveis" % [bad, cells])
		quit(1)
		return
	print("LEVELS_CHECK OK (%d células congeladas, todas divisíveis por um primo obtenível)" % cells)
	quit(0)
