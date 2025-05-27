--!Type(Module)

-- Define events for requesting and responding to coin-related actions
local getCoinsInfoRequest = Event.new("GetCoinsInfoRequest") -- Event for requesting non-dirty coins from storage
local getCoinsInfoResponse = Event.new("GetCoinsInfoResponse") -- Event for responding non-dirty coins from storage

local removeCoinEvent = Event.new("RemoveCoinEvent") -- Event for removing coin from scene
local spawnNewCoinsEvent = Event.new("SpawnNewCoinsEvent") -- Event for spawning new coin from scene

--!SerializeField
local coinPrefab : GameObject = nil -- Prefab for the coin to be spawned, initialized to nil

--!SerializeField
local maxCoinWorth : number = 50 -- maximum value a coin's worth can be 
--!SerializeField
local minCoinScale : number = 0.3 -- minimum scale a coin gameobj can be
--!SerializeField
local maxCoinScale : number = 5 -- maximum scale a coin gameobj can be

--!SerializeField
local floorScale : Vector3 = Vector3.new(10, 0, 10) -- the space coins can spawn on 
--!SerializeField
local floorPos : Vector3 = Vector3.new(0, 0.5, 0) -- the origin position the coins can spawn on 

--!SerializeField
local syncSceneTimer : number = 5 -- timer increments for syncing the scene 

--!SerializeField
local spawnCoinsTimer : number = 10 -- timer increments for spawning coins

local coinCountPerSpawn : number = 3 -- number of coins spawn per increment


local spawnedCoins = {} -- Table to keep track of currently spawned coins
local initialCoinCount : number = 25 -- coin count if none in storage
local maxIdLength : number = 6 -- maximum tens place for coin ids

--[[
    CLIENT
]]

-- Function to spawn a coin at a specific position
function SpawnCoin(id: string, position: Vector3, worth: number)
  local coin = Object.Instantiate(coinPrefab) -- Create a new coin instance from the prefab
  
  coin.transform.position = position -- Set the coin's new position
  local scaleRatio = minCoinScale + ((maxCoinScale - minCoinScale) * worth/maxCoinWorth) -- linear scaling of the object based on its worth
  coin.transform.localScale = Vector3.new(scaleRatio, scaleRatio, scaleRatio)    

  local coinInfo = coin.GetComponent(coin, CoinCollectorScript) -- grab its script component
  if coinInfo ~= nil then
    coinInfo.InitializeCoinValues(id, worth) -- update the new initialized coin with its id and worth
  end

  spawnedCoins[id] = coin
  coin:SetActive(true) -- Ensure the coin is active when first spawned
end

-- Function to destroy a coin
function DestroyCoin(coinObj: GameObject, id: string)
  removeCoinEvent:FireServer(id)
  GameObject.Destroy(coinObj)
  spawnedCoins[id] = nil 
end

-- Function to populate a scene 
function PopulateScene(newCoins)
  -- newCoins is a table with coin id as key and coinData in its value
    for key, value in pairs(newCoins) do
      local coinPos = Vector3.new(value.XPos, 0, value.ZPos)
      if coinPos then -- If the spawn point is valid, spawn a coin there
        SpawnCoin(key, coinPos, value.Value) 
      end 
    end
end

-- Function to handle client initialization
function self:ClientAwake()
  getCoinsInfoRequest:FireServer() -- Fire to server for the getCoinsInfoRequest event

  -- Connect to the getCoinsInfoResponse event
  getCoinsInfoResponse:Connect(function(newCoins) 
    local oldCoins = GameObject.FindGameObjectsWithTag("Coin") -- keep track of old coins on screen 
    PopulateScene(newCoins) -- populate the scene with new coins

    for i = 1, #oldCoins do -- deleting the old coins that previously in scene
        GameObject.Destroy(oldCoins[i])
    end 
  end)

  -- Timer to sync the local scene with the server storage 
  Timer.Every(syncSceneTimer, function() 
    print("Syncing the scene with the server...")
    getCoinsInfoRequest:FireServer() -- Fire to server for the getCoinsInfoRequest event
  end) 
end
  
--[[
    SERVER
]]

