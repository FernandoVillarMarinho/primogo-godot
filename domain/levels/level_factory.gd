class_name LevelFactory
extends RefCounted
## Adaptador de fronteira: LevelResource (disco/engine) -> LevelData (domínio puro).
## É o ÚNICO ponto do contexto Content que conhece o tipo Resource. A leitura do disco
## (ResourceLoader) vive na casca/autoload (Tarefa 07/11), que chama este factory —
## mantendo LevelData/LevelCatalog 100% testáveis sem engine.

static func from_resource(res: LevelResource) -> LevelData:
	var elements: Array = []
	for e in res.elements:
		elements.append({"x": e.x, "y": e.y, "primo_index": e.primo_index})
	return LevelData.new(
		res.stage,
		res.level,
		res.grid_rows,
		res.grid_cols,
		res.chain,
		res.only_one_number,
		res.disguise,
		elements
	)
