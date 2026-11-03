# Party TV Hub — Especificação Completa End-to-End

Documento de produto + técnico para construir um **único aplicativo** com hub de jogos para TV, jogável com amigos em casa. A TV (ou tela grande via HDMI/browser) é a tela principal; os celulares funcionam como controles.

Use este documento como briefing para uma IA gerar o hub e cada jogo do zero.

---

## 1. Visão do produto

### 1.1 Nome de trabalho
**Party TV Hub** (nome final pode mudar; tratar como variável de marca).

### 1.2 Proposta
Um hub na TV onde o anfitrião escolhe o jogo da noite. Os amigos entram com o celular (QR code ou código da sala). Cada jogo compartilha a mesma infraestrutura de sala, jogadores, áudio e placar, mas tem regras e UI próprias.

### 1.3 Experiência-alvo
- 4 a 8 jogadores no sofá
- Partidas de 5 a 20 minutos
- Zero instalação obrigatória no celular (PWA / browser)
- Controles óbvios: toque, swipe, botões grandes
- Caos leve, humor e competitividade social

### 1.4 Papéis
| Papel | Dispositivo | Funções |
|---|---|---|
| **Host (anfitrião)** | TV / PC HDMI | Abre o hub, cria sala, escolhe jogo, inicia rodadas, vê placar |
| **Player** | Celular | Entra na sala, joga, responde, vota, desenha, move personagem |
| **Espectador (opcional MVP+)** | Celular ou só TV | Assiste sem pontuar |

### 1.5 Princípios de design
1. **TV = espetáculo** — pouca UI, muita informação visual clara a 3 metros.
2. **Celular = input** — botões grandes, feedback háptico/visual imediato.
3. **Partida curta** — sempre dá pra “mais uma”.
4. **Regras em 10 segundos** — tutorial de 1 tela antes de cada jogo.
5. **Um hub, muitos jogos** — mesma sala, mesmo login temporário, mesmo ranking da noite.

---

## 2. Arquitetura do aplicativo (Hub)

### 2.1 Fluxo principal (happy path)

```
[Abrir app na TV]
        │
        ▼
[Tela Hub / Home]
  - Logo / marca
  - Botão "Criar sala"
  - Lista de jogos (cards)
        │
        ▼
[Criar sala]
  - Gera código de 4–6 chars (ex: K7P2)
  - Mostra QR code grande na TV
  - Host escolhe nick
        │
        ▼
[Lobby da sala]
  - Lista de jogadores entrando
  - Host seleciona o jogo
  - Host configura opções (duração, rounds, tema)
  - Botão "Começar"
        │
        ▼
[Jogo selecionado]
  - Tutorial rápido (opcional pular)
  - Rodadas
  - Placar intermediário
        │
        ▼
[Resultado final]
  - Ranking da partida
  - Títulos engraçados
  - Botões: "Jogar de novo" | "Trocar de jogo" | "Sair da sala"
```

### 2.2 Fluxo do jogador no celular

```
[Abrir URL / escanear QR]
        │
        ▼
[Entrar na sala]
  - Digita código OU já vem pré-preenchido pelo QR
  - Escolhe nick + avatar/cor
        │
        ▼
[Lobby mobile]
  - "Aguardando o host..."
  - Vê lista de quem entrou
        │
        ▼
[Controles do jogo ativo]
  - UI específica do minijogo
        │
        ▼
[Tela de resultado no celular]
  - Sua posição + pontos
```

### 2.3 Telas do Hub (TV)

1. **Home**
   - Marca em destaque
   - Grid/lista de jogos disponíveis
   - CTA principal: Criar sala
2. **Criar / Lobby**
   - Código + QR
   - Jogadores conectados (avatares)
   - Seletor de jogo
   - Painel de configurações do jogo escolhido
3. **Em jogo**
   - Canvas/área do jogo
   - HUD: round, timer, placar compacto
4. **Resultado**
   - Pódio 1º / 2º / 3º
   - Lista completa
   - CTAs de continuidade

### 2.4 Telas do Hub (Mobile)

1. Join (código + nick)
2. Waiting lobby
3. In-game controller
4. Soft result / “aguarde próxima rodada”

### 2.5 Estados globais da sala

```
IDLE → LOBBY → GAME_STARTING → IN_GAME → ROUND_RESULTS → FINAL_RESULTS → LOBBY
```

Transições só o **Host** controla (exceto desconexões automáticas).

---

