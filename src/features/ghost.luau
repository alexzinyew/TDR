local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ghost = {}
ghost.__index = ghost
local TDR:TDR = _G.TDR

local bread = TDR.Features["bread"]

function ghost.init()
    local self:Feature = setmetatable({
        socket = nil;
        lastPacket = {};
        color = TDR.conVar("tdr_ghost_color",{"0","0","0"});
        ghostFolder = Instance.new("Folder",workspace)
    },ghost)

    TDR.conCommand("tdr_ghost_connect",function(args)return self:Connect(args) end,true)
    TDR.conCommand("tdr_ghost_disconnect",function(args)return self:Disconnect(args) end,true)

    RunService.RenderStepped:Connect(function(deltaTime)
        self:SendSteppedPacket()
    end)

    Players.LocalPlayer.PlayerGui.CurrentLevel.Changed:Connect(function()
        self:SendMapChangePacket()
    end)

    self.ghostFolder.Name = "Ghosts"

    return self
end

function ghost:GetName() : string
    return Players.LocalPlayer.Name
end

function ghost:SendConnectPacket()
    if self.socket then
        local packet = {
            Mode = "Connect";
            User = self:GetName();
            Data = {}
        }

        self.socket:Send(HttpService:JSONEncode(packet))
        self.lastPacket = packet
    end
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
    local Data = HttpService:JSONDecode(msg)
    local Mode = Data.Mode
    local User = Data.User
    local Data = Data.Data
    if Mode == "Step" then
        local Ghost:Model = self.ghostFolder:FindFirstChild(User)
        if Ghost then
            local PositionData = Data.PositionData
            local Position = Vector3.new(PositionData.Position.X,PositionData.Position.Y,PositionData.Position.Z)
            local Rotation = Vector3.new(PositionData.Rotation.X,PositionData.Rotation.Y,PositionData.Rotation.Z)
            local Color = {PositionData.Color[1],PositionData.Color[2],PositionData.Color[3]}
            Ghost:PivotTo(CFrame.new(Position) * CFrame.Angles(math.rad(Rotation.X),math.rad(Rotation.Y),math.rad(Rotation.Z)))
            for i,v in pairs(Ghost:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Color = Color
                end
            end
        end
    elseif Mode == "Disconnect" then
        bread:CreateBread{User.." Has disconnected"}
    elseif Mode == "Connect" then
        bread:CreateBread{User.." Has Connected"}
        local ghost:Model = game:GetObjects(getsynasset("TDR/src/misc/ghost.rbxm"))[1]
        ghost.Parent = self.ghostFolder
        ghost:PivotTo(CFrame.new(0,999,0))
        ghost.Name = User
    elseif Mode == "MapChange" then
        bread:CreateBread{User.." Is now on "..Data.NewMap}
    end
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

    self:SendConnectPacket()
    bread:CreateBread{"Connected to ghost server!"}
    return "Connected!"
end

function ghost:Disconnect()
    if self.socket then
        self.socket:Close()
        self.socket = nil
    else
        return "!DEVERROR!Not connected to a ghost server"
    end
    bread:CreateBread{"Disconnected from ghost server!"}
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