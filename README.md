# EVINI Loader

Loader chamado EVINI que baixa e executa o Nitrogen Hitbox Expander original. **Nao e uma versao modificada do hub.**

## Limites

O arquivo consultado em 29/09/2026 esta protegido com MoonSec V3. Nao foi possivel alterar internamente de forma confiavel:

- o branding visivel do hub;
- o atalho de Insert para L;
- a transparencia do cubo/hitbox.

EVINI aparece no nome deste repositorio, no loader e nas mensagens de carregamento/erro. O original permanece intacto e nao foi republicado neste repositorio.

## Executar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/EDUVlNI/evini-loader/main/main.lua", true))()
```

Requer um ambiente que disponibilize `game:HttpGet` e `loadstring`. Nao foi testado dentro do Roblox; a ofuscacao impede confirmar o comportamento interno do original.

## Origem

[Nitrogen Hitbox Expander](https://github.com/nitrogenhbexp/nitrogen-hitbox-expander), commit `d44c0a5665baa885f1d93d4349b3bc4da7b2f090`.

O loader fixa esse commit para evitar mudancas automaticas no arquivo carregado. Depende da disponibilidade do arquivo original no GitHub.
