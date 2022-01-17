local mod = RegisterMod('REDRUM', 1)
local json = require('json')
local game = Game()

mod.text = 'REDЯUM'

mod.state = {}
mod.state.roomCount = -1
mod.state.stageSeed = nil

function mod:onGameStart(isContinue)
  local level = game:GetLevel()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(level:GetStage())
  mod.state.stageSeed = stageSeed
  
  if mod:HasData() then
    local _, state = pcall(json.decode, mod:LoadData())
    
    if type(state) == 'table' then
      if math.type(state.stageSeed) == 'integer' and math.type(state.roomCount) == 'integer' then
        -- quick check to see if this is the same run being continued
        if state.stageSeed == stageSeed then
          mod.state.roomCount = state.roomCount
        end
      end
    end
    
    if not isContinue then
      mod.state.roomCount = -1
    end
  end
end

function mod:onGameExit()
  mod:SaveData(json.encode(mod.state))
end

function mod:onNewLevel()
  local level = game:GetLevel()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(level:GetStage())
  mod.state.stageSeed = stageSeed
  mod.state.roomCount = -1
end

function mod:onUpdate()
  local level = game:GetLevel()
  local rooms = level:GetRooms()
  local roomCount = #rooms -- rooms.Size
  
  if roomCount > mod.state.roomCount then
    local hud = game:GetHUD()
    
    -- only loop over new rooms
    for i = mod.state.roomCount > 0 and mod.state.roomCount or 0, roomCount - 1 do
      local roomDesc = rooms:Get(i)
      
      if mod:isRedRoom(roomDesc) then
        hud:ShowItemText(mod.text, nil, false) -- hud:ShowFortuneText(mod.text)
        break -- only show the text once
      end
    end
    
    mod.state.roomCount = roomCount
  end
end

function mod:isRedRoom(roomDesc)
  return roomDesc.Flags & RoomDescriptor.FLAG_RED_ROOM ~= 0
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.onNewLevel)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)