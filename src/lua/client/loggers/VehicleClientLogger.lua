--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

local VehicleClientLogger = {
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachmentA = nil,
    vehicleAttachmentB = nil,
}

-- DumpVehicle writes vehicles info to log file.
function VehicleClientLogger.DumpVehicle(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = LogExtenderUtils.getLogLinePrefix(player, action);

    if vehicle then
        local info = LogExtenderUtils.getVehicleInfo(vehicle)

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    else
        message = message .. " vehicle={}";
    end

    if vehicle2 then
        local info = LogExtenderUtils.getVehicleInfo(vehicle2)

        if action == 'attach' then
            message = message .. ' to'
        elseif action == 'detach' then
            message = message .. ' from'
        end

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    end

    local location = LogExtenderUtils.getLocation(player);
    message = message .. " at " .. location

    LogExtenderUtils.writeLog(LogExtenderUtils.filemask.vehicle, message);
end


-- VehicleEnter adds callback for OnEnterVehicle event.
VehicleClientLogger.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtenderClient.vehicle = player:getVehicle()
        VehicleClientLogger.DumpVehicle(player, "enter", LogExtenderClient.vehicle, nil);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
VehicleClientLogger.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        VehicleClientLogger.DumpVehicle(player, "exit", LogExtenderClient.vehicle, nil);
        VehicleClientLogger.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
VehicleClientLogger.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform;

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            VehicleClientLogger.vehicleAttachmentA = self.vehicleA
            VehicleClientLogger.vehicleAttachmentB = self.vehicleB
            VehicleClientLogger.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB);
        end;
    end;
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
VehicleClientLogger.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform;

    ISDetachTrailerFromVehicle.perform = function(self)
        local vehicleB = self.vehicle:getVehicleTowing()
        if vehicleB == nil then
            vehicleB = VehicleClientLogger.vehicleAttachmentB
        end

        originalPerform(self);

        local player = self.character;

        if player then
            VehicleClientLogger.DumpVehicle(player, "detach", self.vehicle, vehicleB);
            VehicleClientLogger.vehicleAttachmentA = nil;
            VehicleClientLogger.vehicleAttachmentB = nil;
        end
    end
end

--
-- Admin tools
--

VehicleClientLogger.ISSpawnVehicleUI_onClick = function()
    local originalOnClick = ISSpawnVehicleUI.onClick;

    ISSpawnVehicleUI.onClick = function(self, button)
        originalOnClick(self, button)

        if self.player == nil then
            return
        end

        local character = self.player

        if button.internal == "SPAWN" then
            local action = "spawned vehicle"

            local message = character:getUsername() .. " " .. action .. " " .. tostring(self:getVehicle())
            message = message .. " at " .. LogExtenderUtils.getLocation(character)

            LogExtenderUtils.writeLog(LogExtenderUtils.filemask.admin, message);
        elseif button.internal == "GETKEY" then
            if self.vehicle ~= nil then
                local action = "got vehicle key"
                local info = LogExtenderUtils.getVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type
                message = message .. " at " .. LogExtenderUtils.getLocation(character)

                LogExtenderUtils.writeLog(LogExtenderUtils.filemask.admin, message);
            end
        elseif button.internal == "REPAIR" then
            if self.vehicle ~= nil then
                local action = "repaired vehicle"
                local info = LogExtenderUtils.getVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type
                message = message .. " at " .. LogExtenderUtils.getLocation(character)

                LogExtenderUtils.writeLog(LogExtenderUtils.filemask.admin, message);
            end
        end
    end
end

if SandboxVars.LogExtender.VehicleEnter then
    Events.OnEnterVehicle.Add(VehicleClientLogger.VehicleEnter)
end

if SandboxVars.LogExtender.VehicleExit then
    Events.OnExitVehicle.Add(VehicleClientLogger.VehicleExit)
end

if SandboxVars.LogExtender.VehicleAttach then
    VehicleClientLogger.VehicleAttach()
end

if SandboxVars.LogExtender.VehicleDetach then
    VehicleClientLogger.VehicleDetach()
end

VehicleClientLogger.ISSpawnVehicleUI_onClick()
