# EVINI 5.2 · Da Hood

Interface refeita a partir do painel de Configurações do projeto do Roblox Studio: coluna à esquerda, degradê preto horizontal, tipografia Gotham, controles claros e abertura/fechamento com fade e deslocamento. Sem a moldura antiga, tela de carregamento ou Play. Título EVINI ampliado, títulos de categoria menores, espaçamento revisado e ícones brancos; Ajustes usa a mesma engrenagem local do painel original do Studio. As categorias entram em sequência com fade e deslocamento; ao passar o mouse, têm inclinação sutil e brilho que acompanha o cursor. Reduzir animações desativa esses movimentos.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua"))()
```

## Abrir e navegar

**K** abre/fecha o painel, que começa oculto. A lista tem **Cam Lock, Hitbox, Triggerbot, Visual, Jogadores e Ajustes**. Clique em uma categoria para acessar seus controles; **Categorias** volta à lista e **Voltar** fecha o painel. **Encerrar EVINI**, em Ajustes, remove os efeitos e restaura a hitbox.

A primeira execução desta versão migra o atalho do painel para K, resolvendo conflitos com os atalhos da câmera e do trigger. Depois, os atalhos personalizados continuam salvos. As demais preferências são preservadas. Tamanho, transparência, escurecimento, contraste, volume e redução das animações ficam em Ajustes. O painel se adapta ao espaço da tela.

## Configurações preservadas

- **Cam Lock:** tecla de captura/liberação, FOV e transparência, seleção da parte do corpo, filtros de parede/time/NPC, suavização e calibração avançada de previsão manual, ping e Air Part. A captura continua exigindo a tecla; não adquire outro alvo automaticamente.
- **Hitbox:** tamanho numérico, invisibilidade, Knock Check e seleção de jogadores. A implementação normal foi preservada. **Hitbox (Painhood) foi removida**, incluindo sua lógica e preferências.
- **Triggerbot:** tecla, modos automático/segurar/alternar, corpo inteiro ou área quadrada, repetição, atraso, intervalo, filtros e método de disparo. Continua pausando com faca equipada.
- **Visual:** nomes de jogadores/entidades, Spectate / Aim Viewer, Anti-Aim separado e indicadores de câmera.
- **Jogadores:** lista, pesquisa, seleção individual, marcar/desmarcar todos e preferência para novos jogadores.
- **Ajustes:** aparência, atalhos, áudio, notificações e salvamento local quando disponível.

Fechar o painel não desliga as opções habilitadas. Hitbox e ESP continuam atualizando. A interação com o painel pausa os disparos do trigger; o modo automático habilitado retoma quando o painel fecha. Segurar/alternar continuam exigindo sua tecla. Escape, perda de foco e indisponibilidade do personagem suspendem o trigger.

## Spectate / Aim Viewer

Em **Visual**, digite Username, DisplayName ou parte do nome e clique em **Buscar e observar**. Use `@username` para distinguir nomes iguais ou escolha **Observar** na lista existente de Jogadores. Buscas com mais de uma correspondência pedem uma escolha explícita. A seleção usa UserId.

**Personagem** acompanha posição/orientação do personagem. **Direção da mira** usa um ponto de mira exposto pelo jogo quando disponível; sem dado recente, mostra direção estimada. A câmera é sempre aproximada, não a câmera real do outro cliente. O aviso mostra quem está sendo observado e a origem da direção. **Parar**, desligar observação ou Esc restaura a câmera anterior. Morte aguarda renascimento; saída do servidor encerra.

A observação pausa cam lock, trigger e pulso Anti-Aim para evitar conflito de câmera/ações, sem apagar preferências. O Anti-Aim continua sendo outro recurso. Ao recarregar o script, o Spectate começa desligado.

[Análise técnica, engenharia reversa estática, limites e testes](docs/aimviewer-analysis.md). A referência externa permanece ofuscada após a camada de transporte; não foi executada nem incorporada.

## Anti-aim · C

Implementação independente da parte legível enviada pelo usuário: aplica os valores X/Y/Z na velocidade linear do próprio personagem durante o Heartbeat e restaura a velocidade capturada antes da renderização seguinte. Os valores iniciais são `68756`, `100`, `-344`; os campos aceitam números entre -100000 e 100000. A tecla padrão **C** pode ser alterada na categoria Visual, com proteção contra conflitos.

Começa desligado a cada execução, mesmo com preferências salvas. Desligar, abrir o painel, perder foco, morrer, trocar de personagem ou encerrar restaura qualquer alteração pendente. Pausa com o painel aberto, falta de foco ou personagem indisponível; retoma quando essas condições cessam se ainda habilitado. Não inclui a falsificação de `IsInGroup` nem executa o carregador remoto ofuscado fornecido. Alterar velocidade pode afetar a física; não há validação em jogo de replicação ou eficácia contra mira.

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
PYTHONPATH=../../work/python-libs python3 tests/anti_velocity.py
PYTHONPATH=../../work/python-libs python3 tests/spectate.py
```
