return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    event = "VeryLazy",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        {
            "nvim-telescope/telescope.nvim",
            event = "VeryLazy",
        },
        "nvim-lua/plenary.nvim", -- required by telescope
        "MunifTanjim/nui.nvim",

        -- optional
        "nvim-tree/nvim-web-devicons",

        -- recommended
        "rcarriga/nvim-notify",
    },
    opts = {
        -- configuration goes here
        lang = "python3",
    },
}
