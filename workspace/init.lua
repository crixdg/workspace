local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.cmd([[highlight LineNr ctermfg=8]])

vim.opt.scrolloff = 7

vim.opt.signcolumn = "yes"

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.foldmethod = "syntax"
    vim.opt_local.foldlevel = 99
  end,
})
vim.opt.foldenable = true

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true

vim.keymap.set("n", "<C-s>", ":w<CR>", { silent = true })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>gv", { silent = true })

vim.keymap.set("n", "<C-_>", "gcc", { remap = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true })

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.keymap.set("n", "<Esc>", ":noh<CR>", { silent = true })

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

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

vim.cmd([[highlight Normal ctermbg=NONE guibg=NONE]])
vim.cmd([[highlight NonText ctermbg=NONE guibg=NONE]])
vim.cmd([[highlight SignColumn ctermbg=NONE guibg=NONE]])
