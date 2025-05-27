--!Type(Module)


local GetCoinsPosRequest = Event.new("GetCoinsPosRequest")
local GetCoinsPosResponse = Event.new("GetCoinsPosResponse")
local RemoveCoinEvent = Event.new("RemoveCoinEvent")

local SpawnNewCoinsEvent = Event.new("SpawnNewCoinsEvent")

--!SerializeField
local InitialCoinCount : number = 25 
local MaxCoinValue : number = 50
local MinCoinScale : number = 0.3
local MaxCoinScale : number = 5

local MaxIdLength : number = 6

local FloorScale : Vector3 = Vector3.new(10, 0, 10)
local FloorPos : Vector3 = Vector3.new(0, 0.5, 0)


--!SerializeField
--local Coins : { Transform } = nil -- Array of Transform objects for coin spawn points, initialized to nil

--!SerializeField
local InitialCoinCount : number = 25 -- Delay time in seconds before a coin respawns after being collected

--!SerializeField
local CoinPrefab : GameObject = nil -- Prefab for the coin to be spawned, initialized to nil


local spawnedCoins = {} -- Table to keep track of currently spawned coins



-- Function to spawn a coin at a specific position
function SpawnCoin(id: string, position: Vector3, value: number)

  local coin = Object.Instantiate(CoinPrefab) -- Create a new coin instance from the prefab
  coin.transform.position = position -- Set the coin's position to the specified position
  local scaleRatio = MinCoinScale + (MaxCoinScale * value/MaxCoinValue)
  coin.transform.localScale = Vector3.new(scaleRatio, scaleRatio, scaleRatio)    

  local coinInfo = coin.GetComponent(coin, CoinCollectorScript)
  if coinInfo ~= nil then
    coinInfo.InitializeCoinValues(id, value)
  end
  spawnedCoins[id] = coin
  coin:SetActive(true) -- Ensure the coin is active when first spawned
end

-- Function to destroy a coin and respawn it after a delay
function DestroyCoin(coinObj: GameObject, id: string)
  RemoveCoinEvent:FireServer(id, coinObj)
  GameObject.Destroy(coinObj)
  spawnedCoins[id] = nil 
  --coin:SetActive(false) -- Deactivate the coin to simulate destruction 
  --DestroyCoinRequest:FireServer(coin.id)  
end


  
--[[
    CLIENT
]]

function PopulateScene(coinData)
    local count = 0

    for key, value in pairs(coinData) do
      local coinPos = Vector3.new(value.XPos, 0, value.ZPos)
      if coinPos then 
        count += 1
        SpawnCoin(key, coinPos, value.Value) 
      end -- If the spawn point is valid, spawn a coin there
    end
end

-- Function to handle client initialization
function self:ClientAwake()
  GetCoinsPosRequest:FireServer()

  GetCoinsPosResponse:Connect(function(coins)

    local oldCoins = GameObject.FindGameObjectsWithTag("Coin")

    PopulateScene(coins)



    print("deleting")
    -- delete 
    -- loop through the list 
    local count = 0
    for i = 1, #oldCoins do 
      print("deleted", tostring(oldCoins[i]))
        GameObject.Destroy(oldCoins[i])
      count += 1
    end 
    print(count, "number of coins in the scene")


  end)


  Timer.Every(5, function()
    GetCoinsPosRequest:FireServer()  
  end) 

  -- SpawnNewCoinsEvent:Connect(function(coins)
  --   GetCoinsPosRequest:FireServer()
  -- end)

  -- Timer.Every(10, function()
  --   local storageCoins = {}
  --   print("new coins")
  --   storageCoins = GenerateCoinsData(3)
  --   GetCoinsPosRequest:FireServer()
  -- end) 


end
  

--[[
    SERVER
]]

function GenerateCoinsData(numCoin: number)
  coins = {}
  for i = 1, numCoin, 1 do
    local coinId = math.random(1, Mathf.Pow(10, MaxIdLength))
    local coinValue = math.random(1, MaxCoinValue)

    local xPos = (math.random() * 2) - 1
    xPos = (xPos * FloorScale.x) + FloorPos.x

    local zPos = (math.random() * 2) - 1
    zPos = (zPos * FloorScale.z) + FloorPos.z

    local coin = {
      Value = coinValue, 
      XPos = xPos, 
      ZPos = zPos, 
      Dirty = false
    }

    table.insert(coins, coin)
    Storage.SetValue("CoinId" .. tostring(coinId), coin) 
  end
  return coins
end



-- Function to handle server initialization
function self:ServerAwake()

  Timer.Every(10, function()
    local storageCoins = {}
    print("new coins")
    storageCoins = GenerateCoinsData(3)
    -- SpawnNewCoinsEvent:FireAllClients()
  end) 


  -- Listen for coin Positions from clients
  GetCoinsPosRequest:Connect(function(player, floorScale, floorPos)

    local count = 0 
    local storageCoins = {}
    function Search(key: string, limit: number, cursorId: string)
      Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
        if(data == nil) then
          print(`Got error {StorageError[errorCode]} while searching`)
          return
        end
        
        for index, entry in data do
          for key, value in entry do
            if value.Dirty == false then 
              -- name as the key and its value as the value
              local coin = {
                  Value = value.Value, 
                  XPos = value.XPos, 
                  ZPos = value.ZPos, 
                  Dirty = false
                }
              storageCoins[key] = coin
              count += 1
            end 
          end
        end
        
        if(newCursorId ~= nil) then
          Search(key, limit, newCursorId)
        else
  --print("done"
          print("grab from storage", count)
          if count == 0 then 
          -- print("there is nothing") 
            storageCoins = GenerateCoinsData(InitialCoinCount)
          end

          GetCoinsPosResponse:FireClient(player, storageCoins)

        end
      end)
    end

    Search("CoinId", InitialCoinCount, "")

  end)





  RemoveCoinEvent:Connect(function(player, id, coinObj)
    print("in event destorying", id)

    function Search(key: string, limit: number, cursorId: string)
      local foundBool = false
      Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
        if(data == nil) then
          print(`Got error {StorageError[errorCode]} while searching`)
          return
        end
        
        for index, entry in data do
          for key, value in entry do
            if key == id then 
            foundBool = true
            -- found the coin in the game 
            -- delete it 
            local coin = {
              Value = value.Value, 
              XPos = value.XPos, 
              ZPos = value.ZPos, 
              Dirty = true
            }

            Storage.SetValue(key, coin)
            end 
          end
        end
        
        if(newCursorId ~= nil and foundBool == false) then
          Search(key, limit, newCursorId)
        else
          print("end search")
        end
      end)
    end

    Search(id, InitialCoinCount, "")

  end)
  



end