# My Neovim Config

Personal config based on kickstart.nvim.

## Requirements

- Neovim 0.11+
- git, make, gcc, ripgrep
- [Nerd Font](https://www.nerdfonts.com/)
- [pixi](https://pixi.prefix.dev/latest/):
  ```sh
  pixi global install stylua black isort clang-format
  ```
- (Optional) [Claude Code](https://code.claude.com/docs/en/setup)

## Install

```sh
git clone git@github.com:tatsukamijo/kickstart.nvim.git ~/.config/nvim
nvim  # auto-setup on first launch
```

## Key Bindings

Leader: `<Space>`

| Key | Action |
|-----|--------|
| `<leader>e` | File explorer |
| `<leader>sf` | Find files |
| `<leader>sg` | Live grep |
| `<leader><leader>` | Open buffers |
| `<leader>st` | Terminal |
| `<leader>sm` | Maximize window |
| `<C-h/j/k/l>` | Navigate splits (tmux-aware) |
| `gd` / `gr` | Definition / references |
| `<leader>f` | Format |
| `<leader>ca` | Code action |
| `<leader>ac` | Claude Code |
| `<leader>ar` | Resume Claude (from history) |

## Structure

```
init.lua                 # main config
lua/
  kickstart/plugins/     # kickstart plugins
  custom/plugins/        # custom plugins (auto-loaded)
```

## LSP

pyright, clangd, ts_ls, lua_ls (auto-installed via Mason)
