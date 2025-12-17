return {
  "chrishrb/gx.nvim",
  keys = {
    { "gx", "<cmd>Browse<cr>", mode = { "n" } },
    {
      "gx",
      function()
        local function get_visual()
          local save_reg = vim.fn.getreg("v")
          local save_type = vim.fn.getregtype("v")
          vim.cmd('noau normal! "vy')
          local text = vim.fn.getreg("v")
          vim.fn.setreg("v", save_reg, save_type)
          return text
        end

        local selection = get_visual()
        local gx = require("gx")
        local options = gx.options or {}
        local handler_options = options.handler_options or { search_engine = "google" }
        local search_handler = require("gx.handlers.search")
        local url = search_handler.handle("v", selection, handler_options)

        require("gx.shell").execute_with_error(
          options.open_browser_app or "open",
          options.open_browser_args or { "--background" },
          url
        )
      end,
      mode = { "x" },
    },
  },
  cmd = { "Browse" },
  config = function()
    require("gx").setup({
      open_browser_app = "open",
      open_browser_args = { "--background" },

      select_prompt = false, -- shows a prompt when multiple handlers match; disable to auto-select the top one

      handlers = {
        plugin = true, -- open plugin links in lua (e.g. packer, lazy, ..)
        github = true, -- open github issues
        brewfile = true, -- open Homebrew formulaes and casks
        package_json = true, -- open dependencies from package.json
        search = true, -- search the web/selection on the web if nothing else is found
        go = true, -- open pkg.go.dev from an import statement (uses treesitter)
        jira = { -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
          name = "jira", -- set name of handler
          handle = function(mode, line, _)
            local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
            if ticket and #ticket < 20 then
              return "http://jira.company.com/browse/" .. ticket
            end
          end,
        },
        rust = { -- custom handler to open rust's cargo packages
          name = "rust", -- set name of handler
          filetype = { "toml" }, -- you can also set the required filetype for this handler
          filename = "Cargo.toml", -- or the necessary filename
          handle = function(mode, line, _)
            local crate = require("gx.helper").find(line, mode, "(%w+)%s-=%s")

            if crate then
              return "https://crates.io/crates/" .. crate
            end
          end,
        },
      },
      handler_options = {
        search_engine = "google", -- you can select between google, bing, duckduckgo, ecosia and yandex
        select_for_search = true, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

        git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
        git_remotes = function(fname) -- you can also pass in a function
          if fname:match("myproject") then
            return { "mygit" }
          end
          return { "upstream", "origin" }
        end,

        git_remote_push = false, -- use the push url for git issue linking,
        git_remote_push = function(fname) -- you can also pass in a function
          return fname:match("myproject")
        end,
      },
    })
  end,
}
