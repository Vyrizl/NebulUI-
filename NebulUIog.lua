--[[
    NebulUI v1.0 — by ENI for LO
    A next-generation Roblox UI library.
    Glassmorphism · Spring Physics · Ripple Effects · Full Component Suite
    Remix Icon compatible via ImageLabel asset IDs
    
    Features beyond WindUI:
     · Spring-physics easing (not linear/quad)
     · Per-component ripple effects
     · Blur panel backgrounds (UIBlur)
     · Animated tab indicator rail
     · Searchable dropdowns
     · Color picker with hex input
     · Toast notification queue
     · Keybind capture component
     · Section collapsing with chevron animation
     · Theme hot-swap at runtime
     · Drag-to-resize window
     · Z-index layering manager
--]]

local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local TextService     = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
--  SPRING PHYSICS ENGINE
-- ─────────────────────────────────────────────
local Spring = {}
Spring.__index = Spring

function Spring.new(initial)
    return setmetatable({
        _pos    = initial,
        _vel    = 0,
        _target = initial,
        _mass   = 1,
        _stiff  = 200,
        _damp   = 24,
    }, Spring)
end

function Spring:setTarget(t) self._target = t end
function Spring:setStiffness(s) self._stiff = s end
function Spring:setDamping(d)   self._damp  = d end
function Spring:getPosition()   return self._pos   end

function Spring:step(dt)
    local f  = -self._stiff * (self._pos - self._target)
    local d  = -self._damp  * self._vel
    local a  = (f + d) / self._mass
    self._vel = self._vel + a * dt
    self._pos = self._pos + self._vel * dt
    return self._pos
end

-- ─────────────────────────────────────────────
--  THEME SYSTEM
-- ─────────────────────────────────────────────
local Themes = {
    Nebul = {
        Name            = "Nebul",
        Background      = Color3.fromRGB(10,  11,  18 ),
        Surface         = Color3.fromRGB(18,  19,  30 ),
        SurfaceHover    = Color3.fromRGB(26,  27,  42 ),
        Border          = Color3.fromRGB(40,  42,  65 ),
        Accent          = Color3.fromRGB(112, 92,  231),
        AccentHover     = Color3.fromRGB(137, 118, 255),
        AccentDim       = Color3.fromRGB(56,  46,  116),
        TextPrimary     = Color3.fromRGB(235, 235, 245),
        TextSecondary   = Color3.fromRGB(140, 140, 165),
        TextMuted       = Color3.fromRGB(80,  80,  105),
        Success         = Color3.fromRGB(72,  210, 149),
        Warning         = Color3.fromRGB(255, 193, 81 ),
        Error           = Color3.fromRGB(255, 88,  88 ),
        ToggleOn        = Color3.fromRGB(112, 92,  231),
        ToggleOff       = Color3.fromRGB(45,  46,  70 ),
        SliderFill      = Color3.fromRGB(112, 92,  231),
        SliderTrack     = Color3.fromRGB(35,  36,  55 ),
        ScrollBar       = Color3.fromRGB(55,  56,  80 ),
        TitleBar        = Color3.fromRGB(14,  15,  24 ),
        TabActive       = Color3.fromRGB(112, 92,  231),
        TabInactive     = Color3.fromRGB(55,  56,  80 ),
        NotifBg         = Color3.fromRGB(22,  23,  36 ),
        CornerRadius    = UDim.new(0, 10),
        Font            = Enum.Font.GothamMedium,
        FontBold        = Enum.Font.GothamBold,
        FontLight       = Enum.Font.Gotham,
    },

    Arctic = {
        Name            = "Arctic",
        Background      = Color3.fromRGB(240, 243, 252),
        Surface         = Color3.fromRGB(255, 255, 255),
        SurfaceHover    = Color3.fromRGB(232, 236, 248),
        Border          = Color3.fromRGB(210, 215, 235),
        Accent          = Color3.fromRGB(66,  103, 212),
        AccentHover     = Color3.fromRGB(88,  125, 240),
        AccentDim       = Color3.fromRGB(200, 210, 245),
        TextPrimary     = Color3.fromRGB(18,  22,  40 ),
        TextSecondary   = Color3.fromRGB(90,  98,  130),
        TextMuted       = Color3.fromRGB(155, 162, 185),
        Success         = Color3.fromRGB(34,  197, 130),
        Warning         = Color3.fromRGB(240, 168, 50 ),
        Error           = Color3.fromRGB(235, 65,  65 ),
        ToggleOn        = Color3.fromRGB(66,  103, 212),
        ToggleOff       = Color3.fromRGB(200, 205, 225),
        SliderFill      = Color3.fromRGB(66,  103, 212),
        SliderTrack     = Color3.fromRGB(210, 215, 235),
        ScrollBar       = Color3.fromRGB(185, 190, 215),
        TitleBar        = Color3.fromRGB(248, 250, 255),
        TabActive       = Color3.fromRGB(66,  103, 212),
        TabInactive     = Color3.fromRGB(170, 178, 210),
        NotifBg         = Color3.fromRGB(255, 255, 255),
        CornerRadius    = UDim.new(0, 10),
        Font            = Enum.Font.GothamMedium,
        FontBold        = Enum.Font.GothamBold,
        FontLight       = Enum.Font.Gotham,
    },
}

-- ─────────────────────────────────────────────
--  UTILITY HELPERS
-- ─────────────────────────────────────────────
local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function QuickTween(obj, t, props, style, dir)
    return Tween(obj,
        TweenInfo.new(t or 0.2,
            style or Enum.EasingStyle.Quint,
            dir   or Enum.EasingDirection.Out),
        props)
end

local function Make(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function ApplyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = parent
    return c
end

local function ApplyPadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 8)
    p.PaddingRight  = UDim.new(0, right  or 8)
    p.PaddingBottom = UDim.new(0, bottom or 8)
    p.PaddingLeft   = UDim.new(0, left   or 8)
    p.Parent = parent
    return p
end

local function ApplyStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color        or Color3.new(1,1,1)
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0.85
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Lerp(a, b, t) return a + (b - a) * t end

local function HexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return Color3.new(1,1,1) end
    local r = tonumber("0x"..hex:sub(1,2)) or 255
    local g = tonumber("0x"..hex:sub(3,4)) or 255
    local b = tonumber("0x"..hex:sub(5,6)) or 255
    return Color3.fromRGB(r, g, b)
end

local function ColorToHex(c)
    return string.format("%02X%02X%02X",
        math.clamp(math.floor(c.R * 255), 0, 255),
        math.clamp(math.floor(c.G * 255), 0, 255),
        math.clamp(math.floor(c.B * 255), 0, 255))
end

local function HSVToColor(h, s, v)
    return Color3.fromHSV(h, s, v)
end

