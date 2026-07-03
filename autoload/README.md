# autoload/ — singletons explícitos

Três autoloads declarados em `project.godot`, substituindo os statics e
`DontDestroyOnLoad` do legado (paradigma aprovado: nós + sinais + estado global explícito).

| Autoload | Nome no engine | Responsabilidade | Tarefa |
|---|---|---|---|
| `progression_store.gd` | `ProgressionStore` | Estado da progressão + **única porta de escrita** do save | 07 |
| `audio_bus.gd` | `AudioBus` | Gate central de mute + música persistente + fachada de efeitos | 08 |
| `scene_router.gd` | `SceneRouter` | Troca de cena com fade + "Voltar" por contexto | 09 |

**Fronteira:** os autoloads são casca — não contêm regra de negócio. `progression_store`
embrulha `domain/economy`; a regra vive no domínio puro.

Hoje são **stubs** (Tarefa 01): carregam sem erro para o projeto abrir e a suíte rodar.
