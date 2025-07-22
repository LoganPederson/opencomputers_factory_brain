local component = require("component")
local me = component.me_controller -- Access the ME system
local term = require("term")
local running = true

-- color
local colorRed = 0xff2d00

--
-- Set screens
local screens = {}
for name, address in component.list("screen") do
	table.insert(screens, address)
end

if #screens >= 2 then
	Screen1 = component.proxy(screens[1])
	Screen2 = component.proxy(screens[2])
else
	do
		Screen1 = component.proxy(screens[1])
	end
end
-- set primary and secondary GPU and Bind to Screens
local gpus = {} --table to store GPU components
for address in component.list("gpu") do
	table.insert(gpus, address)
end
if #gpus >= 2 then
	Gpu1 = component.proxy(gpus[1])
	if Gpu1 and Screen1 then
		Gpu1.bind(Screen1)
	end
	Gpu2 = component.proxy(gpus[2])
	if Gpu2 and Screen2 then
		Gpu2.bind(Screen2)
	end
else
	do
		Gpu1 = component.proxy(gpus[1])
		Gpu1.bind(Screen1)
	end
end

-- Exit on Ctrl+C or other interruption
local function signalHandler(eventName)
	if eventName == "interrupted" then
		running = false
	end
end

-- Colored line of text
-- text, color, paletcolor (optional)
local function cWrite(text, fgc, pIndex, gpu)
	gpu = gpu or Gpu1 -- default to Gpu1 if gpu is nil
	local old_fgc, isPalette = Gpu1.getForeground()
	pIndex = (type(pIndex) == "boolean") and pIndex or false
	Gpu1.setForeground(fgc, pIndex)
	print(text)
	Gpu1.setForeground(old_fgc, isPalette)
end

-- Checks and crafts item
local function checkAndCraft(itemLabel, threshold, craftAmount)
	--TODO:output to a screen or remotely accessible place the items are missing
	cWrite("Testing Screen2!", colorRed, Gpu2)
	local items = me.getItemsInNetwork({ label = itemLabel }) -- Get items in the ME system
	local count = items[1] and items[1].size or 0 -- Get the count of the item or 0 if none
	print(itemLabel .. " in system: " .. count)

	if count < tonumber(threshold) then
		--print("Requesting " .. craftAmount .. " " .. itemLabel)
		local craftables = me.getCraftables({ label = itemLabel }) -- Get craftable items
		if craftables[1] then
			local request = craftables[1].request(tonumber(craftAmount))
			local isCanceled, errorMessage = request.isCanceled()
			if isCanceled or errorMessage == "request failed (missing resources?)" then
				--print("Crafting failed to start for " .. itemLabel)
				if errorMessage ~= nil then
					cWrite("Error Details: " .. errorMessage, 0xff2d00)
				end
			else
				--cWrite("Crafting started successfully for " .. itemLabel,0x0cff00)
				while not request.isDone() do
					-- print("Crafting in progress...")
					-- print("Checking Local CPU's")
					-- local craftingCPUs = me.getCpus()
					-- for _, cpu in ipairs(craftingCPUs) do
					--     print("CPU Name: " .. (cpu.name or "Unnamed"))
					--     print("Busy: " .. tostring(cpu.busy))
					os.sleep(2) -- Wait before checking again
				end
				cWrite("Crafting completed for " .. itemLabel, 0x0cff00)
			end
		else
			cWrite("No crafting recipe for " .. itemLabel, 0xff2d00)
		end
	else
		cWrite(itemLabel .. " stock is sufficient.", 0x845aa3)
	end

	print("\n")
end

-- Event listener for interruptions
require("event").listen("interrupted", signalHandler)

--  Array of items to autocraft
local itemsToCraftArray = {
	-- Vanila Items
	{ "Torch", 64, 10 },
	-- ME Items
	{ "Quartz Fiber", 64, 10 },
	{ "ME Glass Cable - Fluix", 64, 10 },
	-- EnderIO Items
	{ "Basic Universal Cable", 64, 10 },
	{ "Advanced Universal Cable", 64, 1 },
	-- IndustrialCraft2 Items
	--{"Forge Hammer", 5, 1}       -- These seem to only detect the first item seen, and if different durability then it sees just },
	--{"Cutter", 5, 1}            -- I think using a for loop and checking size of each item returned would fix thi},
	{ "Copper Plate", 64, 16 },
	{ "Iron Plate", 64, 16 },
	{ "Copper Cable", 64, 16 },
	{ "Insulated Copper Cable", 64, 16 },
	{ "Electronic Circuit", 64, 16 },
}

--- Monitor and craft items
while running do
	for _, _table in ipairs(itemsToCraftArray) do
		-- return if key pressed (I don't think this is working how I expect though)
		if running == false then
			return
		end

		checkAndCraft(_table[1], _table[2], _table[3])
	end
	os.sleep(1) -- every 1 second

	term.clear()
end
