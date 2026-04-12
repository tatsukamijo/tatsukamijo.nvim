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
    terminal_cmd = vim.fn.expand '~/.pixi/envs/nodejs/bin/happy',
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
    { toggle_key, '<cmd>ClaudeCodeFocus<cr>', desc = 'Toggle Claude', mode = { 'n', 'x' } },
    { '<leader>a', nil, desc = 'AI/Claude Code' },
    { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
    { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>ab', focus_claude_after 'ClaudeCodeAdd %', desc = 'Add current buffer' },
    { '<leader>as', send_selection_to_claude, mode = 'v', desc = 'Send to Claude' },
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
