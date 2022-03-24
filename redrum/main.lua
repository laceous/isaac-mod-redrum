local mod = RegisterMod('REDRUM', 1)
local json = require('json')
local game = Game()

mod.text = 'REDЯUM'

mod.state = {}
mod.state.stageSeeds = {} -- per stage
mod.state.roomCounts = {} -- per stage/type

function mod:onGameStart(isContinue)
  local level = game:GetLevel()
  local stage = level:GetStage()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(stage)
  mod:setStageSeed(stageSeed)
  mod:setRoomCount(-1)
  
  if isContinue and mod:HasData() then
    local _, state = pcall(json.decode, mod:LoadData())
    
    if type(state) == 'table' then
      if type(state.stageSeeds) == 'table' then
        -- quick check to see if this is the same run being continued
        if state.stageSeeds[tostring(stage)] == stageSeed then
          for key, value in pairs(state.stageSeeds) do
            if type(key) == 'string' and math.type(value) == 'integer' then
              mod.state.stageSeeds[key] = value
            end
          end
          if type(state.roomCounts) == 'table' then
            for key, value in pairs(state.roomCounts) do
              if type(key) == 'string' and math.type(value) == 'integer' then
                mod.state.roomCounts[key] = value
              end
            end
          end
        end
      end
    end
  end
end

function mod:onGameExit(shouldSave)
  if shouldSave then
    mod:SaveData(json.encode(mod.state))
    mod:clearStageSeeds()
    mod:clearRoomCounts()
  else
    mod:clearStageSeeds()
    mod:clearRoomCounts()
    mod:SaveData(json.encode(mod.state))
  end
end

function mod:onNewLevel()
  local level = game:GetLevel()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(level:GetStage())
  mod:setStageSeed(stageSeed)
  mod:setRoomCount(-1)
end

function mod:onUpdate()
  local level = game:GetLevel()
  local rooms = level:GetRooms()
  local roomCount = #rooms -- rooms.Size
  local stateRoomCount = mod:getRoomCount()
  
  if roomCount < stateRoomCount then
    mod:setRoomCount(roomCount) -- could happen because of glowing hour glass
  elseif roomCount > stateRoomCount then
    local hud = game:GetHUD()
    
    -- only loop over new rooms
    for i = stateRoomCount > 0 and stateRoomCount or 0, roomCount - 1 do
      local roomDesc = rooms:Get(i)
      
      if mod:isRedRoom(roomDesc) then
        hud:ShowItemText(mod.text, nil, false) -- hud:ShowFortuneText(mod.text)
        break -- only show the text once
      end
    end
    
    mod:setRoomCount(roomCount)
  end
end

function mod:isRedRoom(roomDesc)
  return roomDesc.Flags & RoomDescriptor.FLAG_RED_ROOM == RoomDescriptor.FLAG_RED_ROOM
end

function mod:getRoomCount()
  local roomCount = mod.state.roomCounts[mod:getStageIndex()]
  return roomCount and roomCount or -1
end

function mod:setRoomCount(count)
  mod.state.roomCounts[mod:getStageIndex()] = count
end

function mod:clearRoomCounts()
  for key, _ in pairs(mod.state.roomCounts) do
    mod.state.roomCounts[key] = nil
  end
end

function mod:getStageIndex()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local isAltStage = level:IsAltStage()
  
  -- home switches these midway through, keep it consistent
  if stage == LevelStage.STAGE8 then
    stageType = StageType.STAGETYPE_ORIGINAL -- normal: STAGETYPE_ORIGINAL -> STAGETYPE_WOTL
    isAltStage = false                       -- normal: false -> true
  end
  
  return game:GetVictoryLap() .. '-' .. stage .. '-' .. stageType .. '-' .. (isAltStage and 1 or 0) .. '-' .. (level:IsPreAscent() and 1 or 0) .. '-' .. (level:IsAscent() and 1 or 0)
end

function mod:setStageSeed(seed)
  local level = game:GetLevel()
  mod.state.stageSeeds[tostring(level:GetStage())] = seed
end

function mod:clearStageSeeds()
  for key, _ in pairs(mod.state.stageSeeds) do
    mod.state.stageSeeds[key] = nil
  end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.onNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)