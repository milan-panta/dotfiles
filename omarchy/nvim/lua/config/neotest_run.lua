-- Starting tests from a key, safely right after a file opens.
local M = {}

local started = false

function M.mark_started()
  started = true
end

-- A run requested during discovery reports "No tests found", so wait for discovery.
-- The limit keeps a failed start from swallowing the keypress.
function M.when_started(fn)
  require("nio").run(function()
    for _ = 1, 600 do
      if started then
        break
      end
      require("nio").sleep(50)
    end
    vim.schedule(fn)
  end)
end

local gtest_configured = false

-- neotest-gtest needs to know which binary holds each test. CTest knows, so ask it once.
local function configure_gtest(then_run)
  if gtest_configured then
    return then_run()
  end
  gtest_configured = true
  local ok, ctest = pcall(require, "neotest-gtest.executables.ctest")
  if not ok then
    return then_run()
  end
  ctest.configure_all():wait()
  then_run()
end

-- C and C++ tests run the built binary, so build first, as an IDE does.
function M.run(args)
  local ft = vim.bo.filetype
  M.when_started(function()
    if ft ~= "c" and ft ~= "cpp" then
      require("neotest").run.run(args)
      return
    end
    require("config.build").build_project(function()
      require("nio").run(function()
        configure_gtest(function()
          require("neotest").run.run(args)
        end)
      end)
    end)
  end)
end

return M
