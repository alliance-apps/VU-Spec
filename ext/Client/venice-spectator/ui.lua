class 'SpectatorUI'

local SET_PLAYER = 1;
local REMOVE_PLAYER = 2;
local CLEAR_PLAYERS = 3;
local SET_TEAMS = 4;
local SET_TEAM_NAME = 6;
local SET_CURRENT_GAMEMODE = 7;
local SET_CURRENT_ROUND = 8;
local SET_TOTAL_ROUNDS = 9;
local SET_HAS_TIMER = 10;
local SET_TIME_LEFT = 11;
local ADD_OBJECTIVE = 12;
local REMOVE_OBJECTIVE = 13;
local UPDATE_OBJECTIVE = 14;
local CLEAR_OBJECTIVES = 15;
local SET_SPECTATED_PLAYER = 16;
local SET_SPECTATE_MODE = 17;
local TOGGLE_PLAYER_SCORE = 18;
local SET_KILLFEED_KILLS = 19;
local SET_CURRENT_POSITION = 20;

local SQUAD_COUNT = 32
local TEAM_COUNT = 2
local TEAM_CAPACITY = 16
local SQUAD_CAPACITY = 5 -- TODO: Can now be changed with RCON, handle that.

function SpectatorUI:__init()
    self:RegisterVars()
    self:RegisterEvents()
end

function SpectatorUI:RegisterVars()
    self.m_Players = {}
    self.m_PlayerMappings = {}
    self.m_LastUpdate = 0.0
    self.m_InitialTimer = 5.0
    self.m_Position = { 0.0, 0.0, 0.0 }

    self.m_Rounds = {}
    self.m_Squads = {}
    self.m_Teams = {}
    self.m_Objectives = {}
    self.m_Kills = {}
    self.m_KillCount = 0
    self.m_Tickets = { 0, 0 }
    self.m_SpectatorMode = 0
    self.m_LastPlayer = 0
    self.m_SpectatedPlayer = -1
    self.m_PlayerStats = false

    -- TODO: Make them changeable through RCON or something.
    self.m_TeamNames = {
        [1] = 'USMC',
        [2] = 'RU'
    }
end

function SpectatorUI:RegisterEvents()
    NetEvents:Subscribe('spec:ts', self, self.OnTeamCounts)
    NetEvents:Subscribe('spec:sq', self, self.OnSquadCounts)
    NetEvents:Subscribe('spec:r', self, self.OnRounds)
    NetEvents:Subscribe('spec:k', self, self.OnKill)
end
function SpectatorUI:SendUIAction(p_Action, p_Data)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    local s_Data = p_Data

    if s_Data == nil then
        s_Data = {}
    end

    s_Data['type'] = p_Action

    WebUI:ExecuteJS(string.format('window.store.dispatch(%s);', json.encode(s_Data)))
end

