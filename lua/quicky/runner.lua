local Job = require "plenary.job"

local R = {}

---@param action string
---@param path Path
---@param session_name string
R.run = function(action, path, session_name)
    local curName
    Job:new({
        command = "tmux",
        args = { "display-message", "-p", "#W" },
        on_stdout = function(_, data)
            curName = data
        end,
    }):sync()
    local sess_exists
    Job:new({
        command = "tmux",
        args = { "new-session", "-ds", session_name, "-n", curName },
        on_exit = function(_, code, _)
            sess_exists = code ~= 0
        end,
    }):sync()
    local pane_id
    Job:new({
        command = "tmux",
        args = {
            "list-windows",
            "-t",
            session_name,
            "-f",
            "#{==:#{window_name}," .. curName .. "}",
            "-F",
            "#{pane_id}",
        },
        on_stdout = function(_, data)
            pane_id = data
        end,
    }):sync()

    local location = session_name .. ":" .. curName
    if not pane_id then
        Job:new({
            command = "tmux",
            args = {
                "new-window",
                "-n",
                curName,
                "-t",
                session_name,
                "-P",
                "-F",
                "#{pane_id}",
            },
        }):sync()
    elseif sess_exists then
        Job:new({
            command = "tmux",
            args = {
                "send-keys",
                "-t",
                location,
                "C-c",
            },
        }):sync()
    end

    Job:new({
        command = "tmux",
        args = { "send-keys", "-t", location, "cd " .. path, "C-m" },
    }):sync()
    Job:new({
        command = "tmux",
        args = { "send-keys", "-t", location, action, "C-m" },
    }):sync()
    Job:new({
        command = "tmux",
        args = { "select-window", "-t", location },
    }):sync()
    Job:new({
        command = "tmux",
        args = { "switch-client", "-t", session_name },
    }):sync()
end

return R
