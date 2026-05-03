-- claudecode.nvim
-- https://github.com/coder/claudecode.nvim

local toggle_key = '<C-,>'

-- Helper: Auto-focus Claude Code after command execution
local function focus_claude_after(cmd, delay)
  delay = delay or 100
  return function()
    if vim.bo.buftype == 'terminal' then
      vim.notify('Cannot execute from terminal buffer', vim.log.levels.WARN)
      return
    end
    vim.cmd(cmd)
    vim.defer_fn(function()
      vim.cmd 'ClaudeCodeFocus'
    end, delay)
  end
end

-- Helper: Check if current buffer is Claude Code terminal
local function is_in_claude_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  return bufname:match ':claude' ~= nil or bufname:match '/happy$' ~= nil
end

-- Helper: Resolve terminal command, preferring happy over claude
local function resolve_terminal_cmd()
  local happy = vim.fn.expand '~/.pixi/envs/nodejs/bin/happy'
  if vim.fn.executable(happy) == 1 then
    return happy
  end
  if vim.fn.executable 'happy' == 1 then
    return 'happy'
  end
  return 'claude'
end

-- ===== Multi-agent (per-tab Claude terminal) =====
-- Each tab can host its own `claude` CLI in a right split. All Claudes connect
-- to the same nvim's MCP server (one-server-per-nvim is fine: @mention/diff
-- target the same editor; conversations are independent per CLI process).

local function get_tab_claude_buf(tabid)
  tabid = tabid or 0
  local ok, buf = pcall(vim.api.nvim_tabpage_get_var, tabid, 'claude_buf')
  if ok and buf and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end
  return nil
end

local function find_claude_window_in_tab(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

local function open_claude_split(buf)
  vim.cmd 'botright vsplit'
  vim.cmd('vertical resize ' .. math.floor(vim.o.columns * 0.30))
  if buf then
    vim.api.nvim_win_set_buf(0, buf)
  end
  vim.wo.winfixwidth = true
end

local function spawn_claude_in_current_tab(extra_args, label)
  local cmd = resolve_terminal_cmd()
  local args = extra_args and (' ' .. extra_args) or ''
  open_claude_split(nil)
  vim.cmd('terminal ' .. cmd .. args)
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].is_claude_terminal = true
  vim.wo.winfixwidth = true
  vim.t.claude_buf = buf
  if label and label ~= '' then
    vim.t.claude_label = label
  else
    vim.t.claude_label = 'agent' .. vim.api.nvim_get_current_tabpage()
  end
  vim.cmd 'startinsert'
end

-- Pick a regular file buffer for the new tab's editor pane,
-- avoiding terminal buffers (like the Claude pane we may be in right now).
local function pick_editor_buffer()
  local alt = vim.fn.bufnr '#'
  if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buftype == '' and vim.fn.buflisted(alt) == 1 then
    return alt
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 and vim.bo[buf].buftype == '' then
      return buf
    end
  end
  return nil
end

local function new_agent_tab(extra_args)
  local editor_buf = pick_editor_buffer()
  vim.cmd 'tabnew' -- empty new tab; we control what shows in the left pane
  if editor_buf then
    vim.api.nvim_win_set_buf(0, editor_buf)
  end
  vim.ui.input({ prompt = 'Agent label: ' }, function(input)
    spawn_claude_in_current_tab(extra_args, input)
  end)
end

local function rename_current_label()
  vim.ui.input({
    prompt = 'Agent label: ',
    default = vim.t.claude_label or '',
  }, function(input)
    if input and input ~= '' then
      vim.t.claude_label = input
      vim.cmd 'redrawtabline'
    end
  end)
end

local function close_agent_tab()
  if vim.fn.tabpagenr '$' == 1 then
    vim.notify('Cannot close last tab', vim.log.levels.WARN)
    return
  end
  local buf = get_tab_claude_buf()
  if buf then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  vim.cmd 'tabclose'
end

local function smart_toggle()
  local buf = get_tab_claude_buf()
  if not buf then
    vim.cmd 'ClaudeCodeFocus' -- fallback: claudecode.nvim main terminal
    return
  end
  local win = find_claude_window_in_tab(buf)
  if win then
    vim.api.nvim_win_close(win, false)
  else
    open_claude_split(buf)
    vim.cmd 'startinsert'
  end
end

-- Route <leader>ac / <leader>ar to the current tab's agent if one exists.
-- Otherwise fall back to the claudecode.nvim singleton (main tab behavior).
local function tab_aware_open(fallback_cmd)
  return function()
    if get_tab_claude_buf() then
      smart_toggle()
    else
      vim.cmd(fallback_cmd)
    end
  end