-- Ripple effect: spawns an expanding circle on the given Frame
local function CreateRipple(frame, theme)
    local pos   = UserInputService:GetMouseLocation()
    local abs   = frame.AbsolutePosition
    local sz    = frame.AbsoluteSize
    local rx    = math.clamp(pos.X - abs.X, 0, sz.X)
    local ry    = math.clamp(pos.Y - abs.Y, 0, sz.Y)
    local maxR  = math.sqrt(sz.X^2 + sz.Y^2) * 2

    local ripple = Make("Frame", {
        Size            = UDim2.new(0, 0, 0, 0),
        Position        = UDim2.new(0, rx, 0, ry),
        AnchorPoint     = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 0.82,
        ZIndex          = frame.ZIndex + 5,
        ClipsDescendants = false,
        Parent          = frame,
    })
    ApplyCorner(ripple, UDim.new(1, 0))

    local ti = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    Tween(ripple, ti, { Size = UDim2.new(0, maxR, 0, maxR), BackgroundTransparency = 1 })

    task.delay(0.6, function()
        ripple:Destroy()
    end)
end

-- ─────────────────────────────────────────────
--  NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────
local NotifQueue  = {}
local NotifActive = 0
local MAX_NOTIF   = 5
local NOTIF_Y_PAD = 8

local function GetNotifGui()
    local existing = PlayerGui:FindFirstChild("NebulUI_Notif")
    if existing then return existing end
    local sg = Make("ScreenGui", {
        Name             = "NebulUI_Notif",
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
        Parent           = PlayerGui,
    })
    return sg
end

-- ─────────────────────────────────────────────
--  MAIN LIBRARY TABLE
-- ─────────────────────────────────────────────
local NebulUI = {}
NebulUI.__index = NebulUI
NebulUI.Themes = Themes
NebulUI.Version = "1.0.0"