-- Function to generate new coin position and worth given count 
function GenerateCoinsData(numCoin: number)
  coins = {}
  for i = 1, numCoin, 1 do
    local coinId = math.random(1, Mathf.Pow(10, maxIdLength)) -- coin id
    local coinWorth = math.random(1, maxCoinWorth) -- coin worth

    local xPos = (math.random() * 2) - 1 -- coin x pposition
    xPos = (xPos * floorScale.x) + floorPos.x

    local zPos = (math.random() * 2) - 1 -- coin z pposition
    zPos = (zPos * floorScale.z) + floorPos.z

    local coin = {
      Value = coinWorth, 
      XPos = xPos, 
      ZPos = zPos, 
      Dirty = false
    }

    table.insert(coins, coin) 
    Storage.SetValue("CoinId" .. tostring(coinId), coin) -- update the storage with new coin and its data 
  end
  return coins
end

-- Function to handle server initialization
function self:ServerAwake()

  -- Timer to spawn new coins onto the scene
  Timer.Every(spawnCoinsTimer, function() 
    local storageCoins = {}
    print("Adding new coins to the server...")
    storageCoins = GenerateCoinsData(coinCountPerSpawn)
  end) 

  -- Listen for coin info reequests from clients
  getCoinsInfoRequest:Connect(function(player, floorScale, floorPos)

    local count = 0 
    local storageCoins = {}
    -- searching through the storage recursively to find existing coins, if any 
    function Search(key: string, limit: number, cursorId: string)
      Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
        if(data == nil) then -- if the request fails, print out error 
          print(`Got error {StorageError[errorCode]} while searching`)
          return
        end
        
        for index, entry in data do
          for key, value in entry do
            if value.Dirty == false then 
              local coin = {
                  Value = value.Value, 
                  XPos = value.XPos, 
                  ZPos = value.ZPos, 
                  Dirty = false
                }
              storageCoins[key] = coin -- adding the found coins to a list 
              count += 1
            end 
          end
        end
        
        if(newCursorId ~= nil) then
          Search(key, limit, newCursorId) -- recursively call if there is more coins to look at 
        else
          if count == 0 then -- if there is no coins in storage, generate some 
            storageCoins = GenerateCoinsData(initialCoinCount)
          end
          getCoinsInfoResponse:FireClient(player, storageCoins) -- Fire found coints to client
        end
      end)
    end

    Search("CoinId", initialCoinCount, "") -- looks for coins that start with "CoinId"

  end)

  -- Listen for coin removal reequests from clients
  removeCoinEvent:Connect(function(player, id)
    -- searching through the storage recursively to find the deleted coin, if any 
    function Search(key: string, limit: number, cursorId: string)
      local foundBool = false
      Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
        if(data == nil) then -- if the request fails, print out error 
          print(`Got error {StorageError[errorCode]} while searching`)
          return
        end
        
        for index, entry in data do
          for key, value in entry do
            if key == id then 
            foundBool = true 

            local coin = {
              Value = value.Value, 
              XPos = value.XPos, 
              ZPos = value.ZPos, 
              Dirty = true -- when coin is found in storage, it is flag as dirty
            }

            Storage.SetValue(key, coin)
            end 
          end
        end
        
        if(newCursorId ~= nil and foundBool == false) then
          Search(key, limit, newCursorId) -- recursively call if not found
        end
      end)
    end
    Search(id, initialCoinCount, "") -- looks for coins given its id
  end)
end

-- Function to handle server Destroy
function self:ServerOnDestroy()

  local dirtyCoinsNames = {}

  -- searching through the storage recursively to find all dirty coins, if any 
  function Search(key: string, limit: number, cursorId: string)
  Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
    if(data == nil) then -- if the request fails, print out error 
      print(`Got error {StorageError[errorCode]} while searching`)
      return
    end
    
    for index, entry in data do
      for key, value in entry do
        if value.Dirty == true then 
        table.insert(dirtyCoinsNames, key) -- adding the dirty coins to a list
        end 
      end
    end
    
    if(newCursorId ~= nil) then
      Search(key, limit, newCursorId) -- recursively call if there is more coins to look at 
    end
  end)
  end

  Search("CoinId", initialCoinCount, "") -- looks for coins that start with "CoinId"

  for i = 1, #dirtyCoinsNames do 
    Storage.DeleteValue(dirtyCoinsNames[i]) -- remove every dirty values from storage
  end 


end

