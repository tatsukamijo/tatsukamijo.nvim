# tatsukamijo.nvim

Personal Neovim config based on kickstart.nvim.

## Install

Requires [Nerd Font](https://www.nerdfonts.com/).  
(Optional) [Claude Code](https://code.claude.com/docs/en/setup)

```sh
# Neovim 0.11+, git, make, gcc, ripgrep
pixi global install nvim stylua black isort clang-format

# Clone
git clone git@github.com:tatsukamijo/tatsukamijo.nvim.git ~/.config/nvim
nvim  # auto-setup on first launch
```

## Basic Key Bindings

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

## NeoCodeium (AI Completion)

| Key | Action |
|-----|--------|
| `Alt+;` | Accept suggestion |
| `Alt+w` | Accept word |
| `Alt+.` | Accept line |
| `Alt+n` | Next suggestion |
| `Alt+p` | Prev suggestion |
| `Alt+/` | Clear |

## Structure

```
init.lua                 # main config
lua/
  kickstart/plugins/     # kickstart plugins
  custom/plugins/        # custom plugins (auto-loaded)
```

## LSP

pyright, clangd, ts_ls, lua_ls (auto-installed via Mason)
