-- BitBeast Hyprland configuration for Hyprland 0.57+ (Lua config).
--
-- Hyprland 0.57 no longer reads hyprland.conf. This file is the Lua port of
-- the legacy BitBeast config. It re-reads the BitBeast generated theme files
-- on every config load / reload so `bitbeast <theme>`, `bitbeast style ...`
-- and `bitbeast touchpad` keep working.

local HOME = os.getenv("HOME") or "/home/dranzer"

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local data = f:read("*a")
    f:close()
    return data
end

-- Parse the small KEY = VALUE / SECTION { ... } dialect used by the
-- BitBeast theme files. Returns a flat table such as
--   ["general.border_size"] = "4"
--   ["decoration.shadow.range"] = "22"
local function parse_conf(text)
    local values = {}
    local stack = {}

    if not text then
        return values
    end

    for line in text:gmatch("[^\r\n]+") do
        local current = trim((line:gsub("#.*$", "")))

        if current ~= "" then
            local section = current:match("^(.-)%s*{%s*$")
            if section and not current:match("=") then
                for part in section:gmatch("%S+") do
                    stack[#stack + 1] = part
                end
            elseif current:match("^}%s*$") then
                stack[#stack] = nil
            else
                local key, value = current:match("^%$?([%w_%.%-]+)%s*=%s*(.-)%s*$")
                if key then
                    local prefix = #stack > 0 and (table.concat(stack, ".") .. ".") or ""
                    values[prefix .. key] = value
                end
            end
        end
    end

    return values
end

local colors = parse_conf(read_file(HOME .. "/.config/bitbeast/current.conf"))
local theme = parse_conf(read_file(HOME .. "/.config/hypr/bitbeast-theme.conf"))
local touchpad = parse_conf(read_file(HOME .. "/.config/hypr/touchpad.conf"))

local function expand(value)
    if value == nil then
        return nil
    end
    return (value:gsub("%$([%w_]+)", function(name)
        return colors[name] or ""
    end))
end

local function get(conf, key, default)
    local value = expand(conf[key])
    if value == nil or value == "" then
        return default
    end
    return value
end

local function number(conf, key, default)
    return tonumber(get(conf, key, default)) or default
end

local function boolean(conf, key, default)
    local value = get(conf, key, nil)
    if value == nil then
        return default
    end
    value = value:lower()
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

-- Convert the legacy `rgb(RRGGBB)` colors used by BitBeast into the
-- 0xAARRGGBB form understood by the new config parser.
local function color(value)
    if value == nil or value == "" then
        return nil
    end

    local hex = value:match("^rgb%(%s*(%x%x%x%x%x%x)%s*%)$")
    if hex then
        return "0xff" .. hex
    end

    if value:match("^%x%x%x%x%x%x$") then
        return "0xff" .. value
    end

    return value
end

-- Gradients are "color color [angle]" in the legacy config. Hyprland 0.57's
-- Lua parser wants either one color string or a table of colors + angle.
local function gradient(value)
    if value == nil then
        return nil
    end

    local stops = {}
    local angle = nil

    for token in value:gmatch("%S+") do
        local degrees = token:match("^(%-?%d+%.?%d*)deg$")
        if degrees then
            angle = tonumber(degrees)
        else
            local parsed = color(token)
            if parsed then
                stops[#stops + 1] = parsed
            end
        end
    end

    if #stops == 0 then
        return nil
    end

    if #stops == 1 and angle == nil then
        return stops[1]
    end

    return {
        colors = stops,
        angle = angle or 0,
    }
end

local bg = color(get(colors, "bg", "rgb(150608)"))
local primary = color(get(colors, "primary", "rgb(ff2d55)"))
local secondary = color(get(colors, "secondary", "rgb(2c0d0f)"))
local accent = color(get(colors, "accent", "rgb(ffd166)"))
local text = color(get(colors, "text", "rgb(fff1dd)"))

local border_size = number(theme, "general.border_size", 4)
local active_border = gradient(get(theme, "general.col.active_border", accent .. " " .. primary .. " 45deg"))
local inactive_border = gradient(get(theme, "general.col.inactive_border", secondary))
local rounding = number(theme, "decoration.rounding", 8)
local active_opacity = number(theme, "decoration.active_opacity", 0.97)
local inactive_opacity = number(theme, "decoration.inactive_opacity", 0.93)
local shadow_enabled = boolean(theme, "decoration.shadow.enabled", true)
local shadow_range = number(theme, "decoration.shadow.range", 22)
local shadow_power = number(theme, "decoration.shadow.render_power", 3)
local shadow_color = gradient(get(theme, "decoration.shadow.color", bg))
local group_active = gradient(get(theme, "group.col.border_active", accent))
local group_inactive = gradient(get(theme, "group.col.border_inactive", secondary))

---------------------------
---- PROGRAMS / THEME -----
---------------------------

local mod = "SUPER"
local terminal = "kitty"
local browser = "google-chrome-stable"
local menu = "rofi -show drun -config ~/.config/rofi/config.rasi"
local bitbeast = "~/.local/bin/bitbeast"
local lock = "~/.local/bin/bitbeast lock"

------------------
---- MONITORS ----
------------------

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

---------------
---- ENV -------
---------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprctl plugin load ~/.local/share/hyprland-plugins/Hyprspace.so")
    hl.exec_cmd(bitbeast .. " session-init")
    hl.exec_cmd("~/.local/bin/bitbeast-battery-watcher")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

----------------------
---- WORKSPACES ------
----------------------

for i = 1, 8 do
    hl.workspace_rule({
        workspace = tostring(i),
        persistent = true,
    })
end

------------------
---- INPUT -------
------------------

-- Hyprland 0.57 clamps sensitivity to [-1, 1]. Older BitBeast configs used
-- 2, which was already outside libinput's valid range.
local function clamp_sensitivity(value)
    value = tonumber(value) or 0
    if value > 1 then
        return 1
    elseif value < -1 then
        return -1
    end
    return value
end

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        natural_scroll = true,
        sensitivity = clamp_sensitivity(get(touchpad, "device.sensitivity", 0)),
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.device({
    name = get(touchpad, "device.name", "elan0001:00-04f3:31ad-touchpad"),
    sensitivity = clamp_sensitivity(get(touchpad, "device.sensitivity", 0)),
})

---------------------
---- LOOK & FEEL ----
---------------------

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        layout = "dwindle",
        allow_tearing = false,
        border_size = border_size,
        col = {
            active_border = active_border,
            inactive_border = inactive_border,
        },
    },

    decoration = {
        rounding = rounding,
        active_opacity = active_opacity,
        inactive_opacity = inactive_opacity,
        shadow = {
            enabled = shadow_enabled,
            range = shadow_range,
            render_power = shadow_power,
            color = shadow_color,
        },
    },

    group = {
        col = {
            border_active = group_active,
            border_inactive = group_inactive,
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    gestures = {
        workspace_swipe_distance = 400,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = false,
    },

    animations = {
        enabled = true,
    },
})

-- The old config set dwindle:preserve_split. That option no longer exists in
-- Hyprland 0.57's config registry, so it is intentionally not set here.

---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = { namespace = "waybar" },
    blur = false,
    ignore_alpha = 1,
})