## 3. Sistema compartilhado (core)

Tudo abaixo é comum a todos os jogos. Implementar primeiro.

### 3.1 Entidades

#### Room
```ts
{
  id: string
  code: string                 // ex: "K7P2"
  hostPlayerId: string
  status: "lobby" | "starting" | "in_game" | "round_results" | "final_results"
  selectedGameId: string | null
  gameConfig: Record<string, unknown>
  createdAt: number
  nightScores: Record<playerId, number>  // placar acumulado da sessão
}
```

#### Player
```ts
{
  id: string
  roomId: string
  nick: string
  avatarId: string
  color: string
  isHost: boolean
  isConnected: boolean
  device: "tv" | "mobile"
  scoreMatch: number
  scoreNight: number
}
```

#### GameDefinition
```ts
{
  id: string
  name: string
  shortDescription: string
  minPlayers: number
  maxPlayers: number
  estimatedMinutes: number
  tags: string[]
  supportsTeams: boolean
}
```

### 3.2 Eventos em tempo real (WebSocket / Socket-like)

Eventos mínimos:

| Evento | Direção | Uso |
|---|---|---|
| `room:create` | client → server | Host cria sala |
| `room:join` | client → server | Player entra |
| `room:leave` | client → server | Sai |
| `room:state` | server → clients | Snapshot completo |
| `player:update` | bi | Nick/avatar/ready |
| `game:select` | host → server | Escolhe jogo |
| `game:config` | host → server | Ajusta opções |
| `game:start` | host → server | Inicia |
| `game:input` | mobile → server | Input do jogo |
| `game:event` | server → clients | Eventos do gameplay |
| `game:end` | server → clients | Fim da partida |
| `chat:emote` | mobile → all | Reações rápidas (opcional) |

### 3.3 Regras de sala
- Código único, case-insensitive
- Máximo padrão: 8 jogadores (configurável por jogo)
- Se o host cair: promover o player mais antigo após 15s, ou encerrar sala
- Reconnect por `playerId` salvo em localStorage (até 2 min)
- Kick disponível só para host

### 3.4 Placar
- **scoreMatch**: pontos da partida atual
- **scoreNight**: soma de todas as partidas desde a criação da sala
- Ao trocar de jogo, `scoreMatch` zera; `scoreNight` permanece
- Tela final sempre mostra os dois

### 3.5 Áudio (TV)
- Música de lobby
- Stingers de início/fim de round
- SFX de acerto, erro, power-up, eliminação
- Mute global no hub

### 3.6 Acessibilidade mínima
- Contraste alto na TV
- Textos grandes no mobile
- Cores + ícones (não só cor) para identificar jogadores
- Timer sempre visível

---

## 4. Catálogo de jogos

| ID | Nome | Jogadores | Duração | Complexidade |
|---|---|---|---|---|
| `chaos_party` | Chaos Party (minijogos) | 2–8 | 10–20 min | Média |
| `trivia_rush` | Trivia Rush | 2–8 | 8–15 min | Baixa |
| `sketch_guess` | Traço & Chute | 3–8 | 10–15 min | Média |
| `shadow_roles` | Papéis na Sombra | 4–8 | 12–20 min | Média-Alta |
| `bump_arena` | Bump Arena | 2–8 | 5–10 min | Baixa |

---

## 5. Jogo 1 — Chaos Party (Party de minijogos)

### 5.1 Conceito
Estilo Mario Party: sequência de minijogos curtos (20–60s), pontuação acumulada, caos leve. A TV mostra a arena; o celular é o controle.

### 5.2 Loop da partida
1. Host escolhe quantidade de rounds (padrão: 5)
2. Cada round sorteia 1 minijogo de um pool
3. Countdown 3–2–1
4. Minijogo roda
5. Placar intermediário (3–5s)
6. Repete até acabar rounds
7. Pódio final + títulos

### 5.3 Configurações do host
- Número de rounds: 3 / 5 / 7
- Dificuldade: fácil / normal / caótico
- Permitir o mesmo minijogo mais de uma vez: sim/não
- Modo times (MVP+): off por padrão

### 5.4 Pool inicial de minijogos (MVP)

#### A) Botão Louco
- Objetivo: apertar o botão quando a TV mostrar VERDE; não apertar no VERMELHO
- Input mobile: 1 botão grande
- Pontuação: +1 acerto, −1 erro (mínimo 0)
- Duração: 30s, vários flashes

