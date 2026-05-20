return {
  "not-manu/filemention.nvim",
  event = "InsertEnter",
  dependencies = {
    {
      "dmtrKovalenko/fff.nvim",
      build = function()
        require("fff.download").download_or_build_binary()
      end,
    },
  },
  opts = { finder = "fff" },
}
