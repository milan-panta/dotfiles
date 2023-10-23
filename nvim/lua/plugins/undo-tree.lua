return {
  "mbbill/undotree",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<Leader>u",
      function()
        vim.cmd("UndotreeToggle")
      end,
      desc = "Toggle Undo Tree",
    },
  },
}
