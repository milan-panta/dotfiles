local M = {}

function M.add(a, b)
  return a + b
end

local total = M.add(1, 2)
print(total)

return M
