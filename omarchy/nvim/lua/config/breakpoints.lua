-- Breakpoints that survive restarts and can be switched off without losing their
-- condition, plus IDE-style gutter clicks.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Debug" })
end

local store_file = vim.fn.stdpath("state") .. "/dap-breakpoints.json"
local disabled_group = "dap_disabled"
local disabled = {} -- bufnr -> sign id -> { condition, hitCondition, logMessage }
local store -- path -> list of saved breakpoints

local function read_store()
  if store then
    return store
  end
  local read_ok, lines = pcall(vim.fn.readfile, store_file)
  local decode_ok, decoded = pcall(vim.json.decode, read_ok and table.concat(lines, "\n") or "")
  store = decode_ok and type(decoded) == "table" and decoded or {}
  return store
end

local function disabled_at(buf, line)
  local placed = vim.fn.sign_getplaced(buf, { group = disabled_group, lnum = line })[1]
  local sign = placed and placed.signs[1]
  if sign and disabled[buf] then
    return sign.id, disabled[buf][sign.id]
  end
end

local function breakpoint_at(buf, line)
  for _, bp in ipairs(require("dap.breakpoints").get(buf)[buf] or {}) do
    if bp.line == line then
      return bp
    end
  end
end

local function disable_sign(buf, line, opts)
  local id = vim.fn.sign_place(0, disabled_group, "DapBreakpointDisabled", buf, { lnum = line, priority = 21 })
  disabled[buf] = disabled[buf] or {}
  disabled[buf][id] = opts
end

