# Bênçãos do Dayvinho

Mod para **Project Zomboid Build 42** que adiciona o item **Dayvinho de Bolso** ao mundo. Mantenha-o no inventário e a cada **10 minutos reais** o Dayvinho pode conceder uma bênção, uma maldição — ou simplesmente dar de ombros e não fazer nada.

---

## Como funciona

### 1. Encontre o Dayvinho de Bolso

O item é raro e pode aparecer em **até 3 locais por mapa**. Após atingir esse limite nenhum outro Dayvinho será gerado no mundo.

| Propriedade | Valor |
|---|---|
| Chance por container elegível | **7%** (independente do multiplicador de loot global) |
| Limite global por mapa | **3 unidades** |

**Locais de spawn** — cômodos elegíveis:
- Quartos de dormir e quartos infantis
- Salas de estar, lounges
- Lojas de brinquedos e lojas de presentes
- Depósitos e áreas de varejo

**Containers elegíveis:**
- Cômodas e guarda-roupas
- Estantes e prateleiras
- Caixotes, balcões de loja, vitrines e baús

Mantenha o item no inventário — ele não precisa estar equipado.

---

### 2. Timer de eventos

| Parâmetro | Valor |
|---|---|
| Intervalo entre eventos | **10 minutos reais** |
| Primeiro evento | **20 segundos** após pegar o item |
| Base do timer | Tempo real (sono e avanço de tempo não contam) |
| Persistência | Sobrevive a saves e reloads |

O primeiro evento dispara **20 segundos** após o item entrar no inventário — o Dayvinho quebra o gelo rapidamente.

A partir daí, a cada 10 minutos reais o Dayvinho rola um evento enquanto o item estiver no inventário.

---

### 3. Probabilidades de evento

A cada ciclo de 10 minutos:

| Resultado | Chance |
|---|---|
| Bênção **Comum** | **70%** |
| Maldição aleatória | **20%** |
| Bênção **Lendária** | **5%** |
| Nada acontece | **5%** |

A bênção específica é sorteada por peso entre as disponíveis. A versão **Lendária** tem duração **1,5×** e efeitos mais intensos.

---

### 4. Lista de Bênçãos

Todas as bênçãos com duração têm **10 minutos reais** (600s). A versão Lendária dura **15 minutos** (900s).

#### XP Boost por Habilidade

Cada habilidade do jogo tem sua **própria bênção independente** no pool de sorteio. Quando sorteada, concede +100% XP naquela habilidade (ou +150% se Lendária). O nome da habilidade é exibido no HUD e nas falas do Dayvinho.

#### Bênçãos com duração ativa

| Bênção | Efeito Comum | Efeito Lendário | Duração |
|---|---|---|---|
| **Sorte** | +20% Morale | +30% Morale | 10 min |
| **Achado Valioso** | +25% Morale (surrogate de foraging) | +40% Morale | 10 min |
| **Barriga Cheia** | Reduz fome gradualmente (0,4%/tick) | Reduz fome mais rápido (0,6%/tick) | 10 min |
| **Espírito Forte** | Reduz estresse e tédio gradualmente (0,4%/tick) | Reduz mais rápido (0,6%/tick) | 10 min |
| **Mãos Habilidosas** | +20% Endurance | +30% Endurance | 10 min |
| **Pescador Abençoado** | +20% Morale (surrogate de pesca) | +30% Morale | 10 min |
| **Olhos Atentos** | +25% Morale (surrogate de visão) | +40% Morale | 10 min |
| **Mochila Organizada** | Reduz desconforto gradualmente (0,4%/tick) | Reduz mais rápido (0,6%/tick) | 10 min |
| **Cura Natural** | Reduz dor gradualmente (0,4%/tick) | Reduz mais rápido (0,6%/tick) | 10 min |
| **Corpo Resistente** | Restaura endurance gradualmente (0,4%/tick) | Restaura mais rápido (0,6%/tick) | 10 min |
| **Bênção da Coragem** | Reduz pânico gradualmente (0,4%/tick) | Reduz mais rápido (0,6%/tick) | 10 min |

