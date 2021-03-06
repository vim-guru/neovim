
local helpers = require('test.functional.helpers')
local clear, nvim, eq, neq, ok, expect, eval, next_message, run, stop, session
  = helpers.clear, helpers.nvim, helpers.eq, helpers.neq, helpers.ok,
  helpers.expect, helpers.eval, helpers.next_message, helpers.run,
  helpers.stop, helpers.session

local channel = nvim('get_api_info')[1]

describe('jobs', function()
  before_each(clear)

  -- Creates the string to make an autocmd to notify us.
  local notify_str = function(expr)
    return "au! JobActivity xxx call rpcnotify("..channel..", "..expr..")"
  end

  it('returns 0 when it fails to start', function()
    local status, rv = pcall(eval, "jobstart('', '')")
    eq(false, status)
    ok(rv ~= nil)
  end)

  it('calls JobActivity when the job writes and exits', function()
    nvim('command', notify_str('v:job_data[1]'))
    nvim('command', "call jobstart('xxx', 'echo')")
    eq({'notification', 'stdout', {}}, next_message())
    eq({'notification', 'exit', {}}, next_message())
  end)

  it('allows interactive commands', function()
    nvim('command', notify_str('v:job_data[2]'))
    nvim('command', "let j = jobstart('xxx', 'cat', ['-'])")
    neq(0, eval('j'))
    nvim('command', "call jobsend(j, 'abc')")
    eq({'notification', 'abc', {}}, next_message())
    nvim('command', "call jobsend(j, '123')")
    eq({'notification', '123', {}}, next_message())
    nvim('command', notify_str('v:job_data[1])'))
    nvim('command', "call jobstop(j)")
    eq({'notification', 'exit', {}}, next_message())
  end)

  it('will not allow jobsend/stop on a non-existent job', function()
    eq(false, pcall(eval, "jobsend(-1, 'lol')"))
    eq(false, pcall(eval, "jobstop(-1, 'lol')"))
  end)

  it('will not allow jobstop twice on the same job', function()
    nvim('command', "let j = jobstart('xxx', 'cat', ['-'])")
    neq(0, eval('j'))
    eq(true, pcall(eval, "jobstop(j)"))
    eq(false, pcall(eval, "jobstop(j)"))
  end)

  it('will not cause a memory leak if we leave a job running', function()
    nvim('command', "call jobstart('xxx', 'cat', ['-'])")
  end)
end)
