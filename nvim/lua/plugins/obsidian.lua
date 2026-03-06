local vault = vim.fn.expand("~/Documents/Notes/Private")

return {
  "obsidian-nvim/obsidian.nvim",
  lazy = true,
  cmd = "Obsidian",
  event = {
    ("BufReadPre %s/**"):format(vault),
    ("BufNewFile %s/**"):format(vault),
  },
  -- Tier 1: global keymaps — available from any buffer, load obsidian on first use
  keys = {
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
    { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
    { "<leader>og", "<cmd>Obsidian search<cr>", desc = "Grep notes" },
    { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Today's note" },
    { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday's note" },
    { "<leader>om", "<cmd>Obsidian tomorrow<cr>", desc = "Tomorrow's note" },
    { "<leader>od", "<cmd>Obsidian dailies<cr>", desc = "Daily notes list" },
    { "<leader>oT", "<cmd>Obsidian tags<cr>", desc = "Search tags" },
    { "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "Switch workspace" },
    { "<leader>oo", "<cmd>Obsidian<cr>", desc = "Obsidian menu" },
  },
  init = function()
    -- Tier 2: buffer-local keymaps — only when editing a vault note
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      group = vim.api.nvim_create_augroup("ObsidianKeys", { clear = true }),
      pattern = vault .. "/**",
      callback = function(args)
        local buf = args.buf
        for _, km in ipairs({
          { "n", "<leader>ob", "backlinks", "Backlinks" },
          { "n", "<leader>ol", "links", "Links in note" },
          { "n", "<leader>oa", "template", "Apply template" },
          { "n", "<leader>or", "rename", "Rename note" },
          { "n", "<leader>op", "paste_img", "Paste image" },
          { "n", "<leader>oc", "toggle_checkbox", "Toggle checkbox" },
          { "n", "<leader>os", "toc", "Table of contents" },
          { "n", "<leader>oN", "new_from_template", "New from template" },
          { "v", "<leader>oL", "link", "Link selection" },
          { "v", "<leader>ox", "extract_note", "Extract to note" },
        }) do
          vim.keymap.set(km[1], km[2], "<cmd>Obsidian " .. km[3] .. "<cr>", { buffer = buf, desc = km[4] })
        end
      end,
    })
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "Private", path = vault },
    },

    daily_notes = {
      folder = "daily",
      date_format = "%Y-%m-%d",
      template = "daily.md",
      workdays_only = false,
    },

    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },

    note_id_func = function(title)
      if title and title ~= "" then
        return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      end
      return os.date("%Y-%m-%d-%H%M")
    end,

    new_notes_location = "current_dir",
    link = { style = "wiki" },

    ui = { enable = false }, -- using render-markdown.nvim instead
    footer = { enabled = false },

    note = { template = vim.NIL }, -- suppress default frontmatter template
    frontmatter = { enabled = false },

    checkbox = { order = { " ", "x" } },

    attachments = { folder = "./" },

    completion = {
      blink = true,
      nvim_cmp = false,
      min_chars = 0,
    },
  },
}
