local apps = {
	["1"] = "Ghostty",
	["2"] = "Safari",
	["3"] = "Obsidian",
	["4"] = "Messages",
	["5"] = "Mail",
	["6"] = "Reminders",
	["7"] = "Claude",
	["9"] = "Music",
}

for key, app in pairs(apps) do
	hs.hotkey.bind({ "alt" }, key, function()
		hs.application.launchOrFocus(app)
	end)
end
