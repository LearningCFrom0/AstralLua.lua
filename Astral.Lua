-- Dollarware UI Library - Complete Combat Hub
-- Load the library
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local ui = uiLoader({
    rounding = true,
    theme = 'cherry',
    smoothDragging = true
})

ui.autoDisableToggles = true

-- ============================================
-- CREATE WINDOW
-- ============================================
local window = ui.newWindow({
    text = 'Astral Combat Hub',
    resize = true,
    size = Vector2.new(550, 450)
})

-- ============================================
-- DEFINE SKELETON SETTINGS FIRST
-- ============================================
local SkeletonSettings = {
    Color = Color3.new(0, 1, 0),
    Thickness = 2,
    Transparency = 1
}

-- ============================================
-- 1. COMBAT TAB
-- ============================================
local combatMenu = window:addMenu({ text = 'Combat' })
local combatSection = combatMenu:addSection({ 
    text = 'Combat Settings', 
    side = 'left' 
})

-- Aim Assist Toggle
local aimAssistToggle = combatSection:addToggle({
    text = 'Aim Assist',
    state = false
})
aimAssistToggle:bindToEvent('onToggle', function(newState)
    ui.notify({
        title = 'Aim Assist',
        message = newState and 'Enabled' or 'Disabled',
        duration = 2
    })
end)

-- Silent Aim Toggle
local silentAimToggle = combatSection:addToggle({
    text = 'Silent Aim',
    state = false
})
silentAimToggle:bindToEvent('onToggle', function(newState)
    print('Silent Aim:', newState)
end)

-- Triggerbot Toggle
local triggerbotToggle = combatSection:addToggle({
    text = 'Triggerbot',
    state = false
})
triggerbotToggle:bindToEvent('onToggle', function(newState)
    print('Triggerbot:', newState)
end)

-- FOV Slider
combatSection:addSlider({
    text = 'Aim FOV',
    min = 1,
    max = 360,
    step = 1,
    val = 120
}, function(newValue)
    print('FOV set to:', newValue)
end)

-- ============================================
-- 2. VISUALS TAB (Skeleton ESP + Neon Mode)
-- ============================================
local visualsMenu = window:addMenu({ text = 'Visuals' })
local visualsSection = visualsMenu:addSection({ 
    text = 'Visual Settings', 
    side = 'left' 
})

-- Skeleton ESP Toggle
local skeletonEspToggle = visualsSection:addToggle({
    text = 'Skeleton ESP',
    state = false
})

-- ESP Master Toggle
local espMasterToggle = visualsSection:addToggle({
    text = 'Enable All ESP',
    state = false
})

-- NEON MODE TOGGLE (For ALL Players EXCEPT Self)
local neonModeToggle = visualsSection:addToggle({
    text = 'Neon Mode (Enemies Only)',
    state = false
})
neonModeToggle:setTooltip('Makes all OTHER players\' limbs glow like neon blocks (Head stays normal)')

-- Neon Color Picker
local neonColorPicker = visualsSection:addColorPicker({
    text = 'Neon Color',
    color = Color3.fromRGB(0, 255, 255)
}, function(newColor)
    _G.NeonColor = newColor
    if neonModeToggle:getState() then
        updateAllNeon(true)
    end
end)

-- Skeleton Color Picker
visualsSection:addColorPicker({
    text = 'Skeleton Color',
    color = SkeletonSettings.Color
}, function(newColor)
    SkeletonSettings.Color = newColor
    print('Skeleton color changed:', newColor)
end)

-- Skeleton Thickness Slider
visualsSection:addSlider({
    text = 'Skeleton Thickness',
    min = 1,
    max = 5,
    step = 1,
    val = SkeletonSettings.Thickness
}, function(newValue)
    SkeletonSettings.Thickness = newValue
    print('Skeleton thickness:', newValue)
end)

-- ============================================
-- 3. NEON MODE LOGIC
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

_G.NeonColor = Color3.fromRGB(0, 255, 255)
local originalParts = {}

