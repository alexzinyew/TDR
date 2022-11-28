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
        ghostFolder = Instance.new("Folder",workspace);
        sampleGhost = game:GetObjects(getsynasset(_G.PATH.."/misc/ghost.rbxm"))[1]
    },ghost)

    TDR.conCommand("tdr_ghost_connect",function(args)return self:Connect(args) end,true)
    TDR.conCommand("tdr_ghost_disconnect",function(args)return self:Disconnect(args) end,true)
    TDR.conCommand("tdr_ghost_chat",function(args)return self:Chat(args)end)

    RunService.RenderStepped:Connect(function(deltaTime)
        self:SendSteppedPacket()
    end)

    Players.LocalPlayer.PlayerGui.CurrentLevel.Changed:Connect(function()
        self:SendMapChangePacket()
        for i,v in pairs(self.ghostFolder:GetChildren()) do
            v:PivotTo(CFrame.new(0,999,0))
        end
    end)

    Players.PlayerRemoving:Connect(function()
        if self.socket then
            self.socket:Close()
            self.socket = nil
        end
    end)

    self.ghostFolder.Name = "Ghosts"

    return self
end

function ghost:GetName() : string
    return Players.LocalPlayer.Name
end

function ghost:Chat(args)
    if self.socket then
        local message = args[1] or ""
        for i,v in pairs(args) do if i ~= 1 then message = message.." "..v end end

        local packet = {
            Mode = "Chat";
            User = self:GetName();
            Data = {Message=message}
        }

        self.socket:Send(HttpService:JSONEncode(packet))
        self.lastPacket = packet
    end
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
    if self.socket and Character and Players.LocalPlayer.PlayerGui.CurrentLevel.Value ~= "menu" then
        local _Position = Character.PrimaryPart.Position
        local _Rotation = Character.PrimaryPart.Rotation

        local packet = {
            Mode = "Step";
            User = self:GetName();
            Data = {
                Map = Players.LocalPlayer.PlayerGui.CurrentLevel.Value;
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
    if Mode == "Step" and User ~= self:GetName() then
        local Ghost:Model = self.ghostFolder:FindFirstChild(User)
        if not Ghost then
            local Ghost = self.sampleGhost:Clone()
            Ghost.Parent = self.ghostFolder
            Ghost.Name = User
            Ghost.BillboardGui.Textlabel.Text = User
        end
        if Ghost and Data.Map == Players.LocalPlayer.PlayerGui.CurrentLevel.Value then
            local PositionData = Data.PositionData
            local Position = Vector3.new(unpack(PositionData.Position))
            local Rotation = Vector3.new(unpack(PositionData.Rotation))
            local Color = Color3.fromRGB(unpack(PositionData.Color))
            Ghost:PivotTo(CFrame.new(Position) * CFrame.Angles(math.rad(Rotation.X),math.rad(Rotation.Y),math.rad(Rotation.Z)))
            for i,v in pairs(Ghost:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Color = Color
                end
            end
            Ghost.BillboardGui.Textlabel.TextColor3 = Color
        end
    elseif Mode == "Disconnect" then
        bread:CreateBread{User.." Has disconnected"}
        if self.ghostFolder:FindFirstChild(User) then
            self.ghostFolder[User]:Destroy()
        end
    elseif Mode == "Connect" then
        bread:CreateBread{User.." Has Connected"}
    elseif Mode == "MapChange" then
        bread:CreateBread{User.." Is now on "..Data.NewMap}
    elseif Mode == "Chat" then
        bread:CreateBread{User..": "..Data.Message}
    end
end

function ghost:OnClose()
    self.socket = nil
    self.ghostFolder:ClearAllChildren()
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
    self.ghostFolder:ClearAllChildren()
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