-- Project-wide search and replace, with a preview of every change.
return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  -- stylua: ignore
  keys = {
    { "<leader>sr", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search and Replace in Project" },
    { "<leader>sr", function() require("grug-far").with_visual_selection() end, mode = "x", desc = "Search and Replace Selection in Project" },
  },
  opts = { headerMaxWidth = 80 },
}
