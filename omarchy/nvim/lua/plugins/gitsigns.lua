return {
  "lewis6991/gitsigns.nvim",
  -- After the first screen is drawn, so opening a file doesn't wait for it.
  event = "VeryLazy",
  opts = {
    -- Thin bars in the space the statuscolumn already keeps for git (snacks.lua).
    signcolumn = true,
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buf = buffer, desc = desc, silent = true })
      end

      -- stylua: ignore start
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")
      map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
      map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
      map({ "n", "x" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "x" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
      -- stage_hunk on a staged hunk unstages it (undo_stage_hunk is deprecated).
      map({ "n", "x" }, "<leader>hu", ":Gitsigns stage_hunk<CR>", "Unstage Hunk")
      map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>gB", function() gs.blame() end, "Blame Whole File")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
    end,
  },
}
