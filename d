--[[
    ═══════════════════════════════════════════════════════════════
     Astral.Lua — A modern, animated Roblox UI Library
    ═══════════════════════════════════════════════════════════════

    HOW TO USE (put this at the very top of your script):

        local Astral = loadstring(game:HttpGet("PUT_YOUR_RAW_URL_HERE"))()

    or, if this file is a ModuleScript in your game:

        local Astral = require(path.to.AstralLua)

    ───────────────────────────────────────────────────────────────
    QUICK EXAMPLE
    ───────────────────────────────────────────────────────────────

    local Window = Astral:CreateWindow({
        Name = "Astral.Lua",
        Subtitle = "v1.0",
        AccentColor = Color3.fromRGB(120, 90, 255),
    })

    local Tab = Window:CreateTab("Main", "home")

    Tab:CreateButton({
        Name = "Print Hello",
        Callback = function()
            print("Hello from Astral!")
        end
    })

    -- A toggle that turns YOUR code on/off.
    -- Astral gives you a live table (Toggle.Value) you check inside
    -- your own loop. When the toggle is switched off, Value flips to
    -- false and your loop stops doing whatever it was doing.
    local espToggle = Tab:CreateToggle({
        Name = "ESP",
        Default = false,
        Callback = function(state)
            if state then
                print("ESP turned ON")
            else
                print("ESP turned OFF")
            end
        end
    })

    task.spawn(function()
        while true do
            task.wait(0.2)
            if espToggle.Value then
                -- your ESP code runs here, every loop, only while ON
            end
        end
    end)

    Tab:CreateSlider({
        Name = "Walk Speed",
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            print("Speed set to", value)
        end
    })

    ═══════════════════════════════════════════════════════════════
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// ══════════════════════ THEME (fully customisable) ══════════════════════
local Astral = {}
Astral.__index = Astral

Astral.Theme = {
    Background      = Color3.fromRGB(22, 22, 26),
    Sidebar         = Color3.fromRGB(18, 18, 22),
    Section         = Color3.fromRGB(28, 28, 34),
    Element         = Color3.fromRGB(34, 34, 41),
    ElementHover    = Color3.fromRGB(42, 42, 50),
    Stroke          = Color3.fromRGB(48, 48, 56),
    TextPrimary     = Color3.fromRGB(235, 235, 240),
    TextSecondary   = Color3.fromRGB(150, 150, 160),
    Accent          = Color3.fromRGB(120, 90, 255),
    AccentDark      = Color3.fromRGB(90, 65, 200),
    Success         = Color3.fromRGB(80, 210, 130),
    Danger          = Color3.fromRGB(230, 90, 90),
    Font            = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    CornerRadius    = UDim.new(0, 8),
    AnimSpeed       = 0.18,
}

--// ══════════════════════ INTERNAL HELPERS ══════════════════════
local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time or Astral.Theme.AnimSpeed, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

-- Finds the owning Window for any self (Window, Tab, or Section)
local function getWindow(self)
    if self.ScreenGui then return self end -- self IS the window
    return self.Window
end

-- Registers a small "refresh" function that re-applies the current
-- Theme to one element. Called again automatically whenever
-- Window:SetAccentColor() or Window:SetFont() runs, so live theme
-- changes reach every element already on screen.
local function track(self, applyFn)
    local win = getWindow(self)
    if not win then return end
    win.Registry = win.Registry or {}
    table.insert(win.Registry, applyFn)
    applyFn() -- apply once immediately using current theme
end

local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius)
    return new("UICorner", { CornerRadius = radius or Astral.Theme.CornerRadius })
end

local function stroke(color, thickness)
    return new("UIStroke", {
        Color = color or Astral.Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(l, t, r, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 10),
        PaddingTop = UDim.new(0, t or 10),
        PaddingRight = UDim.new(0, r or 10),
        PaddingBottom = UDim.new(0, b or 10),
    })
end

-- Makes a frame draggable by a given "handle" (usually the top bar)
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--// ══════════════════════ WINDOW ══════════════════════
function Astral:CreateWindow(config)
    config = config or {}
    local Theme = self.Theme
    if config.AccentColor then Theme.Accent = config.AccentColor end

    -- Destroy any previous Astral UI so re-running a script doesn't stack windows
    local existing = PlayerGui:FindFirstChild("AstralLuaUI")
    if existing then existing:Destroy() end

    local ScreenGui = new("ScreenGui", {
        Name = "AstralLuaUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    -- soft drop shadow behind the window
    local Shadow = new("ImageLabel", {
        Name = "Shadow",
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 0,
        Parent = ScreenGui,
    })

    local Main = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(560, 380),
        Position = UDim2.new(0.5, -280, 0.5, -190),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, { corner(UDim.new(0, 12)), stroke(Theme.Stroke, 1) })

    -- subtle pop-in animation
    Main.Size = UDim2.fromOffset(560, 0)
    Main.Visible = true

    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Main,
    }, { corner(UDim.new(0, 12)) })

    -- cover the bottom rounded corners of the topbar so it looks flush
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    local TitleLabel = new("TextLabel", {
        Text = config.Name or "Astral.Lua",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0, 250, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local SubtitleLabel
    if config.Subtitle then
        SubtitleLabel = new("TextLabel", {
            Text = config.Subtitle,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 22),
            Size = UDim2.new(0, 250, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TopBar,
        })
    end

    local CloseBtn = new("TextButton", {
        Text = "✕",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 44),
        Position = UDim2.new(1, -40, 0, 0),
        Parent = TopBar,
    })
    CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {TextColor3 = Theme.Danger}) end)
    CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {TextColor3 = Theme.TextSecondary}) end)
    CloseBtn.MouseButton1Click:Connect(function()
        local t = tween(Main, {Size = UDim2.fromOffset(560, 0)}, 0.2)
        t.Completed:Connect(function() ScreenGui:Destroy() end)
    end)

    local MinimizeBtn = new("TextButton", {
        Text = "—",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(36, 44),
        Position = UDim2.new(1, -76, 0, 0),
        Parent = TopBar,
    })

    makeDraggable(Main, TopBar)

    -- Sidebar (tab list)
    local Sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Main,
    })

    local TabList = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -34),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(8, 0, 8, 0),
    })

    local Footer = new("TextLabel", {
        Text = "Astral.Lua",
        Font = Theme.Font,
        TextSize = 10,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        Parent = Sidebar,
    })

    -- Content area (holds one page per tab)
    local ContentHolder = new("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -140, 1, -44),
        Position = UDim2.new(0, 140, 0, 44),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    -- pop-in animation
    tween(Main, {Size = UDim2.fromOffset(560, 380)}, 0.3, Enum.EasingStyle.Quart)

    local Window = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        TabList = TabList,
        ContentHolder = ContentHolder,
        Tabs = {},
        Theme = Theme,
        Registry = {},
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        _firstTab = true,
        _hidden = false,
        _minimized = false,
    }, {__index = Astral})

    -- keep title/subtitle in sync with Window:SetFont()
    track(Window, function() TitleLabel.Font = Theme.FontBold end)
    if SubtitleLabel then
        track(Window, function() SubtitleLabel.Font = Theme.Font end)
    end
    track(Window, function() TabList.ScrollBarImageColor3 = Theme.Accent end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        Window._minimized = not Window._minimized
        if Window._minimized then
            tween(Main, {Size = UDim2.fromOffset(560, 44)}, 0.25)
        else
            tween(Main, {Size = UDim2.fromOffset(560, 380)}, 0.25)
        end
    end)

    -- Open/close keybind (default RightShift, change via config.ToggleKey
    -- or Window:SetToggleKey(Enum.KeyCode.X) at runtime)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Window.ToggleKey then
            Window:ToggleUI()
        end
    end)

    return Window
