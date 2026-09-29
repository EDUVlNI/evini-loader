# EVINI

Hub independente, de codigo-fonte aberto e legivel, com tema verde-claro. Esta versao substitui o antigo loader e **nao baixa nem executa o Nitrogen**. Como o original usa MoonSec V3, nao e uma recuperacao do seu fonte nem uma replica de todas as suas funcoes.

## Executar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

Se o antigo Nitrogen ja estiver aberto, entre novamente no jogo antes de executar. O EVINI nao remove conexoes nem alteracoes feitas pelo script antigo.

## Controles

- **L** mostra/oculta o hub, exceto ao digitar em uma caixa de texto.
- **EVINI** na lateral tambem mostra/oculta o hub.
- **Hitbox expander** inicia desligado; altera localmente o HumanoidRootPart dos outros jogadores vivos.
- **Tamanho** por slider ou campo numerico, de 2 a 30 studs. Padrao: 8.
- **Box totalmente transparente** torna a parte alterada invisivel. Desligado: verde com transparencia de 65%.
- **Ignorar meu time** permite excluir jogadores do mesmo time nao neutro.
- Arraste pelo cabecalho para mover o hub.
- **–** oculta. **×** encerra, desconecta eventos e restaura as propriedades salvas.
- Reexecutar o EVINI encerra a instancia EVINI anterior antes de criar outra.

## Abertura

Foto do cachorro fornecida pelo usuario, sem blur, com animacao de escala tipo pop. A foto precisa de `getcustomasset` (ou `getsynasset`) e `writefile`. E baixada do repositorio e salva como `evini-dog-v1.jpg` no armazenamento do executor. Sem esses recursos, ou se a imagem falhar, aparece um icone de cachorro. O carregamento da foto tem espera inicial limitada a 3 segundos; nao impede o hub de abrir.

## Limites e verificacao

Requer ambiente cliente com `game:HttpGet` e `loadstring` para a linha acima. A expansao e local: jogos com validacao no servidor, raycasts proprios ou personagens personalizados podem ignorar a alteracao. Nao altera a logica de dano no servidor.

O fonte tem verificacao de sintaxe e testes com simulacao das APIs. Isso nao substitui teste real no Roblox: interface, executor, imagem e efeito nos acertos ainda precisam de verificacao no jogo.
