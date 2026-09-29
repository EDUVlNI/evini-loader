# EVINI 1.1

Hub independente em Lua, com fundo grafite, detalhes verde-claro e controles compactos. Nao carrega o Nitrogen nem reproduz todas as suas funcoes desconhecidas.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

## Controles

- **L** oculta e mostra o hub. Clique na tecla no rodape e pressione outra para trocar. Esc cancela; a captura expira em 8 segundos. A escolha vale para a instancia atual.
- Nao ha botao flutuante no canto da tela. Use a tecla escolhida para reabrir.
- **Ativar hitbox** inicia desligado. Expande localmente o HumanoidRootPart dos outros jogadores vivos.
- **Box invisivel** controla a transparencia total. Desligado: box verde com transparencia de 65%.
- **Ignorar equipe** exclui jogadores do mesmo time nao neutro.
- **Tamanho** usa apenas campo numerico, de 2 a 30 studs. Pressione Enter ou clique fora para aplicar. Aceita ponto ou virgula decimal; entrada invalida mantem o ultimo tamanho.
- Arraste o cabecalho para mover. **−** oculta; **×** encerra e restaura as partes alteradas.

## Abertura

Emblema do grupo Roblox **8440749 (# DEATH)**, usando `rbxthumb` nativo. Apenas a imagem com uma animacao curta, sem cartao, cachorro, blur ou arquivos locais. Se a imagem nao carregar, o hub abre sem a animacao.

## Verificacao e limites

Sintaxe e logica verificadas com APIs simuladas: ativacao, transparencia, tamanho, equipe, respawn, restauracao, ocultar/mostrar e troca de tecla. Aparencia e carregamento real da imagem ainda precisam ser conferidos no Roblox.

A expansao e local: jogos com validacao no servidor, raycasts proprios ou personagens personalizados podem ignorar a alteracao. Reexecutar encerra a instancia EVINI anterior; se o antigo Nitrogen ainda estiver ativo, entre novamente no jogo primeiro.