end

-- Shows/hides the whole window with a quick animation. Bound to
-- Window.ToggleKey (RightShift by default) automatically.
function Astral:ToggleUI()
    self._hidden = not self._hidden
    if self._hidden then
        tween(self.Main, {Size = UDim2.fromOffset(560, 0)}, 0.2)
    else
        local targetHeight = self._minimized and 44 or 380
        tween(self.Main, {Size = UDim2.fromOffset(560, targetHeight)}, 0.2)
    end
end

-- Change the open/close keybind at runtime, e.g.
-- Window:SetToggleKey(Enum.KeyCode.RightControl)
function Astral:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

-- Recolors every accent-tinted element already on screen (toggle
-- switches, slider fills, scrollbars, etc.) plus anything created
-- after this call.
function Astral:SetAccentColor(color)
    self.Theme.Accent = color
    for _, applyFn in ipairs(self.Registry) do
        applyFn()
    end
end

-- Changes the UI's font live. `bodyFont` is used for normal text,
-- `boldFont` (optional, defaults to bodyFont) for titles/headers.
function Astral:SetFont(bodyFont, boldFont)
    self.Theme.Font = bodyFont
    self.Theme.FontBold = boldFont or bodyFont
    for _, applyFn in ipairs(self.Registry) do
        applyFn()
    end
