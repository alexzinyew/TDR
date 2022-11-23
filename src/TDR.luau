local ReplicatedStorage = game:GetService("ReplicatedStorage")
_G.TDR = {}
local TDR:TDR = _G.TDR

function TDR.runFeature(Feature:string) : Feature
    local path = _G.PATH.."features/"..Feature..".luau"
    return loadstring(readfile(path))().init()
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

function TDR.start()
    _G.PATH = "/TDR/src/"

    TDR.runFeature("test_feature")
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

--reason for missing a bunch of typechecks for functions or tables is because synapse x sucks and cant handle them yet!!

--[[
    loadstring(readfile("TDR/src/TDR.luau"))().start();
]]

return TDR