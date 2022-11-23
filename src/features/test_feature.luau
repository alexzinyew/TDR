local test_feature = {}
local TDR:TDR = _G.TDR
test_feature.__index = test_feature

function test_feature.init()
    local self:Feature = setmetatable(test_feature,{})
    print("!")

    TDR.conCommand("test_command",function(Args)
        local a = ""
        for _,v in pairs(Args) do
            a = a..v
        end

        return a
    end)

    return self
end

type TDR = {
    start:()->nil;
    runFeature:(Feature:string)->Feature;
    conCommand:any; -- should be type (name:string,args:{string})->Command
}

type Feature = {
    init:()->Feature;
    name:string;
    desc:string;
}

type Command = {
    name:string;
    callback:any; -- should be type (args:{string})->string
    obj:ModuleScript
}

return test_feature