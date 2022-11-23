local test_feature = {}
local TDR:TDR = _G.TDR
test_feature.__index = test_feature

function test_feature.init()
    local self:Feature = setmetatable(test_feature,{})

    TDR.conCommand("test_command",function(Args)
        local a = ""
        for _,v in pairs(Args) do
            a = a..v
        end

        return a
    end)

    return self
end

return test_feature