function SpectatorUI:OnUpdateInput(p_Delta)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    local s_Player = nil

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_1) then
        if self.m_Players[1] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[1]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_2) then
        if self.m_Players[2] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[2]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_3) then
        if self.m_Players[3] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[3]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_4) then
        if self.m_Players[4] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[4]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_5) then
        if self.m_Players[5] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[5]['realId'])
        end
    end

    -- Get first player id of team 2, squad 1.
    local s_FirstPlayerId = self:GetCustomId(TeamId.Team2, SquadId.Squad1, 0);

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_6) then
        if self.m_Players[s_FirstPlayerId] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[s_FirstPlayerId]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_7) then
        if self.m_Players[s_FirstPlayerId + 1] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[s_FirstPlayerId + 1]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_8) then
        if self.m_Players[s_FirstPlayerId + 2] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[s_FirstPlayerId + 2]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_9) then
        if self.m_Players[s_FirstPlayerId + 3] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[s_FirstPlayerId + 3]['realId'])
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_0) then
        if self.m_Players[s_FirstPlayerId + 4] ~= nil then
            s_Player = PlayerManager:GetPlayerById(self.m_Players[s_FirstPlayerId + 4]['realId'])
        end
    end

    local s_SpectatedPlayer = self.m_PlayerMappings[self.m_LastPlayer];

    if not s_SpectatedPlayer then
        --print('no players connected')
        return
    end

    local s_LeftPlayer = self.m_Players[s_SpectatedPlayer];
    local s_RightPlayer = self.m_Players[s_SpectatedPlayer];

    local s_PlayerCount = 0
    for _ in pairs(self.m_Players) do s_PlayerCount = s_PlayerCount + 1 end

    local s_MaxId = ((TEAM_COUNT * SQUAD_COUNT * SQUAD_CAPACITY) + (TEAM_COUNT * TEAM_CAPACITY))
    for i = 1, s_MaxId do
        local s_Index = (s_SpectatedPlayer + i) % s_MaxId
        --print(string.format('%d %d -> %d', s_SpectatedPlayer, s_PlayerCount, s_Index))

        if self.m_Players[s_Index] ~= nil and self.m_Players[s_Index]['health'] > 0 then
            s_RightPlayer = self.m_Players[s_Index]
            break
        end
    end

    for i = 1, s_MaxId do
        local s_Index = (s_SpectatedPlayer - i)

        if s_Index <= 0 then
            s_Index = s_Index + s_MaxId
        end

        if self.m_Players[s_Index] ~= nil and self.m_Players[s_Index]['health'] > 0 then
            s_LeftPlayer = self.m_Players[s_Index]
            break
        end
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_ArrowLeft) then
        s_Player = PlayerManager:GetPlayerById(s_LeftPlayer['realId'])
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_ArrowRight) then
        s_Player = PlayerManager:GetPlayerById(s_RightPlayer['realId'])
    end

    if s_Player ~= nil then
        local s_FirstPerson = false

        if SpectatorManager:GetCameraMode() == SpectatorCameraMode.FirstPerson then
            s_FirstPerson = true
        end

        self.m_LastPlayer = s_Player.id
        SpectatorManager:SpectatePlayer(s_Player, s_FirstPerson)
    end
end

function SpectatorUI:OnKill(p_Killer, p_Killed, p_Weapon)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self.m_KillCount = self.m_KillCount + 1

    local s_Killer = nil

    if p_Killer ~= -1 then
        s_Killer = self.m_PlayerMappings[p_Killer]
    end

    if self.m_PlayerMappings[p_Killed] == nil then
        return
    end

    self.m_Kills[self.m_KillCount] = {
        killer = s_Killer,
        killed = self.m_PlayerMappings[p_Killed],
        weapon = p_Weapon,
        delta = 5.0
    }

    self:SendUIAction(SET_KILLFEED_KILLS, {
        kills = self.m_Kills
    })
end

function SpectatorUI:OnPlayerDeleted(p_Player)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self:SendUIAction(CLEAR_PLAYERS, {})
    self.m_Players = {}
    self.m_PlayerMappings = {}
end

function SpectatorUI:OnPlayerConnected(p_Player)

    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self:SendUIAction(CLEAR_PLAYERS, {})
    self.m_Players = {}
    self.m_PlayerMappings = {}
end

function SpectatorUI:OnTeamCounts(p_Teams)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self.m_Teams = p_Teams

    local s_Teams = {}

    s_Teams[1] = { id = 0, score = 0, maxPlayers = 24, squadCapacity = 5 }
    s_Teams[2] = { id = 1, score = self.m_Tickets[1], maxPlayers = 16, squadCapacity = 5 }
    s_Teams[3] = { id = 2, score = self.m_Tickets[2], maxPlayers = 16, squadCapacity = 5 }

    self:SendUIAction(SET_TEAMS, { teams = s_Teams })

    self:SendUIAction(SET_TEAM_NAME, { team = 1, name = self.m_TeamNames[1] })
    self:SendUIAction(SET_TEAM_NAME, { team = 2, name = self.m_TeamNames[2] })
end

function SpectatorUI:OnSquadCounts(p_Squads)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self.m_Squads = p_Squads
end

