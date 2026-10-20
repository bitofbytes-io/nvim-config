-- Unit check of normalization and transparent forwarding. The full startup
-- probes separately exercise the real notification plugin after VeryLazy.
local forwarded
local response = {}
vim.notify = function(...)
  forwarded = { n = select('#', ...), ... }
  return response, 'original result'
end
dofile 'scripts/capture-startup.lua'

local options = { title = 'capture regression' }
local function check(level, should_capture)
  local before = #startup_smoke.failures
  local result, second = vim.notify('capture regression', level, options)
  assert(result == response and second == 'original result', 'Notify return values changed')
  assert(forwarded.n == 3 and forwarded[1] == 'capture regression' and forwarded[2] == level and forwarded[3] == options, 'Notify arguments changed')
  assert(#startup_smoke.failures == before + (should_capture and 1 or 0), 'Incorrect notification severity capture')
end
check(vim.log.levels.WARN, true)
check(vim.log.levels.ERROR, true)
check('warn', true)
check('WaRn', true)
check('ERROR', true)
check('info', false)
check(nil, false)
check('unknown-level', false)
check(false, false)
check({}, false)
io.stdout:write 'Notification string levels, unexpected levels, and unchanged arguments/results: passed\n'
