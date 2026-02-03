return {
  "kylechui/nvim-surround",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    keymaps = {
      normal = "ys",
      normal_cur = "yss",
      normal_cur_line = "ySS",
      visual = "S",
      delete = "ds",
      change = "cs",
    },
  },
}