#### B) Corrida de Toques
- Objetivo: quem mais toca no botão em 10s
- Anti-cheat leve: rate limit de toques/seg (ex.: máx 12/s)
- Pontuação: ranking → 3 / 2 / 1 / 0 pontos

#### C) Esquiva
- TV: obstáculos caindo / vindo
- Mobile: setas ou tilt / botões esquerda-direita
- Sobrevive mais = mais pontos; ordem de eliminação define ranking

#### D) Memória Flash
- TV mostra sequência de cores/símbolos
- Mobile: repetir a sequência
- Errou = fora da rodada; último vivo ou mais acertos vence

#### E) Puxe a Corda (votação caótica)
- TV mostra 2 lados
- Jogadores escolhem lado no celular
- O lado com menos gente ganha (minority wins) OU o lado que enche a barra (configurável)
- Rápido e social

### 5.5 Economia de pontos (padrão)
| Colocação no minijogo | Pontos |
|---|---|
| 1º | 3 |
| 2º | 2 |
| 3º | 1 |
| Demais | 0 |

Empates: todos empatados recebem a mesma faixa.

### 5.6 UI TV
- Área central do minijogo
- Top bar: round X/Y + timer
- Lateral ou bottom: avatares + pontos da noite/partida

### 5.7 UI Mobile
- Controles do minijogo ativo
- Feedback: “+3!” / “Eliminado” / “Aguarde”
- Vibração curta em acerto/erro (se disponível)

### 5.8 Critérios de pronto (Definition of Done)
- 5 minijogos jogáveis
- Placar consistente entre rounds
- Host consegue pular minijogo travado
- Desconexão no meio do minijogo: player fica com 0 naquele round e pode voltar no próximo

---

## 6. Jogo 2 — Trivia Rush (Quiz / Trivia)

### 6.1 Conceito
Perguntas na TV; respostas no celular. Temas: filmes, memes, cultura pop e “quem conhece melhor o grupo”.

### 6.2 Loop
1. Host escolhe deck/tema e nº de perguntas
2. Pergunta aparece na TV (texto + imagem opcional)
3. 4 alternativas no celular (ou input texto em modo aberto)
4. Timer (10–20s)
5. Lock das respostas → revelação animada na TV
6. Pontuação + streak
7. Próxima pergunta
8. Resultado final

### 6.3 Modos de pergunta
| Modo | Descrição |
|---|---|
| **Múltipla escolha** | 4 opções (A–D) |
| **Verdadeiro/Falso** | 2 opções |
| **Texto livre** (MVP+) | normalize string; aceitar sinônimos |
| **Sobre o grupo** | perguntas personalizadas cadastradas antes |

### 6.4 Pontuação
- Acerto: 1000 pontos base
- Bônus de velocidade: até +500 (linear com tempo restante)
- Streak: +50 por acerto consecutivo (cap +200)
- Erro: 0
- Sem resposta: 0

Fórmula sugerida:
```
points = correct ? floor(1000 + 500 * (timeLeft / totalTime) + streakBonus) : 0
```

### 6.5 Decks iniciais
1. **Filmes & Séries**
2. **Memes BR**
3. **Cultura Geral Rápida**
4. **Modo Amigos** — host cadastra 8–15 perguntas sobre o grupo no lobby (ex.: “Quem já perdeu o voo?”)

### 6.6 Estrutura de uma pergunta
```ts
{
  id: string
  deckId: string
  type: "multi" | "bool" | "text" | "group"
  prompt: string
  imageUrl?: string
  options?: string[]          // multi
  correctIndex?: number       // multi/bool
  acceptedAnswers?: string[]  // text
  explanation?: string        // mostra após revelar
  timeSeconds?: number
}
```

### 6.7 UI TV
- Pergunta em tipografia grande
- Timer circular
- Após lock: barras com % de cada alternativa
- Destaque da correta + mini ranking da pergunta

### 6.8 UI Mobile
- Botões das alternativas (ocupam a tela)
- Estado: respondido / aguardando
- Não mostrar se acertou até a TV revelar (anti-spoil entre amigos)

### 6.9 Anti-cola social
- Embaralhar ordem das alternativas por jogador (opcional)
- Revelação só depois que todos respondem ou timer zera

### 6.10 DoD
- 3 decks com pelo menos 20 perguntas cada
- Modo Amigos editável no lobby
- Placar com bônus de velocidade funcionando
- Funciona bem em 2 e em 8 jogadores

---

