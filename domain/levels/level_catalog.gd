class_name LevelCatalog
extends RefCounted
## Contêiner puro de LevelData por (stage, level) — contexto Content, somente leitura
## em runtime (C1: 126 níveis). Sem engine. A carga do disco vive na casca/autoload
## (Tarefa 07/11), que alimenta este catálogo via LevelFactory.

var _levels: Dictionary = {}  # Vector2i(stage, level) -> LevelData


## Adiciona (ou substitui) um nível. Retorna a lista de erros de validação (vazia = ok).
func add(data: LevelData) -> PackedStringArray:
	var errors := data.validate()
	if errors.is_empty():
		_levels[data.key()] = data
	return errors


func get_level(stage: int, level: int) -> LevelData:
	return _levels.get(Vector2i(stage, level), null)


func has(stage: int, level: int) -> bool:
	return _levels.has(Vector2i(stage, level))


func size() -> int:
	return _levels.size()


func all() -> Array:
	return _levels.values()