end

-- 0 = fully opaque, 1 = fully invisible. Affects the main window and
-- sidebar background so people can see through the menu if they want.
function Astral:SetTransparency(alpha)
    alpha = math.clamp(alpha, 0, 0.85) -- cap so it never becomes unusable
    tween(self.Main, {BackgroundTransparency = alpha}, 0.15)
    local Sidebar = self.Main:FindFirstChild("Sidebar")
    if Sidebar then tween(Sidebar, {BackgroundTransparency = alpha}, 0.15) end
    local TopBar = self.Main:FindFirstChild("TopBar")
    if TopBar then tween(TopBar, {BackgroundTransparency = alpha}, 0.15) end
end

--// ══════════════════════ TABS ══════════════════════
function Astral:CreateTab(name, icon)
    local Theme = self.Theme

    local TabButton = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = self.TabList,
    }, { corner(UDim.new(0, 6)) })

    local TabLabelText = new("TextLabel", {
        Text = name,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabButton,
    })
    track(self, function() TabLabelText.Font = Theme.Font end)

    local Page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.ContentHolder,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(14, 14, 14, 14),
    })

    local Tab = setmetatable({
        Name = name,
        Button = TabButton,
        Label = TabButton:FindFirstChildOfClass("TextLabel"),
        Page = Page,
        Window = self,
        Theme = Theme,
    }, {__index = Astral})

    track(self, function() Page.ScrollBarImageColor3 = Theme.Accent end)

    local function selectTab()
        for _, t in pairs(self.Tabs) do
            t.Page.Visible = false
            tween(t.Button, {BackgroundTransparency = 1})
            tween(t.Label, {TextColor3 = Theme.TextSecondary})
        end
        Page.Visible = true
        tween(TabButton, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Element})
        tween(Tab.Label, {TextColor3 = Theme.TextPrimary})
    end

    TabButton.MouseButton1Click:Connect(selectTab)
    TabButton.MouseEnter:Connect(function()
        if not Page.Visible then tween(TabButton, {BackgroundTransparency = 0.7}) end
    end)
    TabButton.MouseLeave:Connect(function()
        if not Page.Visible then tween(TabButton, {BackgroundTransparency = 1}) end
    end)

    table.insert(self.Tabs, Tab)
    if self._firstTab then
        self._firstTab = false
        selectTab()
    end

    return Tab
end

--// ══════════════════════ SECTION (visual grouping) ══════════════════════
function Astral:CreateSection(name)
    local Theme = self.Theme
    local Section = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Section,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local SectionTitle = new("TextLabel", {
        Text = name,
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Section,
    })
    track(self, function() SectionTitle.Font = Theme.FontBold end)

    local Holder = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 10, 0, 32),
        BackgroundTransparency = 1,
        Parent = Section,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
        padding(0, 0, 0, 10),
    })

    return setmetatable({ Page = Holder, Theme = Theme, Window = getWindow(self) }, {__index = Astral})
end

--// ══════════════════════ BUTTON ══════════════════════
-- config = { Name = "My Button", Callback = function() end }
function Astral:CreateButton(config)
    config = config or {}
    local Theme = self.Theme

    local Btn = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Element,
        AutoButtonColor = false,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local BtnLabel = new("TextLabel", {
        Text = config.Name or "Button",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Btn,
    })
    track(self, function() BtnLabel.Font = Theme.Font end)

    Btn.MouseEnter:Connect(function() tween(Btn, {BackgroundColor3 = Theme.ElementHover}) end)
    Btn.MouseLeave:Connect(function() tween(Btn, {BackgroundColor3 = Theme.Element}) end)

    Btn.MouseButton1Down:Connect(function() tween(Btn, {Size = UDim2.new(1, -6, 0, 34)}, 0.08) end)
    Btn.MouseButton1Up:Connect(function() tween(Btn, {Size = UDim2.new(1, 0, 0, 36)}, 0.08) end)

    Btn.MouseButton1Click:Connect(function()
        if config.Callback then
            local ok, err = pcall(config.Callback)
            if not ok then warn("[Astral.Lua] Button '"..(config.Name or "?").."' error: "..tostring(err)) end
        end
    end)

    return { Instance = Btn }
