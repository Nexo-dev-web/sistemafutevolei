# Gestor de Torneio de Futevôlei

Aplicação de página única para organizar torneios de futevôlei: cadastro de duplas, geração de chaveamento, lançamento de placares ao vivo, telão para projeção, controle financeiro e de uniformes.

Todo o sistema é **um único arquivo** — [index.html](index.html) — sem build, sem dependências e sem servidor. Basta abrir o arquivo no navegador.

---

## Como usar

1. Abra [index.html](index.html) no navegador (duplo clique já funciona).
2. Preencha nome, data e local para criar um torneio, ou escolha um da lista de torneios salvos.
3. Cadastre as duplas na barra lateral e escolha o formato (mata-mata, grupos ou dupla eliminatória).
4. Clique em **Gerar tabela**.
5. Durante o evento, digite os placares direto nos cartões — o vencedor avança sozinho.
6. Clique em **Abrir telão** para a tela de projeção.

O botão **Modelo teste** preenche 16 duplas fictícias, útil para ensaiar antes do evento.

### O telão

O telão é somente leitura, recarrega a cada 10 segundos e entra em modo de destaque em tela cheia quando detecta que um placar está sendo alterado (o jogo "ao vivo"). Ele tem duas formas de abrir, e a diferença importa:

| URL | Lê de | Funciona em |
|---|---|---|
| `index.html?view=chaveamento` | `localStorage` | Só no mesmo navegador do gestor (projetor ligado no notebook) |
| `index.html?view=chaveamento&t=<id>` | Supabase | Qualquer aparelho, em qualquer rede |

O botão **Abrir telão** usa a primeira forma. O botão **QR do público** gera a segunda.

---

## QR code para o público

O botão **QR do público**, na aba Chave, abre um modal com um QR code que leva ao chaveamento em tempo real. O espectador aponta a câmera, abre a página no celular e ela se atualiza sozinha a cada 10 segundos, sem instalar nada.

O QR é gerado no próprio navegador (veja `qrMatrix()` / `qrSvg()` no `index.html`) — não há chamada a serviço externo, então ele continua funcionando mesmo se a rede do evento estiver ruim.

### Para funcionar, o sistema precisa estar publicado

Um celular não consegue abrir um endereço `file://` ou `localhost` do seu computador. Enquanto o `index.html` estiver aberto por duplo clique, o modal avisa isso e não gera o QR.

Publicar é gratuito e leva alguns minutos. Com **GitHub Pages**:

1. Suba este projeto para um repositório no GitHub.
2. No repositório: **Settings → Pages**.
3. Em *Source*, escolha a branch `main` e a pasta `/ (root)`. Salve.
4. Aguarde um ou dois minutos e copie o endereço gerado (algo como `https://seu-usuario.github.io/nome-do-repo/index.html`).
5. Abra o modal **QR do público** e cole esse endereço no campo *Endereço publicado do sistema*.

O endereço fica salvo no navegador — você só configura uma vez. Netlify e Cloudflare Pages funcionam igual: qualquer hospedagem de site estático serve, já que não há servidor nem build.

### Como a atualização em tempo real funciona

O celular do espectador consulta o Supabase a cada 10 segundos. Não é WebSocket: é uma consulta curta em intervalo fixo, que na prática dá a mesma sensação para um chaveamento e é bem mais simples de manter.

Para o público ver um placar, ele precisa ter chegado ao Supabase. O gestor grava automaticamente (com 1,2 s de espera após parar de digitar), então **o computador do organizador precisa estar com internet** — sem ela o app continua funcionando localmente, mas o QR mostra dados congelados no último envio.

### No celular

O chaveamento é largo demais para caber legível em uma tela de 390px. Em telas estreitas a página mantém uma largura mínima útil e deixa o espectador arrastar para os lados, em vez de encolher tudo até virar um borrão.

---

## Formatos de torneio

| Formato | Duplas | Como funciona |
|---|---|---|
| Mata-mata | 4 a 24 | Perdeu, saiu. Chave simples com byes automáticos. |
| Grupos + mata-mata | 4 a 24 | Fase de grupos (todos contra todos) e depois eliminatória. |
| Dupla eliminatória | 16 (fixo) | Só sai após a segunda derrota. Tem chave principal, repescagem e finais. |

### Dupla eliminatória: o mapa de avanço

