return {
  "folke/snacks.nvim",
  dependencies = { "echasnovski/mini.icons" },
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      preset = {
        -- stylua: ignore start
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "e", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = "󰠮 ", key = "n", desc = "Notes", action = ":lua Snacks.picker.files({cwd = vim.fs.normalize('~/Documents/Notes/Private')})" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({cwd = vim.fs.normalize('~/.config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        -- stylua: ignore end
      },
      sections = {
        {
          section = "terminal",
          cmd = "~/.config/nvim/scripts/square.sh",
          height = 5,
          padding = 1,
        },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    indent = { enabled = true, animate = { enabled = false } },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    quickfile = { enabled = true },
    select = { enabled = true },
    scope = { enabled = true },
    animate = { enabled = true },
    statuscolumn = {
      left = { "sign" },
      right = { "git" },
      folds = { open = true, git_hl = true },
    },
    words = { enabled = true },
    image = {
      enabled = true,
      doc = { inline = true, float = true },
      math = { enabled = true },
    },
    lazygit = { enabled = true },
    gitbrowse = { enabled = true },
    picker = {
      enabled = true,
      previewers = {
        diff = { builtin = true },
        git = { builtin = true },
      },
      sources = {
        files = {
          hidden = true,
          exclude = { ".git", ".obsidian", "node_modules", "venv", ".venv", ".python-version", ".DS_Store" },
        },
        grep = {
          hidden = true,
          exclude = { ".git", ".obsidian", "node_modules", "venv", ".venv", ".python-version", ".DS_Store" },
        },
      },
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
          },
        },
      },
    },
    toggle = { enabled = true },
    zen = {
      toggles = {
        git_signs = false,
        diagnostics = false,
        dim = false,
        blink_cmp = false,
      },
      win = {
        backdrop = { transparent = false },
      },
    },
  },
  keys = {
    -- stylua: ignore start
    { "<leader>ff", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },

    { "<leader><leader>", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    { "<leader>fc", function() Snacks.picker.files({cwd = vim.fs.normalize('~/.config')}) end, desc = "Find Config File" },

    { "<leader>gG", function() Snacks.lazygit() end, desc = "Lazygit (cwd)" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git blame" },
    { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Git Log" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    { "<leader>hl", function() Snacks.lazygit.log_file() end, desc = "Git Log File" },
    { "<leader>hL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },

    { "<leader>/", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sn", function() Snacks.picker.files({ cwd = vim.fs.normalize("~/Documents/Notes/Private") }) end, desc = "Search Notes" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },

    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>sS", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>ss", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },

    { "<leader>uu", function() Snacks.picker.undo() end, desc = "Undo History" },
    { "<leader>uz", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
    { "<c-w>z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
    { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>rf", function() Snacks.rename.rename_file() end, desc = "Rename File" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>N", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    -- stylua: ignore end
  },
  config = function(_, opts)
    local Snacks = require("snacks")
    Snacks.setup(opts)

    vim.ui.select = Snacks.picker.select
    vim.ui.input = Snacks.input.input

    local blink_enabled = true
    Snacks.toggle({
      id = "blink_cmp",
      name = "Blink Completion",
      get = function()
        return blink_enabled
      end,
      set = function(state)
        blink_enabled = state
        vim.b.completion = state
      end,
    })

    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle({
      name = "Inlay Hints",
      get = function()
        return vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
      end,
      set = function(state)
        vim.lsp.inlay_hint.enable(state)
      end,
    }):map("<leader>uh")
    Snacks.toggle.indent():map("<leader>ug")
    Snacks.toggle.dim():map("<leader>uD")
    Snacks.toggle({
      name = "CodeLens",
      get = function()
        return vim.g.codelens_enabled ~= false
      end,
      set = function(state)
        vim.g.codelens_enabled = state
        if state then
          vim.lsp.codelens.enable(true, { bufnr = 0 })
        else
          vim.lsp.codelens.enable(false, { bufnr = 0 })
        end
      end,
    }):map("<leader>uc")
  end,
}