end

--// ══════════════════════ TOGGLE ══════════════════════
-- config = { Name = "ESP", Default = false, Callback = function(state) end }
-- Returns a table with .Value (live bool you can read from your own loops)
-- and :Set(bool) to change it from code.
function Astral:CreateToggle(config)
    config = config or {}
    local Theme = self.Theme
    local state = config.Default or false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Element,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local ToggleLabel = new("TextLabel", {
        Text = config.Name or "Toggle",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    track(self, function() ToggleLabel.Font = Theme.Font end)

    local Switch = new("TextButton", {
        Text = "",
        Size = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3 = state and Theme.Accent or Theme.Section,
        AutoButtonColor = false,
        Parent = Holder,
    }, { corner(UDim.new(1, 0)), stroke(Theme.Stroke) })

    local Knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Switch,
    }, { corner(UDim.new(1, 0)) })

    local ToggleObj = { Value = state }

    local function render(animated)
        local t = animated ~= false and Astral.Theme.AnimSpeed or 0
        tween(Switch, {BackgroundColor3 = ToggleObj.Value and Theme.Accent or Theme.Section}, t)
        tween(Knob, {Position = ToggleObj.Value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, t)
    end

    track(self, function() render(false) end)

    function ToggleObj:Set(newState, fireCallback)
        self.Value = newState and true or false
        render(true)
        if fireCallback ~= false and config.Callback then
            local ok, err = pcall(config.Callback, self.Value)
            if not ok then warn("[Astral.Lua] Toggle '"..(config.Name or "?").."' error: "..tostring(err)) end
        end
    end

    Switch.MouseButton1Click:Connect(function()
        ToggleObj:Set(not ToggleObj.Value)
    end)
    Holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ToggleObj:Set(not ToggleObj.Value)
        end
    end)

    -- fire once on creation so Default state actually applies your code
    if config.Callback and state then
        task.spawn(function() config.Callback(true) end)
    end

    return ToggleObj
end

--// ══════════════════════ SLIDER ══════════════════════
-- config = { Name, Min, Max, Default, Suffix, Callback = function(value) end }
function Astral:CreateSlider(config)
    config = config or {}
    local Theme = self.Theme
    local min, max = config.Min or 0, config.Max or 100
    local value = math.clamp(config.Default or min, min, max)
    local suffix = config.Suffix or ""

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme.Element,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke), padding(12, 8, 12, 10) })

    local Label = new("TextLabel", {
        Text = config.Name or "Slider",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local ValueLabel = new("TextLabel", {
        Text = tostring(value) .. suffix,
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 16),
        Position = UDim2.new(1, -50, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Holder,
    })
    track(self, function() Label.Font = Theme.Font; ValueLabel.Font = Theme.Font end)

    local Track = new("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = Theme.Section,
        Parent = Holder,
    }, { corner(UDim.new(1, 0)) })

    local Fill = new("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = Track,
    }, { corner(UDim.new(1, 0)) })

    local KnobStroke = stroke(Theme.Accent, 2)
    local Knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = Track,
    }, { corner(UDim.new(1, 0)), KnobStroke })

    track(self, function()
        Fill.BackgroundColor3 = Theme.Accent
        KnobStroke.Color = Theme.Accent
    end)

    local SliderObj = { Value = value }

    local dragging = false
    local function updateFromInput(input)
        local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local newValue = math.floor(min + (max - min) * relative + 0.5)
        if newValue ~= SliderObj.Value then
            SliderObj.Value = newValue
            tween(Fill, {Size = UDim2.new(relative, 0, 1, 0)}, 0.05)
            tween(Knob, {Position = UDim2.new(relative, 0, 0.5, 0)}, 0.05)
            ValueLabel.Text = tostring(newValue) .. suffix
            if config.Callback then
                local ok, err = pcall(config.Callback, newValue)
                if not ok then warn("[Astral.Lua] Slider '"..(config.Name or "?").."' error: "..tostring(err)) end
            end
        end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    function SliderObj:Set(newValue)
        newValue = math.clamp(newValue, min, max)
        local relative = (newValue - min) / (max - min)
        self.Value = newValue
        tween(Fill, {Size = UDim2.new(relative, 0, 1, 0)})
        tween(Knob, {Position = UDim2.new(relative, 0, 0.5, 0)})
        ValueLabel.Text = tostring(newValue) .. suffix
    end

    return SliderObj
