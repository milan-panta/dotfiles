return {
    'akinsho/toggleterm.nvim',
    event = "VeryLazy",
    dependencies = {
        "christoomey/vim-tmux-navigator",
        event = "VeryLazy",

        config = function()
            vim.keymap.del("n", "<C-\\>")
        end
    },
    event = "VeryLazy",
    opts = {
        open_mapping = [[<c-\>]],
    }
}
