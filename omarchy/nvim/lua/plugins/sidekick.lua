local function nav(direction)
  return function()
    vim.schedule(function()
      vim.cmd("TmuxNavigate" .. direction)
    end)
  end
end

return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      tools = {
        claude = {
          cmd = { "claude", "--dangerously-skip-permissions" },
        },
        codex = {
          cmd = { "codex", "--yolo" },
        },
        agy = {
          cmd = { "agy", "--dangerously-skip-permissions" },
          is_proc = "\\<agy\\>",
        },
      },
      win = {
        -- Sidekick's own nav actions send <C-h>/<C-l> to the CLI when the
        -- window is at Neovim's edge; route through tmux-navigator instead so
        -- the edge moves to the neighbouring tmux pane.
        keys = {
          nav_left = { "<M-h>", nav("Left"), expr = false, desc = "navigate to the left window/pane" },
          nav_down = { "<M-j>", nav("Down"), expr = false, desc = "navigate to the below window/pane" },
          nav_up = { "<M-k>", nav("Up"), expr = false, desc = "navigate to the above window/pane" },
          nav_right = { "<M-l>", nav("Right"), expr = false, desc = "navigate to the right window/pane" },
        },
        split = {
          width = 0,
          height = 0,
        },
      },
    },
    nes = { enabled = false },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>ao",
      function()
        require("sidekick.cli").toggle({ name = "codex", focus = true })
      end,
      desc = "Sidekick Toggle Codex",
    },
    {
      "<leader>ag",
      function()
        require("sidekick.cli").toggle({ name = "agy", focus = true })
      end,
      desc = "Sidekick Toggle Agy",
    },
  },
}