end

--// ══════════════════════ DROPDOWN ══════════════════════
-- config = { Name, Options = {"A","B","C"}, Default = "A", Callback = function(option) end }
function Astral:CreateDropdown(config)
    config = config or {}
    local Theme = self.Theme
    local options = config.Options or {}
    local selected = config.Default or options[1]
    local open = false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Element,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local Header = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = Holder,
    })

    local DropdownNameLabel = new("TextLabel", {
        Text = config.Name or "Dropdown",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -12, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    local SelectedLabel = new("TextLabel", {
        Text = tostring(selected),
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -30, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Header,
    })
    track(self, function() DropdownNameLabel.Font = Theme.Font; SelectedLabel.Font = Theme.Font end)

    local OptionList = new("Frame", {
        Size = UDim2.new(1, -16, 0, #options * 28),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        Parent = Holder,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    for _, opt in ipairs(options) do
        local OptBtn = new("TextButton", {
            Text = tostring(opt),
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = Theme.Section,
            Size = UDim2.new(1, 0, 0, 24),
            AutoButtonColor = false,
            Parent = OptionList,
        }, { corner(UDim.new(0, 5)), padding(8, 0, 8, 0) })

        OptBtn.MouseEnter:Connect(function() tween(OptBtn, {BackgroundColor3 = Theme.ElementHover}) end)
        OptBtn.MouseLeave:Connect(function() tween(OptBtn, {BackgroundColor3 = Theme.Section}) end)

        OptBtn.MouseButton1Click:Connect(function()
            selected = opt
            SelectedLabel.Text = tostring(opt)
            open = false
            tween(Holder, {Size = UDim2.new(1, 0, 0, 36)})
            if config.Callback then
                local ok, err = pcall(config.Callback, opt)
                if not ok then warn("[Astral.Lua] Dropdown '"..(config.Name or "?").."' error: "..tostring(err)) end
            end
        end)
    end

    Header.MouseButton1Click:Connect(function()
        open = not open
        if open then
            tween(Holder, {Size = UDim2.new(1, 0, 0, 44 + #options * 28)})
        else
            tween(Holder, {Size = UDim2.new(1, 0, 0, 36)})
        end
    end)

    return {
        Get = function() return selected end,
        Set = function(_, opt) selected = opt; SelectedLabel.Text = tostring(opt) end,
    }
end

--// ══════════════════════ LABEL (for status / info text) ══════════════════════
function Astral:CreateLabel(text)
    local Theme = self.Theme
    local Label = new("TextLabel", {
        Text = text,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Page,
    })
    track(self, function() Label.Font = Theme.Font end)
    return {
        Set = function(_, newText) Label.Text = newText end,
        Instance = Label,
    }
end

--// ══════════════════════ KEYBIND ══════════════════════
-- config = { Name = "UI Toggle", Default = Enum.KeyCode.RightShift, Callback = function(keycode) end }
-- Click the button, then press any key to bind it. Returns an object
-- with .Value (the current KeyCode) and :Set(keycode) to change it from code.
function Astral:CreateKeybind(config)
    config = config or {}
    local Theme = self.Theme
    local current = config.Default or Enum.KeyCode.Unknown
    local listening = false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Element,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local NameLabel = new("TextLabel", {
        Text = config.Name or "Keybind",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local KeyBtn = new("TextButton", {
        Text = current.Name,
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Theme.TextPrimary,
        BackgroundColor3 = Theme.Section,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(90, 24),
        Position = UDim2.new(1, -98, 0.5, -12),
        Parent = Holder,
    }, { corner(UDim.new(0, 5)), stroke(Theme.Stroke) })

    track(self, function()
        NameLabel.Font = Theme.Font
        KeyBtn.Font = Theme.FontBold
    end)

    local KeybindObj = { Value = current }

    function KeybindObj:Set(keycode)
        current = keycode
        self.Value = keycode
        KeyBtn.Text = keycode.Name
    end

    KeyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        KeyBtn.Text = "..."
        tween(KeyBtn, {BackgroundColor3 = Theme.Accent})

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            listening = false
            tween(KeyBtn, {BackgroundColor3 = Theme.Section})
            KeybindObj:Set(input.KeyCode)
            if config.Callback then
                local ok, err = pcall(config.Callback, input.KeyCode)
                if not ok then warn("[Astral.Lua] Keybind '"..(config.Name or "?").."' error: "..tostring(err)) end
            end
        end)
    end)

    return KeybindObj
end

--// ══════════════════════ COLOR PICKER ══════════════════════
-- config = { Name = "Accent Color", Default = Color3.fromRGB(120,90,255), Callback = function(color) end }
-- Click to expand R/G/B sliders plus quick-pick swatches.
function Astral:CreateColorPicker(config)
    config = config or {}
    local Theme = self.Theme
    local color = config.Default or Theme.Accent
    local open = false

    local Holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Element,
        ClipsDescendants = true,
        Parent = self.Page,
    }, { corner(), stroke(Theme.Stroke) })

    local Header = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = Holder,
    })

    local NameLabel = new("TextLabel", {
        Text = config.Name or "Color",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })
    track(self, function() NameLabel.Font = Theme.Font end)

    local Swatch = new("Frame", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -36, 0.5, -12),
        BackgroundColor3 = color,
        Parent = Header,
    }, { corner(UDim.new(0, 6)), stroke(Theme.Stroke) })

    local Body = new("Frame", {
        Size = UDim2.new(1, -16, 0, 108),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        Parent = Holder,
    })

    local function fireCallback()
        if config.Callback then
            local ok, err = pcall(config.Callback, color)
            if not ok then warn("[Astral.Lua] ColorPicker '"..(config.Name or "?").."' error: "..tostring(err)) end
        end
    end

    -- one mini R/G/B slider
    local function miniSlider(labelText, y, initial, onChange)
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            Position = UDim2.new(0, 0, 0, y),
            BackgroundTransparency = 1,
            Parent = Body,
        })
        local lbl = new("TextLabel", {
            Text = labelText,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(16, 20),
            Parent = row,
        })
        track(self, function() lbl.Font = Theme.Font end)
        local track_ = new("Frame", {
            Size = UDim2.new(1, -26, 0, 6),
            Position = UDim2.new(0, 22, 0.5, -3),
            BackgroundColor3 = Theme.Section,
            Parent = row,
        }, { corner(UDim.new(1, 0)) })
        local fill = new("Frame", {
            Size = UDim2.new(initial / 255, 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            Parent = track_,
        }, { corner(UDim.new(1, 0)) })
        track(self, function() fill.BackgroundColor3 = Theme.Accent end)

        local dragging = false
        local function update(input)
            local rel = math.clamp((input.Position.X - track_.AbsolutePosition.X) / track_.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            onChange(math.floor(rel * 255 + 0.5))
        end
        track_.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    miniSlider("R", 0, math.floor(color.R * 255), function(v)
        color = Color3.fromRGB(v, math.floor(color.G * 255), math.floor(color.B * 255))
        Swatch.BackgroundColor3 = color
        fireCallback()
    end)
    miniSlider("G", 30, math.floor(color.G * 255), function(v)
        color = Color3.fromRGB(math.floor(color.R * 255), v, math.floor(color.B * 255))
        Swatch.BackgroundColor3 = color
        fireCallback()
    end)
    miniSlider("B", 60, math.floor(color.B * 255), function(v)
        color = Color3.fromRGB(math.floor(color.R * 255), math.floor(color.G * 255), v)
        Swatch.BackgroundColor3 = color
        fireCallback()
    end)

    Header.MouseButton1Click:Connect(function()
        open = not open
        tween(Holder, {Size = UDim2.new(1, 0, 0, open and 156 or 36)})
    end)

    return {
        Get = function() return color end,
        Set = function(_, newColor) color = newColor; Swatch.BackgroundColor3 = newColor end,
    }
end

return Astral
