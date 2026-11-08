-- Hyprland 0.57+ Lua config. Home Manager writes this to ~/.config/hypr/hyprland.lua.

-- Super, not Alt: games use Alt, and Alt+Q here would close the game.
local mod = "SUPER"

-- No connector name, so moving between HDMI and DisplayPort needs no change.
hl.monitor({
  output = "",
  mode = "3840x2160@239.99",
  position = "0x0",
  scale = 1.5,
})

hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NIXOS_OZONE_WL", "1")
-- force_zero_scaling leaves XWayland apps unscaled, and Steam is one.
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.5")

hl.config({
  -- Variable refresh for fullscreen games only.
  misc = { vrr = 2 },
  xwayland = { force_zero_scaling = true },
  cursor = { no_hardware_cursors = true },
})

-- Global rather than per-device: the mouse's name changes with how it is
-- connected (wired G502 vs. its Lightspeed receiver).
hl.config({ input = { sensitivity = -1.0, follow_mouse = 1 } })

-- fuzzel's layer namespace is "launcher"; fade instead of the default pop-in.
hl.layer_rule({ name = "launcher-fade", match = { namespace = "^launcher$" }, animation = "fade" })

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("ghostty")
end)

local function bind(keys, dispatcher, opts)
  hl.bind(mod .. " + " .. keys, dispatcher, opts)
end

bind("F", hl.dsp.exec_cmd("firefox"))
bind("RETURN", hl.dsp.exec_cmd("ghostty"))
bind("ALT + E", hl.dsp.exit())
bind("Q", hl.dsp.window.close())
bind("V", hl.dsp.layout("togglesplit"))
bind("Space", hl.dsp.exec_cmd("fuzzel"))
bind("A", hl.dsp.exec_cmd("~/.dotfiles/scripts/homepod toggle"))

local directions = { H = "left", L = "right", K = "up", J = "down" }
for key, direction in pairs(directions) do
  bind(key, hl.dsp.focus({ direction = direction }))
  bind("SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

bind("ALT + H", hl.dsp.window.resize({ x = -10, y = -10, relative = true }))
bind("ALT + L", hl.dsp.window.resize({ x = 10, y = -10, relative = true }))
bind("ALT + K", hl.dsp.window.resize({ x = 10, y = -10, relative = true }))
bind("ALT + J", hl.dsp.window.resize({ x = -10, y = -10, relative = true }))

-- Super+1..9,0 for workspaces 1..10.
for i = 1, 10 do
  local key = tostring(i % 10)
  bind(key, hl.dsp.focus({ workspace = i }))
  bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Volume follows the default output, including AirPlay speakers.
local volume_up = hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
local volume_down = hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
local mute = hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
local hold = { locked = true, repeating = true }

hl.bind("XF86AudioRaiseVolume", volume_up, hold)
hl.bind("XF86AudioLowerVolume", volume_down, hold)
bind("EQUAL", volume_up, hold)
bind("MINUS", volume_down, hold)
hl.bind("XF86AudioMute", mute, { locked = true })
bind("M", mute, { locked = true })
