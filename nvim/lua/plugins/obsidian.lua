return {
  "obsidian-nvim/obsidian.nvim",
  lazy = true,
  ft = "markdown",
  cmd = "Obsidian",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Today's note" },
    { "<leader>oo", "<cmd>Obsidian<cr>", desc = "Open Obsidian options" },
    { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday's note" },
    { "<leader>om", "<cmd>Obsidian tomorrow<cr>", desc = "Tomorrow's note" },
    { "<leader>od", "<cmd>Obsidian dailies<cr>", desc = "Daily notes list" },
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
    { "<leader>oN", "<cmd>Obsidian new_from_template<cr>", desc = "New from template" },
    { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
    { "<leader>og", "<cmd>Obsidian search<cr>", desc = "Grep notes" },
    { "<leader>oT", "<cmd>Obsidian tags<cr>", desc = "Search tags" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
    { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links in note" },
    { "<leader>oa", "<cmd>Obsidian template<cr>", desc = "Apply template" },
    { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note" },
    { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
    { "<leader>oc", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle checkbox" },
    { "<leader>os", "<cmd>Obsidian toc<cr>", desc = "Table of contents" },
    { "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "Switch workspace" },
    { "<leader>oL", "<cmd>Obsidian link<cr>", mode = "v", desc = "Link selection" },
    { "<leader>ox", "<cmd>Obsidian extract_note<cr>", mode = "v", desc = "Extract to note" },
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "Private", path = "~/Documents/Notes/Private" },
    },

    -- Daily notes for journaling thoughts
    daily_notes = {
      folder = "daily",
      date_format = "%Y-%m-%d",
      alias_format = "%B %d, %Y",
      default_tags = { "daily" },
      template = "daily.md",
      workdays_only = false,
    },

    -- Templates for structured notes
    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },

    -- Just use the title as filename, lowercase with dashes
    note_id_func = function(title)
      if title and title ~= "" then
        return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      end
      return os.date("%Y-%m-%d-%H%M")
    end,

    new_notes_location = "current_dir",

    -- Wiki-style links [[note]]
    preferred_link_style = "wiki",

    -- Disable built-in UI (using render-markdown.nvim instead)
    ui = { enable = false },

    footer = { enabled = false },

    frontmatter = { enabled = false },

    -- Simple checkbox cycling
    checkbox = {
      order = { " ", "x" },
    },

    -- Attachments (images)
    attachments = {
      confirm_img_paste = false,
      img_text_func = function(path)
        local name = Obsidian.opts.preferred_link_style == "markdown" and require("obsidian.util").urlencode(path.name)
          or path.name
        return string.format("![[assets/imgs/%s]]", name)
      end,
    },

    completion = {
      nvim_cmp = true,
      min_chars = 0,
    },
  },
}
