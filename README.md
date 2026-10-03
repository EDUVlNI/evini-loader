# EVINI 3.1

Hub independente inspirado nas capturas das configurações do Da Hood: painel único translúcido, somente cantos superiores arredondados, base reta, título EV centralizado, abas horizontais, interruptores verdes e botão de fechar vermelho. Não carrega Nitrogen ou Azure.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua"))()
```

## Jogadores

Aba com avatar, nome de exibição e @usuário de cada outro jogador presente. Uma caixa marcada permite hitbox e cam lock; desmarcada exclui dos dois. Desmarcar restaura imediatamente a hitbox e libera o alvo atual. Marcar todos / Desmarcar todos afetam o servidor atual, mesmo com busca ativa. A opção Selecionar novos jogadores define o padrão de quem entrar depois; escolhas anteriores salvas prevalecem.

A seleção é salva por UserId quando o executor permite arquivos locais. Ela acompanha respawns e entradas futuras. Os antigos filtros de nick único foram substituídos por esta lista. NPCs continuam sob o controle próprio Incluir NPCs no lock.

## Avisos e visual

- Entradas e saídas: @nick no canto superior esquerdo, até quatro avisos simultâneos, duração de quatro segundos. A lista inicial não gera avisos. Desativação em Ajustes.
- ESP: somente nomes, agora com etiquetas nativas que acompanham o personagem; reaproveitamento dos elementos durante K.O. e recuperação. Máximo de 1.200 studs. Verificação de elegibilidade a cada 0,15 s; sem reprojeção manual contínua dos nomes.
- Aim Viewer: raio e ponto vermelhos em 3D, com atualização limitada a 30 Hz. Quando BodyEffects.MousePos está replicado, funciona inclusive sem arma equipada. Sem esse dado, a opção de estimativa mostra a direção da arma ou cabeça, com legenda explícita. Não revela um cursor remoto que o jogo não compartilha, nem garante a atualidade do último valor replicado. O raio respeita a oclusão 3D; o rótulo permanece visível como sobreposição.

## Controles preservados

**L** abre/oculta; **Q** captura/solta cam lock com hub oculto; **Esc** solta; **X** encerra e restaura hitboxes. Preferências de atalhos continuam valendo. Mantidos FOV invisível, predict, Air Part, Knock Check, tamanho numérico e transparência da hitbox, notificações EVINI / locked in @nome e configurações de aparência. Silent continua removido.

## Validação

Compilação Luau e testes simulados de câmera, seleção individual/em lote, persistência, entrada/saída, limpeza de conexões, limite/expiração de avisos, reutilização do ESP e Aim Viewer sem arma. Testes reproduzíveis em `tests/regression.py`, com Python, lupa e luaparser. Não medimos FPS nem renderizamos a UI dentro do Roblox/Opiumware; aparência e desempenho reais precisam de validação no jogo.

Referências técnicas: [BillboardGui](https://create.roblox.com/docs/reference/engine/classes/BillboardGui), [Beam](https://create.roblox.com/docs/reference/engine/classes/Beam), [Players](https://create.roblox.com/docs/reference/engine/classes/Players). A referência visual principal são os prints fornecidos pelo usuário.

## Interface 3.1

No topo, **− / porcentagem / +** ajustam a escala em passos de 5%; clicar na porcentagem restaura 100%. Em Ajustes há slider e campo numérico de 0,45 a 1,50. O tamanho efetivo é limitado ao espaço da tela e aparece no topo; a preferência é salva.

Minimizar usa uma única transição curta de opacidade e escala, sem separar o painel em blocos. Sons dos botões podem ser desligados e têm controle de volume. Um único Sound local é reutilizado; a reprodução do arquivo interno depende do cliente Roblox.

Os controles têm bordas retas, preenchimento em gradiente e feedback de clique. A área de rolagem ganhou margem direita para não cortar controles. O ajuste à tela só é recalculado quando a janela ou o tamanho escolhido mudam. Compilação e testes simulados passaram; fidelidade visual e som ainda requerem validação dentro do Roblox.