## 7. Jogo 3 — Traço & Chute (Desenhar e adivinhar)

### 7.1 Conceito
Um jogador desenha no celular; o desenho aparece ao vivo na TV; os outros digitam o chute no celular.

### 7.2 Loop de uma rodada
1. Sorteia o **Artista**
2. Artista recebe a palavra secreta só no celular
3. Artista desenha (canvas touch)
4. Demais jogadores enviam palpites em texto
5. Acertou → pontos para artista e para quem acertou
6. Timer esgota ou palavra descoberta por X pessoas
7. Revela palavra → próximo artista
8. Após N rodadas (ou todos terem desenhado 1x), fim

### 7.3 Configurações
- Rodadas: “1 volta completa” (recomendado) ou número fixo
- Dificuldade das palavras: fácil / misto / difícil
- Tempo por desenho: 60 / 90 / 120s
- Modo categorias: animais, objetos, ações, filmes

### 7.4 Pontuação sugerida
- Quem acerta: 100 (primeiro) / 80 / 60 / 40...
- Artista: +50 por cada acerto (cap configurável, ex. +200)
- Ninguém acertou: artista 0

### 7.5 Palavra secreta
- Banco de palavras em PT-BR
- Filtro de palavras inapropriadas
- Artista pode “trocar palavra” 1x por rodada (penalidade: −20s no timer)

### 7.6 Canvas / sincronização
- Mobile do artista envia strokes (ou snapshots) via websocket
- TV renderiza o mesmo canvas
- Formato de stroke:
```ts
{
  color: string
  size: number
  points: { x: number, y: number }[]  // normalizados 0–1
}
```
- Ferramentas do artista: cores básicas, borracha, limpar tudo, grossura

### 7.7 Validação de chute
- Case-insensitive
- Remover acentos
- Aceitar aliases (`tv` = `televisão`) quando cadastrado
- Não aceitar chute idêntico à dica automática (não há dicas no MVP, só no MVP+)

### 7.8 UI TV
- Canvas grande central
- Lista de “fulano acertou!” (sem mostrar a palavra até o fim)
- Timer + nome do artista

### 7.9 UI Mobile
- **Artista:** canvas + toolbar + palavra secreta no topo
- **Adivinhador:** input de texto + histórico dos próprios chutes

### 7.10 DoD
- Desenho sincronizado com latência aceitável (<100ms percebida em LAN)
- Sistema de acerto robusto a acentos
- Todos desenham pelo menos uma vez no modo “volta completa”
- Host pode pular artista AFK

---

## 8. Jogo 4 — Papéis na Sombra (Impostor / roles secretos)

### 8.1 Conceito
Jogo social de dedução. A TV mostra a “sala/mapa” e o andamento público. Cada celular recebe um **papel secreto**. Há fases de ação, discussão e votação.

### 8.2 Jogadores
- Mínimo: 4 (ideal 5–8)
- Papéis MVP:
  - **Inocente (Crew)** — maioria
  - **Impostor** — 1 (ou 2 se ≥7 jogadores)
- Papéis MVP+ (expansão):
  - Detetive (1x “investigar” por partida)
  - Médico (protege 1 jogador por noite)
  - Bufão (ganha se for eliminado por voto)

### 8.3 Estrutura da partida

#### Fase 0 — Distribuição
- Server sorteia papéis
- Cada mobile mostra só o próprio papel
- TV mostra: “Papéis distribuídos” (sem spoilers)

#### Fase 1 — Ação curta (opcional no MVP)
- 45–60s de “tarefas” simbólicas para inocentes (mini progress bar)
- Impostor pode sabotar (atrasa tarefas) ou “eliminar” 1x por rodada (com cooldown)
- Para MVP mais simples: pular ação e ir direto para discussão temática

#### Fase 2 — Discussão
- Timer 60–90s
- TV mostra prompt: “Quem está suspeito?”
- Mobile: chat rápido de emotes / ou só timer (chat de voz é off-app: as pessoas falam no sofá)

#### Fase 3 — Votação
- Cada jogador vota em alguém ou “Pular”
- TV anima os votos ao final
- Mais votado é eliminado (empate = ninguém sai, ou desempate por revoto rápido)

#### Fase 4 — Resolução
- Revela se era impostor ou não (sem revelar todos os papéis restantes)
- Condições de vitória:
  - Inocentes vencem se todos impostores forem eliminados
  - Impostores vencem se número de impostores ≥ inocentes vivos (ou se completar X sabotagens no modo com ação)

