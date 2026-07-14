-- Turn escaped \n and \t (e.g. in JSON log dumps) into real newlines and tabs.
-- Defaults to the current line like :s; use :%Unescape for the whole buffer,
-- or select lines in visual mode.
vim.api.nvim_create_user_command("Unescape", function(opts)
    local range = opts.line1 .. "," .. opts.line2
    -- \t first (keeps line count); \n last since it splits lines and would
    -- otherwise push text outside the precomputed range.
    vim.cmd("silent! " .. range .. "s/\\\\t/\\t/g")
    vim.cmd("silent! " .. range .. "s/\\\\n/\\r/g")
end, { range = true })
