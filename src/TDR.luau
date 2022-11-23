local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function TDR.conVar(name:string, default_value:string)
    local Var : ConVar = {}
    Var.name = name
    Var.value = default_value

    Var.getBool = function()
        return Var.value == "true" or Var.value == "0" and true or false
    end

    return Var
end

function TDR.start()
    _G.PATH = "/TDR/src/"
    TDR.Features = {}
    TDR.Features["record"] = TDR.runFeature("record","Demo recording","")
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

--reason for missing a bunch of typechecks for functions or tables is because synapse x sucks and cant handle them yet!!

--[[
    loadstring(readfile("TDR/src/TDR.luau"))().start();
]]

return TDR