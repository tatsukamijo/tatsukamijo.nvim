return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  init = function()
    -- Auto-restore session on startup (only when no file args)
    vim.api.nvim_create_autocmd('VimEnter', {
      group = vim.api.nvim_create_augroup('persistence-autoload', { clear = true }),
      callback = function()
        if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
          require('persistence').load()
          vim.cmd 'stopinsert'
        end
      end,
      nested = true,
    })
  end,
  keys = {
    { '<leader>qs', function() require('persistence').load() end, desc = 'Restore session (cwd)' },
    { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore last session' },
    { '<leader>qd', function() require('persistence').stop() end, desc = "Don't save current session" },
  },
}