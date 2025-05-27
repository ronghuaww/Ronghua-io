--!Type(UI)

--!SerializeField
local LeaderboardTitle : string = "Leaderboard" -- Title for the leaderboard UI, initialized with the string "Leaderboard"

--!SerializeField
local UpdateInterval : number = 1 -- seconds -- Interval in seconds to update the leaderboard

--!Bind
local _Title : UILabel = nil -- UILabel for displaying the leaderboard title, initialized to nil

--!Bind
local _rankList : VisualElement = nil -- VisualElement for displaying the list of ranked players, initialized to nil

local CoinsTracker = require("CoinsTracker") -- Require the CoinsTracker module to track and fetch player coins

-- Function to initialize the UI elements
function Insitialize()
  _Title:SetPrelocalizedText(tostring(LeaderboardTitle)) -- Set the title text of the leaderboard to the LeaderboardTitle value
end

Insitialize() -- Call the initialization function

-- Function to update the leaderboard with the top players
function UpdateLeaderboard(TopPlayers)
  _rankList:Clear() -- Clear the current list of ranked players from the UI

  if not TopPlayers or #TopPlayers == 0 then -- Check if the TopPlayers list is empty or not provided
    return -- Exit the function if there are no top players
  end

  local playersCount = #TopPlayers -- Get the number of top players
  if playersCount > 10 then -- Limit the number of displayed players to 10
    playersCount = 10
  end

  for i = 1, playersCount do -- Iterate through the top players list up to the number of players to display
    local rankItem = VisualElement.new() -- Create a new VisualElement for each player
    rankItem:AddToClassList("rank-item") -- Add a class to the VisualElement for styling

    local entry = TopPlayers[i] -- Get the player data at index i
    local name = entry.name -- Extract the player's name
    local score = entry.coins -- Extract the player's score (coins)

    local _nameLabel = UILabel.new() -- Create a new UILabel for the player's name
    _nameLabel:AddToClassList("name-label") -- Add a class to the UILabel for styling
    _nameLabel:SetPrelocalizedText(name) -- Set the text of the UILabel to the player's name

    local _scoreLabel = UILabel.new() -- Create a new UILabel for the player's score
    _scoreLabel:AddToClassList("score-label") -- Add a class to the UILabel for styling
    _scoreLabel:SetPrelocalizedText(tostring(score)) -- Set the text of the UILabel to the player's score

    local _rankLabel = UILabel.new() -- Create a new UILabel for the player's rank
    _rankLabel:AddToClassList("rank-label") -- Add a class to the UILabel for styling
    _rankLabel:SetPrelocalizedText(tostring(i) .. ".") -- Set the text of the UILabel to the player's rank

    rankItem:Add(_rankLabel) -- Add the rank label to the rank item
    rankItem:Add(_nameLabel) -- Add the name label to the rank item
    rankItem:Add(_scoreLabel) -- Add the score label to the rank item

    _rankList:Add(rankItem) -- Add the rank item to the rank list
  end
end

-- Schedule the leaderboard update function to run every UpdateInterval seconds
Timer.Every(UpdateInterval, function()
  local topPlayers = CoinsTracker.GetTopPlayers() -- Fetch the top players from the CoinsTracker
  UpdateLeaderboard(topPlayers) -- Update the leaderboard with the fetched top players
end)
