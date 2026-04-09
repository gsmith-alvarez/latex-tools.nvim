-- [[ MATRIX: lua/latex-tools/matrix.lua ]]
-- =============================================================================
-- Purpose: Smart Enter behavior inside LaTeX matrix-like environments.
-- Domain:  Editing / Snippets / Scientific Notetaking
--
-- Architecture: Provides M.handle_enter() for integration with the main CR
--               keymap chain. When inside environments like `pmatrix`, `align`,
--               or `cases`, Enter inserts ` \\ ` (row separator).
--
-- Maintenance:
-- 1. Add new environments to MATRIX_ENVS in context.lua (not here).
-- 2. Enter integration happens in autolist.lua CR keymap chain.
-- =============================================================================

local M = {}
local context = require 'latex-tools.context'

-- =============================================================================
-- ENTER HANDLER: Row Separator ( \\ + newline )
-- =============================================================================

--- Handle Enter key in matrix environments.
--- Returns (true, ' \\ ') if in matrix, (false, nil) otherwise.
--- Called by autolist.lua's CR handler.
--- @return boolean handled
--- @return string|nil keys
function M.handle_enter()
  local in_matrix, _ = context.is_in_matrix_env()
  if in_matrix then
    return true, ' \\\\ '
  end
  return false, nil
end

--- Setup matrix module (config stored for future use).
--- @param config table Plugin configuration
function M.setup(config)
  M.config = config
end

return M