#### Bênçãos instantâneas

| Bênção | Efeito Comum | Efeito Lendário |
|---|---|---|
| **Presente do Jardim** | 2 itens aleatórios no inventário | 3 itens |
| **Água Fresca** | -70% da Sede atual | Zera a sede (100%) |
| **Descanso Revigorante** | -30% da Fadiga atual | -50% da Fadiga atual |
| **Bom Humor** | -50% da Infelicidade atual | -75% da Infelicidade atual |
| **Paz Interior** | -50% do Estresse atual | -75% do Estresse atual |
| **Colheita Feliz** | -15% Estresse imediato | -15% Estresse imediato |
| **Lenhador Sortudo** | +20% Endurance imediato | +20% Endurance imediato |
| **Passos Leves** | -15% Pânico imediato | -15% Pânico imediato |
| **Instinto de Sobrevivência** | -30% Pânico atual | -50% Pânico atual |
| **Sono Tranquilo** | Próximo sono será mais reparador | Mais reparador ainda |
| **Sol Abençoado** | Para a chuva (se estiver chovendo) | Para a chuva |
| **Arco-Íris** | -15% Infelicidade imediata | -15% Infelicidade imediata |

> **XP Boost:** Quando ativo e o personagem sobe de nível na habilidade sorteada, o mod aplica `nível × 75 × multiplicador` de XP bônus via `player:getXp():AddXP()`. A habilidade ativa e seu nome são exibidos no HUD.

---

### 5. Lista de Maldições (11 no total)

Todas as maldições têm duração de **10 minutos reais** (600s).

#### Gatilhos de maldição

| Gatilho | Como ocorre |
|---|---|
| **Aleatório** | 20% de chance a cada ciclo de 10 minutos com o Dayvinho no inventário |
| **Descartar** | Usar a opção "Descartar" no menu de contexto do inventário |
| **Remoção** | Remover o item do inventário por qualquer outro meio (exceto "Descartar") |

#### Efeitos possíveis (1 sorteado aleatoriamente)

| Maldição | Efeito | Tipo |
|---|---|---|
| **Má Sorte** | -10% Morale (revertido ao expirar) | Duração |
| **Pânico Acelerado** | Aumenta pânico gradualmente (+0,3%/tick) | Duração |
| **Fome Repentina** | +20% Fome imediata | Instantâneo |
| **Sede Repentina** | +20% Sede imediata | Instantâneo |
| **Corpo Fraco** | -10% Endurance imediata | Instantâneo |
| **Mais Barulho** | Aumenta pânico gradualmente (+0,2%/tick) | Duração |
| **Infelicidade** | +20% Infelicidade imediata | Instantâneo |
| **Estresse** | +15% Estresse imediato | Instantâneo |
| **Alucinação** | +10% Infelicidade (efeito narrativo) | Instantâneo |
| **Som Aleatório** | Toca um som surpresa + atrai zumbis (raio 50 blocos) | Instantâneo |
| **Helicóptero** | Aciona o evento de helicóptero + atrai zumbis (raio 200 blocos) | Instantâneo |

> **Maldições são persistentes:** continuam ativas mesmo se o item for removido do inventário. Bênçãos são canceladas ao perder o Dayvinho; maldições permanecem até expirar naturalmente.

---

### 6. HUD e Controles

O mod inclui um painel HUD que exibe:
- Efeitos ativos com timer de expiração (MM:SS)
- Bênçãos em amarelo, maldições em vermelho
- Falas do Dayvinho por 15 segundos no topo do painel
- Barra de rolagem quando há mais de 5 efeitos simultâneos

**Controles disponíveis:**

