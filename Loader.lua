local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-------------------------------------------------
-- THIS RUNS ONLY AFTER THE BAR HITS 100%
-------------------------------------------------
local function RunScript()

	-- >>> CHANGE THIS URL to your own raw GitHub link <<<
	local ASTRAL_URL = "https://raw.githubusercontent.com/LearningCFrom0/AstralLua.lua/main/AstralLua.lua"

	local ok, Astral = pcall(function()
		return loadstring(game:HttpGet(ASTRAL_URL))()
	end)

	if not ok or not Astral then
		warn("[Loader] Failed to load Astral.Lua: " .. tostring(Astral))
		return
	end

	local Window = Astral:CreateWindow({
		Name = "Astral.Lua",
		Subtitle = "v1.0",
		AccentColor = Color3.fromRGB(120, 90, 255),
		ToggleKey = Enum.KeyCode.RightShift, -- press to show/hide the UI
	})

	local player = Players.LocalPlayer

	----------------------------------------------------------------
	-- MAIN TAB
	----------------------------------------------------------------
	local MainTab = Window:CreateTab("Main")

	MainTab:CreateButton({
		Name = "Say Hello",
		Callback = function()
			print("Astral.Lua is working!")
		end
	})

	MainTab:CreateLabel("Astral.Lua v1.0 — edit Astral.Theme in AstralLua.lua to re-theme everything.")

	----------------------------------------------------------------
	-- MOVEMENT TAB
	----------------------------------------------------------------
	local MovementTab = Window:CreateTab("Movement")

	MovementTab:CreateSlider({
		Name = "Walk Speed",
		Min = 16,
		Max = 200,
		Default = 16,
		Callback = function(value)
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = value end
		end
	})

	MovementTab:CreateSlider({
		Name = "Jump Power",
		Min = 50,
		Max = 300,
		Default = 50,
		Callback = function(value)
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.JumpPower = value end
		end
	})

	--[[
	    TOGGLE TEMPLATE — this is the pattern for "button turns my
	    code on/off". Create the toggle, keep the object it returns,
	    then check `.Value` inside a loop of your own. When it's
	    switched off, `.Value` goes false and your loop stops acting
	    on the very next pass:

	    local myToggle = MovementTab:CreateToggle({
	        Name = "My Feature",
	        Default = false,
	        Callback = function(state) print("My Feature:", state) end
	    })

	    task.spawn(function()
	        while true do
	            task.wait()
	            if myToggle.Value then
	                -- your code runs here, only while ON
	            end
	        end
	    end)
	]]

	----------------------------------------------------------------
	-- COMBAT TAB
	----------------------------------------------------------------
	local CombatTab = Window:CreateTab("Combat")

	CombatTab:CreateLabel("Add your own toggles/sliders here using the pattern above.")

	----------------------------------------------------------------
	-- VISUALS TAB
	----------------------------------------------------------------
	local VisualsTab = Window:CreateTab("Visuals")

	VisualsTab:CreateSlider({
		Name = "Field of View",
		Min = 60,
		Max = 120,
		Default = 70,
		Callback = function(value)
			workspace.CurrentCamera.FieldOfView = value
		end
	})

	----------------------------------------------------------------
	-- SETTINGS TAB
	----------------------------------------------------------------
	local SettingsTab = Window:CreateTab("Settings")

	SettingsTab:CreateButton({
		Name = "Rejoin Game",
		Callback = function()
			game:GetService("TeleportService"):Teleport(game.PlaceId, player)
		end
	})

	-- Recolors every element already on screen (toggles, sliders, etc.)
	SettingsTab:CreateColorPicker({
		Name = "Accent Color",
		Default = Color3.fromRGB(120, 90, 255),
		Callback = function(color)
			Window:SetAccentColor(color)
		end
	})

	-- Live font swap. Only Roblox's built-in fonts work without extra setup.
	SettingsTab:CreateDropdown({
		Name = "Font",
		Options = {"Gotham", "SourceSans", "Code", "Bangers", "Roboto"},
		Default = "Gotham",
		Callback = function(choice)
			local fonts = {
				Gotham     = {Enum.Font.GothamMedium, Enum.Font.GothamBold},
				SourceSans = {Enum.Font.SourceSans, Enum.Font.SourceSansBold},
				Code       = {Enum.Font.Code, Enum.Font.Code},
				Bangers    = {Enum.Font.Bangers, Enum.Font.Bangers},
				Roboto     = {Enum.Font.Roboto, Enum.Font.RobotoMono},
			}
			local pick = fonts[choice]
			Window:SetFont(pick[1], pick[2])
		end
	})

	-- Change the show/hide keybind from inside the UI itself
	SettingsTab:CreateKeybind({
		Name = "UI Toggle Key",
		Default = Enum.KeyCode.RightShift,
		Callback = function(keycode)
			Window:SetToggleKey(keycode)
		end
	})

	-- Add more tabs / buttons / toggles / sliders here.
	-- Everything you put in this RunScript function only
	-- executes once the loading bar below reaches 100%.

