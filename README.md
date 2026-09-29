# EVINI 2.2

Hub independente e legivel para clientes Roblox. Abas Mira, Visual e Ajustes; calibracao e hitbox em secoes expansiveis; tema grafite/verde, entrada e saida em quatro pecas, blur leve opcional e emblema da crew 8440749.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

Nao carrega Nitrogen, Azure, Luarmor ou bibliotecas de terceiros. O fonte publico do Azure consultado e um loader para Luarmor; as funcoes aqui foram implementadas independentemente. Nao representa copia ou equivalencia de todas as funcoes do Azure.

## Uso rapido

1. Em **Mira**, ative o cam lock e ajuste o raio FOV.
2. Escolha Cabeca, Tronco, Tronco baixo ou Centro.
3. Pressione **Q uma vez** para capturar a pessoa mais proxima do mouse dentro do FOV. Pressione **Q novamente**, ou **Esc**, para soltar. A tecla pode ser trocada dentro de Mira. Nao ha captura automatica, captura ao passar o mouse nem troca automatica de alvo.
4. **L** oculta/abre o hub. A camera fica livre enquanto o hub esta aberto. As duas teclas podem ser trocadas em Ajustes; a mesma tecla nao pode exercer as duas funcoes.
5. Em **Visual**, ative jogadores e/ou entidades. Verde identifica jogadores e ambar identifica NPCs.
6. Na aba **Mira**, use **Ponto de partida 80–120 ms**, ou ajuste a previsao manual/automatica. Os controles tem slider e campo numerico.

Na primeira execucao, hitbox, ESP e cam lock iniciam desligados; nas seguintes, as preferencias salvas sao restauradas sem restaurar o lock em uma pessoa. Knock Check e verificacao de paredes iniciam ligados. Mantenha os recursos que nao estiver usando desligados.

## Hitbox e filtros

- Tamanho numerico de 2 a 30 studs, sem slider. Aceita ponto ou virgula.
- Box totalmente invisivel ou verde com transparencia de 65%.
- **Todos**, **Ignorar nick** e **So este nick**. Confirme o nick com Enter ou clicando fora.
- Usuario exato tem prioridade sobre nome de exibicao. Nomes duplicados exigem o @usuario.
- Filtros por nick tambem valem para o cam lock. O modo So este nick nao seleciona NPCs.
- Knock Check exclui `BodyEffects["K.O"]` mesmo com vida positiva. Vida zero, estado Dead ou `BodyEffects.Dead` sempre excluem o alvo.
- Desativar ou fechar restaura tamanho, transparencia, cor, material e colisao salvos. Ocultar o hub mantem os recursos ativos.

## Visual e personalizacao

ESP apenas com nome de exibicao, sem caixas, distancia ou barra de vida. Jogadores e NPCs podem ser ativados separadamente; entidades precisam de Humanoid no cliente. StreamingEnabled limita o que esta disponivel. Mortos e Knock Check continuam respeitados.

Ajustes de cor (Verde, Esmeralda, Azul, Lilas), transparencia, escala da interface, blur e reducao de movimento. Fontes Builder Sans, tres abas e transicoes curtas. Preferencias de aparencia usam o mesmo salvamento local validado.

Notificacoes opcionais: `EVINI · #death`, `Locked on: Nome` e `Alvo liberado`. Duram dois segundos e substituem a mensagem anterior para nao acumular na tela.

## Cam lock e FOV

O FOV e um **raio em pixels ao redor do mouse**, nao uma alteracao do campo de visao da camera. A captura ocorre somente ao pressionar a tecla. O FOV limita a captura inicial; depois o mesmo alvo e mantido enquanto valido. Se morrer, ficar KO, sair da tela, deixar os filtros ou ficar bloqueado por parede, o lock e solto e exige nova apertada. Pressionar a tecla com o circulo vazio nao arma uma captura futura. Pode verificar paredes, ignorar equipe e incluir NPCs.

A camera e ajustada depois da camera padrao do Roblox, com suavizacao independente da taxa de frames. Em R6, Tronco/Tronco baixo usam Torso; outras partes ausentes usam HumanoidRootPart ou PrimaryPart quando disponivel. Nao ha modificacao de remotes, silent aim, disparo automatico ou garantia de acerto.

