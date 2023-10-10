return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            config = function()
                require("telescope").load_extension("fzf")
            end,
        },
        {
            "debugloop/telescope-undo.nvim",
            keys = { { "<leader>U", "<cmd>Telescope undo<cr>" } },
            config = function()
                require("telescope").load_extension("undo")
            end,
        },
    },
    opts = {
        defaults = {
            layout_strategy = "horizontal",
            layout_config = {
                horizontal = {
                    prompt_position = "top",
                    preview_width = 0.5,
                },
                width = 0.8,
                height = 0.8,
                preview_cutoff = 120,
            },
            sorting_strategy = "ascending",
            winblend = 0,
        },
    },
    keys = {
        {
            "<Leader>ff",
            function()
                require("telescope.builtin").find_files({ hidden = true })
            end,
            desc = "Telescope find files",
        },
        {
            "<Leader>fF",
            function()
                require("telescope.builtin").git_files()
            end,
            desc = "Telescope find Git files",
        },
        {
            "<Leader>fg",
            function()
                require("telescope.builtin").live_grep()
            end,
            desc = "Telescope live grep",
        },
        {
            "<Leader>fh",
            function()
                require("telescope.builtin").help_tags()
            end,
            desc = "Telescope find help tags",
        },
        {
            "<Leader>fd",
            function()
                require("telescope.builtin").diagnostics()
            end,
            desc = "Telescope diagnostics",
        },
        {
            "<Leader>fo",
            function()
                require("telescope.builtin").oldfiles()
            end,
            desc = "Telescope find oldfiles",
        },
        {
            "<Leader>fq",
            function()
                require("telescope.builtin").quickfix()
            end,
            desc = "Telescope quickfix",
        },
    },
}
