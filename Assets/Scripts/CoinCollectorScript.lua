--!Type(Client)

local id : string = "" -- id associated with each coin from storage
local worth : number = 0 -- worth value of this coin

local CoinSound : AudioShader = nil -- AudioShader for the sound effect to play when collecting a coin, initialized to nil

--!SerializeField
local Amount : number = 1 -- Number of coins to add to the player's total when collecting a coin

local CoinsTracker = require("CoinsTracker") -- Require the CoinsTracker module to manage and update the player's gui
local CoinsSpawner = require("CoinsSpawner") -- Require the CoinsSpawner module to handle coin spawning and destruction

-- Function to updatee the id and worth of coin 
InitializeCoinValues = function(id: string, value: number)
  id = id
  worth = value
end

-- Function called when the script's object is initialized
function self:Awake()

  -- Function called when another collider enters the trigger collider attached to this game object
  function self:OnTriggerEnter(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character) -- Get the Character component from the other game object
    if playerCharacter == nil then return end -- If the other game object does not have a Character component, exit the function
        
    CoinsSpawner.DestroyCoin(self.gameObject, id) -- Destroy the coin game object that this script is attached to

    local player = playerCharacter.player -- Get the player associated with the character
    print(player.name, "interacted with a coin worth", worth)

    if client.localPlayer == player then -- Check if the local player is the same as the player associated with the character
      if CoinSound ~= nil then -- If CoinSound is not nil (i.e., a sound has been assigned)
        Audio:PlayShader(CoinSound) -- Play the coin collection sound effect
      end

     CoinsTracker.AddCoins(worth) -- Add the specified amount of coins to the player's total
    end
  end
end
