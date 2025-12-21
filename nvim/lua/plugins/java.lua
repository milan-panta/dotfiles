return {
  "mfussenegger/nvim-jdtls",
  ft = { "java" },
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    local function attach_jdtls()
      local jdtls = require("jdtls")
      local jdtls_setup = require("jdtls.setup")

      -- Find root directory
      local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
      local root_dir = jdtls_setup.find_root(root_markers)

      if not root_dir or root_dir == "" then
        return
      end

      -- Get workspace directory (one per project)
      local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
      local workspace_dir = vim.fn.stdpath("data") .. "/site/java/workspace-root/" .. project_name

      -- Paths to jdtls installed via Mason
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
      local jdtls_path = mason_path .. "/jdtls"
      local lombok_path = jdtls_path .. "/lombok.jar"
      local java_debug_path = mason_path .. "/java-debug-adapter"
      local java_test_path = mason_path .. "/java-test"

      local bundles = {}
      if vim.fn.isdirectory(java_debug_path) == 1 then
        vim.list_extend(bundles, vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n"))
      end

      if vim.fn.isdirectory(java_test_path) == 1 then
        vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n"))
      end

      -- System-specific config
      local os_config = "linux"
      if vim.fn.has("mac") == 1 then
        os_config = "mac"
        -- Use ARM config if available on Apple Silicon
        if vim.fn.system("uname -m"):find("arm64") and vim.fn.isdirectory(jdtls_path .. "/config_mac_arm") == 1 then
          os_config = "mac_arm"
        end
      elseif vim.fn.has("win32") == 1 then
        os_config = "win"
      end

      local config = {
        cmd = {
          "java",
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.protocol=true",
          "-Dlog.level=ALL",
          "-Xmx1g",
          "--add-modules=ALL-SYSTEM",
          "--add-opens",
          "java.base/java.util=ALL-UNNAMED",
          "--add-opens",
          "java.base/java.lang=ALL-UNNAMED",
          "-javaagent:" .. lombok_path,
          "-jar",
          vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
          "-configuration",
          jdtls_path .. "/config_" .. os_config,
          "-data",
          workspace_dir,
        },

        root_dir = root_dir,

        settings = {
          java = {
            eclipse = {
              downloadSources = true,
            },
            configuration = {
              updateBuildConfiguration = "interactive",
              runtimes = {
                -- Add your Java installations here
                -- {
                --   name = "JavaSE-17",
                --   path = "/usr/lib/jvm/java-17-openjdk",
                -- },
                -- {
                --   name = "JavaSE-21",
                --   path = "/usr/lib/jvm/java-21-openjdk",
                -- },
                {
                  name = "JavaSE-25",
                },
              },
            },
            maven = {
              downloadSources = true,
            },
            implementationsCodeLens = {
              enabled = true,
            },
            referencesCodeLens = {
              enabled = true,
            },
            references = {
              includeDecompiledSources = true,
            },
            format = {
              enabled = false, -- Enable this if you have the google-style.xml file
              -- settings = {
              --   url = vim.fn.stdpath("config") .. "/lang-servers/intellij-java-google-style.xml",
              --   profile = "GoogleStyle",
              -- },
            },
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
            completion = {
              favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.mockito.Mockito.*",
              },
              importOrder = {
                "java",
                "javax",
                "com",
                "org",
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
          },
        },

        flags = {
          allow_incremental_sync = true,
        },

        init_options = {
          bundles = bundles,
        },

        on_attach = function(client, bufnr)
          -- DAP Setup
          if pcall(require, "jdtls.dap") then
            require("jdtls").setup_dap({ hotcodereplace = "auto" })
            require("jdtls.dap").setup_dap_main_class_configs()
          end

          -- Enable codelens
          if client.server_capabilities.codeLensProvider then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = bufnr,
              callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
              end,
            })
          end

          -- Keymaps
          local map = function(mode, keys, func, desc)
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
          end

          map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
          map("n", "<leader>ctc", jdtls.test_class, "Test Class")
          map("n", "<leader>ctm", jdtls.test_nearest_method, "Test Method")
          map("n", "<leader>cv", jdtls.extract_variable, "Extract Variable")
          map("v", "<leader>cv", [[<ESC><CMD>lua require('jdtls').extract_variable(true)<CR>]], "Extract Variable")
          map("n", "<leader>cc", jdtls.extract_constant, "Extract Constant")
          map("v", "<leader>cc", [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]], "Extract Constant")
          map("v", "<leader>cm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], "Extract Method")
          map("n", "<leader>cu", "<CMD>JdtUpdateConfig<CR>", "Update Config")
        end,
      }

      -- Start or attach to jdtls
      jdtls.start_or_attach(config)
    end

    -- Attach to current buffer
    if vim.bo.filetype == "java" then
      attach_jdtls()
    end

    -- Attach to future buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "java",
      callback = attach_jdtls,
    })
  end,
}

