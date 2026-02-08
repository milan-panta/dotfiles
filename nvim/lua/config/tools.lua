local M = {}

M.servers = {
  copilot = {},

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

  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "standard",
          autoImportCompletions = true,
        },
      },
    },
  },

  html = {},
  cssls = {},
  jsonls = {},
  vtsls = {},

  marksman = {},

  kotlin_language_server = {},

  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        analyses = { unusedparams = true, unusedwrite = true, useany = true },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        staticcheck = true,
      },
    },
  },

  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
      "--pch-storage=memory",
      "--enable-config",
      "--limit-results=500",
      "-j=" .. tostring(#vim.uv.cpu_info()),
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
        "CMakeLists.txt",
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

M.formatters_by_ft = {
  c = { "clang_format" },
  cpp = { "clang_format" },
  go = { "gofumpt", "goimports" },
  rust = { "rustfmt" },
  java = { "google-java-format" },
  kotlin = { "ktlint" },
  lua = { "stylua" },
  python = { "ruff_fix", "ruff_format" },
  tex = { "latexindent" },
  markdown = { "prettier" },
  html = { "biome" },
  css = { "biome" },
  javascript = { "biome" },
  javascriptreact = { "biome" },
  typescript = { "biome" },
  typescriptreact = { "biome" },
  json = { "biome" },
}

M.linters_by_ft = {
  go = { "golangcilint" },
  python = { "ruff" },
}

M.dap_adapters = {
  "codelldb",
  "delve",
  "python",
  -- java-debug-adapter is handled by nvim-jdtls
}

M.ensure_installed = {
  "stylua",
  "clang-format",
  "prettier",
  "biome",
  "latexindent",
  "ruff",
  "jdtls",
  "google-java-format",
  "java-debug-adapter",
  "java-test",
  "ktlint",
  "delve",
  "gofumpt",
  "goimports",
  "golangci-lint",
}

M.treesitter_parsers = {
  "bash",
  "c",
  "cmake",
  "cpp",
  "css",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "groovy",
  "html",
  "java",
  "javascript",
  "json",
  "kotlin",
  "latex",
  "lua",
  "markdown",
  "markdown_inline",
  "proto",
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

M.diagnostic_config = {
  severity_sort = true,
  signs = true,
  underline = false,
  virtual_text = {
    severity = { min = vim.diagnostic.severity.WARN },
  },
  float = {
    border = "rounded",
    source = true,
  },
}

function M.get_server_names()
  return vim.tbl_keys(M.servers)
end

function M.make_capabilities(server_opts)
  server_opts = server_opts or {}

  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = has_blink and blink.get_lsp_capabilities(server_opts.capabilities)
    or vim.lsp.protocol.make_client_capabilities()

  if server_opts.capabilities then
    capabilities = vim.tbl_deep_extend("force", capabilities, server_opts.capabilities)
  end

  -- Disable dynamic watched files registration for performance
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

  return capabilities
end

return M
