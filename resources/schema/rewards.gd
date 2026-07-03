class_name Rewards
extends Resource
## Tabela de recompensa de energia por estrelas (target_data_model.md §3).
## Legado: GameScene.cs:111-122 (extraído para dados; L-01 mantido: 1★ = +0).
##
## Cada par (a, b) carrega os DOIS valores do legado. A semântica exata de qual
## se aplica (novo recorde × repetição) é regra de `domain/economy` (Tarefa 06) e
## deve ser confirmada contra GameScene.cs na transcrição — aqui só carregamos os números.

@export var three_star: Vector2i = Vector2i(5, 4)  ## 3★ → +5 / +4
@export var two_star: Vector2i = Vector2i(3, 2)    ## 2★ → +3 / +2
@export var one_star: Vector2i = Vector2i(0, 0)    ## 1★ → +0 (L-01)


## Par de valores para uma contagem de estrelas (1..3). 0★ = (0,0).
func pair_for(stars: int) -> Vector2i:
	match stars:
		3: return three_star
		2: return two_star
		1: return one_star
		_: return Vector2i.ZERO