Este é o formato mais complexo e vale entender como ele é definido. Toda a progressão vive num único objeto chamado `flow`, dentro de `syncDoubleEliminationSlots()`. Cada jogo (`J1` a `J30`) declara para onde vão o vencedor (`V`) e o perdedor (`P`):

```js
J13: { V: ["J21", "d1"], P: ["J17", "d1"] },
//     vencedor vai para  perdedor cai na
//     a vaga 1 do J21    vaga 1 do J17 (repescagem)
```

Alterar o chaveamento é editar esse mapa — não há lógica de avanço espalhada pelo código. Os jogos sem `P` são os da repescagem, onde perder significa eliminação.

O desenho do telão para este formato é gerado por `doubleEliminationSvg()`, que monta o SVG por coordenadas explícitas. As ligações usam cinco helpers, cada um com um traçado diferente:

- `connector` — dobra no ponto médio entre origem e destino (o caso comum);
- `connectorAt` — dobra num X escolhido, para desviar de caixas no caminho reto;
- `connectorV` — desce primeiro, depois anda na horizontal;
- `cornerConnector` — um único canto em L;
- `polyline` — recebe os vértices prontos, para contornos que nenhum helper fixo resolve.

### Leitura da tela

O centro é uma coluna vertical, lida de cima para baixo:

```
            CAMPEÃO
        (Grande Final)
       sobre pódio dourado
              |
      +-------+-------+
      |               |
 Semifinal 1     Semifinal 2
      |               |
      +-------+-------+
              |
          3º Lugar
      sobre pódio prateado
```

A **Classificatória** cresce da esquerda para o centro; a **Repescagem**, da direita para o centro. As duas alimentam as semifinais. O selo com o nome do formato fica no canto superior direito.

### Por que existem dois cruzamentos de linha

Cada semifinal recebe **uma dupla da Classificatória e uma da Repescagem** — é assim que este formato funciona. Com as semifinais lado a lado e a Grande Final centralizada acima delas, isso força duas ligações a atravessar o centro:

- J22 (Classificatória, embaixo à esquerda) precisa chegar à Semifinal 2, à direita;
- J25 (Repescagem, em cima à direita) precisa chegar à Semifinal 1, à esquerda.

Cada uma cruza exatamente uma linha no caminho. Não é descuido: qualquer reposicionamento das caixas recria o cruzamento em outro lugar, porque as duas chaves se encontram no meio. As ligações da Repescagem são tracejadas em dourado (`line-feed`) e as do caminho do campeão são douradas e mais grossas (`line-gold`), de modo que os cruzamentos se leiam sem ambiguidade.

### Ordem das caixas na Repescagem

A primeira rodada da Repescagem é desenhada de cima para baixo como **J12, J11, J10, J9** — e não em ordem crescente. Isso é intencional: pelo mapa `flow`, J12 alimenta J17, J11 alimenta J18, e assim por diante. Desenhar em ordem crescente faria as linhas se cruzarem em diagonal por toda a coluna. Antes desta versão o diagrama de fato ligava J9 a J17, contradizendo a lógica de avanço.

---

## Arquitetura

Sendo um arquivo só, a organização é por convenção. O `index.html` tem três blocos:

| Linhas (aprox.) | Bloco | Conteúdo |
|---|---|---|
| 1–2370 | `<style>` | Tema, layout, modo telão, animações |
| 2370–2800 | `<body>` | Marcação estática de todas as abas |
| 2800–fim | `<script>` | Estado, regras e renderização |

### Estado

O estado vive em variáveis de módulo no topo do `<script>` (`teams`, `tournament`, `finances`, `uniforms`, `tournaments`). Não há framework: **toda mudança de estado chama `persist()` e depois `renderAll()`**, que redesenha as telas a partir de templates de string.

`renderAll()` custa cerca de 8 ms com 16 duplas, então o redesenho completo é intencional — é mais simples que atualização granular e não é gargalo nesta escala.

### Persistência

São três camadas, nesta ordem de autoridade:

1. **Variáveis em memória** — o que está na tela agora.
2. **`localStorage`** — fonte de verdade imediata, gravada por `writeLocalState()`. É o único ponto de escrita, e define o formato do estado salvo.
3. **Supabase** — réplica remota, para o histórico de torneios sobreviver à limpeza do navegador.

A gravação remota passa por `queueRemoteSave()`, que agrupa rajadas de digitação num único `POST` (debounce de 1,2 s). Sem isso, digitar um placar de dois dígitos gerava duas requisições.

