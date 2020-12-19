class 'SpectatorVanillaUI'

function SpectatorVanillaUI:__init()
	-- Install our hooks.
	-- TODO: Re-enable push screen hook when our UI is ready.
	self.m_UIPushScreenHook = Hooks:Install('UI:PushScreen', 420, self, self.OnPushScreen)
	self.m_UICreateKillMessageHook = Hooks:Install('UI:CreateKillMessage', 420, self, self.OnCreateKillMessage)
end

function SpectatorVanillaUI:OnUpdate(p_Delta, p_SimDelta)

end

function SpectatorVanillaUI:OnPushScreen(p_Hook, p_Screen, p_GraphPriority, p_ParentGraph)
	if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
		--p_Hook:Next()
		return
	end

	local s_Screen = UIGraphAsset(p_Screen)

	-- Check if this is one of the screens we override.
	if s_Screen.name ~= "UI/Flow/Screen/HudConquestScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudMPScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudGMScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudRushScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudSDMScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/SpawnScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/SpawnScreenTicketCounterTDMScreen" and
	   s_Screen.name ~= "UI/Flow/Screen/HudTDMScreen" then
		--p_Hook:Next()
		return
   	end

   	s_Screen:MakeWritable()
	local s_NodeCount = #s_Screen.nodes

	-- Iterate through all the nodes.
	for i = s_NodeCount - 1, 0, -1 do
		local s_Node = s_Screen.nodes:get(i)

		-- Remove the ones we don't need.
		if s_Node ~= nil then
			if s_Node.name == "HudOutOfBoundsAlertMessage" or
			   s_Node.name == "Ammo" or
			   s_Node.name == "VehicleHealth" or
			   s_Node.name == "PassangerList" or
			   s_Node.name == "Health" or
			   s_Node.name == "SquadList" or
			   s_Node.name == "Compass" or
			   --s_Node.name == "Minimap" or
			   s_Node.name == "LocalKillMessage" or
			   s_Node.name == "SupportIconManager" or
			   s_Node.name == "ScoreAggregator" or
			   s_Node.name == "HudInformationMessage" or
			   s_Node.name == "HudMessageKills" or
			   s_Node.name == "RewardMessage" or
			   s_Node.name == "ScoreMessage" or
			   s_Node.name == "ObjectiveMessage" or
			   s_Node.name == "TooltipMessage" or
			   s_Node.name == "MapmarkerManager" or
			   s_Node.name == "HudBackgroundWidget" or
			   s_Node.name == "ObjectiveBar" or
			   s_Node.name == "CapturepointManager" or
			   s_Node.name == "TicketCounterSpawnScreen" or
			   s_Node.name == "TicketCounter" then
			   	s_Screen.nodes:erase(i)
			end
		end
	end

	-- Pass the modified screen to the original function.
	p_Hook:Pass(s_Screen, p_GraphPriority, p_ParentGraph)
end

function SpectatorVanillaUI:OnPushScreen(p_Hook)
	-- Block the kill feed
	p_Hook:Return()
end

return SpectatorVanillaUI
