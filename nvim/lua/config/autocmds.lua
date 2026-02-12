local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end

-- re-read files when nvim regains focus or a terminal closes
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "CursorHold" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd.checktime()
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- equalize splits across all tabs when terminal is resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd.tabnext(current_tab)
  end,
})

-- jump to last cursor position when reopening a file (mark " stores the position)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].config_last_loc then
      return
    end
    vim.b[buf].config_last_loc = true -- guard against re-triggering on the same buffer
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- map q to close transient/info buffers and hide them from buffer list
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = augroup("close_with_q"),
  callback = function(event)
    local patterns = {
      "ClangdAST",
      "ClangdTypeHierarchy",
      "checkhealth",
      "git",
      "gitsigns-blame",
      "help",
      "lspinfo",
      "neotest-output",
      "neotest-output-panel",
      "neotest-summary",
      "notify",
      "qf",
      "startuptime",
    }
    local ft = vim.bo[event.buf].filetype
    if vim.tbl_contains(patterns, ft) then
      vim.bo[event.buf].buflisted = false
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(event.buf) then
          vim.keymap.set("n", "q", function()
            vim.cmd.close()
            if not ft:match("neotest") then -- neotest manages its own buffers
              pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
            end
          end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup("term_close_q"),
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = ev.buf,
      silent = true,
      nowait = true,
    })
  end,
})

-- hide man pages from buffer list so :bnext/:bprev skip them
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap"),
  pattern = { "text", "plaintex", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("spellcheck"),
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0 -- don't hide quotes in JSON
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("snacks_dashboard"),
  pattern = { "snacks_dashboard" },
  callback = function()
    vim.opt_local.ruler = false
    vim.opt_local.showcmd = false
  end,
})

-- auto-create parent directories when saving to a new path
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then -- skip plugin URLs (oil://, fugitive://, etc.)
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fs.dirname(file), "p")
  end,
})
