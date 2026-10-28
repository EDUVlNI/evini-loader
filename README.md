# EVINI 5.4 · Da Hood

Interface refeita a partir do painel de Configurações do projeto do Roblox Studio: coluna à esquerda, degradê preto horizontal, tipografia Gotham, controles claros e abertura/fechamento com fade e deslocamento. Sem a moldura antiga ou botão Play. Título EVINI ampliado, títulos de categoria menores, espaçamento revisado e ícones brancos; Ajustes usa a mesma engrenagem local do painel original do Studio. As categorias entram em sequência com fade e deslocamento; ao passar o mouse, têm inclinação sutil e brilho que acompanha o cursor. Reduzir animações desativa esses movimentos.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua"))()
```

## Interação do menu (5.3)

Botões sem caixas ou divisórias: ícone e texto acompanham o cursor, com inclinação discreta, retorno amortecido e compressão ao pressionar. A área clicável permanece fixa. Os reflexos neutros são recortados pelas letras e imagens, adaptando os canais CursorLight, Shine e Slash do JOGAR do projeto Studio. Um único controlador atualiza os seis botões; iluminação limitada a 30 atualizações por segundo. A entrada escalonada termina antes de liberar os efeitos.

A inicialização mostra um degradê e uma barra central. Os marcos avançam após criar serviços/visuais, controladores, controles e conexões, terminando em 100% após a primeira atualização. A barra desaparece antes do degradê; o menu permanece fechado. São marcos de montagem do script, não porcentagem de download de assets.

## Abrir e navegar

**K** abre/fecha o painel, que começa oculto. A lista tem **Cam Lock, Hitbox, Triggerbot, Visual, Jogadores e Ajustes**. Clique em uma categoria para acessar seus controles; **Categorias** volta à lista e **Voltar** fecha o painel. **Encerrar EVINI**, em Ajustes, remove os efeitos e restaura a hitbox.

A primeira execução desta versão migra o atalho do painel para K, resolvendo conflitos com os atalhos da câmera e do trigger. Depois, os atalhos personalizados continuam salvos. As demais preferências são preservadas. Tamanho, transparência, escurecimento, contraste, volume e redução das animações ficam em Ajustes. O painel se adapta ao espaço da tela.

## Configurações preservadas

- **Cam Lock:** tecla de captura/liberação, FOV e transparência, seleção da parte do corpo, filtros de parede/time/NPC, suavização e calibração avançada de previsão manual, ping e Air Part. A captura continua exigindo a tecla; não adquire outro alvo automaticamente.
- **Hitbox:** tamanho numérico, invisibilidade, Knock Check e seleção de jogadores. A implementação normal foi preservada. **Hitbox (Painhood) foi removida**, incluindo sua lógica e preferências.
- **Triggerbot:** tecla, modos automático/segurar/alternar, corpo inteiro ou área quadrada, repetição, atraso, intervalo, filtros e método de disparo. Continua pausando com faca equipada.
- **Visual:** nomes de jogadores/entidades, Spectate / Aim Viewer e indicadores de câmera. Anti-Aim removido, inclusive atalhos, preferências e conexões.
- **Jogadores:** lista, pesquisa, seleção individual, marcar/desmarcar todos e preferência para novos jogadores.
- **Ajustes:** aparência, atalhos, áudio, notificações e salvamento local quando disponível.

Fechar o painel não desliga as opções habilitadas. Hitbox e ESP continuam atualizando. A interação com o painel pausa os disparos do trigger; o modo automático habilitado retoma quando o painel fecha. Segurar/alternar continuam exigindo sua tecla. Escape, perda de foco e indisponibilidade do personagem suspendem o trigger.

## Spectate / Aim Viewer

Em **Visual**, digite Username, DisplayName ou parte do nome e clique em **Buscar e observar**. Use `@username` para distinguir nomes iguais ou escolha **Observar** na lista existente de Jogadores. Buscas com mais de uma correspondência pedem uma escolha explícita. A seleção usa UserId.

A câmera acompanha a posição da cabeça, mas yaw/pitch são controlados exclusivamente pelo seu mouse. A rotação do personagem não redefine a câmera. Abrir o menu libera o cursor. Parar, Esc ou saída do jogador restaura câmera e mouse; morte aguarda renascimento. Trocar de jogador preserva a rotação escolhida.

**AimViewer · linha branca** liga um Beam fino da região do tronco ao ponto de mira informado pelo jogo. O adaptador aceita `BodyEffects.MousePos`/`MousePosition` ou valores equivalentes diretamente no personagem. Exige vetor válido e alteração observada recentemente; sem isso, oculta a linha e informa a ausência de dados. Não estima o cursor nem usa a direção da cabeça como mira. Um alvo mirando parado por mais de 0,75 s também pode perder a linha, pois essa fonte não oferece heartbeat/timestamp.

A observação pausa cam lock e trigger. Anti-Aim foi removido definitivamente. A câmera real de outro cliente não é acessível por esse recurso. Em um jogo próprio, a sincronização deve ser implementada pelo servidor; não é possível instalar essa parte no servidor do Da Hood a partir deste script.

[Análise técnica e limites](docs/aimviewer-analysis.md). A referência foi novamente baixada e analisada como texto, sem execução; segue ofuscada e com o mesmo hash.

## Sons do trigger

O texto de status do trigger foi removido tanto do overlay quanto da categoria. Um toque agudo indica ativação e um grave indica desativação/pausa. Só tocam na mudança de estado, inclusive na pausa por faca, sem repetição por quadro ou por alvo. Há uma opção de sons na categoria Triggerbot; o volume segue o controle em Ajustes. O indicador opcional do cursor continua separado.

O som dos botões usa o mesmo arquivo local do painel do Studio, `volume_slider.ogg`. Os avisos do trigger usam um som local com duas alturas, sem download de áudio externo. Para diagnóstico sem texto na tela, `EVINI.GetTriggerStatus()` retorna a última mensagem.

## Limites e validação

Compilação Luau e testes simulados cobrem navegação, atalhos, migração, efeitos com painel oculto, sons por mudança de estado, pausa com faca, reversão de animação, redimensionamento, salvamento e limpeza. Não substituem a conferência visual/sonora no Roblox e no executor do usuário.

A detecção do corpo considera também volumes orientados de cabeça e membros que não retornam em consultas físicas. Esses volumes são caixas de peças, não o contorno exato das malhas. Clique sintético depende do executor; ativação da ferramenta e alterações locais de hitbox dependem do jogo e não garantem registro no servidor.

Testes locais:

```sh
../../work/luau-runtime/source/luau-compile --null main.lua
PYTHONPATH=../../work/python-libs python3 tests/regression.py
PYTHONPATH=../../work/python-libs python3 tests/triggerbot.py
PYTHONPATH=../../work/python-libs python3 tests/trigger_body.py
PYTHONPATH=../../work/python-libs python3 tests/studio_ui.py
PYTHONPATH=../../work/python-libs python3 tests/independent_viewer.py
PYTHONPATH=../../work/python-libs python3 tests/spectate.py
```
