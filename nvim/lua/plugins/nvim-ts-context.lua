return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local tc = require("treesitter-context")

    tc.setup({
      -- only attach when it's a normal buffer, not Telescope
      on_attach = function(buf)
        local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        if bt == "prompt" or ft == "TelescopePrompt" or ft == "TelescopeResults" then
          return false
        end
        return true
      end,
    })

    vim.keymap.set("n", "[w", function()
      tc.go_to_context()
    end, { silent = true, desc = "Treesitter Context: jump up" })
  end,
}
