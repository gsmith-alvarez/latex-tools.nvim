-- Resolve vim.pack opt plugins (e.g. ~/.local/share/nvim/site/pack/core/opt/LuaSnip).
local M = {}

local opt_root = vim.fn.expand('~/.local/share/nvim/site/pack/core/opt')

---@param name string pack directory name under pack/core/opt
---@return string|nil absolute path if present
function M.opt_path(name)
  local path = opt_root .. '/' .. name
  if vim.uv.fs_stat(path) then
    return path
  end
end

---@param name string
---@return boolean loaded
function M.prepend_opt(name)
  local path = M.opt_path(name)
  if path then
    vim.opt.rtp:prepend(path)
    return true
  end
  return false
end

return M
