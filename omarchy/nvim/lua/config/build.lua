-- Builds C/C++ projects (CMake, Meson, Make, Ninja) or a single file, and finds the
-- programs a build made. Used by debugging, test runs and <leader>bp.

local M = {}

local build_markers = { "CMakeLists.txt", "meson.build", "Makefile", "makefile", "build.ninja" }
local cpu_count = tostring(#vim.uv.cpu_info())

local function current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function is_file(path)
  local stat = path and vim.uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function is_executable(path)
  return is_file(path) and vim.fn.executable(path) == 1
end

local function shell_join(command)
  return table.concat(
    vim.tbl_map(function(part)
      return vim.fn.shellescape(part)
    end, command),
    " "
  )
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Build" })
end

function M.build_plan()
  local file = current_file()
  local start = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
  local root = vim.fs.root(start, build_markers)
  if not root then
    return nil
  end

  local build = vim.fs.joinpath(root, "build")
  if is_file(vim.fs.joinpath(root, "CMakeLists.txt")) then
    local commands = {}
    if not is_file(vim.fs.joinpath(build, "CMakeCache.txt")) then
      commands[#commands + 1] = { "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Debug" }
    end
    commands[#commands + 1] = { "cmake", "--build", "build", "--parallel", cpu_count }
    return { root = root, commands = commands, name = "CMake" }
  end

  if is_file(vim.fs.joinpath(root, "meson.build")) then
    local commands = {}
    if not is_file(vim.fs.joinpath(build, "build.ninja")) then
      commands[#commands + 1] = { "meson", "setup", "build", "--buildtype=debug" }
    end
    commands[#commands + 1] = { "meson", "compile", "-C", "build" }
    return { root = root, commands = commands, name = "Meson" }
  end

  if is_file(vim.fs.joinpath(root, "Makefile")) or is_file(vim.fs.joinpath(root, "makefile")) then
    return { root = root, commands = { { "make", "-j" .. cpu_count } }, name = "Make" }
  end

  return { root = root, commands = { { "ninja", "-j" .. cpu_count } }, name = "Ninja" }
end

function M.build_shell_command()
  local plan = M.build_plan()
  if not plan then
    return nil
  end

  local commands = vim.tbl_map(shell_join, plan.commands)
  return "cd " .. vim.fn.shellescape(plan.root) .. " && " .. table.concat(commands, " && "), plan.name
end

function M.executable_candidates()
  local file = current_file()
  local stem = vim.fn.fnamemodify(file, ":t:r")
  local source_output = vim.fn.fnamemodify(file, ":r")
  local plan = M.build_plan()
  local root = plan and plan.root or vim.uv.cwd()
  local build = vim.fs.joinpath(root, "build")
  local candidates = {
    source_output,
    vim.fs.joinpath(root, stem),
    vim.fs.joinpath(build, stem),
    vim.fs.joinpath(build, "bin", stem),
  }

  local seen, result = {}, {}
  local function add(path)
    path = path and vim.fs.normalize(path)
    if path and not seen[path] and is_executable(path) then
      seen[path] = true
      result[#result + 1] = path
    end
  end
  for _, path in ipairs(candidates) do
    add(path)
  end

  if vim.uv.fs_stat(build) then
    local discovered = vim.fs.find(function(_, path)
      return not path:find("CMakeFiles", 1, true)
    end, { path = build, type = "file", limit = 200 })
    table.sort(discovered, function(a, b)
      local a_stat, b_stat = vim.uv.fs_stat(a), vim.uv.fs_stat(b)
      return (a_stat and a_stat.mtime.sec or 0) > (b_stat and b_stat.mtime.sec or 0)
    end)
    for _, path in ipairs(discovered) do
      add(path)
    end
  end

  return result, source_output
end

function M.suggest_executable()
  local candidates, fallback = M.executable_candidates()
  return candidates[1] or fallback
end

function M.prompt_executable()
  return vim.fn.input("Executable: ", M.suggest_executable(), "file")
end

-- A one-file build when there's no project.
function M.standalone_build()
  local file = current_file()
  local output = vim.fn.fnamemodify(file, ":r")
  if vim.bo.filetype == "c" then
    return { root = vim.fs.dirname(file), commands = { { "gcc", "-Wall", "-g", "-std=gnu99", file, "-o", output } } }
  end
  if vim.bo.filetype == "cpp" then
    return {
      root = vim.fs.dirname(file),
      commands = { { "g++", "-g", "-std=c++23", "-Wall", "-Wextra", "-Wpedantic", file, "-o", output } },
    }
  end
end

local function show_build_failure(output)
  vim.fn.setqflist({}, " ", { title = "Build failed", lines = vim.split(output, "\n", { trimempty = true }) })
  local first = vim.tbl_filter(function(item)
    return item.valid == 1
  end, vim.fn.getqflist())[1]
  notify("Build failed: " .. (first and first.text or vim.split(output, "\n")[1] or ""), vim.log.levels.ERROR)
  vim.cmd("botright copen")
end

-- Runs a plan's commands in order; a failure fills the quickfix list instead of calling on_done.
function M.run_commands(plan, on_done)
  local function step(index)
    local command = plan.commands[index]
    if not command then
      vim.schedule(on_done)
      return
    end
    vim.system(command, { cwd = plan.root, text = true }, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          show_build_failure((result.stdout or "") .. "\n" .. (result.stderr or ""))
        end)
        return
      end
      step(index + 1)
    end)
  end
  notify("Building " .. (plan.name or vim.fs.basename(current_file())) .. "…")
  step(1)
end

-- Builds the current file's CMake/Meson/Make/Ninja project, then calls on_done.
-- Without a project it calls on_done straight away.
function M.build_project(on_done)
  local plan = M.build_plan()
  if not plan then
    on_done()
    return
  end
  M.run_commands(plan, on_done)
end

return M
