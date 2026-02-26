return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = function()
      pcall(vim.cmd, "MasonUpdate")
    end,
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      max_concurrent_installers = 4,
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local tools = require("config.tools")
      vim.schedule(function()
        local mr = require("mason-registry")
        for _, tool in ipairs(tools.ensure_installed or {}) do
          local ok, p = pcall(mr.get_package, tool)
          if ok and not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  { "williamboman/mason-lspconfig.nvim", lazy = true },
}
