# EVINI 2.0

Hub independente e legivel para clientes Roblox. Abas HITBOX, ESP, CAM LOCK, PREDICT e INTERFACE; tema grafite/verde, entrada e saida em quatro pecas, blur leve opcional e emblema da crew 8440749.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

Nao carrega Nitrogen, Azure, Luarmor ou bibliotecas de terceiros. O fonte publico do Azure consultado e um loader para Luarmor; as funcoes aqui foram implementadas independentemente. Nao representa copia ou equivalencia de todas as funcoes do Azure.

## Uso rapido

1. Em **CAM LOCK**, ative o cam lock e ajuste o raio FOV.
2. Escolha Cabeca, Tronco, Tronco baixo ou Centro.
3. O padrao e **segurar Q** para acompanhar um alvo dentro do circulo do mouse. Ha tambem **alternar Q** e **automatico**.
4. **L** oculta/abre o hub. A camera fica livre enquanto o hub esta aberto. As duas teclas podem ser trocadas em INTERFACE; a mesma tecla nao pode exercer as duas funcoes.
5. Em **ESP**, ative jogadores e/ou entidades. Verde identifica jogadores e ambar identifica NPCs.
6. Em **PREDICT**, ajuste o tempo manual ou ative a estimativa pelo ping. Os controles tem slider e campo numerico.

Hitbox, ESP e cam lock iniciam desligados. Knock Check e verificacao de paredes iniciam ligados. Mantenha os recursos que nao estiver usando desligados.

## Hitbox e filtros

- Tamanho numerico de 2 a 30 studs, sem slider. Aceita ponto ou virgula.
- Box totalmente invisivel ou verde com transparencia de 65%.
- **Todos**, **Ignorar nick** e **So este nick**. Confirme o nick com Enter ou clicando fora.
- Usuario exato tem prioridade sobre nome de exibicao. Nomes duplicados exigem o @usuario.
- Filtros por nick tambem valem para o cam lock. O modo So este nick nao seleciona NPCs.
- Knock Check exclui `BodyEffects["K.O"]` mesmo com vida positiva. Vida zero, estado Dead ou `BodyEffects.Dead` sempre excluem o alvo.
- Desativar ou fechar restaura tamanho, transparencia, cor, material e colisao salvos. Ocultar o hub mantem os recursos ativos.

## ESP

Caixas 2D aproximadas, nome, distancia em studs e barra de vida. Descoberta de jogadores e modelos com **Humanoid** presentes no cliente, incluindo adicoes e remocoes durante a sessao. StreamingEnabled limita o que o cliente pode ver. Objetos sem Humanoid nao sao identificados automaticamente como entidades.

As caixas usam cabeca/centro e uma altura estimada para nao crescer junto com a hitbox expandida. Personagens de proporcoes incomuns podem precisar de adaptacao. O ESP e independente do filtro por nick; mortos e Knock Check sao respeitados.

## Cam lock e FOV

O FOV e um **raio em pixels ao redor do mouse**, nao uma alteracao do campo de visao da camera. Escolhe o alvo elegivel mais proximo do mouse e o mantem enquanto continuar vivo, visivel na tela, dentro do circulo e permitido pelos filtros. Pode verificar paredes, ignorar equipe e incluir NPCs.

A camera e ajustada depois da camera padrao do Roblox, com suavizacao independente da taxa de frames. Em R6, Tronco/Tronco baixo usam Torso; outras partes ausentes usam HumanoidRootPart ou PrimaryPart quando disponivel. Nao ha modificacao de remotes, silent aim, disparo automatico ou garantia de acerto.

## Ping e Air Part

- **Manual:** posicao observada + velocidade multiplicada pelo tempo em segundos.
- **Automatico:** usa metade do RTT retornado por `LocalPlayer:GetNetworkPing()`, com media suavizada e ganho ajustavel. E apenas uma estimativa inicial; se a leitura falhar, retorna ao valor manual.
- **Air Part:** troca a parte durante Jumping/Freefall. Aplica velocidade e uma estimativa de queda usando a gravidade do jogo. Ha tempo manual separado para o ar; no automatico, o ping define o tempo dos dois casos.
- Previsao limitada a 0–0,5 segundo e velocidade observada limitada a 250 studs/s para evitar deslocamentos extremos.

Isso nao melhora Wi-Fi, nao reduz ping, nao conhece velocidade de bala nem a compensacao de lag de cada arma/servidor. Extrapolacao linear pode errar em mudancas bruscas de direcao, impulsos e pulos personalizados.

## Ciclo de vida e compatibilidade

Reexecutar encerra a instancia anterior. Fechar desconecta eventos, remove caixas/circulo/blur e desfaz as hitboxes. Perder foco solta o lock. Abrir o hub pausa a camera; fechar a janela encerra tudo. A interface se ajusta ao tamanho da tela.

Base para R6/R15 com Humanoid; nao garante funcionamento universal. Jogos com camera propria, personagens customizados, entidades nao replicadas ou validacao no servidor podem ignorar partes dos recursos. Nenhum teste real de Da Hood ou outro FPS foi realizado nesta atualizacao.

## Verificacao

Compilacao Lua e execucao com APIs simuladas, incluindo inicializacao completa, KO/recuperacao, filtros, ESP de jogadores/NPCs, coordenadas do FOV, lock por segurar/alternar/automatico, paredes, equipe, Air Part, gravidade, ping e fallback, R6, atalhos, inversao rapida de animacao e limpeza/restauracao. Testes simulados nao confirmam aparencia, performance nem compatibilidade em uma sessao Roblox.

## Referencias consultadas

- [Loader publico Azure Modded](https://raw.githubusercontent.com/Actyrn/Scripts/main/AzureModded) — apenas leitura; nao executado.
- [Camera / WorldToViewportPoint](https://create.roblox.com/docs/reference/engine/classes/Camera) — coordenadas do FOV e projecao.
- [Player / GetNetworkPing](https://create.roblox.com/docs/reference/engine/classes/Player) — leitura do RTT.
- [RunService / BindToRenderStep](https://create.roblox.com/docs/reference/engine/classes/RunService) — ordem de atualizacao da camera.
