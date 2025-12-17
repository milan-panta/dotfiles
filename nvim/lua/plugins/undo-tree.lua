return {
  "mbbill/undotree",
  keys = {
    {
      "<Leader>su",
      function()
        vim.cmd("UndotreeToggle")
      end,
      desc = "Undo Tree",
    },
  },
}
