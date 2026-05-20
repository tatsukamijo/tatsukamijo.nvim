-- claudecode.nvim
-- https://github.com/coder/claudecode.nvim

local toggle_key = '<C-,>'

-- Helper: Check if current buffer is Claude Code terminal
local function is_in_claude_buffer()
  local bufname = vim.api.nvim_buf_get_name(0)
  return bufname:match ':claude' ~= nil or bufname:match '/happy$' ~= nil
end

-- Helper: Resolve the base terminal command.
-- happy is intentionally NOT used: its backend api.cluster-fluster.com is
-- SSL-intercepted by the campus FortiGate, whose CA is not trusted by Node,
-- so happy fails with "unable to verify the first certificate". Plain claude
-- talks to api.anthropic.com, which the FortiGate does not intercept.
-- To re-enable happy later, install the FortiGate CA and set NODE_EXTRA_CA_CERTS.
local function resolve_terminal_cmd()
  return 'claude'
end

-- Build a Remote Control session name so each nvim-launched Claude is
-- distinguishable in the Claude app / claude.ai. Shape "<project>-<label>",
-- e.g. "slidev-refactor" or "slidev-agent3"; sanitized to [%w-_].
-- Note: the name is fixed at process launch -- <leader>aL renaming a tab
-- afterwards updates only the nvim tabline, not the live RC session name.
local function rc_session_name(label)
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  local name = (label and label ~= '') and (project .. '-' .. label) or project
  return (name:gsub('[^%w%-_]', '_'))
end

-- Append `--remote-control <name>` so the session launches with Remote Control
-- already on (reachable from phone/web, no manual /remote-control) under an
-- explicit, app-visible name. Explicit name => position among other flags
-- does not matter; the value token never starts with "-".
local function with_remote_control(cmd, label)
  return cmd .. ' --remote-control ' .. rc_session_name(label)
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

-- MCP env vars expected by the Claude CLI to find claudecode.nvim's WebSocket
-- server. Without these, a `:terminal happy` Claude does not connect, so
-- ClaudeCodeSend (which broadcasts to all connected clients) skips it and the
-- @mention only lands in whichever Claude was started by claudecode.nvim itself.
local function get_mcp_env()
  local env = {
    ENABLE_IDE_INTEGRATION = 'true',
    FORCE_CODE_TERMINAL = 'true',
  }
  local ok, claudecode = pcall(require, 'claudecode')
  if ok and claudecode.state and claudecode.state.port then
    env.CLAUDE_CODE_SSE_PORT = tostring(claudecode.state.port)
  end
  return env
end

local function spawn_claude_in_current_tab(extra_args, label)
  local cmd = resolve_terminal_cmd()
  local args = extra_args and (' ' .. extra_args) or ''
  open_claude_split(nil)
  -- jobstart{term=true} needs an empty current buffer to attach the terminal.
  vim.cmd 'enew'
  -- Resolve the label before launch so it can name the Remote Control session.
  -- Falls back to "agent<tabpage>" when spawned without an explicit label
  -- (smart_toggle / tab_aware_open).
  local effective_label = (label and label ~= '') and label or ('agent' .. vim.api.nvim_get_current_tabpage())
  vim.fn.jobstart(with_remote_control(cmd .. args, effective_label), { term = true, env = get_mcp_env() })
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].is_claude_terminal = true
  vim.wo.winfixwidth = true
  vim.t.claude_buf = buf
  vim.t.claude_label = effective_label
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
    -- No per-tab agent in this tab → spawn one. Previously fell back to the
    -- claudecode.nvim singleton, whose buffer is shared across tabs.
    spawn_claude_in_current_tab '--enable-auto-mode'
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
-- If none, spawn a new per-tab agent with the requested CLI args (do NOT
-- fall back to the singleton — it shares one buffer across all tabs and
-- makes `gt` + `<leader>ar` show the same session everywhere).
local function tab_aware_open(extra_args)
  return function()
    if get_tab_claude_buf() then
      smart_toggle()
    else
      spawn_claude_in_current_tab(extra_args)
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