function SpectatorUI:OnRounds(p_Rounds)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self.m_Rounds = p_Rounds

    self:SendUIAction(SET_CURRENT_ROUND, { round = p_Rounds[1] + 1 })
    self:SendUIAction(SET_TOTAL_ROUNDS, { rounds = p_Rounds[2] })
end

function SpectatorUI:OnLoaded()
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    WebUI:Init()
    WebUI:Show()
    WebUI:ExecuteJS('document.location.reload()')
end

function SpectatorUI:OnUpdate(p_Delta, p_SimulationDelta)
    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.Disabled then
        return
    end

    self.m_LastUpdate = self.m_LastUpdate + p_Delta

    if self.m_InitialTimer > 0.0 then
        self.m_InitialTimer = self.m_InitialTimer - p_Delta
        return
    end
	
	for i = 1, self.m_KillCount do
		if self.m_Kills[i] ~= nil and self.m_Kills[i]['delta'] ~= nil then
			self.m_Kills[i]['delta'] = self.m_Kills[i]['delta'] - p_Delta
		end
	end

    if not self.m_PlayerStats then
        self.m_PlayerStats = true
        self:SendUIAction(TOGGLE_PLAYER_SCORE, {})
    end

    -- Do UI updates on 60hz
    -- TODO: Reduce update frequency when we have more players.
    if self.m_LastUpdate < (1.0 / 60.0) then
        return
    end

    self.m_LastUpdate = 0.0

    local s_SpectatorMode = SpectatorManager:GetCameraMode()

    if s_SpectatorMode ~= self.m_SpectatorMode then
        self.m_SpectatorMode = s_SpectatorMode
        self:SendUIAction(SET_SPECTATE_MODE, { mode = self.m_SpectatorMode })
    end

    local s_ObjectiveIndex = 1
    local s_ObjectiveCounter = 1
    
    local gameMode = SharedUtils:GetCurrentGameMode()
    if gameMode == nil then
		-- while maploading this can be nil
		return
	elseif gameMode:match("Conquest") or gameMode:match("Superiority") or gameMode == "Domination0" or gameMode == "Scavenger0" then
        
        local s_TicketIterator = EntityManager:GetIterator('ClientTicketCounterEntity')

        local s_NeedsTeamUpdate = false
        
        if s_TicketIterator ~= nil then
            local s_Entity = s_TicketIterator:Next()

            while s_Entity ~= nil do
                local s_TicketCounter = TicketCounterEntity(s_Entity)

                if self.m_Tickets[s_TicketCounter.team] ~= s_TicketCounter.ticketCount then
                    self.m_Tickets[s_TicketCounter.team] = s_TicketCounter.ticketCount
                    s_NeedsTeamUpdate = true
                end

                s_Entity = s_TicketIterator:Next()
            end
        end
        
    elseif gameMode:match("Rush") then
        
        local s_TicketIterator = EntityManager:GetIterator('ClientLifeCounterEntity')

        local s_NeedsTeamUpdate = false
        
        if s_TicketIterator ~= nil then
            local s_Entity = s_TicketIterator:Next()

            while s_Entity ~= nil do
                local s_TicketCounter = LifeCounterEntity(s_Entity)

                if self.m_Tickets[LifeCounterEntityData(s_TicketCounter.data).teamId] ~= s_TicketCounter.lifeCounter then
                    self.m_Tickets[LifeCounterEntityData(s_TicketCounter.data).teamId] = s_TicketCounter.lifeCounter
                    s_NeedsTeamUpdate = true
                end

                s_Entity = s_TicketIterator:Next()
            end
        end
        
    elseif gameMode:match("TeamDeathMatch") or gameMode == "SquadDeathMatch0" then
    
        local s_TicketIterator = EntityManager:GetIterator('ClientKillCounterEntity')

        local s_NeedsTeamUpdate = false
        
        if s_TicketIterator ~= nil then
            local s_Entity = s_TicketIterator:Next()

            while s_Entity ~= nil do
                local s_TicketCounter = KillCounterEntity(s_Entity)

                if self.m_Tickets[KillCounterEntityData(s_TicketCounter.data).teamId] ~= s_TicketCounter.killCount then
                    self.m_Tickets[KillCounterEntityData(s_TicketCounter.data).teamId] = s_TicketCounter.killCount
                    s_NeedsTeamUpdate = true
                end

                s_Entity = s_TicketIterator:Next()
            end
        end
        
    end
    if s_NeedsTeamUpdate then
        local s_Teams = {}

        s_Teams[1] = { id = 0, score = 0, maxPlayers = 24, squadCapacity = 5 }
        s_Teams[2] = { id = 1, score = self.m_Tickets[1], maxPlayers = 16, squadCapacity = 5 }
        s_Teams[3] = { id = 2, score = self.m_Tickets[2], maxPlayers = 16, squadCapacity = 5 }

        self:SendUIAction(SET_TEAMS, { teams = s_Teams })

        self:SendUIAction(SET_TEAM_NAME, { team = 1, name = self.m_TeamNames[1] })
        self:SendUIAction(SET_TEAM_NAME, { team = 2, name = self.m_TeamNames[2] })
    end

    local s_Iterator = EntityManager:GetIterator('ClientCapturePointEntity')
   
	if s_Iterator ~= nil then
        local s_Entity = s_Iterator:Next()

		local s_AddObjectives = false

		if s_Entity == nil then
			-- if we don't find any CapturePointEntity in the beginning we clear our objectives
			self:SendUIAction(CLEAR_OBJECTIVES, {})
		end
	
        while s_Entity ~= nil do
            local s_CaptureEntity = CapturePointEntity(s_Entity)

            local s_Data = CapturePointEntityData(s_CaptureEntity.data)

            if s_Data.capturableType ~= CapturableType.CTUnableToChangeTeam then
                local s_Contested = s_CaptureEntity.location > 0.0 and s_CaptureEntity.location < 1.0
                local s_Team = s_CaptureEntity.team

                if not s_CaptureEntity.controlled then
                    s_Team = TeamId.TeamNeutral
                end
				
                local s_Label = s_CaptureEntity.name
                s_Label = s_Label:gsub('ID_H_US_', '')
                s_Label = s_Label:gsub('ID_H_RU_', '')
				
				-- Order the CapturePoints alphabetic
				if s_Label == "A" then
					s_ObjectiveIndex = 1
				elseif s_Label == "B" then
					s_ObjectiveIndex = 2
				elseif s_Label == "C" then
					s_ObjectiveIndex = 3
				elseif s_Label == "D" then
					s_ObjectiveIndex = 4
				elseif s_Label == "E" then
					s_ObjectiveIndex = 5
				elseif s_Label == "F" then
					s_ObjectiveIndex = 6
				elseif s_Label == "G" then
					s_ObjectiveIndex = 7
				elseif s_Label == "H" then
					s_ObjectiveIndex = 8
				elseif s_Label == "I" then
					s_ObjectiveIndex = 9
				elseif s_Label == "J" then
					s_ObjectiveIndex = 10
				elseif s_Label == "K" then
					s_ObjectiveIndex = 11
				elseif s_Label == "L" then
					s_ObjectiveIndex = 12
				end
				
                local s_Transform = s_CaptureEntity.transform.trans

                if self.m_Objectives[s_ObjectiveIndex] == nil then
					
					s_AddObjectives = true
					
                elseif self.m_Objectives[s_ObjectiveIndex]['label'] ~= s_Label or
                        self.m_Objectives[s_ObjectiveIndex]['currentTeam'] ~= s_Team or
                        self.m_Objectives[s_ObjectiveIndex]['contested'] ~= s_Contested then
                    self:SendUIAction(UPDATE_OBJECTIVE, {
                        objective = {
                            label = s_Label,
                            currentTeam = s_Team,
                            contested = s_Contested,
                            position = { s_Transform.x, s_Transform.y, s_Transform.z }
                        },
                        index = s_ObjectiveIndex - 1
                    })
                end

                self.m_Objectives[s_ObjectiveIndex] = {
                    label = s_Label,
                    currentTeam = s_Team,
                    contested = s_Contested,
                    position = { s_Transform.x, s_Transform.y, s_Transform.z }
                }

                s_ObjectiveCounter = s_ObjectiveCounter + 1
            end

            s_Entity = s_Iterator:Next()
        end
		
		-- Add the Objectives here so the order is correct
		if s_AddObjectives == true then
			
			self:SendUIAction(CLEAR_OBJECTIVES, {})
			for s_ObjectiveIndex,m_Objective in pairs(self.m_Objectives) do
			
				self:SendUIAction(ADD_OBJECTIVE, {
					objective = {
						label = m_Objective.label,
						currentTeam = m_Objective.currentTeam,
						contested = m_Objective.contested,
						position = m_Objective.position
					}
				})
			end
		end
		s_AddObjectives = false
		
    end

    -- Refresh all objectives if there are now less.
    if s_ObjectiveCounter > 1 and self.m_Objectives[s_ObjectiveCounter] ~= nil then
        self:SendUIAction(CLEAR_OBJECTIVES, {})
		self.m_Objectives = {}
    end



    self.m_TempSquads  = { [1] = {}, [2] = {} }
    -- Initialize each team's squads.
    for i = 1, 34 do
        table.insert(self.m_TempSquads[1], 0)
        table.insert(self.m_TempSquads[2], 0)
    end

    local s_BatchedUpdate = ''
    local s_HasUpdate = false

    for i, s_Player in ipairs(PlayerManager:GetPlayers()) do
        if s_Player ~= nil and s_Player.teamId ~= TeamId.TeamNeutral then
            self.m_TempSquads[s_Player.teamId][s_Player.squadId + 1] = self.m_TempSquads[s_Player.teamId][s_Player.squadId + 1] + 1

            local s_PlayerData = self:GetPlayerData(s_Player)

            if self.m_PlayerMappings[s_Player.id] == nil then
                self.m_PlayerMappings[s_Player.id] = s_PlayerData['id']
                self.m_Players[s_PlayerData['id']] = s_PlayerData

                self:SendUIAction(SET_PLAYER, { player = s_PlayerData })
            else
                local s_OldData = self.m_Players[self.m_PlayerMappings[s_Player.id]]
                local s_ShouldUpdate = self:ShouldUpdatePlayer(s_OldData, s_PlayerData)

                if s_ShouldUpdate and s_OldData['team'] ~= s_PlayerData['team'] or s_OldData['squad'] ~= s_PlayerData['squad'] then
                    self.m_Players[s_OldData['id']] = nil;
                    self:SendUIAction(REMOVE_PLAYER, { player = s_OldData['id'] })
                else
                    s_PlayerData['id'] = s_OldData['id']
                end

                self.m_PlayerMappings[s_Player.id] = s_PlayerData['id']
                self.m_Players[s_PlayerData['id']] = s_PlayerData

                local s_Update = {
                    type = SET_PLAYER,
                    player = s_PlayerData
                }

                s_BatchedUpdate = s_BatchedUpdate .. string.format('window.store.dispatch(%s);', json.encode(s_Update))
                s_HasUpdate = true
            end
        end
    end

    if s_HasUpdate then
        WebUI:ExecuteJS(s_BatchedUpdate)
    end

    local s_KillCount = self.m_KillCount
    local s_UpdateKills = false
    local s_Kills = {}
    local s_NewKillCount = 0

    for i = 1, s_KillCount do
        if self.m_Kills[i] ~= nil and self.m_Kills[i]['delta'] ~= nil and self.m_Kills[i]['delta'] <= 0 then
            self.m_Kills[i] = nil
            s_UpdateKills = true
        else
            s_NewKillCount = s_NewKillCount + 1
            s_Kills[s_NewKillCount] = self.m_Kills[i]
        end
    end

    if s_UpdateKills then
        self.m_KillCount = s_NewKillCount
        self.m_Kills = s_Kills

        self:SendUIAction(SET_KILLFEED_KILLS, {
            kills = self.m_Kills
        })
    end

    if s_SpectatorMode > 0 then
        local s_SpectatedPlayer = SpectatorManager:GetSpectatedPlayer()

        if s_SpectatedPlayer ~= nil then
            self.m_LastPlayer = s_SpectatedPlayer.id
        end

        if s_SpectatedPlayer ~= nil and self.m_SpectatedPlayer ~= s_SpectatedPlayer.id then
            self.m_SpectatedPlayer = s_SpectatedPlayer.id
            self:SendUIAction(SET_SPECTATED_PLAYER, { player = self.m_PlayerMappings[self.m_SpectatedPlayer] })
        end
    else
        if self.m_SpectatedPlayer ~= -1 then
            self:SendUIAction(SET_SPECTATED_PLAYER, { player = nil })
        end

        self.m_SpectatedPlayer = -1
    end

    --[[local s_Freecam = SpectatorManager:GetFreecameraTransform().trans
    local s_CurrentPosition = { s_Freecam.x, s_Freecam.y, s_Freecam.z }

    if SpectatorManager:GetCameraMode() == SpectatorCameraMode.FirstPerson then
        local s_SpectatedPlayer = SpectatorManager:GetSpectatedPlayer()

        if s_SpectatedPlayer ~= nil and s_SpectatedPlayer.soldier ~= nil then
            local s_Transform = s_SpectatedPlayer.soldier.transform.trans
            s_CurrentPosition = { s_Transform.x, s_Transform.y, s_Transform.z }
        end
    end]]

    --[[ if s_CurrentPosition[1] ~= self.m_Position[1] or
         s_CurrentPosition[2] ~= self.m_Position[2] or
         s_CurrentPosition[3] ~= self.m_Position[3] then
         self.m_Position = s_CurrentPosition
         --self:SendUIAction(SET_CURRENT_POSITION, { position = s_CurrentPosition })
     end]]
