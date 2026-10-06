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

vim.opt.mouse = "a"
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true

vim.opt.scrolloff = 7

vim.opt.signcolumn = "yes"

vim.opt.undofile = true

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
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>y', '"+yy', { noremap = true, silent = true })

vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { noremap = true, silent = true })
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>gv", { noremap = true, silent = true })

vim.keymap.set("n", "<C-_>", "gcc", { remap = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true })

vim.keymap.set("n", "<A-S-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-S-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-S-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-S-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

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

local function lsp_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  return ok and blink.get_lsp_capabilities() or nil
end

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "-j=4",
  },
  filetypes = { "c", "cpp" },
  root_markers = {
    { "compile_commands.json", "compile_flags.txt", ".clangd" },
    ".git",
  },
  capabilities = lsp_capabilities(),
  on_attach = function(_, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
  end,
})

vim.lsp.enable("clangd")

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local opts = {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = 'rounded',
      source = 'always',
      prefix = ' ',
    }
    vim.diagnostic.open_float(nil, opts)
  end
})

vim.opt.updatetime = 250

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  pattern = { "*.c", "*.cpp", "*.cc", "*.h", "*.hpp" },
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.cpp", "*.cc", "*.h", "*.hpp" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

local loaded_snippet_dirs = {}

local function load_project_snippets()
  local ok, from_vscode = pcall(require, "luasnip.loaders.from_vscode")
  if not ok then
    return
  end

  local found = vim.fs.find(".vscode", {
    upward = true,
    type = "directory",
    path = vim.fn.getcwd(),
  })
  local dir = found[1]
  if not dir or loaded_snippet_dirs[dir] then
    return
  end
  loaded_snippet_dirs[dir] = true

  for _, file in ipairs(vim.fn.glob(dir .. "/*.code-snippets", false, true)) do
    from_vscode.load_standalone({ path = file })
  end
end

require("lazy").setup({
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        transparent_mode = true,
        contrast = "hard",
      })
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    event = "InsertEnter",
    config = function()
      local ls = require("luasnip")
      ls.setup({
        history = true,
        update_events = { "TextChanged", "TextChangedI" },
        enable_autosnippets = false,
      })

      load_project_snippets()
      vim.api.nvim_create_autocmd("DirChanged", { callback = load_project_snippets })

      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if ls.expandable() then
          ls.expand()
        elseif ls.locally_jumpable(1) then
          ls.jump(1)
        else
          vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
        end
      end, { silent = true })

      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if ls.locally_jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true })

      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })

      vim.api.nvim_create_user_command("SnippetsReload", function()
        loaded_snippet_dirs = {}
        load_project_snippets()
      end, {})
    end,
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippets = { preset = "luasnip" },
      keymap = { preset = "default" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      sources = {
        default = { "lsp", "snippets", "path", "buffer" },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix" },
      { "<leader>fu", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
      { "<leader>ss", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>so", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>sr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
      { "<leader>sd", "<cmd>Telescope lsp_definitions<cr>", desc = "Definitions" },
      { "<leader>si", "<cmd>Telescope lsp_incoming_calls<cr>", desc = "Incoming calls" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          path_display = { "truncate" },
          layout_strategy = "flex",
          layout_config = { width = 0.95, height = 0.9 },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
          },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },
})
