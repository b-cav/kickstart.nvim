-- This file defines a global keymap in Normal mode ('n') to toggle LSP Inlay Hints
-- using the 'T' key.

-- This new section creates a buffer-local variable to track the hint state,
-- as vim.lsp.inlay_hint.is_enabled() can sometimes be unreliable.
local inlay_state_group = vim.api.nvim_create_augroup('InlayHintStateTracker', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = inlay_state_group,
  pattern = '*',
  callback = function()
    -- Default inlay hints to OFF for new buffers.
    -- vim.b.inlay_hints_enabled tracks our desired state.
    if vim.b.inlay_hints_enabled == nil then
      vim.b.inlay_hints_enabled = false
    end
  end,
})

vim.keymap.set('n', 'T', function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if any attached LSP client supports the 'textDocument/inlayHint' method
  local supported = false
  for _, client in pairs(vim.lsp.get_active_clients { bufnr = bufnr }) do
    if client and client.supports_method 'textDocument/inlayHint' then
      supported = true
      break
    end
  end

  if supported then
    -- MODIFIED LOGIC:
    -- Toggle state based on our buffer variable, not by checking is_enabled()
    local new_state = not vim.b.inlay_hints_enabled
    vim.lsp.inlay_hint.enable(new_state, { bufnr = bufnr })
    vim.b.inlay_hints_enabled = new_state -- Save the new state

    -- Optional: Display a message in the command line for confirmation
    local state_msg = new_state and 'ENABLED' or 'DISABLED'
    print('LSP Inlay Hints ' .. state_msg .. ' for buffer ' .. bufnr)
  else
    -- Notify the user if the feature isn't available.
    print(
      'Inlay Hints: No active LSP client found for buffer ' .. bufnr .. ', or attached client does not support the feature (e.g., clangd needs to be active).'
    )
  end
end, {
  noremap = true,
  silent = true,
  desc = 'Toggle LSP Inlay Hints (T)',
})
