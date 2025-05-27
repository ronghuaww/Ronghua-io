--!Type(Module)


local getCoinsPosRequest = Event.new("GetCoinsPosRequest")
local getCoinsPosResponse = Event.new("GetCoinsPosResponse")

local removeCoinEvent = Event.new("RemoveCoinEvent")
local spawnNewCoinsEvent = Event.new("SpawnNewCoinsEvent")

--!SerializeField
local coinPrefab : GameObject = nil -- Prefab for the coin to be spawned, initialized to nil

--!SerializeField
local maxCoinValue : number = 50
--!SerializeField
local minCoinScale : number = 0.3
--!SerializeField
local maxCoinScale : number = 5

--!SerializeField
local floorScale : Vector3 = Vector3.new(10, 0, 10)
--!SerializeField
local floorPos : Vector3 = Vector3.new(0, 0.5, 0)


local spawnedCoins = {} -- Table to keep track of currently spawned coins
local initialCoinCount : number = 25 
local maxIdLength : number = 6

--[[
    CLIENT
]]

-- Function to spawn a coin at a specific position
function SpawnCoin(id: string, position: Vector3, worth: number)
  local coin = Object.Instantiate(coinPrefab) -- Create a new coin instance from the prefab
  
  coin.transform.position = position -- Set the coin's new position
  local scaleRatio = minCoinScale + (maxCoinScale * worth/maxCoinValue) -- linear scaling of the object based on its worth
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
  removeCoinEvent:FireServer(id, coinObj)
  GameObject.Destroy(coinObj)
  spawnedCoins[id] = nil 
  --coin:SetActive(false) -- Deactivate the coin to simulate destruction 
  --DestroyCoinRequest:FireServer(coin.id)  
end


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
  getCoinsPosRequest:FireServer()

  getCoinsPosResponse:Connect(function(coins)

    local oldCoins = GameObject.FindGameObjectsWithTag("Coin")

    PopulateScene(coins)



    -- delete 
    -- loop through the list 
    local count = 0
    for i = 1, #oldCoins do 
        GameObject.Destroy(oldCoins[i])
      count += 1
    end 
    print(count, "number of coins in the scene")


  end)


  Timer.Every(5, function()
    getCoinsPosRequest:FireServer()  

  end) 


end
  

--[[
    SERVER
]]

function GenerateCoinsData(numCoin: number)
  coins = {}
  for i = 1, numCoin, 1 do
    local coinId = math.random(1, Mathf.Pow(10, maxIdLength))
    local coinValue = math.random(1, maxCoinValue)

    local xPos = (math.random() * 2) - 1
    xPos = (xPos * floorScale.x) + floorPos.x

    local zPos = (math.random() * 2) - 1
    zPos = (zPos * floorScale.z) + floorPos.z

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
    -- spawnNewCoinsEvent:FireAllClients()
  end) 


  -- Listen for coin Positions from clients
  getCoinsPosRequest:Connect(function(player, floorScale, floorPos)

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
            storageCoins = GenerateCoinsData(initialCoinCount)
          end

          getCoinsPosResponse:FireClient(player, storageCoins)

        end
      end)
    end

    Search("CoinId", initialCoinCount, "")

  end)





  removeCoinEvent:Connect(function(player, id, coinObj)
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

    Search(id, initialCoinCount, "")

  end)
end

function self:ServerOnDestroy()

  local dirtyCoinsNames = {}

      function Search(key: string, limit: number, cursorId: string)
      Storage.SearchValue(key, limit, cursorId, function(data, newCursorId, errorCode)
        if(data == nil) then
          print(`Got error {StorageError[errorCode]} while searching`)
          return
        end
        
        for index, entry in data do
          for key, value in entry do
            if value.Dirty == true then 
            table.insert(dirtyCoinsNames, key)
            end 
          end
        end
        
        if(newCursorId ~= nil) then
          Search(key, limit, newCursorId)
        else
          print("end search")
        end
      end)
    end

    Search("CoinId", initialCoinCount, "")

    for i = 1, #dirtyCoinsNames do 
      print("omg am i actually")
      Storage.DeleteValue(dirtyCoinsNames[i])
    end 


end

