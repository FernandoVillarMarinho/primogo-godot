class_name LevelGrid
extends RefCounted
## Feature level_select — lógica pura da grade paginada (BR-036/037). Sem engine, testável.
## 12 páginas construídas (uma por estágio), navegação trava na 10 (BR-037, L-04);
## grade 3×4 preenchida POR LINHAS (`row*3+col`): 1,2,3 na 1ª linha, 4,5,6 na 2ª, lendo
## da esquerda para a direita e de cima para baixo — pedido do 4º teste em dispositivo
## (o legado preenchia por colunas: L-03/DEV-005; divergência intencional registrada).

const COLS := 3
const ROWS := 4
const PER_PAGE := 12       # 3×4
const PAGE_COUNT := 12     # páginas construídas
const NAV_MAX_PAGE := 10   # navegação trava na 10 (BR-037)


## Índice da fase na página a partir de (coluna, linha): leitura horizontal (4º teste).
static func level_index(col: int, row: int) -> int:
	return row * COLS + col


## Nível 1..12 exibido na caixa (índice + 1; o tutorial _00 não é caixa selecionável).
static func level_number(col: int, row: int) -> int:
	return level_index(col, row) + 1


static func clamp_page(page: int) -> int:
	return clampi(page, 1, NAV_MAX_PAGE)


static func can_navigate_to(page: int) -> bool:
	return page >= 1 and page <= NAV_MAX_PAGE


## Estado visual da caixa a partir do desbloqueio do domínio; a 1ª caixa de cada página
## é sempre acessível (BR-036), então uma bloqueada nessa posição vira desbloqueada.
static func box_state(unlock_state: int, is_first_of_page: bool) -> int:
	if unlock_state == PlayerProgress.UnlockState.WON:
		return PlayerProgress.UnlockState.WON
	if unlock_state == PlayerProgress.UnlockState.UNLOCKED or is_first_of_page:
		return PlayerProgress.UnlockState.UNLOCKED
	return PlayerProgress.UnlockState.LOCKED
