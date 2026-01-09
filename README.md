# tatsukamijo.nvim
<img width="1728" height="1117" alt="Screenshot 2026-01-09 at 15 53 18" src="https://github.com/user-attachments/assets/a816c456-e1ac-42b3-bdf2-8ee80aee9f2d" />

Neovim config based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).

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
| `<C-o>` / `<C-n>` | Jump back / forward |
| `<leader>f` | Format |
| `<leader>ac` | Claude Code |
| `<leader>ar` | Resume Claude (from history) |

## NeoCodeium (Auto Completion)

| Key | Action |
|-----|--------|
| `Tab` | Accept suggestion |
| `Alt+w` | Accept word |
| `Alt+.` | Accept line |
| `Alt+n` | Next suggestion |
| `Alt+p` | Prev suggestion |
| `Alt+/` | Clear |

## Plugins

| Plugin | Description |
|--------|-------------|
| telescope | Fuzzy finder |
| neo-tree | File explorer |
| gitsigns | Git signs & hunk actions |
| which-key | Keymap hints |
| nvim-cmp | Autocompletion |
| treesitter | Syntax highlighting |
| conform | Formatter |
| persistence | Session management |
| claudecode | Claude Code integration |
| neocodeium | AI code completion |
| vim-tmux-navigator | Tmux-aware navigation |
| markdown-preview | Markdown preview in browser |
| mini.nvim | Statusline, text objects |
| autopairs | Auto close brackets |

## LSP

pyright, clangd, ts_ls, lua_ls (auto-installed via Mason)

## Structure

```
init.lua                 # main config
lua/
  kickstart/plugins/     # kickstart plugins
  custom/plugins/        # custom plugins (auto-loaded)
```