-- Focus this tab's per-tab Claude window (re-opening the split if hidden)
-- and enter terminal-job mode so the user can type immediately.
local function focus_tab_claude(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win = find_claude_window_in_tab(buf)
  if not win then
    open_claude_split(buf)
    win = find_claude_window_in_tab(buf)
  end
  if not win then
    return
  end
  vim.api.nvim_set_current_win(win)
  -- Force nvim to flush its terminal-cell renderer so any bytes happy/Claude
  -- emitted in response to a recent chan_send are reflected. Without this,
  -- the input box can render 1-2 lines off when chan_send + focus happen
  -- back-to-back (happy's TUI mid-frame at the moment nvim took its draw).
  vim.cmd 'redraw!'
  -- Defer startinsert one more tick: a bare `:startinsert` right after
  -- nvim_set_current_win is sometimes ignored when the call originated from a
  -- visual-mode mapping (mode transition still settling). Re-checking that we
  -- are still in this window guards against a fast user switching away.
  vim.schedule(function()
    if vim.api.nvim_get_current_win() == win and vim.bo[buf].buftype == 'terminal' then
      vim.cmd 'startinsert'
    end
  end)
end

-- Add current buffer as @mention. Like send_selection_to_claude, route via
-- the per-tab job's channel so the @mention lands only in this tab's Claude
-- (ClaudeCodeAdd broadcasts over WebSocket to all connected clients).
local function add_buffer_to_claude()
  if vim.bo.buftype == 'terminal' then
    vim.notify('Cannot execute from terminal buffer', vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand '%:.'
  if file == '' then
    vim.notify('Buffer has no file path', vim.log.levels.WARN)
    return
  end
  local from_claude = is_in_claude_buffer()
  local tab_buf = get_tab_claude_buf()
  local job_id = tab_buf and vim.b[tab_buf].terminal_job_id or nil

  if job_id then
    vim.api.nvim_chan_send(job_id, '@' .. file .. ' ')
    if not from_claude then
      vim.schedule(function()
        focus_tab_claude(tab_buf)
      end)
    end
  else
    vim.cmd 'ClaudeCodeAdd %'
    if not from_claude then
      vim.defer_fn(function()
        vim.cmd 'ClaudeCodeFocus'
      end, 100)
    end
  end
end

-- Send selection to Claude. If a per-tab agent exists, route there directly
-- (bypassing claudecode.nvim's broadcast which fans out to ALL connected
-- Claudes). Otherwise fall back to the plugin's commands.
local function send_selection_to_claude()
  local buftype = vim.bo.buftype
  local from_claude = is_in_claude_buffer()
  local tab_buf = get_tab_claude_buf()
  local job_id = tab_buf and vim.b[tab_buf].terminal_job_id or nil

  if buftype == 'terminal' then
    vim.cmd 'normal! y'
    local yanked = vim.fn.getreg '"'
    if yanked == '' then
      vim.notify('Selection is empty', vim.log.levels.WARN)
      return
    end

    -- Leave visual mode synchronously before we focus the Claude window.
    -- Mode is global in nvim, so without this the Claude terminal inherits
    -- visual-line mode and shows a gray highlight on a line.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)

    local tmpfile = string.format('%s_claude_%d', vim.fn.tempname(), vim.loop.hrtime())
    vim.fn.writefile(vim.split(yanked, '\n'), tmpfile)

    if job_id then
      vim.api.nvim_chan_send(job_id, '@' .. tmpfile .. ' ')
      if not from_claude then
        -- Small delay so happy's TUI finishes redrawing its input box with
        -- the new @mention / pasted text before we focus + startinsert.
        -- Synchronous focus on a half-rendered TUI causes 1-2 line offset.
        vim.defer_fn(function()
          focus_tab_claude(tab_buf)
        end, 30)
      end
      -- Delay the tmpfile cleanup so Claude has time to read it via @mention.
      vim.defer_fn(function()
        vim.fn.delete(tmpfile)
      end, 1500)
    else
      vim.cmd('ClaudeCodeAdd ' .. tmpfile)
      vim.defer_fn(function()
        if not from_claude then
          vim.cmd 'ClaudeCodeFocus'
        end
        vim.fn.delete(tmpfile)
      end, 500)
    end
  else
    if job_id then
      -- Build @file:line[-line] mention from the visual marks. Path is
      -- relative to nvim's cwd, which equals the per-tab Claude's cwd
      -- since spawn_claude_in_current_tab inherits it.
      local file = vim.fn.expand '%:.'
      if file == '' then
        vim.notify('Buffer has no file path', vim.log.levels.WARN)
        return
      end
      local s_line = vim.fn.line "'<"
      local e_line = vim.fn.line "'>"
      -- Leave visual mode before focusing the Claude window. Mode is global
      -- so otherwise the terminal inherits visual-line mode (gray highlight).
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
      local mention = (s_line == e_line)
        and string.format('@%s:%d ', file, s_line)
        or string.format('@%s:%d-%d ', file, s_line, e_line)
      vim.api.nvim_chan_send(job_id, mention)
      if not from_claude then
        -- Small delay so happy's TUI finishes redrawing its input box with
        -- the new @mention / pasted text before we focus + startinsert.
        -- Synchronous focus on a half-rendered TUI causes 1-2 line offset.
        vim.defer_fn(function()
          focus_tab_claude(tab_buf)
        end, 30)
      end
    else
      vim.cmd 'ClaudeCodeSend'
      vim.defer_fn(function()
        if not from_claude then
          vim.cmd 'ClaudeCodeFocus'
        end
      end, 100)
    end
  end
end

return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    -- Singleton terminal (ClaudeCode commands, *Send/*Add fallback). Named
    -- after the project; the name is frozen at config load (startup cwd).
    terminal_cmd = with_remote_control(resolve_terminal_cmd(), nil),
    terminal = {
      split_side = 'right',
      split_width_percentage = 0.30,
      snacks_win_opts = {
        wo = {
          winhighlight = 'Normal:Normal,NormalNC:Normal,SignColumn:Normal,EndOfBuffer:Normal',
        },
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
    { '<leader>ac', tab_aware_open '--enable-auto-mode', desc = 'Toggle Claude (tab-aware)' },
    { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>ar', tab_aware_open '--resume --enable-auto-mode', desc = 'Resume Claude (tab-aware)' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>ab', add_buffer_to_claude, desc = 'Add current buffer' },
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
