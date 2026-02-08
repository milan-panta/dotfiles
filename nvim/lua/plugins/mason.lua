return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
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
      local mr = require("mason-registry")
      mr.refresh(function()
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
