class_name Grid
extends RefCounted
## Matriz cols×rows de Cell — indexação [x][y], y cresce para baixo (BR-017).
## Fora-do-grid retorna a sentinela NOTHING (BR-018). Puro, sem engine.

var cols: int
var rows: int
var _cells: Array  ## Array[col] de Array[row] de Cell


func _init(p_cols: int = 0, p_rows: int = 0) -> void:
	cols = p_cols
	rows = p_rows
	_cells = []
	for x in cols:
		var col: Array = []
		for y in rows:
			col.append(Cell.empty(x, y))
		_cells.append(col)


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < cols and y >= 0 and y < rows


func at(x: int, y: int) -> Cell:
	if in_bounds(x, y):
		return _cells[x][y]
	return Cell.nothing()


func set_cell(x: int, y: int, cell: Cell) -> void:
	cell.x = x
	cell.y = y
	_cells[x][y] = cell


## Varredura em ordem coluna-maior (x externo, y interno) — mesma do legado.
func find_player() -> Vector2i:
	for x in cols:
		for y in rows:
			if _cells[x][y].kind == Cell.Kind.PLAYER:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func count_frozen() -> int:
	var n := 0
	for x in cols:
		for y in rows:
			if _cells[x][y].kind == Cell.Kind.FROZEN:
				n += 1
	return n


func frozen_positions() -> Array:
	var out: Array = []
	for x in cols:
		for y in rows:
			if _cells[x][y].kind == Cell.Kind.FROZEN:
				out.append(Vector2i(x, y))
	return out


func has_empty() -> bool:
	for x in cols:
		for y in rows:
			if _cells[x][y].kind == Cell.Kind.EMPTY:
				return true
	return false


## Destrói todo o gelo (BR-004). Retorna a quantidade derretida.
func snow_break() -> int:
	var n := 0
	for x in cols:
		for y in rows:
			if _cells[x][y].kind == Cell.Kind.ICE:
				_cells[x][y] = Cell.empty(x, y)
				n += 1
	return n