local function createNeonPart(originalPart, color)
    if not originalPart then return nil end
    
    local neonPart = Instance.new("Part")
    neonPart.Name = "NeonPart"
    neonPart.Size = originalPart.Size
    neonPart.CFrame = originalPart.CFrame
    neonPart.Anchored = false
    neonPart.CanCollide = false
    neonPart.Transparency = 0.1
    neonPart.Material = Enum.Material.Neon
    neonPart.Color = color
    
    originalParts[neonPart] = {
        part = originalPart,
        transparency = originalPart.Transparency,
        material = originalPart.Material,
        color = originalPart.Color
    }
    
    originalPart.Transparency = 1
    neonPart.Parent = originalPart.Parent
    
    local weld = Instance.new("Weld")
    weld.Part0 = originalPart
    weld.Part1 = neonPart
    weld.C0 = originalPart.CFrame:Inverse()
    weld.C1 = neonPart.CFrame:Inverse()
    weld.Parent = neonPart
    
    return neonPart
end

local function applyNeonToCharacter(character, color)
    if not character then return end
    
    local plr = Players:GetPlayerFromCharacter(character)
    if plr == player then return end
    
    local head = character:FindFirstChild("Head")
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "NeonPart" and not part:IsA("Accessory") then
            if part == head then continue end
            
            local isLimb = part.Name:match("Torso") or 
                          part.Name:match("Arm") or 
                          part.Name:match("Leg") or
                          part.Name:match("Hand") or
                          part.Name:match("Foot") or
                          part.Name:match("Root")
            
            if isLimb and not originalParts[part] then
                createNeonPart(part, color)
            end
        end
    end
end

local function removeNeonFromCharacter(character)
    local toRemove = {}
    for neonPart, originalData in pairs(originalParts) do
        if originalData.part and originalData.part:IsDescendantOf(character) then
            local originalPart = originalData.part
            if originalPart then
                originalPart.Transparency = originalData.transparency or 0
                originalPart.Material = originalData.material or Enum.Material.Plastic
                originalPart.Color = originalData.color or Color3.fromRGB(255, 255, 255)
            end
            table.insert(toRemove, neonPart)
        end
    end
    
    for _, neonPart in ipairs(toRemove) do
        neonPart:Destroy()
        originalParts[neonPart] = nil
    end
end

local function updateAllNeon(state)
    local color = _G.NeonColor or Color3.fromRGB(0, 255, 255)
    
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                applyNeonToCharacter(plr.Character, color)
            end
        end
        ui.notify({
            title = 'Neon Mode',
            message = 'Enabled for enemies (Head stays normal)',
            duration = 2
        })
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                removeNeonFromCharacter(plr.Character)
            end
        end
        ui.notify({
            title = 'Neon Mode',
            message = 'Disabled',
            duration = 2
        })
    end
end

-- Track new players
local function onPlayerAdded(plr)
    if plr == player then return end
    
    if neonModeToggle:getState() then
        plr.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            if neonModeToggle:getState() and plr ~= player then
                applyNeonToCharacter(character, _G.NeonColor or Color3.fromRGB(0, 255, 255))
            end
        end)
        
        if plr.Character then
            task.wait(0.5)
            if neonModeToggle:getState() and plr ~= player then
                applyNeonToCharacter(plr.Character, _G.NeonColor or Color3.fromRGB(0, 255, 255))
            end
        end
    end
end

-- Track existing players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        onPlayerAdded(plr)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle respawns
local function onCharacterAdded(character)
    local plr = Players:GetPlayerFromCharacter(character)
    if plr and plr ~= player and neonModeToggle:getState() then
        task.wait(0.5)
        applyNeonToCharacter(character, _G.NeonColor or Color3.fromRGB(0, 255, 255))
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
end

neonModeToggle:bindToEvent('onToggle', function(newState)
    updateAllNeon(newState)
end)

-- ============================================
-- 4. SKELETON ESP LOGIC
-- ============================================
local skeletonEnabled = false
local skeletons = {}
local skeletonConnections = {}

local function createLine()
    return Drawing.new("Line")
end

local function removeSkeleton(skeleton)
    for _, line in pairs(skeleton) do
        line:Remove()
    end
end