end
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Loader"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,360,0,230)
main.Position = UDim2.new(0.5,-180,0.5,-115)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderColor3 = Color3.fromRGB(50,50,50)
main.BorderSizePixel = 1
main.Parent = gui

-- Dragging
local dragging = false
local dragInput
local dragStart
local startPos

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

main.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,28)
header.BackgroundColor3 = Color3.fromRGB(28,28,28)
header.BorderSizePixel = 0
header.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-10,1,0)
title.Position = UDim2.new(0,10,0,0)
title.Font = Enum.Font.SourceSansBold
title.Text = "Loader"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local playerLabel = Instance.new("TextLabel")
playerLabel.BackgroundTransparency = 1
playerLabel.Position = UDim2.new(0,20,0,45)
playerLabel.Size = UDim2.new(1,-40,0,20)
playerLabel.Font = Enum.Font.SourceSansBold
playerLabel.TextSize = 19
playerLabel.TextColor3 = Color3.new(1,1,1)
playerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerLabel.Text = "Player: "..player.Name
playerLabel.Parent = main

local gameLabel = Instance.new("TextLabel")
gameLabel.BackgroundTransparency = 1
gameLabel.Position = UDim2.new(0,20,0,67)
gameLabel.Size = UDim2.new(1,-40,0,20)
gameLabel.Font = Enum.Font.SourceSansBold
gameLabel.TextSize = 19
gameLabel.TextColor3 = Color3.new(1,1,1)
gameLabel.TextXAlignment = Enum.TextXAlignment.Left
gameLabel.Text = "Game ID: "..game.PlaceId
gameLabel.Parent = main

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1,0,0,22)
status.Position = UDim2.new(0,0,0,120)
status.Font = Enum.Font.SourceSansBold
status.TextSize = 20
status.TextColor3 = Color3.new(1,1,1)
status.Text = "Waiting..."
status.Parent = main

local barBG = Instance.new("Frame")
barBG.Size = UDim2.new(0,160,0,6)
barBG.Position = UDim2.new(.5,-80,0,150)
barBG.BackgroundColor3 = Color3.fromRGB(55,55,55)
barBG.BorderSizePixel = 0
barBG.Parent = main

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromRGB(40,140,255)
bar.BorderSizePixel = 0
bar.Parent = barBG

local button = Instance.new("TextButton")
button.Size = UDim2.new(0,120,0,30)
button.Position = UDim2.new(.5,-60,1,-45)
button.BackgroundColor3 = Color3.fromRGB(35,35,35)
button.BorderColor3 = Color3.fromRGB(70,70,70)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 20
button.Text = "LOAD"
button.Parent = main

button.MouseButton1Click:Connect(function()

	button.Active = false
	button.Text = "..."

	for i = 0,100 do

		status.Text = "Loading... "..i.."%"

		TweenService:Create(bar,TweenInfo.new(.02),{
			Size = UDim2.new(i/100,0,1,0)
		}):Play()

		task.wait(.02)
	end

	status.Text = "Loaded!"

	task.wait(0.6)

	gui:Destroy()

	-- RunScript is only ever called here, right after the bar
	-- has finished its loop and hit 100%.
	RunScript()

end)

print("loaded")
