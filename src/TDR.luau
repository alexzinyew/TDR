local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
_G.TDR = {}
local TDR:TDR = _G.TDR

function TDR.runFeature(Feature:string,name:string,desc:string,...) : Feature
    local path = _G.PATH.."features/"..Feature..".luau"
    return loadstring(readfile(path))().init(name,string,...)
end

function TDR.conCommand(name:string, callback, override:boolean)
    if ReplicatedStorage.DebugCommands:FindFirstChild(name) then
        if not override then
            error("Already a existing command of name: "..name)
        else
            ReplicatedStorage.DebugCommands[name]:Destroy()
        end
    end

    local Command : Command = {}
    Command.name = name
    Command.callback = callback

    Command.obj = ReplicatedStorage.DebugCommands.god:Clone()
    Command.obj.Name = name
    Command.obj.Parent = ReplicatedStorage.DebugCommands

    require(Command.obj).runCommand = callback
    return Command
end

function TDR.conVar(name:string, default_value, desc:string) --default_value:{string}
    local Var : ConVar = {}
    Var.name = name
    Var.value = default_value
    Var.desc = desc
    Var.default_value = default_value
    Var.onChanged = Instance.new("BindableEvent")
    Var.command = TDR.conCommand(name,function(args)
        if #args == 0 then
            local text = Var.value[1]
            for i,v in pairs(Var.value) do if i ~= 1 then text = text.." "..v end end
            text = text.." | Default Value: "..Var.default_value[1]
            for i,v in pairs(Var.default_value) do if i ~= 1 then text = text.." "..v end end
            return text
        else
            Var.value = args
        Var.onChanged:Fire()
        end
    end,true)

    Var.getBool = function(index)
        return Var.value[index] == "true" or Var.value[index] == "0" and true or false
    end
    
    return Var
end

function TDR.start()
    _G.PATH = "/TDR/src/"
    TDR.Features = {}

    TDR.Features["bread"]  = TDR.runFeature("bread", "bread ui","")
    TDR.Features["record"] = TDR.runFeature("record","Demos"   ,"")
    TDR.Features["ghost"] = TDR.runFeature("ghost","ghosts"  ,"")
    TDR.Features["qol"] = TDR.runFeature("qol","Stuff ported from QOL","")
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

--reason for missing a bunch of typechecks for functions or tables is because synapse x sucks and cant handle them yet!!

--[[
    loadstring(readfile("TDR/src/TDR.luau"))().start();
]]

return TDR