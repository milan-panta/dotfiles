local function start_jdtls()
  local jdtls = require("jdtls")
  local mason_registry = require("mason-registry")

  local root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" }
  local root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
  if not root_dir then
    vim.notify("Could not find Java project root", vim.log.levels.WARN)
    return
  end

  local project_name = vim.fs.basename(root_dir)
  local workspace_dir = vim.fs.normalize("~/.cache/jdtls-workspace/") .. project_name
  vim.fn.mkdir(workspace_dir, "p")

  local java_home = vim.system({ "/usr/libexec/java_home", "-v", "21" }, { text = true }):wait().stdout:gsub("\n", "")
  local java_exec = (java_home ~= "" and vim.uv.fs_stat(java_home .. "/bin/java")) and java_home .. "/bin/java"
    or vim.fn.exepath("java")

  local cmd = {
    vim.fn.exepath("jdtls"),
    "--java-executable",
    java_exec,
    "--jvm-arg=-Xmx4g",
    "--jvm-arg=-XX:+UseG1GC",
    "--jvm-arg=-XX:+UseStringDeduplication",
  }

  pcall(function()
    local jdtls_path = mason_registry.get_package("jdtls"):get_install_path()
    local lombok_path = vim.fs.joinpath(jdtls_path, "lombok.jar")
    if lombok_path ~= "" and vim.uv.fs_stat(lombok_path) then
      table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_path)
    end
  end)

  table.insert(cmd, "-data")
  table.insert(cmd, workspace_dir)

  local bundles = {}

  pcall(function()
    local debug_path = mason_registry.get_package("java-debug-adapter"):get_install_path()
    local debug_jar = vim.fn.glob(debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
    if debug_jar ~= "" then
      table.insert(bundles, debug_jar)
    end
  end)

  pcall(function()
    local test_path = mason_registry.get_package("java-test"):get_install_path()
    local test_jars = vim.fn.glob(test_path .. "/extension/server/*.jar", true, true)
    for _, jar in ipairs(test_jars) do
      if jar ~= "" and not vim.endswith(jar, "com.microsoft.java.test.runner-jar-with-dependencies.jar") then
        table.insert(bundles, jar)
      end
    end
  end)

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local config = {
    cmd = cmd,
    root_dir = root_dir,
    capabilities = require("config.tools").make_capabilities(),

    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
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
          runtimes = java_home ~= "" and {
            { name = "JavaSE-21", path = java_home, default = true },
          } or {},
        },
      },
    },

    init_options = {
      bundles = bundles,
      extendedClientCapabilities = extendedClientCapabilities,
    },

    on_attach = function(_, bufnr)
      jdtls.setup_dap({ hotcodereplace = "auto" })

      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
      map("n", "<leader>ct", jdtls.pick_test, "Pick Test")
      map("n", "<leader>cT", function()
        jdtls.test_class()
      end, "Run Test Class")
      map("n", "<leader>cm", function()
        jdtls.test_nearest_method()
      end, "Test Nearest Method")

      map("n", "<leader>cU", function()
        require("jdtls.dap").setup_dap_main_class_configs()
        vim.notify("Main class configs updated", vim.log.levels.INFO)
      end, "Update Main Class Configs")

      map("v", "<leader>ce", function()
        jdtls.extract_variable(true)
      end, "Extract Variable")
      map("v", "<leader>cE", function()
        jdtls.extract_constant(true)
      end, "Extract Constant")
      map("v", "<leader>cM", function()
        jdtls.extract_method(true)
      end, "Extract Method")
      map("n", "<leader>ce", jdtls.extract_variable, "Extract Variable")
      map("n", "<leader>cE", jdtls.extract_constant, "Extract Constant")
    end,
  }

  jdtls.start_or_attach(config)
end

return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  dependencies = {
    "williamboman/mason.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    start_jdtls()

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("jdtls_start", { clear = true }),
      pattern = "java",
      callback = start_jdtls,
    })
  end,
}
