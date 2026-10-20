-- Keep Neovim's event loop alive through VeryLazy and delayed installer work.
vim.schedule(function()
  local ok, err = pcall(function()
    local registry = require 'mason-registry'
    -- Wait at least five seconds: mason-tool-installer has a three-second delay.
    vim.wait(5000, function()
      return false
    end, 50)
    local settled = dofile 'scripts/wait-mason.lua'(registry, { 'js-debug-adapter', 'delve' }, 85000)
    assert(settled, 'Mason installers did not finish within the startup deadline')
    for _, name in ipairs { 'js-debug-adapter', 'delve' } do
      assert(registry.get_package(name):is_installed(), 'Missing Mason adapter: ' .. name)
    end
    assert(vim.fn.executable 'node' == 1, 'Node.js is not executable')
    local dap = require 'dap'
    for _, name in ipairs { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' } do
      assert(dap.adapters[name], 'JavaScript DAP adapter not registered: ' .. name)
    end
    dofile 'scripts/check-js-dap.lua'()
    assert(vim.v.errmsg == '', vim.v.errmsg)
  end)
  if not ok then
    table.insert(startup_smoke.failures, tostring(err))
  end
  -- Optional probes prove the capture remains active after VeryLazy.
  if vim.env.NVIM_SMOKE_INJECT == 'warning' then
    vim.notify('injected startup warning', vim.log.levels.WARN)
  elseif vim.env.NVIM_SMOKE_INJECT == 'string-warning' then
    vim.notify('injected startup string-warning', 'warn')
  elseif vim.env.NVIM_SMOKE_INJECT == 'string-error' then
    vim.notify('injected startup string-error', 'ERROR')
  elseif vim.env.NVIM_SMOKE_INJECT == 'error' then
    vim.schedule(function()
      error 'injected startup error'
    end)
  end
  vim.defer_fn(function()
    vim.fn.writefile(startup_smoke.failures, vim.env.NVIM_SMOKE_REPORT)
    if #startup_smoke.failures > 0 then
      for _, failure in ipairs(startup_smoke.failures) do
        io.stderr:write(failure .. '\n')
      end
      vim.cmd 'cquit 1'
    else
      io.stdout:write 'Startup smoke passed: no warnings/errors; Mason JavaScript DAP initialize handshake passed\n'
      vim.cmd 'qa!'
    end
  end, 1000)
end)