hl.layer_rule({
    match = { namespace = "bitbeast-osd" },
    blur = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    match = { namespace = "bitbeast-cc" },
    blur = true,
    ignore_alpha = 0.2,
})

-------------------
---- ANIMATIONS ----
-------------------

hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 },
    },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

--------------------
---- GESTURES ------
--------------------

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.exec_cmd("hyprctl dispatch overview:toggle")
    end,
})

-------------------
---- KEYBINDS -----
-------------------

-- Terminal
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal .. [[ -e bash -c "fastfetch --config ~/.config/fastfetch/config.jsonc; exec $SHELL"]]))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal .. [[ --class="dropdown"]]))

-- Execution and launchers
hl.bind(mod .. " + r", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + b", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + e", hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + h", hl.dsp.exec_cmd(bitbeast .. " keybindings"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("~/.local/bin/bitbeast-control-center"))
hl.bind(mod .. " + g", hl.dsp.exec_cmd("hyprctl dispatch overview:toggle"))
hl.bind(mod .. " + SHIFT + g", hl.dsp.exec_cmd("~/.local/bin/bitbeast-workspace-picker"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " -e yazi"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd(bitbeast .. " pick"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(bitbeast .. " style cycle"))
hl.bind(mod .. " + SHIFT + r", hl.dsp.exec_cmd(bitbeast .. " gradient"))

-- Waybar style picker
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd(bitbeast .. " pick-style"))

-- Zsh theme
hl.bind(mod .. " + T", hl.dsp.exec_cmd(bitbeast .. " zsh cycle"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd(bitbeast .. " zsh pick"))

-- Touchpad sensitivity selector
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd(bitbeast .. " touchpad"))

-- Auto theme from wallpaper
hl.bind(mod .. " + CTRL + T", hl.dsp.exec_cmd(bitbeast .. " auto-theme"))

-- Window management
hl.bind(mod .. " + q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + q", hl.dsp.exit())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())

hl.bind(mod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mod .. " + m", hl.dsp.exec_cmd(bitbeast .. " battery-saver"))
hl.bind(mod .. " + CTRL + f", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + space", hl.dsp.window.float())
hl.bind(mod .. " + ALT + space", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(mod .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())

-- Desktop / workspace
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + L", hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd(bitbeast .. " session-init"))

-- Window focus (arrow keys)
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Move windows (vim keys)
hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

-- Move windows (arrow keys)
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Hold SUPER and drag an app with the mouse to move / resize it
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize windows
hl.bind(mod .. " + CTRL + h", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + l", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Workspaces
for i = 1, 8 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = tostring(i), follow = false }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end

hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
hl.bind(mod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special:special", follow = true }))
hl.bind(mod .. " + U", hl.dsp.workspace.toggle_special())

-- Scroll through existing workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.local/bin/bitbeast-osd brightness raise"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/bitbeast-osd brightness lower"), { repeating = true })

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/bitbeast-osd volume raise"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/bitbeast-osd volume lower"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.local/bin/bitbeast-osd volume mute"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- Media keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Screenshot
hl.bind(mod .. " + s", hl.dsp.exec_cmd([=[mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +'%Y-%m-%d-%H%M%S').png | wl-copy]=]))
hl.bind(mod .. " + SHIFT + s", hl.dsp.exec_cmd([=[mkdir -p ~/Pictures/Screenshots && grim - | tee ~/Pictures/Screenshots/$(date +'%Y-%m-%d-%H%M%S').png | wl-copy]=]))
hl.bind(mod .. " + v", hl.dsp.exec_cmd(bitbeast .. " clipboard"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("~/.local/bin/toggle-transparency"))

---------------------
---- WINDOW RULES ----
---------------------

-- Visualizer
hl.window_rule({
    match = { class = "^(bitbeast-visualizer)$" },
    float = true,
    pin = true,
    center = true,
    size = "800 350",
    border_size = 0,
})

-- Hints
hl.window_rule({
    match = { class = "^(bitbeast-hints)$" },
    float = true,
    pin = true,
    center = true,
    size = "1080 720",
    border_size = 0,
})
