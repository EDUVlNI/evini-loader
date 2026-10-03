# Revisão EVINI 3.3

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
