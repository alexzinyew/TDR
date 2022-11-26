local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local bread = {}
local TDR:TDR = _G.TDR
bread.__index = bread

function bread.init()
    local self:Feature = setmetatable({
        Breads = {},
        textColor = TDR.conVar("tdr_bread_text_color",{"255","255","255"}),
        bgColor = TDR.conVar("tdr_bread_bg_color",{"49","49","49"})
    },bread)

    TDR.BreadUi = game:GetObjects(getsynasset(_G.PATH.."/misc/breadui.rbxm"))[1]
    if Players.LocalPlayer.PlayerGui:FindFirstChild("BreadUi") then Players.LocalPlayer.PlayerGui.BreadUi:Destroy() end
    TDR.BreadUi.Parent = Players.LocalPlayer.PlayerGui

    TDR.conCommand("tdr_create_bread",function(args)return self:CreateBread(args) end,true)
    
    self.textColor.onChanged.Event:Connect(function()
        for i,v in pairs(self.Breads) do
            v.TextColor3 = Color3.fromRGB(self.textColor.value[1],self.textColor.value[2],self.textColor.value[3])
        end
    end)

    self.bgColor.onChanged.Event:Connect(function()
        for i,v in pairs(self.Breads) do
            v.BackgroundColor3 = Color3.fromRGB(self.bgColor.value[1],self.bgColor.value[2],self.bgColor.value[3])
        end
    end)

    return self
end

function bread:CreateBread(args)
    local self:Feature = self
    task.spawn(function()
        local text = ""
        for i,v in pairs(args) do text = text.." "..v end
        local bread : TextLabel = TDR.BreadUi.Frame.sample:Clone()

        bread.Parent = TDR.BreadUi.Frame
        bread.Text = text
        bread.TextColor3 = Color3.fromRGB(self.textColor.value[1],self.textColor.value[2],self.textColor.value[3])
        bread.BackgroundColor3 = Color3.fromRGB(self.bgColor.value[1],self.bgColor.value[2],self.bgColor.value[3])
        bread.Visible = true
        bread.BackgroundTransparency = 1

        table.insert(self.Breads,bread)

        TweenService:Create(bread,TweenInfo.new(.1),{BackgroundTransparency = .2}):Play()
        task.wait(2.5)
        TweenService:Create(bread,TweenInfo.new(.1),{BackgroundTransparency = 1}):Play()
        task.wait(.1)
        bread:Destroy()
        table.remove(self.Breads,table.find(self.Breads,bread))
    end)
end

type TDR = {
    start:()->nil;
    runFeature:(Feature:string)->Feature;
    conCommand:(name:string,callback:()->string,override:boolean)->Command;
    conVar:(name:string, default_value:any)->ConVar;
}

type Feature = {
    init:()->Feature;
    name:string;
    desc:string;
}

type Command = {
    name:string;
    callback:(args)->string;
    obj:ModuleScript
}

type ConVar = {
    name:string;
    value:any;
    command:Command;
    default_value:any;
    desc:string;
    getBool:(number)->boolean;
    onChanged:BindableEvent;
}

return bread