local Unchanged = "Unchanged";
local Enabled 	= "Enabled";

local function OnHaunt_RemoveItem(Prefab, Haunter)
    -- Consume 1 Telltale Heart
    -- We check for stacking incase other mods change it to a stackable item
    if ((Prefab.components.stackable ~= nil) and Prefab.components.stackable:IsStack()) then
        Prefab.components.stackable:Get():Remove();
    else
        Prefab:Remove();
    end

    return true;
end

local function Add_Resurrector(Prefab)
    if (Prefab.components.hauntable == nil) then
        Prefab:AddComponent("hauntable");
    end

    -- This Tuning value tells the game to resurrect the player
    Prefab.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ);
    Prefab.components.hauntable.cooldown = 0;
    Prefab.components.hauntable:SetOnHauntFn(function () return true end);

    if ((GetModConfigData("usetags") == Enabled) or (GetModConfigData("ReturnHotkey") ~= Unchanged)) then
        Prefab:AddTag("resurrector");
    end

    if (Prefab.components.inventoryitem ~= nil) then
        Prefab.components.hauntable:SetOnHauntFn(OnHaunt_RemoveItem)
    end
end

local function Apply(Prefab)
    local Toggle = GetModConfigData(Prefab);

    if (Toggle == Enabled) then
        AddPrefabPostInit(Prefab, Add_Resurrector);
    end
end

local function Apply_CheckBlocking(Prefab)
    -- Block all other settings
    if (GetModConfigData("usetags") == Enabled) then
        return;
    end

    Apply(Prefab);
end

local function Apply_Skeleton(Prefab)
    local Toggle = GetModConfigData(Prefab);

    if (Toggle == Enabled) then
        AddPrefabPostInit(Prefab, Add_Resurrector);
        -- Player Skeleton is a different prefab than Skeleton
        AddPrefabPostInit("skeleton_player", Add_Resurrector);
    end
end

Apply_CheckBlocking("campfire");
Apply_CheckBlocking("firepit");
Apply_CheckBlocking("coldfire");
Apply_CheckBlocking("coldfirepit");
Apply_Skeleton("skeleton");
Apply("reviver");

local function Apply_ToTag()
    if (GetModConfigData("usetags") == Enabled) then
        -- Runs on all prefabs as i couldn't find a way to iterate through all prefabs post-all mods initialization
        AddPrefabPostInitAny(function(Prefab)
            -- Do not try to add "resurrector" if it's already there
            if ((Prefab ~= nil) and (Prefab.components ~= nil) and Prefab:HasTag("campfire") and (not Prefab:HasTag("resurrector"))) then
                Add_Resurrector(Prefab);
            end
        end)
    end
end

Apply_ToTag();

local function Set(Key, Setting)
    Setting = GetModConfigData(Setting);

    if (Setting ~= Unchanged) then
        if (TUNING[Key] ~= nil) then
            TUNING[Key] = Setting;
        end
    end
end

Set("PORTAL_HEALTH_PENALTY",  "Health_Penalty_Portal");
Set("MAXIMUM_HEALTH_PENALTY", "Health_Penalty_Maximum");
Set("EFFIGY_HEALTH_PENALTY",  "Health_Penalty_Meat_Effigy");
Set("REVIVE_HEALTH_PENALTY",  "Health_Penalty_Generic");
Set("RESURRECT_HEALTH",       "Health_Respawn_Amount");

local Hotkey = GetModConfigData("ReturnHotkey");

if (Hotkey ~= Unchanged) then
    -- This is how the game does it too!
    local function GetPortal()
        for Key, Value in pairs(GLOBAL.Ents) do
            if (Value:IsValid() and Value:HasTag("multiplayer_portal")) then
                return Value;
            end
        end
    end

    local function ResurrectPlayer_AtPortal(Player)
        local Portal = GetPortal();

        if (Portal ~= nil) then
            Player.Monkey_LastHauntTarget = Portal;
            local X, Y, Z = Portal.Transform:GetWorldPosition();
            Player.Physics:Teleport(X, Y, Z);
            Player:PushEvent("respawnfromghost", {source = Portal, user = Player});
        end
    end

    local function ResurrectPlayer(Player)
        if (Player.Monkey_LastHauntTarget ~= nil) then
            local X, Y, Z = Player.Monkey_LastHauntTarget.Transform:GetWorldPosition();

            -- If they're nil then the target doesn't exist anymore
            if ((X ~= nil) and (Y ~= nil) and (Z ~= nil)) then
                Player:PushEvent("respawnfromghost", {source = Player.Monkey_LastHauntTarget, user = Player});
                Player.Physics:Teleport(X, Y, Z);
            else
                Player.Monkey_LastHauntTarget = nil;
                ResurrectPlayer_AtPortal(Player);
            end
        else
            ResurrectPlayer_AtPortal(Player);
        end
    end

    AddModRPCHandler(modname, "Monkey_ResurrectPlayer", ResurrectPlayer);

    if (GLOBAL.TheNet:GetIsServer() or GLOBAL.TheNet:IsDedicated()) then
        AddPlayerPostInit(function (Prefab)
            Prefab:ListenForEvent("haunt", function (Ghost, Data)
                if ((Data ~= nil) and (Data.target ~= nil) and Data.target:HasTag("resurrector")) then
                    Ghost.Monkey_LastHauntTarget = Data.target
                end
            end)
        end)
    end

    if (not GLOBAL.TheNet:GetIsServer()) then
        GLOBAL.TheInput:AddKeyUpHandler(GLOBAL["KEY_" .. Hotkey], function ()
            if GLOBAL.GetPortalRez(GLOBAL.TheNet:GetServerGameMode()) then
                local Player = GLOBAL.ThePlayer

                if (Player:HasTag("playerghost")) then
                    SendModRPCToServer(MOD_RPC[modname]["Monkey_ResurrectPlayer"], Player)
                end
            end
        end);
    end
end


