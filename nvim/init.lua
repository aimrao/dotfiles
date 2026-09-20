-- ============================================================
-- Neovim
-- ============================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ------------------------------------------------------------
-- Basic editor settings
-- ------------------------------------------------------------

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = "a"

vim.opt.clipboard = "unnamedplus"

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.termguicolors = true

vim.opt.cursorline = true

vim.opt.signcolumn = "yes"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.confirm = true

vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.showmode = false
vim.opt.laststatus = 3

vim.opt.list = true

vim.opt.listchars = {
    tab = "→ ",
    trail = "·",
    nbsp = "␣",
}

vim.opt.fillchars = {
    eob = " ",
}

-- ------------------------------------------------------------
-- Bootstrap Lazy.nvim
-- ------------------------------------------------------------

local lazypath =
    vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

vim.opt.rtp:prepend(lazypath)

-- ------------------------------------------------------------
-- Plugins
-- ------------------------------------------------------------

require("lazy").setup({

    -- --------------------------------------------------------
    -- Theme
    -- --------------------------------------------------------

    {
        "folke/tokyonight.nvim",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("tokyonight-night")
        end,
    },

    -- --------------------------------------------------------
    -- Telescope
    -- --------------------------------------------------------

    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()

            local telescope = require("telescope")
            telescope.setup({})

            local builtin = require("telescope.builtin")

            vim.keymap.set(
                "n",
                "<leader>ff",
                builtin.find_files,
                { desc = "Find files" }
            )

            vim.keymap.set(
                "n",
                "<leader>fg",
                builtin.live_grep,
                { desc = "Live grep" }
            )

            vim.keymap.set(
                "n",
                "<leader>fb",
                builtin.buffers,
                { desc = "Buffers" }
            )

            vim.keymap.set(
                "n",
                "<leader>fr",
                builtin.oldfiles,
                { desc = "Recent files" }
            )

            vim.keymap.set(
                "n",
                "<leader>fh",
                builtin.help_tags,
                { desc = "Help" }
            )
        end,
    },

    -- --------------------------------------------------------
    -- File explorer
    -- --------------------------------------------------------

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()

            require("nvim-tree").setup({
                view = {
                    width = 32,
                },

                renderer = {
                    group_empty = true,
                },

                filters = {
                    dotfiles = false,
                },
            })

            vim.keymap.set(
                "n",
                "<leader>e",
                "<cmd>NvimTreeToggle<CR>",
                { desc = "File explorer" }
            )
        end,
    },

    -- --------------------------------------------------------
    -- Treesitter
    --
    -- Pin legacy-compatible master branch.
    -- Current main is the Nvim 0.12 rewrite.
    -- --------------------------------------------------------

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",

        config = function()

            local configs =
                require("nvim-treesitter.configs")

            configs.setup({
                ensure_installed = {
                    "bash",
                    "python",
                    "go",
                    "lua",
                    "vim",
                    "vimdoc",
                    "json",
                    "yaml",
                    "toml",
                    "markdown",
                    "markdown_inline",
                    "hcl",
                    "dockerfile",
                    "regex",
                },

                highlight = {
                    enable = true,
                },

                indent = {
                    enable = true,
                },
            })
        end,
    },

    -- --------------------------------------------------------
    -- LSP
    -- --------------------------------------------------------

    {
        "neovim/nvim-lspconfig",

        config = function()

            local capabilities =
                vim.lsp.protocol.make_client_capabilities()

            -- Native Nvim 0.11+ LSP API.
            -- Do NOT use require("lspconfig").server.setup().
            local servers = {
                bashls = {},
                pyright = {},
                gopls = {},
                yamlls = {},
                jsonls = {},
                terraformls = {},
                lua_ls = {},
            }

            for name, config in pairs(servers) do
                config.capabilities = capabilities

                vim.lsp.config(name, config)
                vim.lsp.enable(name)
            end

            -- Navigation
            vim.keymap.set(
                "n",
                "gd",
                vim.lsp.buf.definition,
                { desc = "Go to definition" }
            )

            vim.keymap.set(
                "n",
                "gD",
                vim.lsp.buf.declaration,
                { desc = "Go to declaration" }
            )

            vim.keymap.set(
                "n",
                "gr",
                vim.lsp.buf.references,
                { desc = "References" }
            )

            vim.keymap.set(
                "n",
                "K",
                vim.lsp.buf.hover,
                { desc = "Hover documentation" }
            )

            vim.keymap.set(
                "n",
                "<leader>rn",
                vim.lsp.buf.rename,
                { desc = "Rename" }
            )

            vim.keymap.set(
                "n",
                "<leader>ca",
                vim.lsp.buf.code_action,
                { desc = "Code action" }
            )
        end,
    },

    -- --------------------------------------------------------
    -- Mason
    -- --------------------------------------------------------

    {
        "mason-org/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    {
        "mason-org/mason-lspconfig.nvim",

        dependencies = {
            {
                "mason-org/mason.nvim",
                opts = {},
            },

            "neovim/nvim-lspconfig",
        },

        opts = {
            ensure_installed = {
                "bashls",
                "pyright",
                "gopls",
                "yamlls",
                "jsonls",
                "terraformls",
                "lua_ls",
            },

            automatic_enable = true,
        },
    },

    -- --------------------------------------------------------
    -- Completion
    -- --------------------------------------------------------

    {
        "hrsh7th/nvim-cmp",

        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },

        config = function()

            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({

                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                mapping = cmp.mapping.preset.insert({

                    ["<C-Space>"] =
                        cmp.mapping.complete(),

                    ["<CR>"] =
                        cmp.mapping.confirm({
                            select = true,
                        }),

                    ["<Tab>"] = cmp.mapping(function(fallback)

                        if cmp.visible() then
                            cmp.select_next_item()

                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()

                        else
                            fallback()
                        end

                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)

                        if cmp.visible() then
                            cmp.select_prev_item()

                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)

                        else
                            fallback()
                        end

                    end, { "i", "s" }),
                }),

                sources = {
                    { name = "nvim_lsp" },
                    { name = "path" },
                    { name = "buffer" },
                },
            })
        end,
    },

    -- --------------------------------------------------------
    -- Git
    -- --------------------------------------------------------

    {
        "lewis6991/gitsigns.nvim",

        config = function()

            require("gitsigns").setup()

            vim.keymap.set(
                "n",
                "]c",
                function()
                    require("gitsigns").next_hunk()
                end,
                { desc = "Next Git hunk" }
            )

            vim.keymap.set(
                "n",
                "[c",
                function()
                    require("gitsigns").prev_hunk()
                end,
                { desc = "Previous Git hunk" }
            )

            vim.keymap.set(
                "n",
                "<leader>hs",
                function()
                    require("gitsigns").stage_hunk()
                end,
                { desc = "Stage hunk" }
            )

            vim.keymap.set(
                "n",
                "<leader>hr",
                function()
                    require("gitsigns").reset_hunk()
                end,
                { desc = "Reset hunk" }
            )
        end,
    },

    -- --------------------------------------------------------
    -- Which-key
    -- --------------------------------------------------------

    {
        "folke/which-key.nvim",
        event = "VeryLazy",

        config = function()
            require("which-key").setup()
        end,
    },

    -- --------------------------------------------------------
    -- Status line
    -- --------------------------------------------------------

    {
        "nvim-lualine/lualine.nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        config = function()

            require("lualine").setup({
                options = {
                    theme = "tokyonight",
                    globalstatus = true,
                },
            })
        end,
    },

    -- --------------------------------------------------------
    -- Comments
    -- --------------------------------------------------------

    {
        "numToStr/Comment.nvim",

        config = function()
            require("Comment").setup()
        end,
    },

    -- --------------------------------------------------------
    -- Indentation
    -- --------------------------------------------------------

    {
        "lukas-reineke/indent-blankline.nvim",

        main = "ibl",

        config = function()
            require("ibl").setup()
        end,
    },

    -- --------------------------------------------------------
    -- Formatting
    -- --------------------------------------------------------

    {
        "stevearc/conform.nvim",

        config = function()

            require("conform").setup({

                formatters_by_ft = {
                    lua = { "stylua" },
                    python = { "ruff_format" },
                    go = { "gofmt" },
                    sh = { "shfmt" },
                    bash = { "shfmt" },
                    json = { "prettier" },
                    yaml = { "prettier" },
                    markdown = { "prettier" },
                    terraform = { "terraform_fmt" },
                },

                format_on_save = {
                    timeout_ms = 1000,
                    lsp_format = "fallback",
                },
            })

            vim.keymap.set(
                "n",
                "<leader>f",
                function()
                    require("conform").format({
                        async = true,
                        lsp_format = "fallback",
                    })
                end,
                { desc = "Format buffer" }
            )
        end,
    },

})

-- ============================================================
-- General keybindings
-- ============================================================

vim.keymap.set(
    "n",
    "<leader>w",
    "<cmd>w<CR>",
    { desc = "Save" }
)

vim.keymap.set(
    "n",
    "<leader>q",
    "<cmd>q<CR>",
    { desc = "Quit" }
)

vim.keymap.set(
    "n",
    "<leader>h",
    "<cmd>nohlsearch<CR>",
    { desc = "Clear search highlight" }
)

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Keep selection after indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- ============================================================
-- Autocommands
-- ============================================================

local augroup =
    vim.api.nvim_create_augroup(
        "UserConfig",
        { clear = true }
    )

-- Highlight copied text
vim.api.nvim_create_autocmd(
    "TextYankPost",
    {
        group = augroup,

        callback = function()
            vim.highlight.on_yank()
        end,
    }
)

-- Remove trailing whitespace
vim.api.nvim_create_autocmd(
    "BufWritePre",
    {
        group = augroup,
        pattern = "*",

        callback = function()
            vim.cmd([[%s/\s\+$//e]])
        end,
    }
)