| Ação | Como fazer |
|---|---|
| Abrir/fechar HUD | **Botão Dayvinho na barra lateral** (ao lado do mapa/debug) |
| Abrir/fechar HUD (alternativo) | Menu de contexto do item → "Mostrar/Ocultar HUD Dayvinho" |
| Mover painel | Arrastar com clique esquerdo (quando desbloqueado) |
| Redimensionar | Arrastar o handle no canto inferior direito |
| Fixar posição | Clique direito no painel |
| Forçar sorteio (teste) | **Shift+F9** (apenas com modo debug ativo) |

---

## O Item

| Propriedade | Valor |
|---|---|
| ID | `Base.DayvinhoDeBolso` |
| Peso | 0,1 |
| Ícone | `LawnGnome` (anão de jardim nativo do jogo) |
| Empilhável | Não |
| Equipável | Não |

---

## Estrutura do projeto

```
DayvinhoBlessings/
├── workshop.txt
├── preview.png
└── Contents/mods/DayvinhoBlessings/42/
    ├── mod.info
    ├── poster.png
    └── media/
        ├── scripts/
        │   └── items_dayvinho.txt          — definição do item
        ├── ui/
        │   └── DayvinhoBlessings/
        │       ├── Dayvinho_Off.png        — ícone da barra lateral (inativo)
        │       └── Dayvinho_On.png         — ícone da barra lateral (ativo)
        └── lua/
            ├── shared/
            │   ├── DayvinhoBlessings/
            │   │   ├── Logger.lua          — logs do mod (INFO/WARN/ERROR/DEBUG)
            │   │   └── Distributions.lua   — spawn (2%, limite 3 por mapa)
            │   └── Translate/
            │       ├── EN/UI.json          — ~120 chaves de mensagem em inglês
            │       └── PTBR/UI.json        — ~120 chaves em português
            └── client/
                └── DayvinhoBlessings/
                    ├── Messages.lua        — getText helpers por tipo de evento
                    ├── Blessings.lua       — 23 bênçãos fixas + pool dinâmico de XP Boost por habilidade
                    ├── Curses.lua          — 11 maldições + hook de menu de inventário
                    ├── HUD.lua             — painel HUD com timers, scroll e falas
                    ├── Sidebar.lua         — botão do Dayvinho na barra lateral (ISEquippedItem)
                    └── Main.lua            — motor de timer, efeitos, eventos e Shift+F9
```

---

## Notas técnicas (B42)

- **CharacterStat:** Todos os efeitos usam o enum `CharacterStat` do B42 (HUNGER, THIRST, FATIGUE, ENDURANCE, PANIC, MORALE, STRESS, BOREDOM, UNHAPPINESS, PAIN, DISCOMFORT). Escala 0–1.
- **Sem APIs de B41:** `setLuck`, `setForagingRadius`, `setFishingMultiplier`, `setWalkingSpeed` não existem em B42 — substituídos por surrogates via MORALE/ENDURANCE.
- **Kahlua (VM Lua do PZ):** `math.random` → `ZombRand`/`ZombRandFloat`; `os.time` → `getTimeInMillis()/1000`; `next()` → loop com `pairs`. Chamar `nil` como função escapa do `pcall` como `RuntimeException` Java — todas as chamadas de método de objeto usam nil-guard.
- **XP Boost dinâmico:** Pool de bênçãos de XP gerado em runtime via `Perks.getMaxIndex()` + `Perks.fromIndex()`. Peso total do pool = 15, dividido igualmente entre todas as habilidades válidas. IDs no formato `xp_boost_<PerkType>`.
- **ISEquippedItem (Sidebar):** Monkey-patch em `initialise`, `onOptionMouseDown` e `prerender`. Textura carregada no `initialise`; tamanho do botão herdado de `self.invBtn`. Compatível com `checkSidebarSizeOption` (recriação ao mudar tamanho da sidebar).
- **OnFillContainer:** Roda no contexto server. É independente do multiplicador de loot global — dispara uma vez por container na primeira exploração.
- **getGameModData():** Usado para o contador global de spawns. Persiste com o mundo, disponível em contexto server/shared.

