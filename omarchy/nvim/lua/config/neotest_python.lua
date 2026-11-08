-- Extends neotest-python:
-- - Discovers doctests, in projects whose pytest config enables --doctest-modules.
-- - Finds the project root when Neovim was started from a parent folder.
local lib = require("neotest.lib")
local Tree = require("neotest.types").Tree

local M = {}

-- Namespaces are captured so a method's id can include its class name. Functions
-- nested inside functions are skipped because pytest does not collect them.
local query = [[
  (class_definition name: (identifier) @namespace.name) @namespace.definition
  ((function_definition
    name: (identifier) @test.name
    body: (block . (expression_statement (string) @doc))) @test.definition
    (#lua-match? @doc ">>>")
    (#not-has-ancestor? @test.definition function_definition))
]]

local function file_contains(path, text)
  local file = io.open(path, "r")
  if not file then
    return false
  end
  local content = file:read("*a")
  file:close()
  return content:find(text, 1, true) ~= nil
end

local function has_init(dir)
  return vim.uv.fs_stat(dir .. "/__init__.py") ~= nil
end

-- The module name pytest gives a file: its package path, or, outside a package,
-- its dotted path from the project root.
local function module_name(path)
  local dir = vim.fs.dirname(path)
  local stem = vim.fs.basename(path):gsub("%.py$", "")

  if not has_init(dir) then
    local root = require("neotest-python.base").get_root(path)
    local relative = path:sub(#root + 2):gsub("%.py$", "")
    return (relative:gsub("/", "."))
  end

  local parts = stem == "__init__" and {} or { stem }
  while has_init(dir) do
    table.insert(parts, 1, vim.fs.basename(dir))
    dir = vim.fs.dirname(dir)
  end
  return table.concat(parts, ".")
end

-- Matches pytest's doctest node ids, e.g. `<path>::pkg.module.Class.method`.
function M.position_id(position, parents)
  local names = { module_name(position.path) }
  for _, parent in ipairs(parents) do
    names[#names + 1] = parent.name
  end
  names[#names + 1] = position.name
  return position.path .. "::" .. table.concat(names, ".")
end

-- Drops classes with no doctests, so they don't get a button that runs nothing.
local function without_empty_classes(node)
  local kept = { node[1] }
  for i = 2, #node do
    local child = without_empty_classes(node[i])
    if child[1].type == "test" or #child > 1 then
      kept[#kept + 1] = child
    end
  end
  return kept
end

-- Doctest failures arrive as numbered source lines, the expected and actual output,
-- then `<path>:<line>: DocTestFailure`. Keeps the output and moves the error to <line>.
local function tidy_doctest_error(err)
  local line = err.message:match(":(%d+): DocTestFailure%s*$") or err.message:match(":(%d+): UnexpectedException%s*$")
  if not line then
    return
  end
  local kept = {}
  local lines = vim.split(vim.trim(err.message), "\n")
  for i = 1, #lines - 1 do
    if not lines[i]:match("^%d%d%d ") then
      kept[#kept + 1] = lines[i]
    end
  end
  err.message = vim.trim(table.concat(kept, "\n"))
  err.line = tonumber(line) - 1
end

local function tidy_doctest_errors(results)
  for _, result in pairs(results or {}) do
    for _, err in ipairs(result.errors or {}) do
      tidy_doctest_error(err)
    end
  end
  return results
end

---@param adapter table the neotest-python adapter, changed in place
---@return table
function M.wrap(adapter)
  local is_pytest_file = adapter.is_test_file
  local discover_pytest = adapter.discover_positions
  local filter_dir = adapter.filter_dir
  local build_spec = adapter.build_spec
  local results = adapter.results
  local find_root = adapter.root

  -- With no project at or above `dir`, neotest would treat `dir` itself as the
  -- project and miss its .venv, so use the current file's project below `dir`.
  adapter.root = function(dir)
    local root = find_root(dir)
    if root then
      return root
    end
    local file = require("nio").api.nvim_buf_get_name(0)
    local file_root = file ~= "" and find_root(file)
    return file_root and vim.startswith(file_root, dir .. "/") and file_root or nil
  end

  local function doctests_enabled(path)
    local root = find_root(path)
    return root ~= nil
      and (
        file_contains(root .. "/pyproject.toml", "--doctest-modules")
        or file_contains(root .. "/pytest.ini", "--doctest-modules")
      )
  end

  adapter.is_test_file = function(path)
    return is_pytest_file(path) or (vim.endswith(path, ".py") and file_contains(path, ">>>") and doctests_enabled(path))
  end

  adapter.discover_positions = function(path)
    if is_pytest_file(path) then
      return discover_pytest(path)
    end
    local tree = lib.treesitter.parse_positions(path, query, {
      position_id = "require('config.neotest_python').position_id",
    })
    return Tree.from_list(without_empty_classes(tree:to_list()), function(position)
      return position.id
    end)
  end

  adapter.filter_dir = function(name, ...)
    return name ~= ".venv" and filter_dir(name, ...)
  end

  -- A class's id is not a pytest doctest id. Returning nil makes neotest run its
  -- methods one by one instead.
  adapter.build_spec = function(args)
    local position = args.tree:data()
    if position.type == "namespace" and not is_pytest_file(position.path) then
      return nil
    end
    local spec = build_spec(args)
    if not (spec and spec.stream) then
      return spec
    end
    -- Streamed results need tidying too: neotest fixes a diagnostic's line from the
    -- first result it sees for a test.
    local stream = spec.stream
    spec.stream = function(...)
      local next_results = stream(...)
      return function()
        return tidy_doctest_errors(next_results())
      end
    end
    return spec
  end

  adapter.results = function(...)
    return tidy_doctest_errors(results(...))
  end

  return adapter
end

return M
