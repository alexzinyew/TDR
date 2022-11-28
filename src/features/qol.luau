local qol = {}
local TDR:TDR = _G.TDR
qol.__index = qol

function qol.init()
    local self:Feature = setmetatable(qol,{})
    print("!")

    TDR.conCommand("tdr_qol_setangle",function(args)return self:setangle(args) end)
    TDR.conCommand("qol_setangle",function(args)return self:setangle(args) end)
    TDR.conCommand("tdr_qol_setposition",function(args)return self:setposition(args) end)
    TDR.conCommand("qol_setposition",function(args)return self:setposition(args) end)


    return self
end

-- TODO - Diagonose why arguments arent transferring

function qol.setangle(Arguments)
    if #Arguments ~= 3 then
        return "!DEVERROR!Provide 3 XYZ values"         
    else
        local x,y,z = tonumber(Arguments[1]),tonumber(Arguments[2]),tonumber(Arguments[3])
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position) * CFrame.Angles(math.rad(x),math.rad(y),math.rad(z))
        return "Set angle to "..tostring(x).." "..tostring(y).." "..tostring(z)
    end
end

function qol.setposition(Arguments)
    if #Arguments ~= 3 then
        return "!DEVERROR!Provide 3 XYZ values"         
    else
        local x,y,z = tonumber(Arguments[1]),tonumber(Arguments[2]),tonumber(Arguments[3])
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(
            CFrame.new(x,y,z)
        )
        return "Set position to "..tostring(x).." "..tostring(y).." "..tostring(z)
    end
end

return qol

