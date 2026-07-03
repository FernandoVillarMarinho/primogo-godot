# Primogo — Godot 4

Reconstrução do puzzle educacional **Primogo** (Unity 5.3 → Godot 4), guiada pelas specs do
Reversa em `../_reversa_sdd/migration/`. Puzzle offline single-player de números primos.

- **Paradigma:** nós + sinais + **núcleo de domínio puro** (`paradigm_decision.md`, opção 1).
- **Topologia:** feature-based com domínio puro (`topology_decision.md`, opção 2).
- **Stack:** Godot 4.x LTS · GDScript · GUT · Android primário, desktop/web secundários ·
  save local `ConfigFile` em `user://` · sem backend (AD-01).

## Estrutura

```
primogo-godot/
├── project.godot          # 3 autoloads declarados, renderer GL Compatibility, portrait
├── autoload/              # ProgressionStore · AudioBus · SceneRouter (stubs → Tarefas 07/08/09)
├── domain/                # PURO, sem engine — regras testáveis headless
│   ├── board/  economy/  levels/   (→ Tarefas 05/06/04)
│   └── tests/            # suíte GUT (smoke test na Tarefa 01)
├── features/             # casca Godot — cenas + sinais (→ Tarefas 10..14)
│   ├── shared/ board/ level_select/ main_menu/ tutorial/
├── resources/            # dados versionados: levels/ balance/ layout/ (→ Fase 0)
├── assets/               # sprites, fontes, áudios (reuso do legado)
├── tools/extraction/     # pipeline Fase 0 (fora do build, .gdignore)
├── addons/               # GUT (instalado à parte / pelo CI)
└── .github/workflows/    # CI: godot --headless + GUT
```

## Regras de fronteira (inderrogáveis)

1. `domain/` **não importa** nada de `features/` nem de `autoload/`. É puro e headless.
2. `features/` **não guarda** estado de progressão — lê/escreve via `ProgressionStore`.
3. Nenhuma regra de negócio na casca (`features/`); regra na casca = defeito.
4. `resources/` só é escrito pelo pipeline `tools/extraction` e por level designers — nunca em runtime.
5. O repositório Unity legado (`../Assets`, `../ProjectSettings`, ...) é **somente leitura, para sempre**.

## Rodar os testes localmente

```bash
# 1. Instale o GUT 9.x em res://addons/gut (ver addons/README.md)
# 2. Rode a suíte headless:
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://domain/tests -ginclude_subdirs -gexit
```

O CI faz isso automaticamente (instala o GUT e roda a suíte) a cada push/PR.

## Estado da reconstrução

Ver `../_reversa_sdd/reconstruction-plan.md` (16 tarefas). **Tarefa 01 (Setup) concluída.**
A Fase 0 (extração dos níveis, Tarefas 02/03) está bloqueada em **COD-006** — cenas Unity em
formato binário; requer Unity 5.3.2f1 funcional ou um conversor. Ver `tools/extraction/README.md`.
