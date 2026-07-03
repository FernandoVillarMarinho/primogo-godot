class_name LevelResource
extends Resource
## Schema de conteúdo de uma fase (target_data_model.md §2).
## Gerado pelo pipeline `tools/extraction` (Fase 0, Tarefa 03) a partir das cenas Unity.
##
## É a **fronteira de serialização** (extends Resource = engine). O domínio puro
## `domain/levels` (Tarefa 04) constrói um `LevelData` imutável a partir daqui.
## Runtime só LÊ este recurso (fronteira da topologia: resources/ nunca escrito em runtime).

const DISGUISE_SIZE := 9

@export var stage: int = 0                 ## 1..N (legado: parseado do nome da cena — ADR-005 descartado)
@export var level: int = 0                 ## 1..N
@export var grid_rows: int = 0             ## legado: GameManager.matrixRow
@export var grid_cols: int = 0             ## legado: GameManager.matrixColumn
@export var chain: PackedInt32Array = PackedInt32Array()  ## janela efetiva da cadeia (legado: varsArray[min..max])
@export var only_one_number: bool = false ## legado: LevelManager.onlyOneNumber
@export var disguise: PackedFloat32Array = PackedFloat32Array([2, 1, 1, 1, 1, 1, 1, 1, 1])  ## legado: LevelManager.r
@export var elements: Array[LevelElement] = []  ## elements[0] = jogador


## Retorna a lista de erros estruturais (vazia = válido).
## Aplicada na extração E na carga (target_data_model §2, restrições C2/C3).
## Nota: a checagem "valor gerado chain[i]*chain[i-1] ≤ 9999" é regra de geração
## do domínio (domain/levels, Tarefa 04) — validada lá, não aqui.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if stage < 1:
		errors.append("stage inválido (%d): deve ser ≥ 1" % stage)
	if level < 1:
		errors.append("level inválido (%d): deve ser ≥ 1" % level)
	if grid_rows < 1 or grid_cols < 1:
		errors.append("dimensões inválidas: %dx%d" % [grid_rows, grid_cols])
	if disguise.size() != DISGUISE_SIZE:
		errors.append("disguise.size()=%d: esperado %d" % [disguise.size(), DISGUISE_SIZE])
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
		if chain.size() > 0 and (e.primo_index < 0 or e.primo_index >= chain.size()):
			errors.append("elements[%d].primo_index=%d fora da cadeia (size=%d)" % [i, e.primo_index, chain.size()])
		var key := Vector2i(e.x, e.y)
		if seen.has(key):
			errors.append("posição duplicada em elements[%d]: (%d,%d)" % [i, e.x, e.y])
		seen[key] = true

	return errors


func is_valid() -> bool:
	return validate().is_empty()


## Insumo da decisão G-01 (fatorabilidade): a janela alcança o não-primo 27?
## Níveis assim são LISTADOS pelo relatório de extração, nunca rejeitados.
func chain_reaches_27() -> bool:
	return chain.has(27)
