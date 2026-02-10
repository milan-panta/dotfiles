return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("nvim-treesitter-textobjects").setup({
      select = {
        lookahead = true,
        selection_modes = {
          ["@function.outer"] = "V",
          ["@function.inner"] = "V",
          ["@class.outer"] = "V",
          ["@class.inner"] = "V",
        },
        include_surrounding_whitespace = function(opts)
          return opts.query_string:match("outer$") ~= nil
        end,
      },
      move = { set_jumps = true },
    })

    local function has_textobjects(buf)
      local ft = vim.bo[buf].filetype
      local lang = vim.treesitter.language.get_lang(ft) or ft
      local ok = pcall(vim.treesitter.query.get, lang, "textobjects")
      return ok
    end

    local function attach(buf)
      if not has_textobjects(buf) then
        return
      end

      local select = require("nvim-treesitter-textobjects.select")
      local select_maps = {
        ["aa"] = { query = "@parameter.outer", desc = "outer parameter" },
        ["ia"] = { query = "@parameter.inner", desc = "inner parameter" },
        ["ai"] = { query = "@conditional.outer", desc = "outer conditional" },
        ["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
        ["al"] = { query = "@loop.outer", desc = "outer loop" },
        ["il"] = { query = "@loop.inner", desc = "inner loop" },
        ["af"] = { query = "@call.outer", desc = "outer call" },
        ["if"] = { query = "@call.inner", desc = "inner call" },
        ["am"] = { query = "@function.outer", desc = "outer function" },
        ["im"] = { query = "@function.inner", desc = "inner function" },
        ["ac"] = { query = "@class.outer", desc = "outer class" },
        ["ic"] = { query = "@class.inner", desc = "inner class" },
        ["a="] = { query = "@assignment.outer", desc = "outer assignment" },
        ["i="] = { query = "@assignment.inner", desc = "inner assignment" },
        ["l="] = { query = "@assignment.lhs", desc = "assignment lhs" },
        ["r="] = { query = "@assignment.rhs", desc = "assignment rhs" },
        ["aR"] = { query = "@return.outer", desc = "outer return" },
        ["iR"] = { query = "@return.inner", desc = "inner return" },
        ["a/"] = { query = "@comment.outer", desc = "outer comment" },
        ["an"] = { query = "@number.inner", desc = "number" },
        ["in"] = { query = "@number.inner", desc = "number" },
      }
      for key, mapping in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(mapping.query, "textobjects")
        end, { buffer = buf, desc = mapping.desc, silent = true })
      end

      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>Ca", function()
        swap.swap_next("@parameter.inner")
      end, { buffer = buf, desc = "Swap parameter with next" })
      vim.keymap.set("n", "<leader>CA", function()
        swap.swap_previous("@parameter.inner")
      end, { buffer = buf, desc = "Swap parameter with previous" })

      local move = require("nvim-treesitter-textobjects.move")
      -- [c/]c conflicts with vim's diff navigation, skip in diff buffers
      local in_diff = vim.wo.diff
      local move_maps = {
        { "]m", "goto_next_start", "@function.outer", "Next function start" },
        { "]M", "goto_next_end", "@function.outer", "Next function end" },
        { "[m", "goto_previous_start", "@function.outer", "Prev function start" },
        { "[M", "goto_previous_end", "@function.outer", "Prev function end" },
        { "]f", "goto_next_start", "@call.outer", "Next call start" },
        { "]F", "goto_next_end", "@call.outer", "Next call end" },
        { "[f", "goto_previous_start", "@call.outer", "Prev call start" },
        { "[F", "goto_previous_end", "@call.outer", "Prev call end" },
        { "]c", "goto_next_start", "@class.outer", "Next class start", skip_diff = true },
        { "]C", "goto_next_end", "@class.outer", "Next class end", skip_diff = true },
        { "[c", "goto_previous_start", "@class.outer", "Prev class start", skip_diff = true },
        { "[C", "goto_previous_end", "@class.outer", "Prev class end", skip_diff = true },
        { "]i", "goto_next_start", "@conditional.outer", "Next conditional start" },
        { "]I", "goto_next_end", "@conditional.outer", "Next conditional end" },
        { "[i", "goto_previous_start", "@conditional.outer", "Prev conditional start" },
        { "[I", "goto_previous_end", "@conditional.outer", "Prev conditional end" },
        { "]l", "goto_next_start", "@loop.outer", "Next loop start" },
        { "]L", "goto_next_end", "@loop.outer", "Next loop end" },
        { "[l", "goto_previous_start", "@loop.outer", "Prev loop start" },
        { "[L", "goto_previous_end", "@loop.outer", "Prev loop end" },
        { "]a", "goto_next_start", "@parameter.outer", "Next parameter" },
        { "[a", "goto_previous_start", "@parameter.outer", "Prev parameter" },
        { "]=", "goto_next_start", "@assignment.outer", "Next assignment" },
        { "[=", "goto_previous_start", "@assignment.outer", "Prev assignment" },
        { "]/", "goto_next_start", "@comment.outer", "Next comment" },
        { "[/", "goto_previous_start", "@comment.outer", "Prev comment" },
      }
      for _, m in ipairs(move_maps) do
        if not (in_diff and m.skip_diff) then
          vim.keymap.set({ "n", "x", "o" }, m[1], function()
            move[m[2]](m[3], "textobjects")
          end, { buffer = buf, desc = m[4], silent = true })
        end
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_textobjects", { clear = true }),
      callback = function(ev)
        attach(ev.buf)
      end,
    })
    -- attach to buffers already loaded before plugin init
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end

    -- make ; , also repeat treesitter motions
    local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}