## Ping e Air Part

- **Manual:** posicao observada + velocidade multiplicada pelo tempo em segundos.
- **Automatico / Auto Pred Math:** formula propria do EVINI: `base + ping_em_segundos * (250 / Math)`, limitada a 0–0,5 segundo. O ping usa `LocalPlayer:GetNetworkPing()` suavizado. O ponto de partida usa Math 250 e base 0,040: 80 ms resulta em 0,120 s; 120 ms em 0,160 s. Aumentar Math reduz a antecipacao. Nao e uma reproducao verificada da formula do Azure. Se a leitura falhar, retorna ao valor manual.
- **Air Part:** troca a parte durante Jumping/Freefall. Aplica velocidade e uma estimativa de queda usando a gravidade do jogo. Ha tempo manual separado para o ar; no automatico, o ping define o tempo dos dois casos.
- Previsao limitada a 0–0,5 segundo e velocidade observada limitada a 250 studs/s para evitar deslocamentos extremos.

Isso nao melhora Wi-Fi, nao reduz ping, nao conhece velocidade de bala nem a compensacao de lag de cada arma/servidor. Extrapolacao linear pode errar em mudancas bruscas de direcao, impulsos e pulos personalizados.

## Salvamento

Preferencias e teclas sao gravadas automaticamente, apos 0,35 s sem novas alteracoes, e ao fechar/reexecutar. Arquivo `evini-settings-<GameId>.json` no armazenamento local do executor, separado por experiencia Roblox (PlaceId como alternativa). Nao salva alvo capturado nem ativa o lock ao reabrir.

Requer `readfile` e `writefile`. A aba Ajustes mostra sucesso, indisponibilidade ou falha. Sem suporte, o hub funciona sem persistencia. O JSON e validado; arquivos invalidos retornam aos padroes. Nao sincroniza entre dispositivos ou executores, e uma interrupcao abrupta antes da gravacao pode perder a ultima alteracao.

## Ciclo de vida e compatibilidade

Reexecutar encerra a instancia anterior. Fechar desconecta eventos, remove caixas/circulo/blur e desfaz as hitboxes. Perder foco solta o lock. Abrir o hub pausa a camera; fechar a janela encerra tudo. A interface se ajusta ao tamanho da tela.

Base para R6/R15 com Humanoid; nao garante funcionamento universal. Jogos com camera propria, personagens customizados, entidades nao replicadas ou validacao no servidor podem ignorar partes dos recursos. Nenhum teste real de Da Hood ou outro FPS foi realizado nesta atualizacao.

## Verificacao

Compilacao Lua e execucao com APIs simuladas, incluindo inicializacao completa, KO/recuperacao, filtros, ESP de jogadores/NPCs, coordenadas do FOV, captura apenas por tecla, soltura e ausencia de recaptura automatica, paredes, equipe, Air Part, gravidade, ping e fallback, R6, atalhos, inversao rapida de animacao e limpeza/restauracao. Foram acrescentados testes de salvamento/restauracao, teclas, arquivo corrompido e executor sem armazenamento. Testes simulados nao confirmam aparencia, performance nem compatibilidade em uma sessao Roblox.

## Referencias consultadas

- [Loader publico Azure Modded](https://raw.githubusercontent.com/Actyrn/Scripts/main/AzureModded) — apenas leitura; nao executado.
- [Camera / WorldToViewportPoint](https://create.roblox.com/docs/reference/engine/classes/Camera) — coordenadas do FOV e projecao.
- [Player / GetNetworkPing](https://create.roblox.com/docs/reference/engine/classes/Player) — leitura do RTT.
- [RunService / BindToRenderStep](https://create.roblox.com/docs/reference/engine/classes/RunService) — ordem de atualizacao da camera.

Atualizacao 2.2: testes adicionais de tres abas, ESP somente nomes, expansao de secoes, cor/transparencia, movimento reduzido e persistencia visual. Aparencia real ainda depende de verificacao no cliente Roblox.
