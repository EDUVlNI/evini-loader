# EVINI 1.3

Hub independente em Lua, com fundo quase preto, verde classico, campos retangulares, bordas finas e fonte pixelada Arcade, inspirado na referencia visual fornecida. Nao carrega o Nitrogen nem reproduz todas as suas funcoes desconhecidas.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

## Controles

- **L** oculta e mostra o hub. Clique na tecla no rodape e pressione outra para trocar. Esc cancela; a captura expira em 8 segundos. A escolha vale para a instancia atual.
- Nao ha botao flutuante no canto da tela. Use a tecla escolhida para reabrir.
- **Ativar hitbox** inicia desligado. Expande localmente o HumanoidRootPart dos outros jogadores vivos.
- **Knock Check** inicia ligado: exclui personagens com `BodyEffects["K.O"]` verdadeiro, mesmo com vida positiva. Restaura as propriedades originais em vez de deixar a box expandida no chao. Ao se recuperar, o jogador volta a seguir o filtro selecionado.
- Vida zero, estado `HumanoidStateType.Dead` ou marcador booleano `BodyEffects.Dead` sempre removem a expansao, inclusive com Knock Check desligado. A verificacao roda a cada aproximadamente 0,05 segundo, dependendo dos frames.
- **Box invisivel** controla a transparencia total. Desligado: box verde com transparencia de 65%.
- **Todos** expande os outros jogadores normalmente.
- **Ignorar nick** mantem a pessoa digitada com a hitbox original e expande os demais.
- **So este nick** expande apenas a pessoa digitada; os demais voltam ao tamanho original.
- Digite o @usuario exato ou um nome de exibicao unico e confirme com Enter ou clicando fora. A busca ignora maiusculas e minusculas, prioriza o usuario exato e mostra a selecao confirmada. Nomes de exibicao repetidos exigem @usuario.
- Em **So este nick**, campo vazio ou jogador ausente significa nenhuma expansao. Em **Ignorar nick**, sem correspondencia, os demais continuam expandidos. O painel informa quando nao encontra o jogador.
- Os filtros valem para o servidor atual, continuam sendo aplicados depois do respawn e nao dependem de equipes.
- **Tamanho** usa apenas campo numerico, de 2 a 30 studs. Pressione Enter ou clique fora para aplicar. Aceita ponto ou virgula decimal; entrada invalida mantem o ultimo tamanho.
- Arraste o cabecalho para mover. **−** oculta; **×** encerra e restaura as partes alteradas.

## Abertura

Emblema do grupo Roblox **8440749 (# DEATH)**, usando `rbxthumb` nativo. Apenas a imagem com uma animacao curta, sem cartao, cachorro, blur ou arquivos locais. Se a imagem nao carregar, o hub abre sem a animacao.

## Verificacao e limites

Sintaxe e logica verificadas com APIs simuladas: ativacao, transparencia, tamanho, exclusao por nick, alvo unico, nomes ambiguos, K.O com vida positiva, recuperacao, marcadores de morte, respawn, restauracao, ocultar/mostrar e troca de tecla. Aparencia e carregamento real da imagem ainda precisam ser conferidos no Roblox.

A expansao e local: jogos com validacao no servidor, raycasts proprios ou personagens personalizados podem ignorar a alteracao. Reexecutar encerra a instancia EVINI anterior; se o antigo Nitrogen ainda estiver ativo, entre novamente no jogo primeiro.

Os marcadores especificos de Da Hood ainda precisam de confirmacao na sessao real do jogo. O script restaura a parte original; nao remove o corpo do personagem.
