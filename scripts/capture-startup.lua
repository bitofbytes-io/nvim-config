-- Loaded with --cmd, before init.lua or any plugin can report a problem.
local failures = {}
_G.startup_smoke = { failures = failures }
local function record(kind, message)
  failures[#failures + 1] = kind .. ': ' .. tostring(message)
end

local function capture_notifications()
  local notify = vim.notify
  if notify == _G.startup_smoke.notify then
    return
  end
  local wrapper = function(message, level, opts)
    if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
      record('notification', message)
    end
    return notify(message, level, opts)
  end
  _G.startup_smoke.notify = wrapper
  vim.notify = wrapper
end
capture_notifications()
-- nvim-notify replaces vim.notify during VeryLazy. Reattach after plugin config.
vim.api.nvim_create_autocmd('User', { pattern = { 'LazyLoad', 'VeryLazy' }, callback = capture_notifications })

local deprecate = vim.deprecate
vim.deprecate = function(name, ...)
  record('deprecated API', name)
  return deprecate(name, ...)
end

-- Capture native error/warning messages, including Lua callback failures.
vim.ui_attach(vim.api.nvim_create_namespace 'startup-smoke', { ext_messages = true }, function(event, kind, chunks)
  if event == 'msg_show' and (kind == 'emsg' or kind == 'echoerr' or kind == 'wmsg' or kind == 'lua_error' or kind == 'rpc_error' or kind == 'shell_err') then
    local message = {}
    for _, chunk in ipairs(chunks) do
      message[#message + 1] = chunk[2]
    end
    record(kind, table.concat(message))
  end
  -- Do not consume or hide messages.
end)
