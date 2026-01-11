# tatsukamijo.nvim
Neovim config based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).


<img width="1728" height="1117" alt="Screenshot 2026-01-09 at 15 53 18" src="https://github.com/user-attachments/assets/a816c456-e1ac-42b3-bdf2-8ee80aee9f2d" />


## Install

Requires [Nerd Font](https://www.nerdfonts.com/).
(Optional) [Claude Code](https://code.claude.com/docs/en/setup)

```sh
# Neovim 0.11+, git, make, gcc, ripgrep
# xclip: for large clipboard over SSH (Linux only, not needed on macOS)
pixi global install nvim stylua black isort clang-format xclip

# Clone
git clone git@github.com:tatsukamijo/tatsukamijo.nvim.git ~/.config/nvim
nvim  # auto-setup on first launch
```

## Core Settings

- **Leader key**: Space (`<space>`)
- **Line numbers**: Absolute + relative
- **Clipboard**: OSC 52 (works over SSH/tmux)
- **Folding**: Indent-based
- **Colorscheme**: gruvbox-material (medium background)

## Basic Key Bindings

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |
| `<leader>sf` | Find files |
| `<leader>sF` | Find files (hidden + ignored) |
| `<leader>sg` | Live grep |
| `<leader><leader>` | Open buffers |
| `<leader>s.` | Recent files |
| `<leader>/` | Fuzzy search in current buffer |
| `<C-h/j/k/l>` | Navigate splits (tmux-aware) |
| `gd` / `gr` | Go to definition / references |
| `gI` / `gD` | Go to implementation / declaration |
| `<C-o>` / `<C-n>` | Jump back / forward |
| `<leader>f` | Format buffer |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>D` | Type definition |
| `<leader>ds` | Document symbols |
| `<leader>ws` | Workspace symbols |

## Terminal & Window Management

| Key | Action |
|-----|--------|
| `<leader>st` | Toggle bottom terminal |
| `<leader>sv` | Vertical terminal split |
| `<leader>sm` | Maximize/restore window |
| `<leader>sM` | Maximize all terminals |
| `<Esc><Esc>` | Exit terminal mode |
| `jk` | Exit insert/terminal mode |
| `<C-s>` | Save file |
| `<leader>Q` | Save all and quit |
| `<leader>bb` | Switch to previous buffer |
| `<leader>bd` | Delete buffer |

## Folding

| Key | Action |
|-----|--------|
| `<Tab>` | Open fold |
| `<S-Tab>` | Close fold |
| `<leader><Tab>` | Open all folds |
| `<leader><S-Tab>` | Close all folds |

## Visual Mode

| Key | Action |
|-----|--------|
| `J` / `K` | Move selected lines down/up |
| `<` / `>` | Indent and stay in visual mode |
| `<leader>p` | Paste without yanking |

## Claude Code Integration

| Key | Action |
|-----|--------|
| `<C-,>` | Toggle Claude Code |
| `<leader>ac` | Toggle Claude |
| `<leader>af` | Focus Claude |
| `<leader>ar` | Resume Claude (from history) |
| `<leader>aC` | Continue Claude |
| `<leader>am` | Select Claude model |
| `<leader>ab` | Add current buffer |
| `<leader>as` | Send selection to Claude (visual) |
| `<leader>aa` | Accept diff |
| `<leader>ad` | Deny diff |

## NeoCodeium (Auto Completion)
`:NeoCodeium auth` to authenticate.

| Key | Action |
|-----|--------|
| `Tab` | Accept suggestion |
| `Alt+w` | Accept word |
| `Alt+.` | Accept line |
| `Alt+n` | Next suggestion |
| `Alt+p` | Prev suggestion |
| `Alt+/` | Clear suggestion |

## Session Management (persistence.nvim)

Sessions auto-restore when opening Neovim without file arguments.

| Key | Action |
|-----|--------|
| `<leader>qs` | Restore session (cwd) |
| `<leader>ql` | Restore last session |
| `<leader>qd` | Don't save current session |
| `<leader>qD` | Delete session file (cwd) |

## LSP & Formatters

### Language Servers (auto-installed via Mason)

| Language | Server |
|----------|--------|
| Python | pyright |
| C/C++ | clangd |
| TypeScript/JS | ts_ls |
| Lua | lua_ls |

### Formatters

| Language | Formatter | Install Method |
|----------|-----------|----------------|
| Lua | stylua | pixi |
| Python | black, isort | pixi |
| C/C++ | clang-format | pixi |
| JS/TS/JSON/HTML/CSS | prettier | Mason |

## Plugins

| Plugin | Description |
|--------|-------------|
| [telescope](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Git signs & hunk actions |
| [which-key](https://github.com/folke/which-key.nvim) | Keymap hints (0 delay) |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion |
| [treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |
| [conform](https://github.com/stevearc/conform.nvim) | Auto-formatter |
| [persistence](https://github.com/folke/persistence.nvim) | Session management |
| [claudecode](https://github.com/coder/claudecode.nvim) | Claude Code integration |
| [neocodeium](https://github.com/monkoose/neocodeium) | AI code completion |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Tmux-aware navigation |
| [markdown-preview](https://github.com/iamcco/markdown-preview.nvim) | Markdown preview in browser |
| [mini.nvim](https://github.com/echasnovski/mini.nvim) | Statusline, text objects |
| [autopairs](https://github.com/windwp/nvim-autopairs) | Auto close brackets |
| [todo-comments](https://github.com/folke/todo-comments.nvim) | Highlight TODO/NOTE in comments |
| [lazydev](https://github.com/folke/lazydev.nvim) | Lua LSP for Neovim config |
| [fidget](https://github.com/j-hui/fidget.nvim) | LSP progress indicator |

## Structure

```
init.lua                 # main config
lua/
  kickstart/plugins/     # kickstart plugins
  custom/plugins/        # custom plugins (auto-loaded)
```
