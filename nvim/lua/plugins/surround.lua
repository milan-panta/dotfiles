return {
  "kylechui/nvim-surround",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    keymaps = {
      normal = "gs",
      normal_cur = "gss",
      normal_cur_line = "gSS",
      visual = "S",
      delete = "ds",
      change = "cs",
    },
  },
}