local function trackPlayerSkeleton(plr)
    if plr == player then return end
    
    local skeleton = {}
    local camera = workspace.CurrentCamera

    local function updateSkeleton()
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
            return
        end

        if not skeletonEnabled then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
            return
        end

        local character = plr.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local joints = {}
        local connections = {}

        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            joints = {
                ["Head"] = character:FindFirstChild("Head"),
                ["UpperTorso"] = character:FindFirstChild("UpperTorso"),
                ["LowerTorso"] = character:FindFirstChild("LowerTorso"),
                ["LeftUpperArm"] = character:FindFirstChild("LeftUpperArm"),
                ["LeftLowerArm"] = character:FindFirstChild("LeftLowerArm"),
                ["LeftHand"] = character:FindFirstChild("LeftHand"),
                ["RightUpperArm"] = character:FindFirstChild("RightUpperArm"),
                ["RightLowerArm"] = character:FindFirstChild("RightLowerArm"),
                ["RightHand"] = character:FindFirstChild("RightHand"),
                ["LeftUpperLeg"] = character:FindFirstChild("LeftUpperLeg"),
                ["LeftLowerLeg"] = character:FindFirstChild("LeftLowerLeg"),
                ["RightUpperLeg"] = character:FindFirstChild("RightUpperLeg"),
                ["RightLowerLeg"] = character:FindFirstChild("RightLowerLeg"),
            }
            connections = {
                { "Head", "UpperTorso" },
                { "UpperTorso", "LowerTorso" },
                { "LowerTorso", "LeftUpperLeg" },
                { "LeftUpperLeg", "LeftLowerLeg" },
                { "LowerTorso", "RightUpperLeg" },
                { "RightUpperLeg", "RightLowerLeg" },
                { "UpperTorso", "LeftUpperArm" },
                { "LeftUpperArm", "LeftLowerArm" },
                { "LeftLowerArm", "LeftHand" },
                { "UpperTorso", "RightUpperArm" },
                { "RightUpperArm", "RightLowerArm" },
                { "RightLowerArm", "RightHand" },
            }
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            joints = {
                ["Head"] = character:FindFirstChild("Head"),
                ["Torso"] = character:FindFirstChild("Torso"),
                ["LeftLeg"] = character:FindFirstChild("Left Leg"),
                ["RightLeg"] = character:FindFirstChild("Right Leg"),
                ["LeftArm"] = character:FindFirstChild("Left Arm"),
                ["RightArm"] = character:FindFirstChild("Right Arm"),
            }
            connections = {
                { "Head", "Torso" },
                { "Torso", "LeftArm" },
                { "Torso", "RightArm" },
                { "Torso", "LeftLeg" },
                { "Torso", "RightLeg" },
            }
        end

        for index, connection in ipairs(connections) do
            local jointA = joints[connection[1]]
            local jointB = joints[connection[2]]

            if jointA and jointB then
                local posA, onScreenA = camera:WorldToViewportPoint(jointA.Position)
                local posB, onScreenB = camera:WorldToViewportPoint(jointB.Position)

                local line = skeleton[index] or createLine()
                skeleton[index] = line

                line.Color = SkeletonSettings.Color
                line.Thickness = SkeletonSettings.Thickness
                line.Transparency = SkeletonSettings.Transparency

                if onScreenA and onScreenB then
                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            elseif skeleton[index] then
                skeleton[index].Visible = false
            end
        end
    end

    skeletons[plr] = skeleton

    local connection = RunService.RenderStepped:Connect(function()
        if plr and plr.Parent then
            updateSkeleton()
        else
            removeSkeleton(skeleton)
        end
    end)
    
    skeletonConnections[plr] = connection
end

local function untrackPlayer(plr)
    if skeletons[plr] then
        removeSkeleton(skeletons[plr])
        skeletons[plr] = nil
    end
    if skeletonConnections[plr] then
        skeletonConnections[plr]:Disconnect()
        skeletonConnections[plr] = nil
    end
end

local function toggleESP(state)
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                trackPlayerSkeleton(plr)
            end
        end
    else
        for plr, _ in pairs(skeletons) do
            untrackPlayer(plr)
        end
    end
end

skeletonEspToggle:bindToEvent('onToggle', function(newState)
    skeletonEnabled = newState
    ui.notify({
        title = 'Skeleton ESP',
        message = newState and 'Enabled' or 'Disabled',
        duration = 2
    })
    if espMasterToggle:getState() then
        toggleESP(true)
    end
end)

espMasterToggle:bindToEvent('onToggle', function(newState)
    if newState then
        toggleESP(true)
        ui.notify({
            title = 'ESP',
            message = 'Skeleton ESP Enabled',
            duration = 2
        })
    else
        toggleESP(false)
        ui.notify({
            title = 'ESP',
            message = 'Skeleton ESP Disabled',
            duration = 2
        })
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if plr ~= player and espMasterToggle:getState() then
        trackPlayerSkeleton(plr)
    end
end)