---

## Compatibilidade

- **Build:** Project Zomboid B42.19+
- **Multiplayer:** compatível (bênçãos e maldições são client-side por jogador; contador de spawn é server-side via `getGameModData`)
- **Outros mods:** não modifica arquivos base, sem conflito esperado

---

## Histórico de versões

| Versão | Descrição |
|---|---|
| `v1.0.0` | Implementação inicial: item, spawn, bênçãos de XP por level-up, PT-BR |
| `v1.0.1` | Ícone trocado para `LawnGnome` |
| `v1.0.2` | Corrigido: `GardenGnome` não existe nos texture packs |
| `v1.0.3` | Corrigido: typo `DayvinhoDeBollo` → `DayvinhoDeBolso` |
| `v1.1.0` | Conversão para padrão EN + sistema de tradução JSON (EN + PTBR) |
| `v2.0.0` | Rework completo: timer de 6h, 24 tipos de bênção com efeitos reais, sistema de maldições com gatilhos e 9 efeitos, ~120 chaves de tradução |
| `v2.0.1` | XP Boost afeta apenas 1 habilidade sorteada (não todas) |
| `v2.0.2` | Timer ajustado de 6h → 1 dia in-game |
| `v2.0.3` | API de stats migrada B41→B42 (CharacterStat enum) |
| `v2.0.4` | XP Boost corrigido: cache de perks via `Perks.getMaxIndex()`; XP via `player:getXp():AddXP()` |
| `v2.0.5` | Logger.lua: níveis INFO/WARN/ERROR/DEBUG, `Log.try()` com log automático de erros |
| `v2.0.6` | B42.19: `containsType` → `containsTypeRecurse`; `RainManager`; surrogate DISCOMFORT |
| `v2.0.7` | Estrutura movida para `DayvinhoBlessings/` (padrão Workshop) |
| `v2.0.8` | Fix: `next()` não disponível no Kahlua → substituído por `pairs` |
| `v2.0.9` | Fix: `math.random()` → `ZombRandFloat` em `Distributions.lua` |
| `v2.1.0` | Fix abrangente de compatibilidade Kahlua: `math.random`/`os.time`/`GameTime` em todos os scripts |
| `v2.1.1` | Maldição via "Descartar" no menu de inventário; mensagem de boas-vindas ao pegar o item |
| `v2.1.2–2.1.9` | Rebalanceamento de probabilidades; HUD com timers; XP Boost mostra habilidade sorteada; correções de escopo Lua; fix crash `ipairs(nil)` no HUD |
| `v2.1.10–2.1.13` | Bênçãos buffadas para dificuldade ultra; duração bênçãos/maldições → 20 min; timer → 20 min; spawn 2%; falas 15s no HUD |
| `v2.2.0` | Primeiro evento 20s após pegar o item; limite global de 3 Dayvinhos por mapa via `getGameModData()` |
| `v2.2.1–2.2.3` | HUD: barra de rolagem, fala do Dayvinho no topo, ordem mais recente primeiro, resize por arrastar |
| `v2.3.0` | XP Boost separado por habilidade: pool dinâmico gerado em runtime (`xp_boost_Aiming`, `xp_boost_Carpentry`, etc.) |
| `v2.3.1` | Timers reduzidos: bênçãos, maldições e cooldown de 20 min → **10 min** |
| `v2.3.2` | Shift+F9: sorteio forçado para testes (bênção ou maldição) |
| `v2.3.3` | Botão do Dayvinho na barra lateral (ISEquippedItem); Shift+F9 restrito ao modo debug |
| `v2.3.4` | HUD: barra de rolagem totalmente funcional — arrastar o thumb corrigido, direção do scroll por roda do mouse corrigida |
| `v2.3.5` | Fix: modversion em mod.info atualizado para 2.3.5 |
