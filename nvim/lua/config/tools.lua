-- tools.lua: all external tooling lives here
-- Add a language? Update this file, mason/lsp/formatters just work.

local M = {}

-- LSP servers: mason-lspconfig name -> lspconfig opts (empty {} = defaults)
M.servers = {
  -- copilot
  copilot = {},

  -- Lua
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        completion = { callSnippet = "Replace" },
        hint = { enable = true },
        codeLens = { enable = true },
        diagnostics = {
          disable = { "incomplete-signature-doc", "trailing-space", "missing-local-export-doc" },
          groupSeverity = { strong = "Warning", strict = "Warning" },
        },
      },
    },
  },

  -- Python
  basedpyright = {},

  -- Web
  html = {},
  cssls = {},
  jsonls = {},
  tailwindcss = {},
  vtsls = {},

  -- Markdown
  marksman = {},

  -- Typst
  tinymist = {
    settings = {
      formatterMode = "typstyle",
      exportPdf = "never",
    },
  },

  -- C/C++
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
    },
    capabilities = { offsetEncoding = { "utf-16" } },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
    },
    root_dir = function(fname)
      local util = require("lspconfig.util")
      return util.root_pattern(
        "Makefile",
        "configure.ac",
        "configure.in",
        "config.h.in",
        "meson.build",
        "opt/build/ninja.build",
        "build.ninja"
      )(fname) or util.root_pattern("compile_commands.json", "compile_flags.txt")(fname) or vim.fs.dirname(
        vim.fs.find(".git", { path = fname, upward = true })[1]
      )
    end,
  },

  -- rust-analyzer: handled by rustaceanvim
}

-- Formatters (conform.nvim)
M.formatters_by_ft = {
  c = { "clang_format" },
  cpp = { "clang_format" },
  lua = { "stylua" },
  python = { "ruff_fix", "ruff_format" },
  tex = { "latexindent" },
  typst = { "typstyle" },
  markdown = { "prettier" },
  html = { "biome" },
  css = { "biome" },
  javascript = { "biome" },
  javascriptreact = { "biome" },
  typescript = { "biome" },
  typescriptreact = { "biome" },
  json = { "biome" },
}

-- Linters (nvim-lint)
M.linters_by_ft = {
  python = { "ruff" },
}

-- DAP adapters (mason-nvim-dap)
M.dap_adapters = {
  "codelldb", -- C/C++/Rust
  "python", -- Python (debugpy)
}

-- Mason packages (non-LSP tools to auto-install)
M.ensure_installed = {
  "stylua",
  "clang-format",
  "prettier",
  "biome",
  "typstyle",
  "latexindent",
  "ruff",
}

-- Treesitter parsers
M.treesitter_parsers = {
  "bash",
  "c",
  "cpp",
  "css",
  "gitignore",
  "java",
  "javascript",
  "json",
  "kotlin",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "ron",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

-- Diagnostics config
M.diagnostic_config = {
  severity_sort = true,
  signs = true,
  underline = true,
  virtual_text = {
    severity = vim.diagnostic.severity.ERROR,
  },
  -- virtual_text = true,
  float = {
    border = "rounded",
    source = true,
  },
}

-- Helpers
function M.get_server_names()
  return vim.tbl_keys(M.servers)
end

function M.make_capabilities(server_opts)
  server_opts = server_opts or {}

  -- Get base capabilities - blink.cmp is guaranteed loaded by lsp-config dependencies
  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = has_blink and blink.get_lsp_capabilities(server_opts.capabilities)
    or vim.lsp.protocol.make_client_capabilities()

  -- Merge any server-specific capabilities
  if server_opts.capabilities then
    capabilities = vim.tbl_deep_extend("force", capabilities, server_opts.capabilities)
  end

  -- Disable dynamic watched files registration for performance
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

  return capabilities
end

return M