end

function SpectatorUI:ShouldUpdatePlayer(p_OldData, p_NewData)
	if p_OldData == nil then
		return true
	end

    if p_OldData['team'] ~= p_NewData['team'] then
        return true
    end

    if p_OldData['squad'] ~= p_NewData['squad'] then
        return true
    end

    if p_OldData['currentWeapon'] ~= p_NewData['currentWeapon'] then
        return true
    end

    if p_OldData['health'] ~= p_NewData['health'] then
        return true
    end

    if p_OldData['maxHealth'] ~= p_NewData['maxHealth'] then
        return true
    end

    if p_OldData['kills'] ~= p_NewData['kills'] then
        return true
    end

    if p_OldData['deaths'] ~= p_NewData['deaths'] then
        return true
    end

    if p_OldData['score'] ~= p_NewData['score'] then
        return true
    end

    if p_OldData['accuracy'] ~= p_NewData['accuracy'] then
        return true
    end

    if p_OldData['score'] ~= p_NewData['score'] then
        return true
    end

    if p_OldData['score'] ~= p_NewData['score'] then
        return true
    end

    if p_OldData['transform'][1] ~= p_NewData['transform'][1] or
            p_OldData['transform'][2] ~= p_NewData['transform'][2] or
            p_OldData['transform'][3] ~= p_NewData['transform'][3] then
        return true
    end

    if p_OldData['screen'][1] ~= p_NewData['screen'][1] or
            p_OldData['screen'][2] ~= p_NewData['screen'][2] then
        return true
    end

    for i = 1, 10 do
        local s_OldWeapon = p_OldData['weapons'][i]
        local s_NewWeapon = p_NewData['weapons'][i]

        if (s_OldWeapon == nil and s_NewWeapon ~= nil) or
                (s_OldWeapon ~= nil and s_NewWeapon == nil) then
            return true
        end

        if s_OldWeapon ~= nil and s_NewWeapon ~= nil then
            if s_OldWeapon['name'] ~= s_NewWeapon['name'] then
                return true
            end

            if s_OldWeapon['displayName'] ~= s_NewWeapon['displayName'] then
                return true
            end

            if s_OldWeapon['ammo'] ~= s_NewWeapon['ammo'] then
                return true
            end

            if s_OldWeapon['ammoMags'] ~= s_NewWeapon['ammoMags'] then
                return true
            end
        end
    end

    return false
