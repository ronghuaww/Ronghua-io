--!Type(Module)

local UpdatePlayerCoinsRequest = Event.new("UpdatePlayerCoinsRequest")

-- Define events for requesting and responding to coin-related actions
local GetCoinsRequest = Event.new("GetCoinsRequest") -- Event for requesting the player's coin count
local GetCoinsResponse = Event.new("GetCoinsResponse") -- Event for responding with the player's coin count
local UpdateCoinsEvent = Event.new("UpdateCoinsEvent") -- Event for updating the player's coin count

local GetTopPlayersRequest = Event.new("GetTopPlayersRequest") -- Event for requesting the top players
local GetTopPlayersResponse = Event.new("GetTopPlayersResponse") -- Event for responding with the top players

local players = {} -- Table to store player information including their coin count
local CoinsUI = nil -- Reference to the UI component for displaying coins, initialized to nil
local topPlayers = {} -- Table to store the top players' information

-- Function to track players in the game and set up character change callbacks
local function TrackPlayers(game, callBack)
  -- Connect to the PlayerConnected event
  game.PlayerConnected:Connect(function(player) 
      players[player.name] = { -- Initialize player data
        playerName = player.name,
        coins = 0 -- Start with 0 coins
      }
  end)

  -- Connect to the PlayerDisconnected event
  game.PlayerDisconnected:Connect(function(player)

    -- searching the player from the topPlayers list 
    local indexTopPlayer = -1
    for i = 1, #topPlayers do
      if topPlayers[i].name == player.name then 
        indexTopPlayer = i
        break
      end 
    end 

    -- removing the player from the topPlayers list 
    if indexTopPlayer ~= -1 then 
      table.remove(topPlayers, indexTopPlayer)
    end

    -- searching the player from the topPlayers list 
    local indexPlayer = -1
    for i = 1, #players do
      if players[i].name == player.name then 
        indexPlayer = i
        break
      end 
    end 

    -- removing the player from the player list 
    if indexPlayer ~= -1 then 
      table.remove(players, indexPlayer)
    end
  end)
end

-- Function to add coins to the local player's total
AddCoins = function(coins: number)
  local player = client.localPlayer -- Get the local player
  local playerInfo = players[player.name] -- Get the player's information

  local coinSum = playerInfo.coins + coins -- Calculate the new coin total
  playerInfo.coins = coinSum -- Update the player's coin total

  UpdateCoinsEvent:FireServer(coins) -- Notify the server of the coin update
  CoinsUI.PopulateCoins(coinSum) -- Update the UI to show the new coin total
end

-- Function to get the list of top players sorted by coin count
GetTopPlayers = function()
  table.sort(topPlayers, function(a, b)
    return a.coins > b.coins -- Sort players by coin count in descending order
  end)

  return topPlayers -- Return the sorted list of top players
end

-- Function to initialize the client-side setup
function self:ClientAwake()
  if CoinsUI == nil then -- Check if the CoinsUI reference is not set
    CoinsUI = self.gameObject:GetComponent(CoinsHUD) -- Get the CoinsHUD component from the game object
  end

  GetTopPlayersRequest:FireServer(0)

  GetTopPlayersResponse:Connect(function(newTopPlayers)
    topPlayers = newTopPlayers -- Update the list of top players
  end)

  TrackPlayers(client) -- Start tracking players on the client side
end

-- Function to initialize the server-side setup
function self:ServerAwake()
  TrackPlayers(server) -- Start tracking players on the server side

  Storage.GetValue("TopPlayers", function(k)
    if k == nil then k = {} end -- Initialize topPlayers if not found
    topPlayers = k -- Load the top players from storage
  end)


  -- Listen for updated coin info reequests from clients
  UpdateCoinsEvent:Connect(function(player, coins)
    local playerInfo = players[player.name] -- Get the player's information
    
    if playerInfo == nil then
        print("Player info not found for player: " .. player.name) -- Log if player info is not found
        return
    end

    local newCoinsValue = playerInfo.coins + coins -- Calculate the new coin total
    playerInfo.coins = newCoinsValue -- Update the player's coin total

    print(player.name .. " is updating coins to " .. tostring(newCoinsValue)) -- Log the coin update
    --Storage.IncrementPlayerValue(player, "Coins", coins) -- Increment the player's coin count in storage

    local playerEntry = { name = player.name, coins = newCoinsValue } -- Create an entry for the player
    local found = false -- Flag to check if the player is already in the top players list

    for i = 1, #topPlayers do -- Iterate through the top players
        if topPlayers[i].name == player.name then -- Check if the player is already in the list
            topPlayers[i] = playerEntry -- Update the player's entry
            found = true
            break
        end
    end

    if not found then
        print("Adding new entry for player: " .. player.name) -- Log if a new entry is added
        table.insert(topPlayers, playerEntry) -- Add the new player entry
    end

    table.sort(topPlayers, function(a, b)
        return a.coins > b.coins -- Sort top players by coin count in descending order
    end)

    local topPlayersToSend = {} -- Table to hold the top players to send to clients
    for i = 1, math.min(10, #topPlayers) do
        table.insert(topPlayersToSend, topPlayers[i]) -- Add the top players to send
    end

    print("Sending top players") -- Log sending top players
    GetTopPlayersResponse:FireAllClients(topPlayersToSend) -- Respond to all clients with the top players
    Storage.SetValue("TopPlayers", topPlayers) -- Save the updated top players list to storage
  end)

  -- Listen for get top players reequests from clients
  GetTopPlayersRequest:Connect(function(player, totalCoins)

    Storage.GetValue("TopPlayers", function(oldList) -- grabbing the top players from storage
      
      local newList = {}
      if oldList == nil then oldList = newList end 
      for index, entry in oldList do
        if entry.name ~= player.name then
          table.insert(newList, entry) -- grabbing all the other players
        end
      end
      
      local playerInfo = {name = player.name, coins = totalCoins}
      table.insert(newList, playerInfo) -- adding player starting at zero

      topPlayers = newList -- Load the top players from storage

      local topPlayersToSend = {} -- Table to hold the top players to send to clients
      table.sort(topPlayers, function(a, b)
        return a.coins > b.coins -- Sort top players by coin count in descending order
      end)

      for i = 1, math.min(10, #topPlayers) do
        table.insert(topPlayersToSend, topPlayers[i]) -- Add the top players to send
      end
      
      print("Sending top players...") -- Log sending top players
      GetTopPlayersResponse:FireAllClients(topPlayersToSend) -- Respond to all clients with the top players
      Storage.SetValue("TopPlayers", topPlayers) -- Save the updated top players list to storage
    end)
  end)

end

-- Function to handle server Destroy
function self:ServerOnDestroy()
  Storage.DeleteValue("TopPlayers") -- remove topPlayers from storage
end