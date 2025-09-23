# Project-I (Godot 4.x)

> Plataforma 2D em Godot com organização de pastas em PT‑BR, autoloads e mecânicas como pulo duplo e wall jump.

## Requisitos

- Godot 4.x (o `project.godot` está preparado para a série 4.x)
- Windows/macOS/Linux

## Como abrir e rodar

1. Abra o Godot 4.x e escolha “Import/Scan” apontando para a pasta do repositório.
2. A cena principal está configurada em `project.godot` → `res://cenas/niveis/test_level.tscn`.
3. Pressione F5 (Run) para executar.

Dica: Se o editor carregar referências antigas, vá em Project → Reload Current Project.

## Controles (padrão)

- A/D ou ←/→: mover
- Espaço: pular
- Pulo duplo: pressione Espaço novamente no ar
- Wall jump: encoste em uma parede, segure a direção contra ela e pressione Espaço

## Funcionalidades

- Personagem com pulo, pulo duplo e wall jump
- Checkpoint e hitbox reutilizáveis (prefabs)
- Autoloads para controle de eventos e estado global
- Estrutura de cenas modular (níveis, inimigos, coletáveis, etc.)

## Estrutura de pastas

- `cenas/niveis/` — cenas de níveis (principal: `test_level.tscn`)
- `personagem/` — cena e script do jogador
- `inimigos/` — inimigos (`inimigo_1`, `inimigo_2`)
- `Coletaveis/` — moedas e UI (mantido conforme origem)
- `prefabricados/` — prefabs (ex.: `checkpoint.tscn`, `hitbox.tscn`)
- `armadilhas/` — cenas de armadilhas
- `scripts/` — scripts utilitários/gerais (inclui `niveis/World_01.gd`)
- `globais/` — autoloads (ex.: `globals.gd`)
- `sprites/` — artes 2D e tilesets
- `sons/` — coloque seus áudios (veja `sons/README.md`)

## Dicas de desenvolvimento

- Autoloads: confira `[autoload]` no `project.godot` (EventController, GameController, Globals)
- Layers 2D: veja `[layer_names]` no `project.godot` para “player”, “enemies”, “hitbox”, “hurtbox”
- TileSets e assets: ficam em `sprites/`
- Ajuste da física: `physics/2d/default_gravity` em `project.godot`

## Como contribuir

- Siga a estrutura de pastas em PT‑BR
- Prefira nomes descritivos para nós e scripts

## Licença


## Colaboradores

Esta seção é gerada automaticamente pelo workflow `update_contributors`. Edite manualmente SOMENTE se for para ajustar descrições entre colchetes. Para mudar papéis, use o arquivo opcional `tools/contributors_overrides.json`.

<!-- CONTRIBUTORS-LIST:START -->
| Nome / Handle | Função / Foco | Commits |
|---------------|---------------|---------|
| Zapitos | Criador / Dev Principal | (inicial) |
<!-- CONTRIBUTORS-LIST:END -->

### Como adicionar um novo colaborador

1. (Opcional) Para ajustar descrição de alguém, adicione/edite `tools/contributors_overrides.json`.
2. Rode localmente: `python tools/update_contributors.py` (ou espere o workflow agendado).
3. Commit: `docs: atualiza colaboradores`.
4. Abra Pull Request se não for push direto.

### Automatização opcional (futuro)

Pode-se criar um script que consome a API do GitHub para gerar esta lista automaticamente (ex.: `scripts/update_contributors.gd` ou workflow GitHub Actions) — não implementado ainda para manter o repositório simples.

