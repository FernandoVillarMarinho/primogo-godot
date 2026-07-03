class_name LevelFactory
extends RefCounted
## Adaptador de fronteira: LevelResource (disco/engine) -> LevelData (domínio puro).
## Único ponto do contexto Content que conhece o tipo Resource. A leitura do disco
## (ResourceLoader) vive na casca/autoload, que chama este factory.

static func from_resource(res: LevelResource) -> LevelData:
	var elements: Array = []
	for e in res.elements:
		elements.append({"x": e.x, "y": e.y, "primo": e.primo})
	return LevelData.new(
		res.stage,
		res.level,
		res.grid_rows,
		res.grid_cols,
		res.only_one_number,
		res.r,
		elements
	)
