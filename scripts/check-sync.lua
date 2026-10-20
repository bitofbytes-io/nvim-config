-- Lazy! waits for tasks, but a failed clone/build must also fail the process.
for name, plugin in pairs(require('lazy.core.config').plugins) do
  for _, task in ipairs(plugin._.tasks or {}) do
    if task:has_errors() then
      io.stderr:write(name .. ': ' .. task:output() .. '\n')
      vim.cmd 'cquit 1'
    end
  end
end
