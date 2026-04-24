-- markdown-preview
-- https://github.com/iamcco/markdown-preview.nvim
--
return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = 'cd app && ./install.sh',
  config = function()
    local bin = vim.fn.stdpath('data') .. '/lazy/markdown-preview.nvim/app/bin'
    if vim.fn.isdirectory(bin) == 0 then
      vim.fn['mkdp#util#install']()
    end
  end,
}
