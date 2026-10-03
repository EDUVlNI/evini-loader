# Revisão EVINI 4.1

- Interface reorganizada em Mira, Visual, Jogadores e Ajustes; estilo inspirado nas capturas fornecidas, sem copiar imagens do jogo.
- Filtro por nick único substituído por caixas de seleção persistentes por UserId, busca e seleção em lote. Restauração imediata ao desmarcar; validação do alvo também durante cam lock.
- Eventos reais PlayerAdded/PlayerRemoving alimentam avisos superiores à esquerda e a lista. Sem notificar o elenco inicial; fila limitada e limpeza no encerramento.
- ESP convertido a BillboardGui com cache e elegibilidade em frequência reduzida. Etiquetas não são recriadas em cada K.O./recuperação. Remoção de personagens libera recursos.
- Aim Viewer convertido a Beam e ponto vermelho. Não depende de Tool para ler MousePos replicado; estimativa opcional da orientação da cabeça quando sem arma, sempre identificada. Não recupera mira que não foi replicada.
- Sem alterações em remotes e sem reintroduzir silent.

## Evidência e limites

Luau compila. A suíte simulada cobre controles anteriores e cenários novos: exclusão restaura hitbox/solta câmera, busca mantém seleção, seleção por UserId sobrevive a arquivo, padrão de novas entradas, desconexão de linhas removidas, quatro avisos no máximo, expiração, efeitos sem arma, cor vermelha, alternância de visibilidade e ausência de novas alocações durante atualizações estáveis.

Não foi feito teste visual, de FPS ou de acertos em sessão real do Da Hood. O código reduz trabalho manual do ESP, mas não é evidência de ganho medido no dispositivo do usuário.

## Interface 3.1

Substituídos quatro CanvasGroups por um CanvasGroup único; cabeçalho, abas, conteúdo e rodapé são regiões transparentes de um mesmo painel. A silhueta recorta a metade inferior do topo arredondado e continua em base reta, sem sobrepor preenchimentos translúcidos.

Adicionados controles de escala no topo, slider com aplicação imediata, limite pelo viewport, porcentagem efetiva e reset. Som compartilhado com mute/volume. Testes cobrem reduzir/aumentar/restaurar escala, áudio ativado/desativado, inversão de animação e encerramento, além das regressões anteriores. Sem confirmação visual ou auditiva no jogo.

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
