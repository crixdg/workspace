vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.scrolloff = 7
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.updatetime = 250

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.cmd.colorscheme("habamax")

vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "<C-s>", "<cmd>w<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-s>", "<cmd>w<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<C-s>", "<cmd>w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true })
vim.keymap.set("n", "<A-S-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-S-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-S-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-S-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>", { silent = true })
