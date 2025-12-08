return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    vim.opt.ruler = true
    require("gitsigns").setup({
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]h", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true })

        map("n", "[h", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true })

        -- Actions
        vim.keymap.set("n", "<Leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
        vim.keymap.set("n", "<Leader>hr", gs.reset_hunk, { desc = "Git reset hunk" })
        vim.keymap.set("v", "<Leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage selected hunk" })
        vim.keymap.set("v", "<Leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Git reset selected" })
        vim.keymap.set("n", "<Leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
        vim.keymap.set("n", "<Leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
        vim.keymap.set("n", "<Leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
        vim.keymap.set("n", "<Leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
        vim.keymap.set("n", "<Leader>hb", function()
          gs.blame_line({ full = true })
        end, { desc = "Toggle blame on file" })
        vim.keymap.set("n", "<Leader>htb", gs.toggle_current_line_blame, { desc = "Toggle blame on line" })
        vim.keymap.set("n", "<Leader>hd", gs.diffthis, { desc = "Git diff hunk" })
        vim.keymap.set("n", "<Leader>hD", function()
          gs.diffthis("~")
        end, { desc = "Git diff file" })
        vim.keymap.set("n", "<Leader>td", gs.toggle_deleted, { desc = "Toggle deleted git" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
      end,
    })
  end,
}
