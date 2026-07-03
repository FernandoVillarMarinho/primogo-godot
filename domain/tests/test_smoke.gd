extends GutTest
## Smoke test da Tarefa 01: prova que a suíte GUT roda headless e verde.
## Substituído/ampliado pelos testes TT-xx e de paridade nas Tarefas 04..06.

func test_suite_runs() -> void:
	assert_true(true, "Suíte GUT operacional (esqueleto da Tarefa 01).")

func test_gdscript_math_sanity() -> void:
	assert_eq(2 * 3, 6, "Sanidade básica do runtime GDScript.")
