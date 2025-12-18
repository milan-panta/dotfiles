return {
  "mbbill/undotree",
  keys = {
    {
      "<Leader>uu",
      function()
        vim.cmd("UndotreeToggle")
      end,
      desc = "Undo Tree",
    },
  },
}
