local component = require("component")
local me = component.me_controller -- Access the ME system
local term = require("term")
local gpu = component.gpu
local running = true

-- Exit on Ctrl+C or other interruption
local function signalHandler(eventName)
	if eventName == "interrupted" then
		running = false
	end
end

-- Colored line of text
-- text, color, paletcolor (optional)
local function cWrite(text, fgc, pIndex)
	local old_fgc, isPalette = gpu.getForeground()
	pIndex = (type(pIndex) == "boolean") and pIndex or false
	gpu.setForeground(fgc, pIndex)
	print(text)
	gpu.setForeground(old_fgc, isPalette)
end

-- Checks and crafts item
local function checkAndCraft(itemLabel, threshold, craftAmount)
	local items = me.getItemsInNetwork({ label = itemLabel }) -- Get items in the ME system
	local count = items[1] and items[1].size or 0 -- Get the count of the item or 0 if none
	print(itemLabel .. " in system: " .. count)

	if count < threshold then
		--print("Requesting " .. craftAmount .. " " .. itemLabel)
		local craftables = me.getCraftables({ label = itemLabel }) -- Get craftable items
		if craftables[1] then
			local request = craftables[1].request(craftAmount)
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

-- Monitor and craft items
while running do
	-- Vanila Items
	checkAndCraft("Torch", 64, 10)
	-- ME Items
	checkAndCraft("Quartz Fiber", 64, 10)
	checkAndCraft("ME Glass Cable - Fluix", 64, 10)
	-- EnderIO Items
	checkAndCraft("Basic Universal Cable", 64, 10)
	checkAndCraft("Advanced Universal Cable", 64, 1)
	-- IndustrialCraft2 Items

	--checkAndCraft("Forge Hammer", 5, 1)       -- These seem to only detect the first item seen, and if different durability then it sees just 1
	--checkAndCraft("Cutter", 5, 1)            -- I think using a for loop and checking size of each item returned would fix this

	checkAndCraft("Copper Plate", 64, 16)
	checkAndCraft("Iron Plate", 64, 16)
	checkAndCraft("Copper Cable", 64, 16)
	checkAndCraft("Insulated Copper Cable", 64, 16)
	checkAndCraft("Electronic Circuit", 64, 16)
	clear()

	os.sleep(3) -- Check every 3 seconds
end