function M.save_breakpoints()
  local breakpoints = package.loaded["dap.breakpoints"]
  if not breakpoints then
    return
  end
  -- Re-read first: another Neovim may have saved its files' breakpoints since.
  store = nil
  local all = read_store()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and path ~= "" then
      local saved = {}
      for _, bp in ipairs(breakpoints.get(buf)[buf] or {}) do
        saved[#saved + 1] =
          { line = bp.line, condition = bp.condition, hitCondition = bp.hitCondition, logMessage = bp.logMessage }
      end
      local placed = vim.fn.sign_getplaced(buf, { group = disabled_group })[1]
      for _, sign in ipairs(placed and placed.signs or {}) do
        local opts = (disabled[buf] or {})[sign.id] or {}
        saved[#saved + 1] = {
          line = sign.lnum,
          condition = opts.condition,
          hitCondition = opts.hitCondition,
          logMessage = opts.logMessage,
          disabled = true,
        }
      end
      all[path] = #saved > 0 and saved or nil
    end
  end
  vim.fn.mkdir(vim.fs.dirname(store_file), "p")
  vim.fn.writefile({ vim.json.encode(all) }, store_file)
end

-- nvim-dap draws a hit-count breakpoint as a plain one, so give it the condition sign.
local function mark_hit_count(buf, line)
  local placed = vim.fn.sign_getplaced(buf, { group = "dap_breakpoints", lnum = line })[1]
  local sign = placed and placed.signs[1]
  if sign then
    vim.fn.sign_place(sign.id, "dap_breakpoints", "DapBreakpointCondition", buf, { lnum = line, priority = 21 })
  end
end

-- Restores a file's breakpoints when it opens. Files with none don't load nvim-dap.
function M.restore_breakpoints(buf)
  local saved = read_store()[vim.api.nvim_buf_get_name(buf)]
  if not saved then
    return
  end
  local breakpoints = require("dap.breakpoints")
  local count = vim.api.nvim_buf_line_count(buf)
  for _, bp in ipairs(saved) do
    if bp.line <= count then
      if bp.disabled then
        disable_sign(buf, bp.line, bp)
      else
        breakpoints.set(
          { condition = bp.condition, hit_condition = bp.hitCondition, log_message = bp.logMessage },
          buf,
          bp.line
        )
        if bp.hitCondition then
          mark_hit_count(buf, bp.line)
        end
      end
    end
  end
end

function M.toggle_breakpoint()
  local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
  local id = disabled_at(buf, line)
  if id then
    vim.fn.sign_unplace(disabled_group, { buffer = buf, id = id })
    disabled[buf][id] = nil
  else
    require("dap").toggle_breakpoint()
  end
  M.save_breakpoints()
end

-- Switches the breakpoint on this line off or on, keeping its condition.
function M.toggle_enabled()
  local dap = require("dap")
  local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
  local id, opts = disabled_at(buf, line)
  if id then
    vim.fn.sign_unplace(disabled_group, { buffer = buf, id = id })
    disabled[buf][id] = nil
    opts = opts or {}
    dap.set_breakpoint(opts.condition, opts.hitCondition, opts.logMessage)
  else
    local bp = breakpoint_at(buf, line)
    if not bp then
      notify("No breakpoint on this line", vim.log.levels.WARN)
      return
    end
    dap.toggle_breakpoint()
    disable_sign(buf, line, { condition = bp.condition, hitCondition = bp.hitCondition, logMessage = bp.logMessage })
  end
  M.save_breakpoints()
end

-- field is "condition", "hitCondition" or "logMessage". Empty input keeps what was there.
local function edit_breakpoint(field, prompt)
  local dap = require("dap")
  local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
  local bp = breakpoint_at(buf, line) or {}
  vim.ui.input({ prompt = prompt, default = bp[field] }, function(input)
    if not input or input == "" then
      return
    end
    local new = { condition = bp.condition, hitCondition = bp.hitCondition, logMessage = bp.logMessage }
    new[field] = input
    vim.api.nvim_win_set_cursor(0, { line, vim.fn.col(".") - 1 })
    dap.set_breakpoint(new.condition, new.hitCondition, new.logMessage)
    if new.hitCondition and not new.condition and not new.logMessage then
      mark_hit_count(buf, line)
    end
    M.save_breakpoints()
  end)
end

function M.set_condition()
  edit_breakpoint("condition", "Break when: ")
end

function M.set_hit_count()
  edit_breakpoint("hitCondition", "Break after this many hits: ")
end

function M.set_log_message()
  edit_breakpoint("logMessage", "Log message, {expr} for values: ")
end

-- Every breakpoint action for this line, for the right-click menu.
function M.breakpoint_menu()
  local actions = {
    { "Condition…", M.set_condition },
    { "Hit count…", M.set_hit_count },
    { "Log message…", M.set_log_message },
    { "Disable or enable", M.toggle_enabled },
    { "Add or remove", M.toggle_breakpoint },
  }
  vim.ui.select(actions, {
    prompt = "Breakpoint",
    format_item = function(item)
      return item[1]
    end,
  }, function(choice)
    if choice then
      choice[2]()
    end
  end)
end

-- Clicks in the gutter, IDE style. key is "<LeftMouse>" or "<RightMouse>".
-- A test's ▶ runs it (left) or debugs it (right). The line number toggles a breakpoint
-- (left) or opens the breakpoint menu (right). Every other click is unchanged.
function M.gutter_click(key)
  local mouse = vim.fn.getmousepos()
  local win = vim.fn.getwininfo(mouse.winid)[1]
  if not win or win.textoff == 0 or mouse.wincol > win.textoff or mouse.line == 0 then
    return key
  end
  local buf = win.bufnr
  local left = key == "<LeftMouse>"
  local function place_cursor()
    vim.api.nvim_set_current_win(mouse.winid)
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
  end

  -- The sign column is the first two cells; the line number comes after it.
  local in_signs = mouse.wincol <= 2
  if in_signs then
    local placed = vim.fn.sign_getplaced(buf, { group = "neotest-status", lnum = mouse.line })
    if #placed > 0 and #placed[1].signs > 0 then
      vim.schedule(function()
        place_cursor()
        require("config.neotest_run").run(not left and { strategy = "dap" } or nil)
      end)
      return "<Ignore>"
    end
  end

  if vim.bo[buf].buftype ~= "" then
    return key
  end
  local dap_loaded = package.loaded["dap.breakpoints"] ~= nil
  local has_bp = dap_loaded and (breakpoint_at(buf, mouse.line) or disabled_at(buf, mouse.line))
  if in_signs and not has_bp then
    return key
  end
  vim.schedule(function()
    place_cursor()
    if left then
      M.toggle_breakpoint()
    else
      M.breakpoint_menu()
    end
  end)
  return "<Ignore>"
end

return M
