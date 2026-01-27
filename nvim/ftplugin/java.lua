-- Java filetype configuration with nvim-jdtls
-- This file is automatically sourced when a Java file is opened

local jdtls = require("jdtls")
local mason_registry = require("mason-registry")

-- Find project root
local root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" }
local root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])

if not root_dir then
  vim.notify("Could not find Java project root", vim.log.levels.WARN)
  return
end

-- Workspace directory for jdtls (persistent across sessions)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.expand("~/.cache/jdtls-workspace/") .. project_name

-- Ensure workspace directory exists
vim.fn.mkdir(workspace_dir, "p")

-- Get Mason install paths
local jdtls_path = mason_registry.get_package("jdtls"):get_install_path()
local java_debug_path = mason_registry.get_package("java-debug-adapter"):get_install_path()
local java_test_path = mason_registry.get_package("java-test"):get_install_path()

-- Find lombok jar (bundled with jdtls or standalone)
local lombok_path = vim.fn.glob(jdtls_path .. "/lombok.jar")
if lombok_path == "" then
  lombok_path = vim.fn.glob(vim.fn.expand("~/.local/share/lombok/lombok.jar"))
end

-- Platform-specific launcher and config
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
local config_dir
if vim.fn.has("mac") == 1 then
  config_dir = jdtls_path .. "/config_mac"
elseif vim.fn.has("unix") == 1 then
  config_dir = jdtls_path .. "/config_linux"
else
  config_dir = jdtls_path .. "/config_win"
end

-- Debug bundles
local bundles = {}

-- java-debug-adapter
local java_debug_bundle = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
if java_debug_bundle ~= "" then
  table.insert(bundles, java_debug_bundle)
end

-- java-test
local java_test_bundles = vim.split(
  vim.fn.glob(java_test_path .. "/extension/server/*.jar", true),
  "\n"
)
for _, bundle in ipairs(java_test_bundles) do
  if bundle ~= "" and not vim.endswith(bundle, "com.microsoft.java.test.runner-jar-with-dependencies.jar") then
    table.insert(bundles, bundle)
  end
end

-- Extended capabilities for debugging
local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

-- Get capabilities from blink.cmp if available
local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

-- jdtls configuration
local config = {
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx2g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    lombok_path ~= "" and ("-javaagent:" .. lombok_path) or nil,
    "-jar", launcher_jar,
    "-configuration", config_dir,
    "-data", workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,

  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" }, -- Decompiler
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.Assume.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.junit.jupiter.api.DynamicContainer.*",
          "org.junit.jupiter.api.DynamicTest.*",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
          "org.mockito.Answers.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
      configuration = {
        -- Detect installed JDKs
        runtimes = (function()
          local runtimes = {}
          local java_home = os.getenv("JAVA_HOME")
          if java_home then
            table.insert(runtimes, {
              name = "JavaSE-21",
              path = java_home,
              default = true,
            })
          end
          return runtimes
        end)(),
      },
    },
  },

  init_options = {
    bundles = bundles,
    extendedClientCapabilities = extendedClientCapabilities,
  },

  on_attach = function(_, bufnr)
    -- Enable debugging
    jdtls.setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()

    -- Java-specific keymaps
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Code actions
    map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
    map("n", "<leader>ct", jdtls.pick_test, "Test Class")
    map("n", "<leader>cT", function() jdtls.test_class() end, "Run Test Class")
    map("n", "<leader>cm", function() jdtls.test_nearest_method() end, "Test Nearest Method")

    -- Extract refactorings (visual mode)
    map("v", "<leader>ce", function() jdtls.extract_variable(true) end, "Extract Variable")
    map("v", "<leader>cE", function() jdtls.extract_constant(true) end, "Extract Constant")
    map("v", "<leader>cM", function() jdtls.extract_method(true) end, "Extract Method")

    -- Normal mode extract (for cursor position)
    map("n", "<leader>ce", jdtls.extract_variable, "Extract Variable")
    map("n", "<leader>cE", jdtls.extract_constant, "Extract Constant")
  end,
}

-- Filter out nil values from cmd (lombok might not exist)
config.cmd = vim.tbl_filter(function(v) return v ~= nil end, config.cmd)

-- Start jdtls
jdtls.start_or_attach(config)
