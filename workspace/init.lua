vim.opt.number = true
vim.cmd([[highlight LineNr ctermfg=8]])

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true

vim.keymap.set("n", "<C-s>", ":w<CR>", { silent = true })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>gv", { silent = true })

vim.opt.guicursor =
  "n-v-c:block-Cursor/lCursor," ..
  "ve:ver35-Cursor," ..
  "o:hor50-Cursor," ..
  "i-ci:ver25-Cursor/lCursor," ..
  "r-cr:hor20-Cursor/lCursor," ..
  "sm:block-Cursor," ..
  "a:blinkwait175-blinkoff150-blinkon175"

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    vim.opt.guicursor =
      "a:ver25-Cursor-blinkwait700-blinkon400-blinkoff250"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(ev)
    vim.lsp.start({
      name = "clangd",
      cmd = { "clangd" },
      root_dir = vim.fn.getcwd(),
    })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