Repete fases até win condition.

### 8.4 Configurações do host
- Nº de impostores (auto ou manual)
- Tempo de discussão
- Anônimo nos votos até o fim: sim
- Modo “só dedução” (sem fase de ação): default on para MVP

### 8.5 UI TV
- Mapa simples / sala com avatares
- Indicadores: vivos, eliminados
- Telas de fase bem explícitas (AÇÃO / DISCUSSÃO / VOTAÇÃO / RESULTADO)
- Reveal dramático na eliminação

### 8.6 UI Mobile
- Card do papel secreto (com “segurar para revelar” evitando shoulder surfing)
- Botões de ação conforme papel e fase
- Lista para votar (avatares grandes)

### 8.7 Fairness / UX
- Impostor nunca recebe tarefa que o entregue demais no MVP
- Eliminado vira espectador (vê tudo, não vota)
- Log público na TV: “Round 2 — Maria foi eliminada”

### 8.8 DoD
- Funciona 4–8 jogadores
- Win conditions corretas
- Papel secreto nunca vaza para a TV
- Votação com empate tratada
- Host pode forçar avançar fase

---

## 9. Jogo 5 — Bump Arena (Corrida / arena 2D local)

### 9.1 Conceito
Todos na mesma tela (TV). Cada um controla um personagem pelo celular. Colisões, knockback e power-ups. Último vivo ou quem mais pontua vence.

### 9.2 Modos
| Modo | Objetivo | Duração |
|---|---|---|
| **Last Stand** | Último vivo | até restar 1 (máx 90s) |
| **Gem Rush** | Coletar gemas | 60s |
| **King Hill** | Ficar na zona | 60s |

MVP: implementar **Last Stand** + **Gem Rush**.

### 9.3 Controles mobile
- Joystick virtual (movimento)
- Botão de ação (dash / golpe)
- Dash com cooldown de 2s

### 9.4 Regras Last Stand
- Arena fechada com bordas que matam (ou empurram para fora)
- Colisão entre players causa knockback
- Dash aumenta knockback
- Power-ups spawnam a cada 10s: escudo, super dash, gelo ( Congela outros 1s )
- Ordem de eliminação define ranking (último = 1º)

### 9.5 Regras Gem Rush
- Gemas spawnam no mapa
- Pegar gema = +1
- Bater em alguém pode dropar 1 gema
- Fim do timer: maior score vence

### 9.6 Física (simples)
- Loop fixo no server (ex.: 20–30 ticks/s) para autoridade
- Client envia input; server simula posição
- TV só renderiza estado
- Hitbox circular
- Atrito e velocidade máxima definidos por constantes

### 9.7 UI TV
- Arena full-bleed
- Skins/cores por jogador
- Indicadores de nome curtos acima do personagem
- Timer + placar

### 9.8 UI Mobile
- Joystick + botão
- Cooldown visível
- “Você foi eliminado — spectate”

### 9.9 DoD
- 8 players simultâneos estáveis em LAN
- Colisão e dash confiáveis
- 2 modos jogáveis
- Desconexão remove ou deixa o boneco AFK por 5s e depois elimina

---

## 10. Stack técnica recomendada (para a IA implementar)

### 10.1 Opção recomendada (web-first, TV + mobile)
| Camada | Tecnologia |
|---|---|
| Frontend TV + Mobile | React + TypeScript (Vite) |
| Estilos | CSS Modules ou Tailwind |
| Game canvas 2D | HTML Canvas / PixiJS (Bump Arena + strokes) |
| Realtime | Socket.IO ou WebSocket nativo |
| Backend | Node.js + TypeScript (Fastify/Express) |
| Estado de sala | In-memory (Map) no MVP; Redis depois |
| Deploy local | Docker Compose opcional |
| Persistência MVP | Nenhuma (salas voláteis) |

### 10.2 Por que essa stack
- TV abre URL fullscreen no browser / Smart TV / PC
- Mobile abre a mesma origem com rota `/play`
- Um só codebase
- Fácil de a IA gerar e iterar

### 10.3 Estrutura de monorepo sugerida
```
party-tv-hub/
  apps/
    web/                 # React (TV + mobile por rotas)
    server/              # Node realtime + game logic
  packages/
    shared/              # tipos, eventos, constantes
  docs/
    party-tv-hub-especificacao.md
```