end

function SpectatorUI:GetCustomId(p_TeamId, p_SquadId, p_SquadPlayerCount)
    if p_SquadId == SquadId.SquadNone then
        return (TEAM_COUNT * SQUAD_COUNT * SQUAD_CAPACITY) + ((p_TeamId - 1) * TEAM_CAPACITY + p_SquadPlayerCount) + 1
    else
        return ((p_TeamId - 1) * SQUAD_COUNT * SQUAD_CAPACITY) + (((p_SquadId - 1) * SQUAD_CAPACITY) + p_SquadPlayerCount) + 1
    end
end

function SpectatorUI:GetPlayerData(p_Player)
    if p_Player == nil then
        return
    end

    local s_PlayerData = {}

    local s_SquadPlayerCount
    if p_Player.squadId == SquadId.SquadNone then
        s_SquadPlayerCount = self.m_TempSquads[p_Player.teamId][1] - 1
    else
        s_SquadPlayerCount = self.m_TempSquads[p_Player.teamId][p_Player.squadId + 1] - 1
    end

    s_PlayerData['id'] = self:GetCustomId(p_Player.teamId, p_Player.squadId, s_SquadPlayerCount)
    s_PlayerData['realId'] = p_Player.id
    s_PlayerData['name'] = p_Player.name
    s_PlayerData['team'] = p_Player.teamId
    s_PlayerData['squad'] = p_Player.squadId
    s_PlayerData['currentWeapon'] = 0
    s_PlayerData['health'] = 0
    s_PlayerData['maxHealth'] = 100
    s_PlayerData['kills'] = p_Player.kills
    s_PlayerData['deaths'] = p_Player.deaths
    s_PlayerData['score'] = p_Player.score
    s_PlayerData['accuracy'] = 1.0 -- TODO
    s_PlayerData['weapons'] = { nil, nil, nil, nil, nil, nil, nil, nil }
    s_PlayerData['transform'] = { 0.0, 0.0, 0.0 }
    s_PlayerData['screen'] = { -9999.0, -9999.0 }

    local s_Soldier = p_Player.soldier

    if s_Soldier ~= nil then

        s_PlayerData['health'] = s_Soldier.health
        local s_WeaponsComponent = s_Soldier.weaponsComponent

        if s_WeaponsComponent ~= nil then
            s_PlayerData['currentWeapon'] = s_WeaponsComponent.currentWeaponSlot

            for i,s_Weapon in pairs(s_WeaponsComponent.weapons) do
                s_PlayerData['weapons'][i] = {}
                
                if s_Weapon ~= nil then
                    local s_SoldierWeaponData = SoldierWeaponData(s_Weapon.data)
                    local s_SoldierWeaponBlueprint = s_SoldierWeaponData.soldierWeaponBlueprint
                    if s_SoldierWeaponBlueprint ~= nil then
                        s_SoldierWeaponBlueprint = SoldierWeaponBlueprint(s_SoldierWeaponBlueprint)
                    end
                        s_PlayerData['weapons'][i]['name'] = s_SoldierWeaponBlueprint.name or s_Weapon.name -- Old: GetWeaponEntityNameByIndex
                        s_PlayerData['weapons'][i]['displayName'] = s_Weapon.name -- Old: GetWeaponNameByIndex
                        s_PlayerData['weapons'][i]['ammo'] = s_Weapon.primaryAmmo
                        s_PlayerData['weapons'][i]['ammoMags'] = s_Weapon.secondaryAmmo
                    
                end
            end

            --s_PlayerData['transform'] = { s_Transform.x, s_Transform.y, s_Transform.z }

            --local s_W2S = SharedUtils:WorldToScreen(s_Transform)

            --[[if s_W2S ~= nil then
                s_PlayerData['screen'] = { s_W2S.x, s_W2S.y }
            else
                s_PlayerData['screen'] = { -9999.0, -9999.0 }
            end]]
        end
    end

    return s_PlayerData
end

return SpectatorUI
