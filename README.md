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

<!-- markdownlint-disable MD033 -->
<a href="https://github.com/Zapitos/Project-I/graphs/contributors">
 <img src="https://contrib.rocks/image?repo=Zapitos/Project-I" alt="Contribuidores" />
</a>
<!-- markdownlint-enable MD033 -->

Obrigado a todas as pessoas que já contribuíram! (A imagem acima é gerada dinamicamente pelo serviço público contrib.rocks.)

### Guia rápido para contribuir

1. Faça um fork ou crie uma branch.
2. Commits pequenos e mensagens em pt-BR de preferência.
3. Abra um Pull Request descrevendo claramente a mudança.

Se quiser futuramente manter papéis/funções detalhados, pode-se criar manualmente uma tabela abaixo ou adicionar outra seção; por enquanto usamos apenas o grid de avatares.

