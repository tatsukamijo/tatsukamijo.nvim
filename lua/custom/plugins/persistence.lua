return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  init = function()
    local group = vim.api.nvim_create_augroup('persistence-custom', { clear = true })

    -- Close terminal windows before saving (they can't be properly restored)
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'PersistenceSavePre',
      callback = function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == 'terminal' then
            vim.api.nvim_win_close(win, true)
          end
        end
      end,
    })

    -- Auto-restore session on startup (only when no file args)
    vim.api.nvim_create_autocmd('VimEnter', {
      group = group,
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