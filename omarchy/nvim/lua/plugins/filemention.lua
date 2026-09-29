return {
  "not-manu/filemention.nvim",
  event = "InsertEnter",
  dependencies = {
    {
      "dmtrKovalenko/fff",
      version = "0.*",
      build = function()
        require("fff.download").download_or_build_binary()
      end,
    },
  },
  opts = { finder = "fff" },
}
