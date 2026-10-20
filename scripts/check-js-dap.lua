-- Exercise nvim-dap's actual server launch, port substitution, TCP transport,
-- and DAP framing against Mason's installed adapter, without a debuggee.
return function()
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
