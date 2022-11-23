local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local record = {}
local TDR:TDR = _G.TDR
local LevelService = require(game:GetService("ReplicatedStorage").LevelService)
record.__index = record

local Player = Players.LocalPlayer

function math_round(n: number, scale: number?)
    return tonumber(string.format("%." .. (typeof(scale) == "number" and scale or 2) .. "f", n))
end

function record.init(name:string,desc:string,...)
    local self:Feature = setmetatable({
        name=name,
        desc=desc,
        Recording=false,
        Playing = false,
        DemoName="";
        Buffer = {};
        onStop = Instance.new("BindableEvent")
    },record)

    TDR.conCommand("tdr_record",function(args)return self:Record(args) end,true)
    TDR.conCommand("tdr_record_stop",function(args)return self:Stop(args) end,true)
    TDR.conCommand("tdr_playdemo",function(args)return self:PlayCommand(args) end,true)
    TDR.conCommand("tdr_clear_onload_demos",function(args)return self:ClearOnLoad(args) end,true)
    TDR.conCommand("tdr_stop_demo",function(args)return self:StopDemo(args) end,true)

    while task.wait() do
        if self.Recording == true and Player.Character then
            local pos = LevelService:GetLevelPosition(Player.Character.PrimaryPart.Position)
            local rot = Player.Character.PrimaryPart.Rotation
            local lookx,looky,lookz = workspace.CurrentCamera.CFrame:ToOrientation()
            table.insert(self.Buffer,{
                {math_round(pos.X,3),math_round(pos.Y,3),math_round(pos.Z,3)},
                {math_round(rot.X,3),math_round(rot.Y,3),math_round(rot.Z,3)},
                {math_round(lookx,3),math_round(looky,3),math_round(lookz,3)},
                Player.Character.crouch.Value
            })
        end
    end

    Player.PlayerGui.CurrentLevel.Changed:Connect(function()
        self:Stop()
        if self.onLoadDemo then
            self:PlayDemo(self.onLoadDemo)
        end
    end)

    return self

end

function record:Record(args)
    local self:Feature = self
    if #args ~= 1 then
        return "!DEVERROR!Please provide a demo name."
    elseif self.Recording == true then
        return "!DEVERROR!Already recording"
    end

    self.Recording = true;
    self.DemoName = args[1];
    self.Buffer = {}
    self.Map = Players.PlayerGui.CurrentLevel.Value
    writefile("TDR/.demo/"..self.DemoName..".tdrdemo","")

    return "Recording!"
end

function record:Stop()
    if self.Recording == false then
        return "!DEVERROR!Not recording"
    end

    local tmp = ""..self.DemoName;
    writefile("TDR/.demo/"..self.DemoName..".tdrdemo",HttpService:JSONEncode({
        User = Player.Name;
        Map = self.Map;
        PositionData = self.Buffer
    }))
    self.Recording = false;
    self.DemoName = "";
    self.Buffer = {}
    self.Map = ""
    return "Stopped recording: "..tmp
end

function record:PlayCommand(args)
    if #args ~= 3 then
        return "!DEVERROR!Provide arguments: <demoName>, <onLoad 0 or 1>, <firstPerson 0 or 1>"
    elseif self.Playing then
        return "!DEVERROR!Already playing a demo"
    end
    local demoName,onLoad = args[1],args[2]

    local demo = HttpService:JSONDecode(readfile("TDR/.demo/"..demoName..".tdrdemo"))
    if demo then
        if onLoad == "1" then
            self.onLoadDemo = demo
        end
        return self:PlayDemo(demo,args[3] == "1" and true or false)
    else
        return "!DEVERROR!No demo found of name: "..demoName
    end
end

function record:PlayDemo(demo,doCamera:boolean)
    local model:Model
    self.Playing = true
    if not doCamera then
        model = game:GetService("ReplicatedStorage").Playermodels.tester:Clone()
        model.Parent = workspace
        model.Name = demo.User
        
        for i,v in pairs(model:GetChildren()) do
            if v:IsA("BasePart") then
                v.Transparency = .5
                v.Color = Color3.fromRGB(85, 255, 127)
                v.Material = Enum.Material.ForceField
            end
        end
    else
        model = Instance.new("Model",workspace)
        local _part = Instance.new("Part",model)
        _part.Anchored = true
        _part.CanCollide = false
        _part.CanTouch = false
        _part.CanQuery = false
        _part.Transparency = 1
    end

    local stop = false
    self.onStop.Event:Connect(function()
        stop = true
    end)

    for i,Data in pairs(demo.PositionData) do
        if stop == true then break end
        local Position = Vector3.new(Data[1][1], Data[1][2], Data[1][3]) + ReplicatedStorage.Levels[Player.PlayerGui.CurrentLevel.Value].SpawnLocation.Position
        local Rot = Vector3.new(Data[2][1], Data[2][2], Data[2][3])
        local Look = Vector3.new(Data[3][1], Data[3][2], Data[3][3])
        local Crouched = Data[4]
        
        model:PivotTo(CFrame.new(Position) * CFrame.Angles(math.rad(Rot.X),math.rad(Rot.Y),math.rad(Rot.Z)))

        if doCamera then
            Player.PlayerGui.noclipEnabled.Value = true
            Player.Character:PivotTo(model:GetPivot())
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position) * CFrame.Angles(Look.X,Look.Y,Look.Z)
        end
        task.wait()
    end
    Player.PlayerGui.noclipEnabled.Value = false
    model:Destroy()
    self.Playing = false
    return "Done playing demo"
end

function record:ClearOnLoad(args)
    self.onLoadDemo = nil
end

function record:StopDemo()
    self.onStop:Fire()
    return "Stopped"
end

type TDR = {
    start:()->nil;
    runFeature:(Feature:string)->Feature;
    conCommand:(name:string,callback:()->string,override:boolean)->Command;
    ConVar:(name:string, default_value:string)->ConVar;
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
    value:string;
    getBool:()->boolean;
}



return record