end

-- Custom tabline: show "N:label" per tab
function _G.ClaudeAgentTabline()
  local s = ''
  local current = vim.api.nvim_get_current_tabpage()
  for i, tabid in ipairs(vim.api.nvim_list_tabpages()) do
    local hl = (tabid == current) and '%#TabLineSel#' or '%#TabLine#'
    local ok, label = pcall(vim.api.nvim_tabpage_get_var, tabid, 'claude_label')
    if not ok or not label or label == '' then
      label = 'tab' .. i
    end
    s = s .. hl .. '%' .. i .. 'T ' .. i .. ':' .. label .. ' '
  end
  s = s .. '%#TabLineFill#%T'
  return s
end
vim.o.tabline = '%!v:lua.ClaudeAgentTabline()'

-- Helper: Send selection to Claude (handles both normal and terminal buffers)
local function send_selection_to_claude()
  local buftype = vim.bo.buftype
  local from_claude = is_in_claude_buffer()

  if buftype == 'terminal' then
    vim.cmd 'normal! y'
    local yanked = vim.fn.getreg '"'

    if yanked == '' then
      vim.notify('Selection is empty', vim.log.levels.WARN)
      return
    end

    local tmpfile = string.format('%s_claude_%d', vim.fn.tempname(), vim.loop.hrtime())
    vim.fn.writefile(vim.split(yanked, '\n'), tmpfile)

    vim.cmd('ClaudeCodeAdd ' .. tmpfile)
    vim.defer_fn(function()
      if not from_claude then
        vim.cmd 'ClaudeCodeFocus'
      end
      vim.fn.delete(tmpfile)
    end, 500)
  else
    vim.cmd 'ClaudeCodeSend'
    vim.defer_fn(function()
      if not from_claude then
        vim.cmd 'ClaudeCodeFocus'
      end
    end, 100)
  end
end

return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    terminal_cmd = resolve_terminal_cmd(),
    terminal = {
      split_side = 'right',
      split_width_percentage = 0.30,
      snacks_win_opts = {
        keys = {
          claude_hide = {
            toggle_key,
            function(self)
              self:hide()
            end,
            mode = 't',
            desc = 'Hide Claude',
          },
          nav_left = {
            '<C-h>',
            function()
              vim.cmd 'TmuxNavigateLeft'
            end,
            mode = 't',
            desc = 'Navigate left',
          },
          nav_right = {
            '<C-l>',
            function()
              vim.cmd 'TmuxNavigateRight'
            end,
            mode = 't',
            desc = 'Navigate right',
          },
          nav_up = {
            '<C-k>',
            function()
              vim.cmd 'TmuxNavigateUp'
            end,
            mode = 't',
            desc = 'Navigate up',
          },
          nav_down = {
            '<C-j>',
            function()
              vim.cmd 'TmuxNavigateDown'
            end,
            mode = 't',
            desc = 'Navigate down',
          },
        },
      },
    },
  },
  keys = {
    { toggle_key, smart_toggle, desc = 'Toggle Claude (tab-aware)', mode = { 'n', 'x' } },
    { '<leader>a', nil, desc = 'AI/Claude Code' },
    { '<leader>ac', tab_aware_open 'ClaudeCode --enable-auto-mode', desc = 'Toggle Claude (tab-aware)' },
    { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>ar', tab_aware_open 'ClaudeCode --resume --enable-auto-mode', desc = 'Resume Claude (tab-aware)' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>ab', focus_claude_after 'ClaudeCodeAdd %', desc = 'Add current buffer' },
    { '<leader>as', send_selection_to_claude, mode = 'v', desc = 'Send to Claude' },
    -- Multi-agent (per-tab)
    {
      '<leader>aN',
      function()
        new_agent_tab '--enable-auto-mode'
      end,
      desc = '[N]ew agent tab',
    },
    {
      '<leader>aR',
      function()
        new_agent_tab '--resume --enable-auto-mode'
      end,
      desc = '[R]esume in new agent tab',
    },
    { '<leader>aL', rename_current_label, desc = '[L]abel current agent tab' },
    { '<leader>aX', close_agent_tab, desc = 'Close agent tab' },
    {
      '<leader>as',
      function()
        vim.cmd 'ClaudeCodeTreeAdd'
        vim.defer_fn(function()
          vim.cmd 'ClaudeCodeFocus'
        end, 100)
      end,
      desc = 'Add file',
      ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
    },
    { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
    { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
  },
}
