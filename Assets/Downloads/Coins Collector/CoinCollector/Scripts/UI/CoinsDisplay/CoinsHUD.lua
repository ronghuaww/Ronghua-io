--!Type(UI)

--!SerializeField
local CoinImage : Texture = nil -- Texture for the coin icon, initialized to nil

--!Bind
local _CoinIcon : UIImage = nil -- UIImage for displaying the coin icon, initialized to nil

--!Bind
local _CoinLabel : UILabel = nil -- UILabel for displaying the number of coins, initialized to nil

-- Function to update the coin icon image
function PopulateIcon(icon: Texture)
  _CoinIcon.image = icon -- Set the image of the coin icon to the provided texture
end

-- Function to update the coin count display
function PopulateCoins(coins: number)
  _CoinLabel:SetPrelocalizedText(tostring(coins)) -- Set the text of the coin label to the number of coins
end

PopulateCoins(0) -- Initialize the coin display with 0 coins
PopulateIcon(CoinImage) -- Initialize the coin icon with the provided CoinImage texture
