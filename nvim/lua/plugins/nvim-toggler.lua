return {
  "nguyenvukhang/nvim-toggler",
  event = "BufReadPost",
  opts = {
    -- your own inverses
    inverses = {
      ["vim"] = "emacs",
    },
  },
}
