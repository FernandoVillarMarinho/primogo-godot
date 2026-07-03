class_name Collection
extends RefCounted
## Coleção de valores coletados na partida — só cresce, sem duplicatas (BR-011).
## A troca pelo balão NÃO devolve o valor corrente (L-09): quem descarta é o Match.

var _values: Array[int] = []


## Retorna false se o valor já estava presente (dedupe).
func add(value: int) -> bool:
	if value in _values:
		return false
	_values.append(value)
	return true


func has(value: int) -> bool:
	return value in _values


func values() -> Array[int]:
	return _values.duplicate()


func size() -> int:
	return _values.size()
