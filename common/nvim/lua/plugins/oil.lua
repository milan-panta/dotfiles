return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "<Leader>-", "<cmd>Oil<cr>", desc = "Open Oil" },
  },
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  init = function()
    vim.api.nvim_create_autocmd("BufWinEnter", {
      nested = true,
      callback = function(args)
        local path = vim.api.nvim_buf_get_name(args.buf)
        if path ~= "" and vim.fn.isdirectory(path) == 1 then
          vim.cmd.Oil(vim.fn.fnameescape(path))
          return true
        end
      end,
    })
  end,
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
  },
}
