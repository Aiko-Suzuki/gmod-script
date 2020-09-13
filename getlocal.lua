-- Function to get local var from current thread
function _Local()
    local locals = {}
    local i = 1

    while (true) do
        name, value = debug.getlocal(2, i)
        if (name == nil) then break end
        if name ~= "(*temporary)" then
            locals[name] = value == nil or value
        end

        i = i + 1
    end

    return locals
end

-- little example

local Book_1 = {"test1", "test2"}
local Book_2 = {"test4", "test3"}
local bibli = {}

local yeet = _Local()

for i = 1, 99 do
    if yeet["Book_" .. i] == nil then break end
    table.insert(bibli, yeet["Book_" .. i])
end

PrintTable(bibli)
