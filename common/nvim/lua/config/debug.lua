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

function M.parse_args(input)
  local args, current = {}, {}
  local quote = nil
  local escaped = false
  local started = false

  local function finish_arg()
    if started then
      args[#args + 1] = table.concat(current)
      current = {}
      started = false
    end
  end

  for i = 1, #input do
    local char = input:sub(i, i)
    if escaped then
      current[#current + 1] = char
      escaped = false
      started = true
    elseif char == "\\" and quote ~= "'" then
      escaped = true
      started = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        current[#current + 1] = char
      end
      started = true
    elseif char == "'" or char == '"' then
      quote = char
      started = true
    elseif char:match("%s") then
      finish_arg()
    else
      current[#current + 1] = char
      started = true
    end
  end

  if escaped then
    return nil, "trailing escape in arguments"
  end
  if quote then
    return nil, "unterminated " .. quote .. " quote in arguments"
  end

  finish_arg()
  return args
end

function M.prompt_args()
  while true do
    local args, err = M.parse_args(vim.fn.input("Args: "))
    if args then
      return args
    end
    vim.notify(err, vim.log.levels.ERROR)
  end
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

local function executable_candidates()
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
  local candidates, fallback = executable_candidates()
  return candidates[1] or fallback
end

function M.prompt_executable()
  return vim.fn.input("Executable: ", M.suggest_executable(), "file")
end

local function standalone_build()
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

function M.build_and_debug()
  vim.cmd.write()
  local plan = M.build_plan() or standalone_build()
  if not plan then
    vim.notify("Build and debug supports C and C++ buffers", vim.log.levels.WARN)
    return
  end

  local function run(index)
    local command = plan.commands[index]
    if not command then
      vim.schedule(function()
        require("dap").run({
          name = "Build and debug",
          type = "gdb",
          request = "launch",
          program = M.prompt_executable,
          cwd = plan.root,
          stopAtBeginningOfMainSubprogram = false,
        })
      end)
      return
    end

    vim.system(command, { cwd = plan.root, text = true }, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          local output = vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
          vim.notify("Build failed\n" .. output, vim.log.levels.ERROR)
        end)
        return
      end
      run(index + 1)
    end)
  end

  vim.notify("Building before debug…", vim.log.levels.INFO)
  run(1)
end

return M
