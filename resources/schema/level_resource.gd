class_name LevelResource
extends Resource
## Schema de conteúdo de uma fase — dados reais extraídos das cenas Unity (Fase 0).
## Fronteira de serialização (extends Resource). O domínio puro `domain/levels`
## (LevelData) constrói a partir daqui e reproduz a geração do legado (CreateTile).
##
## Geração (ver LevelData): jogador = elements[0].primo; congelado i =
## elements[i].primo * elements[i-1].primo (ou * elements[0].primo se only_one_number);
## exibido = int(trueValue * r[i-1]). `r` é o disfarce, VARIÁVEL por fase.

@export var stage: int = 0            ## 1..10 (nome da cena; ADR-005 descartado)
@export var level: int = 0            ## 0..12 (0 = nível tutorial _00)
@export var grid_rows: int = 0        ## legado: GameManager.matrixRow
@export var grid_cols: int = 0        ## legado: GameManager.matrixColumn
@export var only_one_number: bool = false
@export var r: PackedFloat32Array = PackedFloat32Array()  ## disfarce por fase (LevelManager.r)
@export var elements: Array[LevelElement] = []            ## elements[0] = jogador


## Erros estruturais (vazio = válido). C2/C3: aplicada na carga (falha explícita).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if stage < 1:
		errors.append("stage inválido (%d)" % stage)
	if level < 0:
		errors.append("level inválido (%d)" % level)
	if grid_rows < 1 or grid_cols < 1:
		errors.append("dimensões inválidas: %dx%d" % [grid_cols, grid_rows])
	if elements.size() < 2:
		errors.append("elements.size()=%d: mínimo 2 (jogador + ao menos 1)" % elements.size())

	var seen := {}
	for i in elements.size():
		var e := elements[i]
		if e == null:
			errors.append("elements[%d] é nulo" % i)
			continue
		if grid_cols > 0 and grid_rows > 0:
			if e.x < 0 or e.x >= grid_cols or e.y < 0 or e.y >= grid_rows:
				errors.append("elements[%d] fora do grid: (%d,%d) em %dx%d" % [i, e.x, e.y, grid_cols, grid_rows])
		var key := Vector2i(e.x, e.y)
		if seen.has(key):
			errors.append("posição duplicada em elements[%d]: (%d,%d)" % [i, e.x, e.y])
		seen[key] = true
	return errors


func is_valid() -> bool:
	return validate().is_empty()
