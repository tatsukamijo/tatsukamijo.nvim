-- neocodeium: free AI code completion (Codeium)
-- https://github.com/monkoose/neocodeium

return {
  'monkoose/neocodeium',
  event = 'VeryLazy',
  config = function()
    local neocodeium = require('neocodeium')
    neocodeium.setup()

    -- Keymaps (Alt + key, avoiding skhd conflicts)
    vim.keymap.set('i', '<A-;>', neocodeium.accept, { desc = 'Accept suggestion' })
    vim.keymap.set('i', '<A-w>', neocodeium.accept_word, { desc = 'Accept word' })
    vim.keymap.set('i', '<A-.>', neocodeium.accept_line, { desc = 'Accept line' })
    vim.keymap.set('i', '<A-n>', neocodeium.cycle_or_complete, { desc = 'Next suggestion' })
    vim.keymap.set('i', '<A-p>', function() neocodeium.cycle_or_complete(-1) end, { desc = 'Prev suggestion' })
    vim.keymap.set('i', '<A-/>', neocodeium.clear, { desc = 'Clear suggestion' })
  end,
}