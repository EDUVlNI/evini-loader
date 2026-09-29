# Revisao EVINI 2.3

Esta revisao corrige omissoes: silent aim, silent lock e Aim Viewer nao existiam na 2.2. Agora existem implementacoes, com dependencias expostas na interface. Nenhum teste simulado confirma acertos no servidor Roblox.

| Pedido | Implementacao | Limite / verificacao |
|---|---|---|
| Hub simples e personalizavel | Mira, Visual e Ajustes; Builder Sans, cor, transparencia, escala, blur e movimento reduzido | Aparencia real nao validada no Roblox |
| Montar/desmontar e transicoes | Animacao cancelavel em quatro partes e transicao entre abas | Teste de inversao rapida de animacao passou |
| ESP somente nomes | Nome de exibicao de jogadores e nome de NPCs, sem caixa, distancia ou vida | Entidades precisam de Humanoid e estar disponiveis no cliente |
| Knock Check | Health, estado Dead, BodyEffects.Dead e K.O | Testes de KO, recuperacao e restauracao passaram |
| Tamanho e transparencia da hitbox | Campo numerico 2–30 e invisibilidade | Modificacao local; servidor pode ignorar |
| Ignorar nick / apenas um nick | Usuario exato ou nome de exibicao unico | Ambiguidades sao informadas |
| Cam lock por tecla | Q padrao; uma apertada captura, outra solta; sem retarget automatico | Camera local; filtros e KO testados |
| Silent com FOV | Selecao automatica dentro de raio proprio, sem mover camera | Requer adaptador e executor compativeis; tiros reais nao testados |
| Silent lock fixo | R padrao configuravel; captura uma pessoa, continua fora do FOV, solta por tecla/morte/KO | Mesmo requisito de adaptador; nenhum disparo automatico |
| Aim Viewer | Linha a partir de MousePos replicado; estimativa da arma apenas se ativada, rotulada | Mira real pode nao estar replicada |
| Tudo visivel ou invisivel | FOV, marcador e linha de camera/silent separados; opcao de ocultar todos os desenhos | Ocultar nao desliga o recurso de mira |
| Notificar lock | EVINI · #death · 8440749 + nome; notificacoes opcionais | Teste de troca/expiracao e limpeza |
| Pred e Air Part | Parte selecionavel, extrapolacao, gravidade e formula propria com Auto Pred Math | Nao copia formula Azure nem elimina lag |
| Salvar configuracoes | JSON local por experiencia, validado; controles/teclas/visual salvos | Requer readfile/writefile; nao salva alvo preso |

## Adaptador silent

Somente RemoteEvent `ReplicatedStorage.MainEvent`, metodo FireServer, acao `UpdateMousePos` ou `UpdateMousePosI` e segundo argumento Vector3. O codigo altera apenas esse vetor quando ha um alvo valido; nao gera eventos extras nem modifica outros argumentos/remotes. Ao fechar, o adaptador deixa de alterar chamadas. Reexecutar reutiliza uma ponte para evitar hooks duplicados.

- **Sem recursos do executor:** o painel informa as funcoes ausentes.
- **Sem MainEvent:** o painel informa que nao ha adaptador para o jogo.
- **Pronto, aguardando dados:** o hook foi instalado; o formato ainda nao foi observado.
- **Formato observado / redirecionamentos:** chamadas compativeis foram vistas/alteradas no cliente. Isso nao comprova que o servidor aceitou o acerto.

## Fontes tecnicas consultadas

Somente leitura; nenhum script externo foi executado ou incluido:

- [Exemplo publico de mapeamento de comandos Da Hood](https://github.com/DeDuonq/DeDuonq/blob/main/Juju.lol).
- [Exemplo publico de leitura de BodyEffects.MousePos](https://gist.github.com/DetectiveLaw/060df11d3193f2fec98a1d3cdb248717).
- [Roblox Camera](https://create.roblox.com/docs/reference/engine/classes/Camera) e [Player](https://create.roblox.com/docs/reference/engine/classes/Player).

Validacao adicional: compilacao concluida com Luau 0.740; diagnosticos de executor sem hooks e jogo sem MainEvent tambem testados.