Players.PlayerRemoving:Connect(untrackPlayer)

-- ============================================
-- 5. MISC TAB (Anti-Aim)
-- ============================================
local miscMenu = window:addMenu({ text = 'Misc' })
local miscSection = miscMenu:addSection({ 
    text = 'Anti-Aim Settings', 
    side = 'left' 
})

-- Anti-Aim Toggle
local antiAimToggle = miscSection:addToggle({
    text = 'Enable Anti-Aim',
    state = false
})

-- Anti-Aim Speed Slider
local speedSlider = miscSection:addSlider({
    text = 'Anti-Aim Speed',
    min = 0.01,
    max = 0.5,
    step = 0.01,
    val = 0.1
}, function(newValue)
    antiAimWaitTime = newValue
end)
speedSlider:setTooltip('Higher number = slower rotation')

-- Display current speed label
local speedLabel = miscSection:addLabel({
    text = 'Current Speed: 0.10s',
    dim = true
})

speedSlider:bindToEvent('onNewValue', function(newValue)
    speedLabel:setText('Current Speed: ' .. string.format('%.2f', newValue) .. 's')
end)

-- ============================================
-- 6. ANTI-AIM LOGIC
-- ============================================
local antiAimRunning = false
local antiAimWaitTime = 0.1

local function toggleAntiAim(state)
    if state then
        if not antiAimRunning then
            antiAimRunning = true
            antiAimWaitTime = speedSlider:getValue()
            
            ui.notify({
                title = 'Anti-Aim',
                message = 'Activated at ' .. string.format('%.2f', antiAimWaitTime) .. 's speed',
                duration = 2
            })

            spawn(function()
                while antiAimRunning do
                    local character = player.Character
                    if character and character.PrimaryPart then
                        local randomAngle = math.random(0, 360)
                        character:SetPrimaryPartCFrame(
                            CFrame.new(character.PrimaryPart.Position) *
                            CFrame.Angles(0, math.rad(randomAngle), 0)
                        )
                    end
                    task.wait(antiAimWaitTime)
                end
            end)
        end
    else
        antiAimRunning = false
        ui.notify({
            title = 'Anti-Aim',
            message = 'Deactivated',
            duration = 2
        })
    end
end

antiAimToggle:bindToEvent('onToggle', function(newState)
    toggleAntiAim(newState)
end)

speedSlider:bindToEvent('onNewValue', function(newValue)
    antiAimWaitTime = newValue
end)

-- ============================================
-- 7. SETTINGS TAB
-- ============================================
local settingsMenu = window:addMenu({ text = 'Settings' })
local settingsSection = settingsMenu:addSection({ 
    text = 'UI Settings', 
    side = 'left' 
})

-- Reset All Settings Button
settingsSection:addButton({
    text = 'Reset All Settings',
    style = 'large'
}, function()
    -- Reset Anti-Aim
    if antiAimRunning then
        antiAimRunning = false
        antiAimToggle:disable()
    end
    
    -- Reset ESP
    if espMasterToggle:getState() then
        espMasterToggle:disable()
        toggleESP(false)
    end
    
    -- Reset Neon Mode
    if neonModeToggle:getState() then
        neonModeToggle:disable()
        updateAllNeon(false)
    end
    
    -- Reset toggles
    speedSlider:setValue(0.1)
    antiAimWaitTime = 0.1
    skeletonEspToggle:disable()
    aimAssistToggle:disable()
    silentAimToggle:disable()
    triggerbotToggle:disable()
    
    -- Reset skeleton settings
    SkeletonSettings.Color = Color3.new(0, 1, 0)
    SkeletonSettings.Thickness = 2
    
    ui.notify({
        title = 'Settings',
        message = 'All settings have been reset',
        duration = 3
    })
end)

-- Close UI Button
settingsSection:addButton({
    text = 'Close UI',
    style = 'large'
}, function()
    window:destroy()
end)

-- ============================================
-- 8. CLEANUP
-- ============================================
window:bindToEvent('destroyInternal', function()
    antiAimRunning = false
    toggleESP(false)
    if neonModeToggle:getState() then
        updateAllNeon(false)
    end
end)

print('Astral Combat Hub loaded successfully!')
