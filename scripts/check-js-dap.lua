-- Exercise nvim-dap's actual server launch, port substitution, TCP transport,
-- and DAP framing against Mason's installed adapter, without a debuggee.
return function()
  -- Exercise Windows path assembly without pretending to run a Windows binary.
  -- Both arguments contain spaces and must stay unquoted, separate argv values.
  local windows = require('custom.js_debug').executable('C:/Users/Test User/AppData/Local/nvim-data/mason', 'C:/Program Files/nodejs/node.exe')
  assert(windows.command == 'C:/Program Files/nodejs/node.exe', 'Windows DAP must launch the native Node executable')
  assert(
    vim.deep_equal(windows.args, {
      'C:/Users/Test User/AppData/Local/nvim-data/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js',
      '${port}',
      '127.0.0.1',
    }),
    'Windows DAP must pass the script, port, and host as separate arguments'
  )
  assert(windows.detached == false, 'Windows DAP server must retain process cleanup')
  io.stdout:write 'Windows JavaScript DAP path/argv regression: passed (not native Windows execution)\n'
  local adapter = require('dap').adapters['pwa-node']
  local session
  local done, failure, capabilities
  local ok, err = pcall(function()
    assert(type(adapter) == 'table' and adapter.type == 'server', 'Expected a native JavaScript DAP server adapter')
    session = require('dap.session').connect(
      adapter,
      { type = 'pwa-node', name = 'startup-handshake', request = 'launch' },
      {},
      vim.schedule_wrap(function(connect_error)
        if connect_error then
          failure = 'JavaScript DAP connection failed: ' .. tostring(connect_error)
          done = true
          return
        end
        session:request('initialize', {
          clientID = 'neovim-smoke',
          adapterID = 'pwa-node',
          pathFormat = 'path',
          linesStartAt1 = true,
          columnsStartAt1 = true,
        }, function(request_error, response)
          failure = request_error and ('JavaScript DAP initialize failed: ' .. tostring(request_error)) or nil
          capabilities = response
          done = true
        end)
      end)
    )
    assert(
      vim.wait(10000, function()
        return done == true
      end, 10),
      'JavaScript DAP initialize timed out after 10 seconds'
    )
    assert(not failure, failure)
    assert(type(capabilities) == 'table' and capabilities.supportsConfigurationDoneRequest == true, 'JavaScript DAP returned invalid initialize capabilities')
  end)
  -- Session.close terminates its server executable on success, failure, or timeout.
  -- detached=false also lets the Python harness kill the process group on timeout.
  if session then
    session:close()
  end
  assert(ok, err)
  io.stdout:write 'JavaScript DAP initialize: success (native server, allocated port, explicit loopback)\n'
end
