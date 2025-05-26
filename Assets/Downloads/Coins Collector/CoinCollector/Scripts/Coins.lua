--!Type(ClientAndServer)

--!SerializeField
local _id : string = ""
local _value : number = 0

local CoinSound : AudioShader = nil -- AudioShader for the sound effect to play when collecting a coin, initialized to nil

--!SerializeField
local Amount : number = 1 -- Number of coins to add to the player's total when collecting a coin

local coinsTracker = require("CoinsTracker") -- Require the CoinsTracker module to manage and update the player's coin count
local coinsManager = require("CoinsManager") -- Require the CoinsSpawner module to handle coin spawning and destruction

local shader = nil -- Variable for storing a shader, initialized to nil (currently unused)

InitializeCoinValues = function(id: string, value: number)
  _id = id
  _value = value
end


-- Function called when the script's object is initialized
function self:ClientAwake()
  Amount = math.random(1, 73) 


  -- Function called when another collider enters the trigger collider attached to this game object
  function self:OnTriggerEnter(other : Collider)
    print("single trigger")
    local playerCharacter = other.gameObject:GetComponent(Character) -- Get the Character component from the other game object
    if playerCharacter == nil then return end -- If the other game object does not have a Character component, exit the function
    
    local player = playerCharacter.player -- Get the player associated with the character
    if client.localPlayer == player then -- Check if the local player is the same as the player associated with the character
      print("plaer is not nil")
      if CoinSound ~= nil then -- If CoinSound is not nil (i.e., a sound has been assigned)
        Audio:PlayShader(CoinSound) -- Play the coin collection sound effect
      end

     -- coinsTracker.AddCoins(Amount) -- Add the specified amount of coins to the player's total
      coinsManager.DestroyCoin(self.gameObject, _id) -- Destroy the coin game object that this script is attached to
    end
  end
end