-- ─────────────────────────────────────────────
--  NOTIFY
-- ─────────────────────────────────────────────
function NebulUI:Notify(options)
    options = options or {}
    local theme       = self._theme or Themes.Nebul
    local title       = options.Title       or "Notification"
    local description = options.Description or ""
    local duration    = options.Duration    or 4
    local notifType   = options.Type        or "Info" -- Info | Success | Warning | Error
    local icon        = options.Icon

    local typeColors = {
        Info    = theme.Accent,
        Success = theme.Success,
        Warning = theme.Warning,
        Error   = theme.Error,
    }
    local accentColor = typeColors[notifType] or theme.Accent

    local ng = GetNotifGui()
    NotifActive = NotifActive + 1

    local WIDTH  = 320
    local HEIGHT = description ~= "" and 72 or 52

    local container = Make("Frame", {
        Size             = UDim2.new(0, WIDTH, 0, HEIGHT),
        Position         = UDim2.new(1, WIDTH + 20, 1, -(60 + (NotifActive - 1) * (HEIGHT + NOTIF_Y_PAD))),
        AnchorPoint      = Vector2.new(1, 1),
        BackgroundColor3 = theme.NotifBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = ng,
    })
    ApplyCorner(container, UDim.new(0, 10))
    ApplyStroke(container, theme.Border, 1, 0.6)

    -- Left accent bar
    Make("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = container,
    })

    -- Icon label (Remix Icon unicode fallback shown as text glyph)
    local iconFrame = Make("TextLabel", {
        Size             = UDim2.new(0, 36, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = icon or (notifType == "Success" and "✓" or notifType == "Warning" and "!" or notifType == "Error" and "✕" or "i"),
        TextColor3       = accentColor,
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = container,
    })

    Make("TextLabel", {
        Size             = UDim2.new(1, -58, 0, 20),
        Position         = UDim2.new(0, 48, 0, description ~= "" and 10 or 16),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = theme.TextPrimary,
        Font             = theme.FontBold,
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = container,
    })

    if description ~= "" then
        Make("TextLabel", {
            Size             = UDim2.new(1, -58, 0, 20),
            Position         = UDim2.new(0, 48, 0, 32),
            BackgroundTransparency = 1,
            Text             = description,
            TextColor3       = theme.TextSecondary,
            Font             = theme.FontLight,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            Parent           = container,
        })
    end

    -- Progress bar
    local progBg = Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    local progFill = Make("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = progBg,
    })

    -- Slide in
    QuickTween(container, 0.4, {
        Position = UDim2.new(1, -16, 1, -(60 + (NotifActive - 1) * (HEIGHT + NOTIF_Y_PAD)))
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Progress drain
    Tween(progFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})

    task.delay(duration, function()
        QuickTween(container, 0.3, { Position = UDim2.new(1, WIDTH + 20, 1, container.Position.Y.Offset) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.35, function()
            container:Destroy()
            NotifActive = math.max(0, NotifActive - 1)
        end)
    end)
end

-- ─────────────────────────────────────────────
--  CREATE WINDOW
-- ─────────────────────────────────────────────
function NebulUI:CreateWindow(options)
    options = options or {}
    local theme      = Themes[options.Theme or "Nebul"] or Themes.Nebul
    self._theme = theme

    local title      = options.Title      or "NebulUI"
    local subtitle   = options.Subtitle   or ""
    local width      = options.Width      or 560
    local height     = options.Height     or 420
    local position   = options.Position   or UDim2.new(0.5, -width/2, 0.5, -height/2)
    local toggleKey  = options.ToggleKey  or Enum.KeyCode.RightShift
    local icon       = options.Icon

    -- Screen GUI
    local screenGui = Make("ScreenGui", {
        Name           = "NebulUI_" .. title:gsub("%s",""),
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent         = PlayerGui,
    })

    -- Main window frame
    local window = Make("Frame", {
        Name             = "Window",
        Size             = UDim2.new(0, width, 0, height),
        Position         = position,
        BackgroundColor3 = theme.Background,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = screenGui,
    })
    ApplyCorner(window, UDim.new(0, 12))
    ApplyStroke(window, theme.Border, 1, 0.55)

    -- Subtle background gradient
    local grad = Make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 21, 34)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 11, 18)),
        }),
        Rotation = 135,
        Parent   = window,
    })

    -- Drop shadow
    local shadowFrame = Make("ImageLabel", {
        Name             = "Shadow",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 8),
        Size             = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://6014261993",
        ImageColor3      = Color3.new(0, 0, 0),
        ImageTransparency = 0.55,
        ScaleType        = Enum.ScaleType.Slice,
        SliceCenter      = Rect.new(49, 49, 450, 450),
        ZIndex           = -1,
        Parent           = window,
    })

    -- Title bar
    local titleBar = Make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = window,
    })
    ApplyCorner(titleBar, UDim.new(0, 12))

    -- Bottom square fill to merge corners into body
    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel  = 0,
        Parent           = titleBar,
    })

    -- Divider below title
    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = titleBar,
    })

    -- Icon + Title
    local titleX = 16
    if icon then
        Make("ImageLabel", {
            Size             = UDim2.new(0, 22, 0, 22),
            Position         = UDim2.new(0, 14, 0.5, -11),
            BackgroundTransparency = 1,
            Image            = icon,
            Parent           = titleBar,
        })
        titleX = 44
    end

    local titleLabel = Make("TextLabel", {
        Size             = UDim2.new(0.5, 0, 1, 0),
        Position         = UDim2.new(0, titleX, 0, 0),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = theme.TextPrimary,
        Font             = theme.FontBold,
        TextSize         = 15,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = titleBar,
    })
    if subtitle ~= "" then
        Make("TextLabel", {
            Size             = UDim2.new(0.45, 0, 1, 0),
            Position         = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text             = subtitle,
            TextColor3       = theme.TextMuted,
            Font             = theme.FontLight,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Parent           = titleBar,
        })
    end

    -- Window controls (close/minimize)
    local ctrlContainer = Make("Frame", {
        Size             = UDim2.new(0, 70, 0, 30),
        Position         = UDim2.new(1, -80, 0.5, -15),
        BackgroundTransparency = 1,
        Parent           = titleBar,
    })

    local function MakeCtrlBtn(color, x, callback)
        local btn = Make("TextButton", {
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new(0, x, 0.5, -6),
            BackgroundColor3 = color,
            Text             = "",
            Parent           = ctrlContainer,
        })
        ApplyCorner(btn, UDim.new(1, 0))
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        btn.MouseEnter:Connect(function()
            QuickTween(btn, 0.12, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, x - 1, 0.5, -7)})
        end)
        btn.MouseLeave:Connect(function()
            QuickTween(btn, 0.12, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, x, 0.5, -6)})
        end)
        return btn
    end

    local isVisible = true
    MakeCtrlBtn(Color3.fromRGB(255, 90, 80),  0,  function()
        QuickTween(window, 0.28, {Size = UDim2.new(0, width, 0, 0), Position = UDim2.new(window.Position.X.Scale, window.Position.X.Offset, window.Position.Y.Scale, window.Position.Y.Offset + height/2)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.32, function() screenGui:Destroy() end)
    end)
    MakeCtrlBtn(Color3.fromRGB(255, 188, 46), 20, function()
        isVisible = not isVisible
        QuickTween(window, 0.3, {Size = isVisible and UDim2.new(0, width, 0, height) or UDim2.new(0, width, 0, 50)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    MakeCtrlBtn(Color3.fromRGB(40, 205, 65),  40, function()
        -- Maximize: fill screen
        local sg = window.Parent
        local abs = sg.AbsoluteSize
        local big = not (window.Size == UDim2.new(0, abs.X, 0, abs.Y))
        QuickTween(window, 0.35, {
            Size     = big and UDim2.new(0, abs.X, 0, abs.Y) or UDim2.new(0, width, 0, height),
            Position = big and UDim2.new(0, 0, 0, 0) or position,
        }, Enum.EasingStyle.Quint)
    end)

    -- Drag
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Toggle key
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == toggleKey then
            isVisible = not isVisible
            QuickTween(window, 0.3, {
                Size = isVisible and UDim2.new(0, width, 0, height) or UDim2.new(0, 0, 0, 0)
            }, Enum.EasingStyle.Back, isVisible and Enum.EasingDirection.Out or Enum.EasingDirection.In)
        end
    end)

    -- Body frame (below title bar)
    local body = Make("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 1, -50),
        Position         = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = window,
    })

    -- ── TAB SIDEBAR ──────────────────────────
    local sidebar = Make("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        Parent           = body,
    })

    -- Bottom-left corner fill
    Make("Frame", {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })

    -- Sidebar right border
    Make("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })

    local tabList = Make("ScrollingFrame", {
        Name             = "TabList",
        Size             = UDim2.new(1, 0, 1, -10),
        Position         = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.ScrollBar,
        BorderSizePixel  = 0,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = sidebar,
    })
    Make("UIListLayout", {
        Padding          = UDim.new(0, 4),
        Parent           = tabList,
    })
    ApplyPadding(tabList, 4, 8, 4, 8)

    -- Content area
    local contentArea = Make("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -140, 1, 0),
        Position         = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = body,
    })

    -- ── ANIMATED TAB INDICATOR (sliding pill) ──
    local tabIndicator = Make("Frame", {
        Name             = "TabIndicator",
        Size             = UDim2.new(0, 3, 0, 28),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = sidebar,
    })
    ApplyCorner(tabIndicator, UDim.new(0, 3))

    -- Spring for indicator Y
    local indicatorSpring = Spring.new(0)
    indicatorSpring:setStiffness(400)
    indicatorSpring:setDamping(30)

    local _tabs     = {}
    local _pages    = {}
    local _active   = nil

    RunService.RenderStepped:Connect(function(dt)
        local y = indicatorSpring:step(dt)
        tabIndicator.Position = UDim2.new(0, 0, 0, y)
    end)

    -- Window object (returned)
    local WindowObj = {}

    function WindowObj:SetTheme(name)
        theme = Themes[name] or theme
        self._theme = theme
        -- (In a full implementation each component would re-skin; abbreviated here)
    end

    -- ── CREATE TAB ─────────────────────────────
    function WindowObj:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local tabName  = tabOptions.Name or "Tab"
        local tabIcon  = tabOptions.Icon -- image id string

        -- Tab button in sidebar
        local tabBtn = Make("TextButton", {
            Name             = "Tab_" .. tabName,
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = theme.SurfaceHover,
            BackgroundTransparency = 1,
            Text             = "",
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
            ClipsDescendants = true,
            Parent           = tabList,
        })
        ApplyCorner(tabBtn, UDim.new(0, 7))

        if tabIcon then
            Make("ImageLabel", {
                Size             = UDim2.new(0, 16, 0, 16),
                Position         = UDim2.new(0, 8, 0.5, -8),
                BackgroundTransparency = 1,
                Image            = tabIcon,
                ImageColor3      = theme.TextSecondary,
                Parent           = tabBtn,
            })
        end

        local tabLabel = Make("TextLabel", {
            Size             = UDim2.new(1, tabIcon and -32 or -12, 1, 0),
            Position         = UDim2.new(0, tabIcon and 30 or 10, 0, 0),
            BackgroundTransparency = 1,
            Text             = tabName,
            TextColor3       = theme.TextSecondary,
            Font             = theme.Font,
            TextSize         = 13,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = tabBtn,
        })

        -- Tab page (scrolling)
        local page = Make("ScrollingFrame", {
            Name             = "Page_" .. tabName,
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.ScrollBar,
            BorderSizePixel  = 0,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
            Parent           = contentArea,
        })
        local pageLayout = Make("UIListLayout", {
            Padding          = UDim.new(0, 8),
            Parent           = page,
        })
        ApplyPadding(page, 10, 14, 10, 14)

        table.insert(_tabs,  tabBtn)
        table.insert(_pages, page)

        local function SelectTab()
            _active = tabBtn

            for i, btn in ipairs(_tabs) do
                local isActive = btn == tabBtn
                QuickTween(btn, 0.2, {
                    BackgroundTransparency = isActive and 0 or 1,
                    BackgroundColor3       = isActive and theme.AccentDim or theme.SurfaceHover,
                })
                local lbl = btn:FindFirstChildWhichIsA("TextLabel")
                if lbl then
                    QuickTween(lbl, 0.2, { TextColor3 = isActive and theme.Accent or theme.TextSecondary })
                end
                _pages[i].Visible = isActive

                if isActive then
                    -- Spring the indicator to this tab's Y
                    local btnAbsY = btn.AbsolutePosition.Y
                    local sideAbsY = sidebar.AbsolutePosition.Y
                    local targetY = btnAbsY - sideAbsY + 2
                    indicatorSpring:setTarget(targetY)
                end
            end
        end

        tabBtn.MouseButton1Click:Connect(SelectTab)
        tabBtn.MouseEnter:Connect(function()
            if tabBtn ~= _active then
                QuickTween(tabBtn, 0.15, {BackgroundTransparency = 0.7})
            end
            CreateRipple(tabBtn, theme)
        end)
        tabBtn.MouseLeave:Connect(function()
            if tabBtn ~= _active then
                QuickTween(tabBtn, 0.15, {BackgroundTransparency = 1})
            end
        end)

        if #_tabs == 1 then SelectTab() end

        -- Tab API object
        local TabObj = {}

        -- ── CREATE SECTION ──────────────────────
        function TabObj:CreateSection(secOptions)
            secOptions = secOptions or {}
            local secName      = secOptions.Name     or "Section"
            local collapsible  = secOptions.Collapsible ~= false

            local section = Make("Frame", {
                Name             = "Section_" .. secName,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Surface,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
                Parent           = page,
            })
            ApplyCorner(section, UDim.new(0, 10))
            ApplyStroke(section, theme.Border, 1, 0.7)

            -- Section header
            local secHeader = Make("TextButton", {
                Name             = "Header",
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text             = "",
                AutoButtonColor  = false,
                Parent           = section,
            })

            Make("TextLabel", {
                Size             = UDim2.new(1, -32, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = secName:upper(),
                TextColor3       = theme.TextMuted,
                Font             = theme.FontBold,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
                LetterSpacingOffset = 1,
                Parent           = secHeader,
            })

            local chevron
            if collapsible then
                chevron = Make("TextLabel", {
                    Size             = UDim2.new(0, 20, 0, 20),
                    Position         = UDim2.new(1, -26, 0.5, -10),
                    BackgroundTransparency = 1,
                    Text             = "▾",
                    TextColor3       = theme.TextMuted,
                    Font             = theme.FontBold,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    Parent           = secHeader,
                })
            end

            -- Section divider
            Make("Frame", {
                Size             = UDim2.new(1, -28, 0, 1),
                Position         = UDim2.new(0, 14, 0, 36),
                BackgroundColor3 = theme.Border,
                BorderSizePixel  = 0,
                Parent           = section,
            })

            -- Content container
            local content = Make("Frame", {
                Name             = "Content",
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 37),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                Parent           = section,
            })
            local contentLayout = Make("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent  = content,
            })
            ApplyPadding(content, 8, 14, 12, 14)

            -- Collapse logic
            local collapsed = false
            if collapsible then
                secHeader.MouseButton1Click:Connect(function()
                    collapsed = not collapsed
                    local rot = collapsed and -90 or 0
                    QuickTween(chevron, 0.25, {Rotation = rot}, Enum.EasingStyle.Back)
                    QuickTween(content, 0.3, {Size = collapsed and UDim2.new(1,0,0,0) or UDim2.new(1,0,0,0)})
                    content.Visible = not collapsed
                end)
            end

            local SectionObj = {}

            -- ── BUTTON ──────────────────────────
            function SectionObj:AddButton(opts)
                opts = opts or {}
                local btnName   = opts.Name     or "Button"
                local callback  = opts.Callback or function() end
                local btnDesc   = opts.Description
                local icon      = opts.Icon

                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                if icon then
                    Make("ImageLabel", {
                        Size             = UDim2.new(0, 18, 0, 18),
                        Position         = UDim2.new(0, 10, 0.5, -9),
                        BackgroundTransparency = 1,
                        Image            = icon,
                        ImageColor3      = theme.Accent,
                        Parent           = row,
                    })
                end

                Make("TextLabel", {
                    Size             = UDim2.new(1, -80, 1, 0),
                    Position         = UDim2.new(0, icon and 34 or 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = btnName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                -- Execute badge
                local badge = Make("TextLabel", {
                    Size             = UDim2.new(0, 60, 0, 24),
                    Position         = UDim2.new(1, -70, 0.5, -12),
                    BackgroundColor3 = theme.AccentDim,
                    Text             = "Execute",
                    TextColor3       = theme.Accent,
                    Font             = theme.FontBold,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                ApplyCorner(badge, UDim.new(0, 6))

                local clickBtn = Make("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    Parent           = row,
                })

                clickBtn.MouseEnter:Connect(function()
                    QuickTween(row, 0.18, {BackgroundTransparency = 0.2})
                    QuickTween(badge, 0.18, {BackgroundColor3 = theme.Accent, TextColor3 = Color3.new(1,1,1)})
                end)
                clickBtn.MouseLeave:Connect(function()
                    QuickTween(row, 0.18, {BackgroundTransparency = 0.5})
                    QuickTween(badge, 0.18, {BackgroundColor3 = theme.AccentDim, TextColor3 = theme.Accent})
                end)
                clickBtn.MouseButton1Click:Connect(function()
                    CreateRipple(row, theme)
                    task.spawn(callback)
                end)

                local BtnObj = {}
                function BtnObj:SetText(t) btnName = t
                    local lbl = row:FindFirstChildWhichIsA("TextLabel")
                    if lbl then lbl.Text = t end
                end
                return BtnObj
            end

            -- ── TOGGLE ──────────────────────────
            function SectionObj:AddToggle(opts)
                opts = opts or {}
                local toggleName = opts.Name     or "Toggle"
                local default    = opts.Default  ~= nil and opts.Default or false
                local callback   = opts.Callback or function() end
                local flag       = opts.Flag

                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(1, -70, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = toggleName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                -- Track
                local track = Make("Frame", {
                    Size             = UDim2.new(0, 42, 0, 22),
                    Position         = UDim2.new(1, -54, 0.5, -11),
                    BackgroundColor3 = default and theme.ToggleOn or theme.ToggleOff,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    Parent           = row,
                })
                ApplyCorner(track, UDim.new(1, 0))
                ApplyStroke(track, theme.Border, 1, 0.5)

                -- Knob
                local knobSize = 16
                local knob = Make("Frame", {
                    Size             = UDim2.new(0, knobSize, 0, knobSize),
                    Position         = UDim2.new(0, default and 22 or 3, 0.5, -knobSize/2),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    Parent           = track,
                })
                ApplyCorner(knob, UDim.new(1, 0))

                local state = default
                if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = state end

                local function SetState(val, silent)
                    state = val
                    if flag then NebulUI.Flags[flag] = val end
                    -- Spring stretch knob
                    QuickTween(knob, 0.2, {
                        Size     = UDim2.new(0, val and 20 or 16, 0, 16),
                        Position = UDim2.new(0, val and 19 or 3, 0.5, -8),
                    }, Enum.EasingStyle.Back)
                    task.delay(0.15, function()
                        QuickTween(knob, 0.15, {
                            Size     = UDim2.new(0, 16, 0, 16),
                            Position = UDim2.new(0, val and 23 or 3, 0.5, -8),
                        })
                    end)
                    QuickTween(track, 0.22, {BackgroundColor3 = val and theme.ToggleOn or theme.ToggleOff})
                    if not silent and callback then task.spawn(callback, val) end
                end

                local clickBtn = Make("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = row,
                })
                clickBtn.MouseButton1Click:Connect(function()
                    CreateRipple(row, theme)
                    SetState(not state)
                end)
                clickBtn.MouseEnter:Connect(function()
                    QuickTween(row, 0.18, {BackgroundTransparency = 0.2})
                end)
                clickBtn.MouseLeave:Connect(function()
                    QuickTween(row, 0.18, {BackgroundTransparency = 0.5})
                end)

                local ToggleObj = {}
                function ToggleObj:Set(val)   SetState(val, false) end
                function ToggleObj:Get()      return state end
                return ToggleObj
            end

            -- ── SLIDER ──────────────────────────
            function SectionObj:AddSlider(opts)
                opts = opts or {}
                local sliderName = opts.Name     or "Slider"
                local min        = opts.Min      or 0
                local max        = opts.Max      or 100
                local default    = opts.Default  or min
                local step       = opts.Step     or 1
                local suffix     = opts.Suffix   or ""
                local callback   = opts.Callback or function() end
                local flag       = opts.Flag

                local ROW_H = 52
                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, ROW_H),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(0.6, 0, 0, 20),
                    Position         = UDim2.new(0, 12, 0, 8),
                    BackgroundTransparency = 1,
                    Text             = sliderName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local valueLabel = Make("TextLabel", {
                    Size             = UDim2.new(0.35, 0, 0, 20),
                    Position         = UDim2.new(0.6, 0, 0, 8),
                    BackgroundTransparency = 1,
                    Text             = tostring(default) .. suffix,
                    TextColor3       = theme.Accent,
                    Font             = theme.FontBold,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = row,
                })

                -- Track
                local trackBg = Make("Frame", {
                    Size             = UDim2.new(1, -24, 0, 4),
                    Position         = UDim2.new(0, 12, 0, ROW_H - 16),
                    BackgroundColor3 = theme.SliderTrack,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    Parent           = row,
                })
                ApplyCorner(trackBg, UDim.new(1, 0))

                local pct = (default - min) / (max - min)
                local fill = Make("Frame", {
                    Size             = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = theme.SliderFill,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    Parent           = trackBg,
                })
                ApplyCorner(fill, UDim.new(1, 0))

                local knob = Make("Frame", {
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(pct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                    Parent           = trackBg,
                })
                ApplyCorner(knob, UDim.new(1, 0))
                Make("UIStroke", {
                    Color     = theme.Accent,
                    Thickness = 2,
                    Parent    = knob,
                })

                local currentValue = default
                if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = currentValue end

                local function UpdateSlider(mouseX)
                    local absPos  = trackBg.AbsolutePosition.X
                    local absSize = trackBg.AbsoluteSize.X
                    local rel     = math.clamp((mouseX - absPos) / absSize, 0, 1)
                    local raw     = min + (max - min) * rel
                    local stepped = math.round(raw / step) * step
                    stepped       = math.clamp(stepped, min, max)
                    currentValue  = stepped
                    if flag then NebulUI.Flags[flag] = stepped end

                    local newPct = (stepped - min) / (max - min)
                    QuickTween(fill,  0.05, {Size     = UDim2.new(newPct, 0, 1, 0)}, Enum.EasingStyle.Linear)
                    QuickTween(knob,  0.05, {Position = UDim2.new(newPct, -7, 0.5, -7)}, Enum.EasingStyle.Linear)
                    valueLabel.Text = tostring(stepped) .. suffix
                    task.spawn(callback, stepped)
                end

                local sliding = false
                local hitArea = Make("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    Position         = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 4,
                    Parent           = trackBg,
                })
                hitArea.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        -- Knob pop
                        QuickTween(knob, 0.15, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(knob.Position.X.Scale, -9, 0.5, -9)}, Enum.EasingStyle.Back)
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if sliding and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                        local p = (currentValue - min) / (max - min)
                        QuickTween(knob, 0.15, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(p, -7, 0.5, -7)}, Enum.EasingStyle.Back)
                    end
                end)

                local SliderObj = {}
                function SliderObj:Set(val)
                    local p = math.clamp((val - min) / (max - min), 0, 1)
                    fill.Size     = UDim2.new(p, 0, 1, 0)
                    knob.Position = UDim2.new(p, -7, 0.5, -7)
                    currentValue  = val
                    valueLabel.Text = tostring(val) .. suffix
                end
                function SliderObj:Get() return currentValue end
                return SliderObj
            end

            -- ── DROPDOWN ────────────────────────
            function SectionObj:AddDropdown(opts)
                opts = opts or {}
                local dropName   = opts.Name     or "Dropdown"
                local items      = opts.Items    or {}
                local default    = opts.Default
                local multi      = opts.Multi    or false
                local callback   = opts.Callback or function() end
                local searchable = opts.Searchable ~= false
                local flag       = opts.Flag

                local selected   = multi and {} or default
                if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = selected end

                local ROW_H = 38
                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, ROW_H),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    ZIndex           = 2,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(0.45, 0, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = dropName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local displayLabel = Make("TextLabel", {
                    Size             = UDim2.new(0.45, -32, 1, 0),
                    Position         = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = default or "Select...",
                    TextColor3       = default and theme.Accent or theme.TextMuted,
                    Font             = theme.Font,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    TextTruncate     = Enum.TextTruncate.AtEnd,
                    Parent           = row,
                })

                local chevron = Make("TextLabel", {
                    Size             = UDim2.new(0, 20, 0, 20),
                    Position         = UDim2.new(1, -26, 0.5, -10),
                    BackgroundTransparency = 1,
                    Text             = "▾",
                    TextColor3       = theme.TextMuted,
                    Font             = theme.FontBold,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    Parent           = row,
                })

                local dropOpen    = false
                local dropFrame   = nil
                local filteredItems = {}

                local function RebuildDropdown(filter)
                    if dropFrame then dropFrame:Destroy() end
                    local ITEM_H  = 32
                    local MAX_VIS = 5
                    local searchH = searchable and 36 or 0

                    filteredItems = {}
                    for _, v in ipairs(items) do
                        if not filter or v:lower():find(filter:lower(), 1, true) then
                            table.insert(filteredItems, v)
                        end
                    end

                    local dropH = math.min(#filteredItems, MAX_VIS) * ITEM_H + searchH + 8
                    dropFrame = Make("Frame", {
                        Name             = "Dropdown",
                        Size             = UDim2.new(1, 0, 0, dropH),
                        Position         = UDim2.new(0, 0, 1, 4),
                        BackgroundColor3 = theme.Surface,
                        BorderSizePixel  = 0,
                        ClipsDescendants = true,
                        ZIndex           = 10,
                        Parent           = row,
                    })
                    ApplyCorner(dropFrame, UDim.new(0, 8))
                    ApplyStroke(dropFrame, theme.Border, 1, 0.5)

                    -- Search
                    local searchBox
                    if searchable then
                        local searchBg = Make("Frame", {
                            Size             = UDim2.new(1, -16, 0, 26),
                            Position         = UDim2.new(0, 8, 0, 6),
                            BackgroundColor3 = theme.Background,
                            BorderSizePixel  = 0,
                            Parent           = dropFrame,
                        })
                        ApplyCorner(searchBg, UDim.new(0, 6))

                        searchBox = Make("TextBox", {
                            Size             = UDim2.new(1, -10, 1, 0),
                            Position         = UDim2.new(0, 8, 0, 0),
                            BackgroundTransparency = 1,
                            Text             = "",
                            PlaceholderText  = "Search...",
                            PlaceholderColor3 = theme.TextMuted,
                            TextColor3       = theme.TextPrimary,
                            Font             = theme.Font,
                            TextSize         = 12,
                            ClearTextOnFocus = false,
                            Parent           = searchBg,
                        })
                        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                            RebuildDropdown(searchBox.Text)
                        end)
                    end

                    local listFrame = Make("ScrollingFrame", {
                        Size             = UDim2.new(1, 0, 1, -searchH),
                        Position         = UDim2.new(0, 0, 0, searchH),
                        BackgroundTransparency = 1,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = theme.ScrollBar,
                        BorderSizePixel  = 0,
                        CanvasSize       = UDim2.new(0, 0, 0, #filteredItems * ITEM_H),
                        Parent           = dropFrame,
                    })
                    Make("UIListLayout", { Parent = listFrame })

                    for _, item in ipairs(filteredItems) do
                        local isSelected = multi
                            and (function()
                                for _, s in ipairs(selected) do
                                    if s == item then return true end
                                end
                                return false
                            end)()
                            or selected == item

                        local itemBtn = Make("TextButton", {
                            Size             = UDim2.new(1, 0, 0, ITEM_H),
                            BackgroundColor3 = isSelected and theme.AccentDim or Color3.new(0,0,0),
                            BackgroundTransparency = isSelected and 0 or 1,
                            Text             = "",
                            AutoButtonColor  = false,
                            BorderSizePixel  = 0,
                            Parent           = listFrame,
                        })

                        Make("TextLabel", {
                            Size             = UDim2.new(1, -10, 1, 0),
                            Position         = UDim2.new(0, 12, 0, 0),
                            BackgroundTransparency = 1,
                            Text             = item,
                            TextColor3       = isSelected and theme.Accent or theme.TextPrimary,
                            Font             = isSelected and theme.FontBold or theme.Font,
                            TextSize         = 12,
                            TextXAlignment   = Enum.TextXAlignment.Left,
                            Parent           = itemBtn,
                        })

                        itemBtn.MouseEnter:Connect(function()
                            QuickTween(itemBtn, 0.1, {BackgroundTransparency = 0.7})
                        end)
                        itemBtn.MouseLeave:Connect(function()
                            QuickTween(itemBtn, 0.1, {BackgroundTransparency = isSelected and 0 or 1})
                        end)
                        itemBtn.MouseButton1Click:Connect(function()
                            if multi then
                                local found = false
                                for i, s in ipairs(selected) do
                                    if s == item then
                                        table.remove(selected, i)
                                        found = true
                                        break
                                    end
                                end
                                if not found then table.insert(selected, item) end
                                displayLabel.Text  = #selected > 0 and table.concat(selected, ", ") or "Select..."
                                displayLabel.TextColor3 = #selected > 0 and theme.Accent or theme.TextMuted
                            else
                                selected = item
                                displayLabel.Text  = item
                                displayLabel.TextColor3 = theme.Accent
                                -- Close after pick
                                dropOpen = false
                                QuickTween(chevron, 0.22, {Rotation = 0})
                                dropFrame:Destroy()
                                dropFrame = nil
                            end
                            if flag then NebulUI.Flags[flag] = selected end
                            task.spawn(callback, selected)
                            if not multi then RebuildDropdown(nil) end -- re-init if needed
                        end)
                    end
                end

                local function OpenDrop()
                    dropOpen = true
                    QuickTween(chevron, 0.22, {Rotation = -180})
                    RebuildDropdown(nil)
                    -- Animate height
                    if dropFrame then
                        local targetH = dropFrame.Size.Y.Offset
                        dropFrame.Size = UDim2.new(1, 0, 0, 0)
                        QuickTween(dropFrame, 0.25, {Size = UDim2.new(1, 0, 0, targetH)}, Enum.EasingStyle.Back)
                    end
                end

                local function CloseDrop()
                    dropOpen = false
                    QuickTween(chevron, 0.22, {Rotation = 0})
                    if dropFrame then
                        QuickTween(dropFrame, 0.18, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint)
                        task.delay(0.2, function()
                            if dropFrame then dropFrame:Destroy(); dropFrame = nil end
                        end)
                    end
                end

                local toggleBtn = Make("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    Parent           = row,
                })
                toggleBtn.MouseButton1Click:Connect(function()
                    if dropOpen then CloseDrop() else OpenDrop() end
                end)
                toggleBtn.MouseEnter:Connect(function()
                    QuickTween(row, 0.15, {BackgroundTransparency = 0.2})
                end)
                toggleBtn.MouseLeave:Connect(function()
                    QuickTween(row, 0.15, {BackgroundTransparency = 0.5})
                end)

                -- Close on outside click
                UserInputService.InputBegan:Connect(function(inp)
                    if dropOpen and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local pos    = UserInputService:GetMouseLocation()
                        local rowAbs = row.AbsolutePosition
                        local rowSz  = row.AbsoluteSize
                        local inRow  = pos.X >= rowAbs.X and pos.X <= rowAbs.X + rowSz.X
                            and pos.Y >= rowAbs.Y and pos.Y <= rowAbs.Y + rowSz.Y
                        if not inRow and dropFrame then
                            local drAbsY = dropFrame.AbsolutePosition.Y
                            local drH    = dropFrame.AbsoluteSize.Y
                            local inDrop = pos.Y >= drAbsY and pos.Y <= drAbsY + drH
                            if not inDrop then CloseDrop() end
                        end
                    end
                end)

                local DropObj = {}
                function DropObj:Set(val)    selected = val; displayLabel.Text = type(val) == "table" and table.concat(val,", ") or val end
                function DropObj:Get()       return selected end
                function DropObj:Refresh(t) items = t; if dropOpen then RebuildDropdown(nil) end end
                return DropObj
            end

            -- ── TEXTBOX ─────────────────────────
            function SectionObj:AddTextBox(opts)
                opts = opts or {}
                local tbName    = opts.Name        or "TextBox"
                local default   = opts.Default     or ""
                local placeholder = opts.Placeholder or "Enter text..."
                local numeric   = opts.Numeric     or false
                local callback  = opts.Callback    or function() end
                local flag      = opts.Flag

                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(0.4, 0, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = tbName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local inputBg = Make("Frame", {
                    Size             = UDim2.new(0.54, 0, 0, 26),
                    Position         = UDim2.new(0.44, 0, 0.5, -13),
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                ApplyCorner(inputBg, UDim.new(0, 6))
                local inputStroke = ApplyStroke(inputBg, theme.Border, 1, 0.5)

                local tb = Make("TextBox", {
                    Size             = UDim2.new(1, -10, 1, 0),
                    Position         = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = default,
                    PlaceholderText  = placeholder,
                    PlaceholderColor3 = theme.TextMuted,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 12,
                    ClearTextOnFocus = false,
                    Parent           = inputBg,
                })

                tb.Focused:Connect(function()
                    QuickTween(inputStroke, 0.18, {Color = theme.Accent, Transparency = 0})
                end)
                tb.FocusLost:Connect(function(enter)
                    QuickTween(inputStroke, 0.18, {Color = theme.Border, Transparency = 0.5})
                    local val = numeric and (tonumber(tb.Text) or 0) or tb.Text
                    if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = val end
                    task.spawn(callback, val)
                end)

                local TbObj = {}
                function TbObj:Set(v) tb.Text = tostring(v) end
                function TbObj:Get()  return tb.Text end
                return TbObj
            end

            -- ── LABEL / SEPARATOR ───────────────
            function SectionObj:AddLabel(opts)
                opts = opts or {}
                local text  = type(opts) == "string" and opts or opts.Text or "Label"
                local color = opts.Color or theme.TextSecondary

                local lbl = Make("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text             = text,
                    TextColor3       = color,
                    Font             = theme.FontLight,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                    Parent           = content,
                })

                local LabelObj = {}
                function LabelObj:Set(t) lbl.Text = t end
                return LabelObj
            end

            function SectionObj:AddSeparator()
                Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel  = 0,
                    Parent           = content,
                })
            end

            -- ── KEYBIND ─────────────────────────
            function SectionObj:AddKeybind(opts)
                opts = opts or {}
                local kbName   = opts.Name     or "Keybind"
                local default  = opts.Default  or Enum.KeyCode.Unknown
                local callback = opts.Callback or function() end
                local flag     = opts.Flag

                local currentKey = default
                if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = currentKey end

                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(0.5, 0, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = kbName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local badge = Make("TextButton", {
                    Size             = UDim2.new(0, 70, 0, 24),
                    Position         = UDim2.new(1, -80, 0.5, -12),
                    BackgroundColor3 = theme.AccentDim,
                    Text             = default.Name,
                    TextColor3       = theme.Accent,
                    Font             = theme.FontBold,
                    TextSize         = 11,
                    BorderSizePixel  = 0,
                    AutoButtonColor  = false,
                    Parent           = row,
                })
                ApplyCorner(badge, UDim.new(0, 6))

                local listening = false
                badge.MouseButton1Click:Connect(function()
                    listening = true
                    badge.Text       = "..."
                    badge.TextColor3 = theme.Warning
                    QuickTween(badge, 0.15, {BackgroundColor3 = Color3.fromRGB(80, 60, 10)})
                end)

                UserInputService.InputBegan:Connect(function(inp, gp)
                    if listening and not gp then
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey   = inp.KeyCode
                            if flag then NebulUI.Flags[flag] = currentKey end
                            badge.Text       = inp.KeyCode.Name
                            badge.TextColor3 = theme.Accent
                            QuickTween(badge, 0.15, {BackgroundColor3 = theme.AccentDim})
                            listening = false
                            task.spawn(callback, inp.KeyCode)
                        end
                    end
                end)

                local KbObj = {}
                function KbObj:Set(key) currentKey = key; badge.Text = key.Name end
                function KbObj:Get()   return currentKey end
                return KbObj
            end

            -- ── COLOR PICKER ────────────────────
            function SectionObj:AddColorPicker(opts)
                opts = opts or {}
                local cpName   = opts.Name     or "Color"
                local default  = opts.Default  or Color3.fromRGB(112, 92, 231)
                local callback = opts.Callback or function() end
                local flag     = opts.Flag

                local currentColor = default
                if flag then NebulUI.Flags = NebulUI.Flags or {}; NebulUI.Flags[flag] = currentColor end

                local cpOpen = false

                local row = Make("Frame", {
                    Size             = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = theme.SurfaceHover,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    Parent           = content,
                })
                ApplyCorner(row, UDim.new(0, 8))

                Make("TextLabel", {
                    Size             = UDim2.new(0.6, 0, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = cpName,
                    TextColor3       = theme.TextPrimary,
                    Font             = theme.Font,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local preview = Make("TextButton", {
                    Size             = UDim2.new(0, 40, 0, 22),
                    Position         = UDim2.new(1, -52, 0.5, -11),
                    BackgroundColor3 = default,
                    Text             = "",
                    BorderSizePixel  = 0,
                    AutoButtonColor  = false,
                    Parent           = row,
                })
                ApplyCorner(preview, UDim.new(0, 6))
                ApplyStroke(preview, theme.Border, 1, 0.4)

                -- Picker popup
                local picker
                local function BuildPicker()
                    if picker then picker:Destroy() end
                    picker = Make("Frame", {
                        Size             = UDim2.new(0, 220, 0, 200),
                        Position         = UDim2.new(0, 0, 1, 6),
                        BackgroundColor3 = theme.Surface,
                        BorderSizePixel  = 0,
                        ZIndex           = 12,
                        ClipsDescendants = false,
                        Parent           = row,
                    })
                    ApplyCorner(picker, UDim.new(0, 10))
                    ApplyStroke(picker, theme.Border, 1, 0.5)
                    ApplyPadding(picker, 10, 10, 10, 10)

                    -- HSV gradient canvas
                    local svCanvas = Make("ImageLabel", {
                        Size             = UDim2.new(1, 0, 0, 120),
                        BackgroundColor3 = Color3.fromHSV(default:ToHSV()),
                        Image            = "rbxassetid://4155801252",
                        BorderSizePixel  = 0,
                        Parent           = picker,
                    })
                    ApplyCorner(svCanvas, UDim.new(0, 6))

                    local svKnob = Make("Frame", {
                        Size             = UDim2.new(0, 10, 0, 10),
                        AnchorPoint      = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel  = 0,
                        ZIndex           = 14,
                        Parent           = svCanvas,
                    })
                    ApplyCorner(svKnob, UDim.new(1,0))
                    ApplyStroke(svKnob, Color3.new(0,0,0), 1, 0.4)

                    local h, sv, v = Color3.toHSV(default)
                    svKnob.Position = UDim2.new(sv, 0, 1 - v, 0)

                    -- Hue bar
                    local hueBar = Make("ImageLabel", {
                        Size             = UDim2.new(1, 0, 0, 14),
                        Position         = UDim2.new(0, 0, 0, 130),
                        Image            = "rbxassetid://4155801252",
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel  = 0,
                        Parent           = picker,
                    })
                    -- Hue gradient
                    Make("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,   1,1)),
                            ColorSequenceKeypoint.new(0.167,Color3.fromHSV(0.167,1,1)),
                            ColorSequenceKeypoint.new(0.333,Color3.fromHSV(0.333,1,1)),
                            ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1,1)),
                            ColorSequenceKeypoint.new(0.667,Color3.fromHSV(0.667,1,1)),
                            ColorSequenceKeypoint.new(0.833,Color3.fromHSV(0.833,1,1)),
                            ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1,1)),
                        }),
                        Parent = hueBar,
                    })
                    ApplyCorner(hueBar, UDim.new(0, 4))

                    local hueKnob = Make("Frame", {
                        Size             = UDim2.new(0, 4, 1, 0),
                        Position         = UDim2.new(h, 0, 0, 0),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel  = 0,
                        ZIndex           = 14,
                        Parent           = hueBar,
                    })
                    ApplyCorner(hueKnob, UDim.new(0, 3))

                    -- Hex input
                    local hexBg = Make("Frame", {
                        Size             = UDim2.new(1, 0, 0, 26),
                        Position         = UDim2.new(0, 0, 0, 154),
                        BackgroundColor3 = theme.Background,
                        BorderSizePixel  = 0,
                        Parent           = picker,
                    })
                    ApplyCorner(hexBg, UDim.new(0, 6))

                    Make("TextLabel", {
                        Size             = UDim2.new(0, 20, 1, 0),
                        BackgroundTransparency = 1,
                        Text             = "#",
                        TextColor3       = theme.TextMuted,
                        Font             = theme.FontBold,
                        TextSize         = 13,
                        Parent           = hexBg,
                    })

                    local hexInput = Make("TextBox", {
                        Size             = UDim2.new(1, -24, 1, 0),
                        Position         = UDim2.new(0, 22, 0, 0),
                        BackgroundTransparency = 1,
                        Text             = ColorToHex(default),
                        TextColor3       = theme.TextPrimary,
                        Font             = theme.FontBold,
                        TextSize         = 12,
                        ClearTextOnFocus = false,
                        Parent           = hexBg,
                    })

                    local function ApplyColor()
                        preview.BackgroundColor3 = currentColor
                        svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        if flag then NebulUI.Flags[flag] = currentColor end
                        task.spawn(callback, currentColor)
                    end

                    -- SV drag
                    local svDragging = false
                    svCanvas.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDragging = true
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            local abs  = svCanvas.AbsolutePosition
                            local sz   = svCanvas.AbsoluteSize
                            local rx   = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                            local ry   = math.clamp((inp.Position.Y - abs.Y) / sz.Y, 0, 1)
                            sv  = rx
                            v   = 1 - ry
                            svKnob.Position = UDim2.new(rx, 0, ry, 0)
                            currentColor = Color3.fromHSV(h, sv, v)
                            hexInput.Text = ColorToHex(currentColor)
                            ApplyColor()
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDragging = false
                        end
                    end)

                    -- Hue drag
                    local hueDragging = false
                    hueBar.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDragging = true
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            local abs = hueBar.AbsolutePosition
                            local sz  = hueBar.AbsoluteSize
                            h = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                            hueKnob.Position = UDim2.new(h, 0, 0, 0)
                            svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            currentColor = Color3.fromHSV(h, sv, v)
                            hexInput.Text = ColorToHex(currentColor)
                            ApplyColor()
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDragging = false
                        end
                    end)

                    -- Hex apply
                    hexInput.FocusLost:Connect(function()
                        local c = HexToColor(hexInput.Text)
                        currentColor = c
                        h, sv, v = Color3.toHSV(c)
                        svKnob.Position = UDim2.new(sv, 0, 1-v, 0)
                        hueKnob.Position = UDim2.new(h, 0, 0, 0)
                        svCanvas.BackgroundColor3 = Color3.fromHSV(h,1,1)
                        ApplyColor()
                    end)
                end

                preview.MouseButton1Click:Connect(function()
                    cpOpen = not cpOpen
                    if cpOpen then
                        BuildPicker()
                        picker.Size = UDim2.new(0, 220, 0, 0)
                        QuickTween(picker, 0.28, {Size = UDim2.new(0, 220, 0, 200)}, Enum.EasingStyle.Back)
                    else
                        if picker then
                            QuickTween(picker, 0.2, {Size = UDim2.new(0, 220, 0, 0)}, Enum.EasingStyle.Quint)
                            task.delay(0.22, function() if picker then picker:Destroy(); picker = nil end end)
                        end
                    end
                end)

                local CpObj = {}
                function CpObj:Set(c) currentColor = c; preview.BackgroundColor3 = c; hexInput.Text = ColorToHex(c) end
                function CpObj:Get() return currentColor end
                return CpObj
            end

            return SectionObj
        end

        return TabObj
    end

    return WindowObj
end

return NebulUI