### 10.4 Rotas web
- `/` — Hub TV (detectar tela grande; ou `/tv`)
- `/tv` — experiência TV forçada
- `/play` — experiência mobile
- `/play/:roomCode` — deep link do QR

### 10.5 Detecção de dispositivo
- Query `?mode=tv|mobile`
- Fallback: largura + touch
- QR da TV já aponta para `/play/CODE`

---

## 11. Modelo de eventos por jogo

Todos os inputs sobem como:
```ts
{
  type: "game:input",
  roomId: string,
  playerId: string,
  gameId: string,
  payload: unknown
}
```

### Exemplos de payload
- Trivia: `{ action: "answer", questionId, optionIndex }`
- Sketch: `{ action: "stroke", stroke }` / `{ action: "guess", text }`
- Chaos: `{ action: "tap" }` / `{ action: "move", dir }`
- Shadow: `{ action: "vote", targetPlayerId }`
- Bump: `{ action: "move", x, y }` / `{ action: "dash" }`

Server valida, atualiza estado, broadcasta `room:state` ou `game:event` delta.

---

## 12. UX visual e tom

### 12.1 Direção
- Visual festivo, legível na TV, sem parecer dashboard
- Marca “Party TV Hub” como herói na home
- Cada jogo tem cor-tema própria no card do hub
- Animações curtas de entrada/saída de round (2–3 motions intencionais)

### 12.2 Tom de copy
- Informal, BR, sem cringe corporativo
- Títulos de fim de partida engraçados:
  - “O cérebro da operação”
  - “Sorte ou ousadia?”
  - “Quase, mas foi feio”
  - “Impostor aposentado”

---

## 13. Plano de implementação (fases)

### Fase 0 — Fundações (obrigatória)
1. Monorepo web + server
2. Criar sala, QR, join, lobby, reconnect
3. Seleção de jogo (mesmo que só um esteja ativo)
4. Placar night/match
5. Tela de resultado genérica

### Fase 1 — Primeiro jogo vertical completo
- **Trivia Rush** (mais simples de fechar end-to-end)

### Fase 2
- **Bump Arena** (Last Stand)

### Fase 3
- **Traço & Chute**

### Fase 4
- **Chaos Party** com 3 minijogos; depois completar 5

### Fase 5
- **Papéis na Sombra** (modo só dedução primeiro)

### Fase 6 — Polimento
- Sons, avatares, títulos, decks extras, power-ups, times

---

## 14. Critérios de aceite do produto (MVP da noite)

Uma sessão de amigos deve conseguir:
1. Abrir a TV, criar sala, 4+ celulares entrarem em <2 min
2. Jogar Trivia completo
3. Voltar ao hub sem sair da sala
4. Jogar pelo menos mais 1 jogo (Bump ou Sketch)
5. Ver placar da noite acumulado
6. Sobreviver a 1 celular desconectando e reconectando

---

## 15. Prompt-guia para a IA implementadora

Ao pedir para a IA construir, usar blocos nesta ordem:

1. **“Implemente a Fase 0 conforme `docs/party-tv-hub-especificacao.md`”**
2. **“Implemente Trivia Rush completo (Fase 1)”**
3. Em seguida um jogo por vez, sempre citando a seção do documento
4. Pedir testes manuais: checklist de sala com 2 browsers (TV + mobile)

Checklist que a IA deve validar por jogo:
- [ ] Host inicia sem erros
- [ ] N mobiles recebem UI correta
- [ ] Timer sincronizado
- [ ] Pontuação correta
- [ ] Fim de jogo volta ao resultado e depois ao lobby
- [ ] Refresh no mobile reconecta

---

## 16. Fora de escopo (MVP)

- Contas de usuário / login social
- Matchmaking online com estranhos
- Compras / monetização
- Voice chat in-app
- App nativo das lojas (PWA basta)
- Editor visual de níveis
- Suporte offline total

---

## 17. Resumo executivo

Construir **um hub** com sala compartilhada e **cinco jogos** plugáveis:

1. **Chaos Party** — rounds de minijogos e placar acumulado  
2. **Trivia Rush** — quiz TV + resposta no celular  
3. **Traço & Chute** — desenho ao vivo e palpites  
4. **Papéis na Sombra** — impostor com votação social  
5. **Bump Arena** — arena 2D com colisão e power-ups  

Base técnica: **React + Node + WebSocket**, TV e mobile no mesmo app, jogos como módulos registrados no hub.

Este documento é a fonte da verdade para gerar o produto end-to-end com IA.