Falhas de rede no Supabase são registradas no console e **não interrompem o uso** — o app continua funcionando só com `localStorage`.

### Segurança

Nomes de atletas são digitados pelo organizador e depois exibidos no telão, então precisam ser tratados como texto não confiável:

- `teamName()` devolve o valor **cru** — use apenas para lógica, comparação e busca.
- `teamNameHtml()` devolve o valor **escapado** — use em qualquer template que vire `innerHTML`.

Ao adicionar uma tela nova, use sempre `teamNameHtml()` / `escapeAttr()` nos templates. Um nome como `<img src=x onerror=...>` executava script antes dessa separação, e o efeito se propagava para o telão e para os outros dispositivos via Supabase.

A chave do Supabase no código é a *publishable key*, feita para ficar no cliente. A proteção real dos dados depende das políticas de RLS configuradas na tabela `futevolei_tournaments` — veja [supabase_futevolei_tournaments.sql](supabase_futevolei_tournaments.sql).

---

## Animações

O movimento é usado para comunicar eventos, não como enfeite — o telão precisa continuar legível de longe durante o jogo.

| Classe / seletor | Quando aparece | O que comunica |
|---|---|---|
| `.score-bump` | Ao digitar um placar | O lançamento foi registrado |
| `.winner-reveal` | Confronto decidido | Quem venceu |
| `.slot-filled` | Vaga "A definir" preenchida | Uma dupla avançou |
| `.view.active` | Troca de aba | Mudança de contexto |
| `--stagger` | Listas e tabelas | Cascata na ordem das linhas |
| `.line` (SVG) | Telão | As ligações se desenham progressivamente |

As classes de evento são aplicadas por `playOnce()`, que força o reinício da animação mesmo quando a classe já estava presente.

Todo o conjunto é desligado sob `@media (prefers-reduced-motion: reduce)`. Nesse modo, as linhas do SVG recebem `stroke-dashoffset: 0` explicitamente — sem isso elas ficariam invisíveis, já que nascem com o traço "não desenhado".

### Ao adicionar uma animação

Ela precisa sobreviver ao redesenho: `renderAll()` recria os nós, então animações de entrada reiniciam. No telão isso importa muito — por isso `renderBracket()` compara `publicBracketSignature()` e **não repinta quando nada mudou**, senão a tela piscaria a cada 10 segundos.

---

## Testes

Não há suíte no repositório. Os testes usados na última revisão foram scripts Playwright avulsos que cobriam: criação de torneio nos três formatos, lançamento de placar, avanço do vencedor, persistência após reload, carga do telão, escape de HTML em nomes, contagem de requisições ao Supabase por tecla, comportamento sob `prefers-reduced-motion`, e o fluxo completo do QR (um contexto de celular limpo abrindo o link e recebendo as atualizações do gestor).

Para recriar, basta `npm i playwright`, `npx playwright install chromium` e apontar para o `index.html` via `file://`.

Duas armadilhas que valem lembrar ao escrever testes:

- **`allMatches()` devolve cópias**, não os objetos do estado. Para alterar placares num teste, mexa em `tournament.rounds[i].matches[j]` diretamente.
- **Criar torneios grava no Supabase de verdade.** Rodar testes suja a tabela `futevolei_tournaments`; limpe os registros de teste depois.

O gerador de QR pode ser verificado de ponta a ponta decodificando a matriz com `jsqr`: gere com `qrMatrix(texto)`, converta para bitmap e confirme que o texto decodificado bate. Foi assim que se descobriu que os padrões de alinhamento precisavam ser desenhados antes da linha de temporização — sem isso, todo QR da versão 7 em diante ficava ilegível.

---

## Limitações conhecidas

- **O QR exige o sistema publicado e internet no computador do gestor.** Sem publicar, não há endereço que o celular alcance; sem internet no gestor, os placares não chegam ao Supabase e o público vê dados congelados.
- **A atualização é por consulta a cada 10s, não WebSocket.** Suficiente para um chaveamento, mas não é instantâneo.
- **Dupla eliminatória é fixa em 16 duplas.** O mapa `flow` e as coordenadas do SVG são escritos à mão para esse tamanho.
- **Pontuação fixa em 18.** O campo existe em `defaultSettings()`, mas `getSettings()` e a validação usam 18 direto.
- **Sem controle de acesso.** Quem abrir a página edita o torneio.
- **Edição simultânea não é resolvida.** Dois gestores na mesma tabela sobrescrevem um ao outro; vence o último a salvar.
