local M = {}

M.servers = {
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
  starpls = {},

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
      "--header-insertion=never",
      "--header-insertion-decorators=0",
      "--completion-style=bundled",
      "--function-arg-placeholders=1",
      "--all-scopes-completion",
      "--ranking-model=decision_forest",
      "--fallback-style=llvm",
      "--pch-storage=memory",
      "--enable-config",
      -- "--malloc-trim", -- only on linux
      "--log=error",
      "--limit-results=50",
      "--limit-references=200",
      "-j=" .. tostring(#vim.uv.cpu_info()),
    },
    capabilities = { offsetEncoding = { "utf-16" } },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
    },
    root_markers = {
      "WORKSPACE",
      "WORKSPACE.bazel",
      "MODULE.bazel",
      "CMakeLists.txt",
      "Makefile",
      "configure.ac",
      "configure.in",
      "config.h.in",
      "meson.build",
      "build.ninja",
      "compile_commands.json",
      "compile_flags.txt",
      ".git",
    },
  },

  -- rust-analyzer: handled by rustaceanvim
}

-- Externally managed servers: never passed to Mason's install/enable lists.
local ghcup_bin = vim.fn.expand("~/.ghcup/bin")
M.system_servers = {
  hls = {
    cmd = { ghcup_bin .. "/haskell-language-server-wrapper", "--lsp" },
    -- Keep HLS and its child processes on the course's GHCup toolchain,
    -- even when Mason has prepended its own bin directory to Neovim's PATH.
    cmd_env = { PATH = ghcup_bin .. ":" .. (vim.env.PATH or "") },
  },
}

M.formatters_by_ft = {
  bzl = { "buildifier" },
  c = { "clang_format" },
  cpp = { "clang_format" },
  css = { "biome" },
  go = { "gofumpt", "goimports" },
  html = { "biome" },
  javascript = { "biome" },
  javascriptreact = { "biome" },
  json = { "biome" },
  lua = { "stylua" },
  markdown = { "prettier" },
  python = { "ruff_fix", "ruff_format" },
  rust = { "rustfmt" },
  tex = { "latexindent" },
  typescript = { "biome" },
  typescriptreact = { "biome" },
}

M.linters_by_ft = {
  go = { "golangcilint" },
}

-- DAP adapters managed by Mason. lldb-dap comes from the Xcode Command Line
-- Tools and is configured directly in plugins/dap.lua.
M.mason_dap_adapters = {
  "delve",
  "python",
}

M.ensure_installed = {
  "biome",
  "buildifier",
  "clang-format",
  "delve",
  "gofumpt",
  "goimports",
  "golangci-lint",
  "latexindent",
  "prettier",
  "ruff",
  "stylua",
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
  "haskell",
  "html",
  "javascript",
  "json",
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
  "starlark",
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
  underline = true,
  virtual_text = true,
  float = {
    border = "rounded",
    source = true,
  },
}

function M.get_server_names()
  return vim.tbl_keys(M.servers)
end

function M.make_capabilities()
  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = has_blink and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

  -- Disable dynamic watched files registration for performance
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

  return capabilities
end

return M
