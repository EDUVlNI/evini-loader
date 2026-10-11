# EVINI 4.4

Hub independente inspirado nas capturas das configurações do Da Hood: painel único translúcido, somente cantos superiores arredondados, base reta, título EV centralizado, abas horizontais, interruptores verdes e botão de fechar vermelho. Não carrega Nitrogen ou Azure.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua"))()
```

## Triggerbot — 4.4

Aba separada, sem modificar as duas hitboxes. **Habilite o triggerbot, equipe sua arma, esconda o painel com L e segure T**. A tecla é editável na própria aba. Em modo ligar/desligar, uma pressão arma e outra desarma. Esc, abertura do painel, digitação, morte/K.O. local ou perda de foco desarmam; fechar o painel ou recuperar foco não rearma automaticamente.

- **Lado do quadrado:** 4–300 pixels ao redor do cursor; padrão 32. A seleção verifica se o centro da parte escolhida está nessa área. Isso não aumenta o personagem nem move a mira até ele. Quadrados maiores podem disparar mesmo com o cursor fora da silhueta, sem garantir acerto.
- Parte de referência: tronco, cabeça ou centro. Apenas jogadores vivos e permitidos na aba Jogadores; sem NPCs. Controles próprios de equipe e Knock Check.
- **Verificar paredes** ativado por padrão: exige linha livre da câmera à parte escolhida. Desligar remove esse filtro, mas não permite que projéteis atravessem paredes.
- Atraso inicial de 0–0,5 s e intervalo de 0,05–1 s entre disparos. Nenhuma rajada acumulada após travamento de quadro. Clique manual pausa a automação.
- **Clique (executor)** usa `mouse1click`, se disponível. **Ativar Tool** é uma alternativa nativa de ativação curta de ferramenta equipada, seguida de desativação. A compatibilidade depende da arma; não chama remotes de dano e não é silent aim.
- Mostrar/ocultar o quadrado é independente da ativação. Ele fica verde quando armado. Preferências são salvas, mas o estado armado nunca é restaurado ao executar novamente.

O status informa falta de arma, indisponibilidade de clique ou erros. Compilação Luau e `tests/triggerbot.py` cobrem ativação, tempo entre disparos, filtros, tecla, pausa e limpeza. O disparo real no Painhood/Opiumware ainda precisa de validação em jogo; os testes são simulados.

## Correção Painhood — 4.3

A expansão agora define a peça como `Massless` e reduz seu `RootPriority` antes de alterar o tamanho. Isso evita que o volume ampliado ganhe massa ou passe a ser escolhido como raiz física apenas por seu tamanho. Se a raiz mudar, o modo restaura e bloqueia aquela peça; peças já ancoradas ou que já são a raiz não são expandidas. Não escreve posição, velocidade, Anchored ou juntas. A Hitbox original permanece intacta.

Massa e prioridade originais também são restauradas ao desligar, trocar de alvo, morrer ou encerrar. O teste de regressão modela a troca de raiz por tamanho e a restauração; ele não confirma movimento/replicação dentro do Painhood. A causa do congelamento relatado é uma hipótese consistente com as [regras de assemblies do Roblox](https://create.roblox.com/docs/physics/assemblies), ainda dependente de confirmação em jogo.

## Hitbox (Painhood) — 4.2

Nova aba independente da **Hitbox** original. A função original de expansão do HumanoidRootPart permanece intacta. As abas têm nomes completos e o conteúdo permanece em áreas de rolagem independentes.

- Ative **Ativar Painhood** no jogo informado pelo usuário: place `138308349761110`, universo `10770257767`.
- O padrão **Tronco (R6/R15)** redimensiona UpperTorso ou Torso existentes. **Peça** alterna entre cabeça e peças reais encontradas nos personagens; **Atualizar lista de peças** refaz essa leitura. Uma peça listada não é necessariamente usada pelo servidor para registrar acertos.
- Tamanho numérico próprio, invisibilidade própria e Knock Check próprio. A seleção de jogadores é compartilhada, mas os dois modos têm controles e restauração separados.
- Não cria uma caixa fictícia. Nunca altera HumanoidRootPart por esta aba; também exclui ferramentas e acessórios. As duas hitboxes podem ficar ligadas sem disputar a mesma peça.
- Restaura tamanho, transparência e colisão ao desativar, trocar de peça, desmarcar jogador, morrer, ficar K.O., trocar de personagem ou encerrar.
- Após detectar três reversões do tamanho, interrompe as tentativas naquela peça e mostra o bloqueio no status. Desligar e ligar permite uma tentativa explícita. Não há promessa de contornar uma validação do servidor.

**Limite importante:** a página pública do jogo não expõe seu código nem identifica a caixa cinza da captura. A implementação é uma alternativa de geometria local para testar, não uma confirmação de expansão da hitbox usada pelo servidor. Se o jogo calcula acertos com dimensões fixas ou no servidor, mudar o tamanho local pode não aumentar a área aceita. Não foi validada dentro de uma partida de Painhood.

Compilação Luau e os testes simulados `tests/regression.py` e `tests/painhood.py` passaram. Cobrem coexistência com o modo original, seleção de peças aninhadas, restauração, reversões, persistência e restrição à experiência informada. O código original de `apply()` foi comparado e preservado integralmente.

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

## Correção 3.2

Corrigida a inicialização interrompida por Enum.Font.Arvo, inexistente no Roblox; o título agora usa GothamBlack. O teste valida fontes estritamente e reproduz a falha da 3.1 antes de confirmar a correção.

Cada aba agora tem um Frame de conteúdo próprio com margem direita de 20 pixels e espaço reservado para a barra vertical. Rolagem horizontal desativada; altura de conteúdo e canvas sincronizadas na lista de jogadores e painéis expansíveis. Compilação e regressões passaram; renderização real ainda requer conferência no Roblox.

## Atualização 3.3

Hitbox agora tem aba própria. Painel e textos clareados, barra vertical próxima da borda com margem e conteúdo protegido. Removido BlurEffect e seus controles. Título EVINI em Bevan, branco com contorno preto, metade acima do painel; arte gerada da fonte Google Fonts com licença em assets/Bevan-OFL.txt. Carregamento opcional via getcustomasset/getsynasset e writefile; sem suporte, permanece texto em Merriweather e o hub continua abrindo.

Mira: transparência do FOV de 0 a 1; alternância opcional entre cabeça e tronco com intervalo de 0,3 a 3 segundos (Air Part prevalece durante salto). Alvo encoberto ou fora da tela pausa o movimento sem apagar a seleção; retoma automaticamente quando visível. Morte/K.O., exclusão, tecla e Esc continuam liberando o alvo. Não troca automaticamente de jogador.

Testes simulados verificam pausa/retomada sem nova tecla, alternância, transparência do FOV, cinco abas, ausência de blur e regressões anteriores. Compilação passou. Fonte/imagem, aparência e comportamento no cliente real ainda precisam de validação no Roblox.

## Revisão visual 3.4

Título Bevan branco espesso com contorno preto, desenhado com 398 retângulos estáticos nativos: não usa getcustomasset, arquivo local nem carregamento remoto. A fonte fina de fallback não é mais exibida. Os retângulos são criados uma vez, sem atualização por frame.

Tema preto fumê, transparência inicial de 0,28 aplicada uma vez ao migrar do tema cinza. As escolhas posteriores de transparência continuam salvas. Abas com borda preta, brilho interno superior e gradiente escuro. Abrir, fechar e trocar de aba não movimentam a interface; somente sons.

Tamanho agora muda a largura e altura da janela, mantendo textos e controles em tamanho legível. Largura mínima 400 e altura mínima 430 pixels lógicos; em telas menores a interface inteira é limitada ao viewport. Campos e interruptores centralizados nas linhas, margem interna comum e barras mais curtas. Cinco abas distribuem-se proporcionalmente.

Compilação e regressões simuladas passaram. A renderização real no Opiumware ainda requer confirmação pelo usuário; não alegamos reprodução exata comprovada no jogo.

## Ajustes 3.5

Aba selecionada mantém fundo mais claro, texto branco e brilho superior. Margem interna da rolagem reduzida de 20 para 9 pixels, preservando espaço próprio para a barra. Janela com proporção base 580 × 610 e medidas inteiras, largura mínima 420; textos e controles não encolhem junto com a janela. Ícones de fechar, minimizar e tamanho desenhados com linhas nativas. Testes simulados cobrem seleção da aba, margens, ícones e regressões anteriores; visual real ainda depende de conferência no Roblox.

## Harmonização 3.6

Título Bevan reduzido de 65% para 42% da largura, com máximo de 260 pixels para evitar corte no topo ao ampliar. Menor espaço entre cabeçalho, abas e conteúdo. Rodapé dividido proporcionalmente para impedir sobreposição entre atalhos e ping em janelas menores. Margem maior entre legendas e seletores. Compilação e regressões simuladas verificadas; renderização real não validada neste ambiente.

## Visual 3.7

Fundo quase preto com transparência padrão 0,16 aplicada uma vez na migração; ajustes posteriores continuam salvos. Interruptores retangulares sem cantos arredondados, peça branca quadrada com borda escura e sombra discreta.

## Aparência 3.8

Verde dos interruptores e caixas selecionadas amostrado do centro do print: RGB (37,71,41), #254729, sem gradiente que altere a cor. Fundo mais transparente por padrão (0,38), aplicado uma vez ao atualizar. Em Ajustes há sliders e campos numéricos independentes para Transparência (0–0,80) e Escurecimento (0 = cinza escuro, 1 = preto). Alterações instantâneas e persistentes; não afetam a transparência do texto.

## Notificação 3.9

Aviso de alvo movido para a região inferior direita, com 28 pixels de margem lateral e 110 pixels acima da base. Avisos de entrada/saída permanecem no alto à esquerda.

## Fundo 4.0

Fundo preto puro com transparência 0,10 (90% opaco). Aplicado uma vez ao atualizar; controles de transparência e escurecimento permanecem editáveis e salvos.

## Áudio 4.1

Incluído trecho de 0,24 s (3,525–3,765 s) da gravação fornecida pelo usuário, próximo à troca de aba. Áudio mono PCM, filtrado levemente e normalizado, sem metadados do vídeo. Não é o asset original identificado, nem teve confirmação auditiva neste ambiente. O vídeo completo não foi publicado.

O hub tenta carregar assets/settings-click-v1.wav por getcustomasset/getsynasset e writefile, mantém velocidade original e respeita mute/volume. Som padrão permanece ativo quando a API ou o carregamento falha; o estado aparece em Ajustes. A aceitação do arquivo pelo Opiumware precisa ser confirmada no cliente.
