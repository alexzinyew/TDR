local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ghost = {}
ghost.__index = ghost
local TDR:TDR = _G.TDR

function ghost.init()
    local self:Feature = setmetatable({
        socket = nil;
        lastPacket = {};
        color = TDR.conVar("tdr_ghost_color",{"0","0","0"});
        name = TDR.conVar("tdr_ghost_name",{Players.LocalPlayer.Name});
    },ghost)

    TDR.conCommand("tdr_ghost_connect",function(args)return self:Connect(args) end,true)
    TDR.conCommand("tdr_ghost_disconnect",function(args)return self:Disconnect(args) end,true)

    RunService.RenderStepped:Connect(function(deltaTime)
        self:SendSteppedPacket()
    end)

    Players.LocalPlayer.PlayerGui.CurrentLevel.Changed:Connect(function()
        self:SendMapChangePacket()
    end)

    return self
end

function ghost:GetName() : string
    local a = ""
    for _,v in pairs(self.name.value) do a = a.." "..v end
    return a
end

function ghost:SendMapChangePacket()
    if self.socket then
        local packet = {
            Mode = "MapChange";
            User = self:GetName();
            Data = {
                NewMap = Players.LocalPlayer.PlayerGui.CurrentLevel.Value
            }
        }

        self.socket:Send(HttpService:JSONEncode(packet))
        self.lastPacket = packet
    end
end

function ghost:SendSteppedPacket()
    local Character = Players.LocalPlayer.Character
    if self.socket and Character then
        local _Position = Character.PrimaryPart.Position
        local _Rotation = Character.PrimaryPart.Rotation

        local packet = {
            Mode = "Step";
            User = self:GetName();
            Data = {
                PositionData = {
                    Position = {_Position.X,_Position.Y,_Position.Z};
                    Rotation = {_Rotation.X,_Rotation.Y,_Rotation.Z};
                    Color = {self.color.value[1],self.color.value[2],self.color.value[3]}
                }
            }
        }

        self.socket:Send(HttpService:JSONEncode(packet))
        self.lastPacket = packet
    end
end

function ghost:OnMessage(msg:string)
    print(msg)
end

function ghost:OnClose()
    self.socket = nil
end

function ghost:Connect(args)
    if #args ~= 1 then
        return "!DEVERROR!Please provide a ghost server url"
    elseif self.socket then
        return "!DEVERROR!Already connected!"
    end
    local url = args[1]

    local success,err = pcall(function()
        self.socket = syn.websocket.connect(url)
    end)
    if not success or err then
        self.socket = nil
        return "Error connecting"
    end
    self.socket.OnMessage:Connect(function(msg:string)
        self:OnMessage(msg)
    end)
    self.socket.OnClose:Connect(function()
        self:OnClose()
    end)

    return "Connected!"
end

function ghost:Disconnect()
    if self.socket then
        self.socket:Close()
        self.socket = nil
    else
        return "!DEVERROR!Not connected to a ghost server"
    end
    return "Disconnected!"
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

return ghost