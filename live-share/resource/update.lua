local condition = require'cqueues.condition'
local EventStream = require'live-share.EventStream'
local server = require'live-share.server'


local update_resource = {}

local event_condition = condition.new()
local observer_events = {}

function update_resource.notify_observers(type, data)
    local event = {type = type, data = data}
    for _, event_list in pairs(observer_events) do
        table.insert(event_list, event)
    end
    event_condition:signal()
end

server.router:get('/updates', function(p)
    local stream = p.stream
    local connection = stream.connection
    local socket = connection.socket

    local event_stream = EventStream(p)

    local event_list = {}
    observer_events[event_stream] = event_list -- event_stream doubles as unique key

    while true do
        local condition_signaled, socket_signaled = event_condition:wait(socket)

        if condition_signaled then
            print'condition'
        end

        if socket_signaled then
            print'socket'
            break -- TODO: Is this the solution?
        end

        if socket:eof'r' then
            print'remote closed in meantime'
            break
        end

        if condition_signaled then
            -- process list
            for _, event in ipairs(event_list) do
                event_stream:send_json(event.type, event.data)
            end

            -- clear list
            for i = #event_list, 1, -1 do
                event_list[i] = nil
            end
        end
    end

    observer_events[event_stream] = nil

    event_stream:close()
end)

return update_resource
