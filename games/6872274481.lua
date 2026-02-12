local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('KKK', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/wrj80z/wrj80zSUP/'..readfile('ReVape/profiles/commit.txt')..'/'..select(1, path:gsub('ReVape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	local suc, err = pcall(func)

	if not suc then
		task.spawn(error, err)
	end
end
local Tun = function(func)
	task.spawn(function()
		func()
	end)
end

local cloneref = cloneref or function(obj)
	return obj
end

local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local canDebug = shared.CheatEngineMode
if canDebug == nil then
	canDebug = false
end
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))
local TeleportService = cloneref(game:GetService("TeleportService"))
local lightingService = cloneref(game:GetService("Lighting"))
local vim = cloneref(game:GetService("VirtualInputManager"))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))
local isnetworkowner = identifyexecutor and table.find({'Nihon','Volt','Wave'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end


local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local oldpred = loadstring(downloadFile('ReVape/libraries/oldpred.lua'), 'oldpred')()
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset
local hash = loadstring(downloadFile('ReVape/libraries/hash.lua'), 'hash')()
local role = 'owner'



local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {}
}
getgenv().store = store
local Reach = {}
local HitBoxes = {}
local InfiniteFly
local AntiFallPart
local Speed
local Fly
local Breaker
local Scaffold
local AutoTool
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('ReVape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function GetBestItemToBreakBlock(Type: string)
    local Inventory = GetInventory()
    local Data = {
        Item = nil,
        Damage = 0
    }

    if Inventory and Inventory.items then
        for i,v in Inventory.items do
            local Meta = GameData.Utils.ItemMeta[v.itemType]
            if Meta and Meta.breakBlock then
                for i2: string, v2: number in Meta.breakBlock do
                    if Type:lower():find(i2:lower()) and v2 > Data.Damage then
                        Data = {
                            Item = v.tool,
                            Damage = v2
                        }
                    end
                end

            end
        end
    end

    return Data
end

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getItem(itemName, inv)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local swordMeta = bedwars.ItemMeta[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end

local function getStrength(plr)
	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then
			strength = itemmeta.sword.damage
		end
	end

	return strength
end

local function getPlacedBlock(pos)
	if not pos then
		return
	end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, mag, closest = entitylib.character.RootPart.Position, 60
	local blocks = getBlocksInPoints(bedwars.BlockController:getBlockPosition(localPosition - range), bedwars.BlockController:getBlockPosition(localPosition + range))

	for _, v in blocks do
		if not getPlacedBlock(v + Vector3.new(0, 3, 0)) then
			local newmag = (localPosition - v).Magnitude
			if newmag < mag then
				mag, closest = newmag, v + Vector3.new(0, 3, 0)
			end
		end
	end

	table.clear(blocks)
	return closest
end

local function getShieldAttribute(char)
	local returned = 0
	for name, val in char:GetAttributes() do
		if name:find('Shield') and type(val) == 'number' and val > 0 then
			returned += val
		end
	end
	return returned
end

local function getSpeed()
	local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

	for v in modifiers do
		local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
		if val and val > math.max(multi, 1) then
			increase = false
			multi = val - (0.06 * math.round(val))
		end
	end

	for v in modifiers do
		multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
	end

	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end

	return 20 * (multi + 1)
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end

local pos = {}
vape:Clean(function()
	workspace.ItemDrops.ChildAdded:Connect(function(obj)
		if obj then
			table.insert(pos,obj.Position)
		end
	end)
	workspace.ItemDrop.ChildRemoved:Connect(function(obj)
		table.remove(pos,obj.Position)
	end)
end)

local function GetNearGen(legit, origin)

	local MaxStuds = legit and 10 or 23
	local closest, dist
	for _, pos in ipairs(pos) do
		if pos ~= currentbedpos then
			local d = (pos - origin).Magnitude
			if d <= MaxStuds then
				if not dist or d < dist then
					dist = d
					closest = pos
				end
			end
		end
	end

	return closest
end

local function hotbarSwitch(slot)
	if slot and store.inventory.hotbarSlot ~= slot then
		bedwars.Store:dispatch({
			type = 'InventorySelectHotbarSlot',
			slot = slot
		})
		vapeEvents.InventoryChanged.Event:Wait()
		return true
	end
	return false
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...) return
	vape:CreateNotification(...)
end
local function notify(...) return
	vape:CreateNotification(...)
end
local function notifys(...) return
	vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function roundPos(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end

local function switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	local check = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') or nil
	if check and check.Value ~= tool and tool.Parent ~= nil then
		task.spawn(function()
			bedwars.Client:Get(remotes.EquipItem):CallServerAsync({hand = tool})
		end)
		check.Value = tool
		if delayTime > 0 then
			task.wait(delayTime)
		end
		return true
	end
end

local function getSwordSlot()
	for i, v in store.inventory.hotbar do
		if v.item and bedwars.ItemMeta[v.item.itemType] then
			local meta = bedwars.ItemMeta[v.item.itemType]
			if meta.sword then
				return i - 1
			end
		end
	end
	return nil
end

local function getObjSlot(nme)
	local Obj = {}
	for i, v in store.inventory.hotbar do
		if v.item and v.item.itemType then
			if v.item.itemType == nme then
				return i - 1
			end
		end
	end
	return nil
end

local function getPickaxeSlot()
    for i, v in store.inventory.hotbar do
        if v.item and bedwars.ItemMeta[v.item.itemType] then
            local meta = bedwars.ItemMeta[v.item.itemType]
            if meta.breakBlock then
                return i - 1
            end
        end
    end
    return nil
end

local function GetOriginalSlot()
	return store.inventory.hotbarSlot 
end

local function currentitem(type)
	if type == "tool" then
		return store.hand.tool
	elseif type == "tt" then
		return store.hand.toolType
	elseif type == "amount" then
		return store.hand.amount
	else
		return nil
	end
end
getgenv().current = currentitem

local function switchItemV2(tool, delayTime)
	delayTime = delayTime or 0.05
	delayTime = (delayTime == 0 and 0.05 or delayTime)
	if tool ~= nil and typeof(tool) == "string" then
		tool = getItem(tool) and getItem(tool).tool
	end
	task.delay(delayTime,function()
		bedwars.Client:Get('SetInvItem'):CallServer({hand = tool})
	end)
end


local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait(0.1)
	until false
	return returned
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local function isEveryoneDead()
	return #bedwars.Store:getState().Party.members <= 0
end
	
local function joinQueue()
	if not bedwars.Store:getState().Game.customMatch and bedwars.Store:getState().Party.leader.userId == lplr.UserId and bedwars.Store:getState().Party.queueState == 0 then
		bedwars.QueueController:joinQueue(store.queueType)
	end
end

local function lobby()
	game.ReplicatedStorage.rbxts_include.node_modules['@rbxts'].net.out._NetManaged.TeleportToLobby:FireServer()
end

local kitorder = {
	hannah = 5,
	spirit_assassin = 4,
	dasher = 3,
	jade = 2,
	regent = 1
}

local sortmethods = {
	Damage = function(a, b)
		return a.Entity.Character:GetAttribute('LastDamageTakenTime') < b.Entity.Character:GetAttribute('LastDamageTakenTime')
	end,
	Threat = function(a, b)
		return getStrength(a.Entity) > getStrength(b.Entity)
	end,
	Kit = function(a, b)
		return (a.Entity.Player and kitorder[a.Entity.Player:GetAttribute('PlayingAsKits')] or 0) > (b.Entity.Player and kitorder[b.Entity.Player:GetAttribute('PlayingAsKits')] or 0)
	end,
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local angle = math.acos(localfacing:Dot(((a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		local angle2 = math.acos(localfacing:Dot(((b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		return angle < angle2
	end
}
if canDebug then
	vape:CreateNotification("Onyx",`Your current executor {({identifyexecutor()})[1]} and has successfully loaded in Cheat Engine mode. some modules may be missing.`,12,"warning")
end

run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		if ent:HasTag('inventory-entity') and not ent:HasTag('Monster') and not string.find(ent.Name, 'Dummy') then
			return
		end
		entitylib.addEntity(ent, nil, ent:HasTag('Drone') and function(self)
			local droneplr = playersService:GetPlayerByUserId(self.Character:GetAttribute('PlayerUserId'))
			return not droneplr or lplr:GetAttribute('Team') ~= droneplr:GetAttribute('Team')
		end or function(self)
			return lplr:GetAttribute('Team') ~= self.Character:GetAttribute('Team')
		end)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('entity') do
				customEntity(ent)
			end
			for _, ent in collectionService:GetTagged('trainingRoomDummy') do
				customEntity(ent)
			end			
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('entity'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('entity'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('trainingRoomDummy'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('trainingRoomDummy'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))			
		end
	end

	entitylib.addPlayer = function(plr)
		if plr.Character then
			entitylib.refreshEntity(plr.Character, plr)
		end
		entitylib.PlayerConnections[plr] = {
			plr.CharacterAdded:Connect(function(char)
				entitylib.refreshEntity(char, plr)
			end),
			plr.CharacterRemoving:Connect(function(char)
				entitylib.removeEntity(char, plr == lplr)
			end),
			plr:GetAttributeChangedSignal('Team'):Connect(function()
				for _, v in entitylib.List do
					if v.Targetable ~= entitylib.targetCheck(v) then
						entitylib.refreshEntity(v.Character, v.Player)
					end
				end

				if plr == lplr then
					entitylib.start()
				else
					entitylib.refreshEntity(plr.Character, plr)
				end
			end)
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum, humrootpart, head
			if plr then
				hum = waitForChildOfType(char, 'Humanoid', 10)
				humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
				head = char:WaitForChild('Head', 10) or humrootpart
			else
				hum = {HipHeight = 0.5}
				humrootpart = waitForChildOfType(char, 'PrimaryPart', 10, true)
				head = humrootpart
			end
			local updateobjects = plr and plr ~= lplr and {
				char:WaitForChild('ArmorInvItem_0', 5),
				char:WaitForChild('ArmorInvItem_1', 5),
				char:WaitForChild('ArmorInvItem_2', 5),
				char:WaitForChild('HandInvItem', 5)
			} or {}

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					Jumps = 0,
					JumpTick = tick(),
					Jumping = false,
					LandTick = tick(),
					MaxHealth = char:GetAttribute('MaxHealth') or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
					table.insert(entitylib.Connections, char.AttributeChanged:Connect(function(attr)
						vapeEvents.AttributeChanged:Fire(attr)
					end))
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char)
							entity.MaxHealth = char:GetAttribute('MaxHealth') or 100
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					for _, v in updateobjects do
						table.insert(entity.Connections, v:GetPropertyChangedSignal('Value'):Connect(function()
							task.delay(0.1, function()
								if bedwars.getInventory then
									store.inventories[plr] = bedwars.getInventory(plr)
									entitylib.Events.EntityUpdated:Fire(entity)
								end
							end)
						end))
					end

					if plr then
						local anim = char:FindFirstChild('Animate')
						if anim then
							pcall(function()
								anim = anim.jump:FindFirstChildWhichIsA('Animation').AnimationId
								table.insert(entity.Connections, hum.Animator.AnimationPlayed:Connect(function(playedanim)
									if playedanim.Animation.AnimationId == anim then
										entity.JumpTick = tick()
										entity.Jumps += 1
										entity.LandTick = tick() + 1
										entity.Jumping = entity.Jumps > 1
									end
								end))
							end)
						end

						task.delay(0.1, function()
							if bedwars.getInventory then
								store.inventories[plr] = bedwars.getInventory(plr)
							end
						end)
					end
					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end

				table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
					if part == humrootpart or part == hum or part == head then
						if part == humrootpart and hum.RootPart then
							humrootpart = hum.RootPart
							entity.RootPart = hum.RootPart
							entity.HumanoidRootPart = hum.RootPart
							return
						end
						entitylib.removeEntity(char, plr == lplr)
					end
				end))
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local char = ent.Character
		local tab = {
			char:GetAttributeChangedSignal('Health'),
			char:GetAttributeChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}

		if ent.Player then
			table.insert(tab, ent.Player:GetAttributeChangedSignal('PlayingAsKits'))
		end

		for name, val in char:GetAttributes() do
			if name:find('Shield') and type(val) == 'number' then
				table.insert(tab, char:GetAttributeChangedSignal(name))
			end
		end

		return tab
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return lplr:GetAttribute('Team') ~= ent.Player:GetAttribute('Team')
	end
	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()
local function safeGetProto(func, index)
    if not func then return nil end
    local success, proto = pcall(safeGetProto, func, index)
    if success then
        return proto
    else
		if not getgenv().Closet then
       		--warn("function:", func, "index:", index,", WM - proto") 
		end
        return nil
    end
end


run(function()
	
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit then break end
		task.wait(0.1)
	until KnitInit

	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait(0.1) until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local OldGet, OldBreak = Client.Get
	if Client == nil or Knit == nil then
		vape:CreateNotification("Bedwars Client was not founded, bedwars has probably updated their knit system please report to "..vape.Discord.."!!",120,'alert')
		return
	end
	bedwars = setmetatable({
        BalanceFile = require(replicatedStorage.TS.balance["balance-file"]).BalanceFile,
        ClientSyncEvents = require(lplr.PlayerScripts.TS['client-sync-events']).ClientSyncEvents,
        SyncEventPriority = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['sync-event'].out),
		AbilityId = require(replicatedStorage.TS.ability['ability-id']).AbilityId,
        IdUtil = require(replicatedStorage.TS.util['id-util']).IdUtil,
		BlockSelector = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelector,
		KnockbackUtilInstance = replicatedStorage.TS.damage['knockback-util'],
		BedwarsKitSkin = require(replicatedStorage.TS.games.bedwars['kit-skin']['bedwars-kit-skin-meta']).BedwarsKitSkinMeta,
		KitController = Knit.Controllers.KitController,
		FishermanUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fisherman-util']).FishermanUtil,
		FishMeta = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fish-meta']),
	 	MatchHistroyApp = require(lplr.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
	 	MatchHistroyController = Knit.Controllers.MatchHistoryController,
		BlockEngine = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out).BlockEngine,
		BlockSelectorMode = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelectorMode,
		EntityUtil = require(game:GetService("ReplicatedStorage").TS.entity["entity-util"]).EntityUtil,
		GamePlayer = require(replicatedStorage.TS.player['game-player']),
		OfflinePlayerUtil = require(replicatedStorage.TS.player['offline-player-util']),
		PlayerUtil = require(replicatedStorage.TS.player['player-util']),
		KKKnitController = require(lplr.PlayerScripts.TS.lib.knit['knit-controller']),
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
		BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
		BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
		BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8),
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
		CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
		SharedConstants = require(replicatedStorage.TS['shared-constants']),
		DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		NotificationController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/notification-controller@NotificationController'),
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		MatchHistoryController = require(lplr.PlayerScripts.TS.controllers.global['match-history']['match-history-controller']),
		PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
		KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
		Knit = Knit,
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		NametagController = Knit.Controllers.NametagController,
		PartyController = Flamework.resolveDependency("@easy-games/lobby:client/controllers/party-controller@PartyController"),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.shared.sound['sound-manager']).SoundManager,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 6),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network),
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	getgenv().BWStore = bedwars.Store:getState()

	local remoteNames = {
		AfkStatus = safeGetProto(Knit.Controllers.AfkController.KnitStart, 1),
		AttackEntity = Knit.Controllers.SwordController.sendServerRequest,
		BeePickup = Knit.Controllers.BeeNetController.trigger,
		CannonAim = safeGetProto(Knit.Controllers.CannonController.startAiming, 5),
		CannonLaunch = Knit.Controllers.CannonHandController.launchSelf,
		ConsumeBattery = safeGetProto(Knit.Controllers.BatteryController.onKitLocalActivated, 1),
		ConsumeItem = safeGetProto(Knit.Controllers.ConsumeController.onEnable, 1),
		ConsumeSoul = Knit.Controllers.GrimReaperController.consumeSoul,
		ConsumeTreeOrb = safeGetProto(Knit.Controllers.EldertreeController.createTreeOrbInteraction, 1),
		DepositPinata = safeGetProto(Knit.Controllers.PiggyBankController.KnitStart, 5),
		DragonBreath = safeGetProto(Knit.Controllers.VoidDragonController.onKitLocalActivated, 5),
		DragonEndFly = safeGetProto(Knit.Controllers.VoidDragonController.flapWings, 1),
		DragonFly = Knit.Controllers.VoidDragonController.flapWings,
		DropItem = Knit.Controllers.ItemDropController.dropItemInHand,
		FireProjectile = debug.getupvalue(Knit.Controllers.ProjectileController.launchProjectileWithValues, 2),
		GroundHit = Knit.Controllers.FallDamageController.KnitStart,
		GuitarHeal = Knit.Controllers.GuitarController.performHeal,
		HannahKill = safeGetProto(Knit.Controllers.HannahController.registerExecuteInteractions, 1),
		HarvestCrop = safeGetProto(safeGetProto(Knit.Controllers.CropController.KnitStart, 4), 1),
		KaliyahPunch = safeGetProto(Knit.Controllers.DragonSlayerController.onKitLocalActivated, 1),
		MageSelect = safeGetProto(Knit.Controllers.MageController.registerTomeInteraction, 1),
		MinerDig = safeGetProto(Knit.Controllers.MinerController.setupMinerPrompts, 1),
		PickupItem = Knit.Controllers.ItemDropController.checkForPickup,
		PickupMetal = safeGetProto(Knit.Controllers.HiddenMetalController.onKitLocalActivated, 4),
		ReportPlayer = require(lplr.PlayerScripts.TS.controllers.global.report['report-controller']).default.reportPlayer,
		ResetCharacter = safeGetProto(Knit.Controllers.ResetController.createBindable, 1),
		SpawnRaven = safeGetProto(Knit.Controllers.RavenController.KnitStart, 1),
		SummonerClawAttack = Knit.Controllers.SummonerClawHandController.attack,
		WarlockTarget = safeGetProto(Knit.Controllers.WarlockStaffController.KnitStart, 2),
		EquipItem = safeGetProto(require(replicatedStorage.TS.entity.entities['inventory-entity']).InventoryEntity.equipItem, 3),

	}
	local function dumpRemote(tab)
		local ind
		for i, v in tab do
			if v == 'Client' then
				ind = i
				break
			end
		end
		return ind and tab[ind + 1] or ''
	end

	for i, v in remoteNames do
		local remote = dumpRemote(debug.getconstants(v))
		if remote == '' then
			notif('Onyx', 'Failed to grab remote ('..i..')', 10, 'alert')
		end
		remotes[i] = remote
	end

	OldBreak = bedwars.BlockController.isBlockBreakable

	Client.Get = function(self, remoteName)
		local call = OldGet(self, remoteName)
		if remoteName == remotes.AttackEntity then
			return {
				instance = call.instance,
				SendToServer = function(_, attackTable, ...)
					local suc, plr = pcall(function()
						return playersService:GetPlayerFromCharacter(attackTable.entityInstance)
					end)

					local selfpos = attackTable.validate.selfPosition.value
					local targetpos = attackTable.validate.targetPosition.value
					store.attackReach = ((selfpos - targetpos).Magnitude * 100) // 1 / 100
					store.attackReachUpdate = tick() + 1

					if Reach.Enabled or HitBoxes.Enabled then
						attackTable.validate.raycast = attackTable.validate.raycast or {}
						attackTable.validate.selfPosition.value += CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - 14.399, 0)
					end

					if suc and plr then
						if not select(2, whitelist:get(plr)) then return end
					end

					return call:SendToServer(attackTable, ...)
				end
			}
		end

		return call
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)

		if obj and obj.Name == 'bed' then
			for _, plr in playersService:GetPlayers() do
				if obj:GetAttribute('Team'..(plr:GetAttribute('Team') or 0)..'NoBreak') and not select(2, whitelist:get(plr)) then
					return false
				end
			end
		end

		return OldBreak(self, breakTable, plr)
	end

	local cache, blockhealthbar = {}, {blockHealth = -1, breakingBlockPosition = Vector3.zero}
	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'wool_white')

	local function getBlockHealth(block, blockpos)
		local blockdata = bedwars.BlockController:getStore():getBlockData(blockpos)
		return (blockdata and (blockdata:GetAttribute('1') or blockdata:GetAttribute('Health')) or block:GetAttribute('Health'))
	end

	local function getBlockHits(block, blockpos)
		if not block then return 0 end
		local breaktype = bedwars.ItemMeta[block.Name].block.breakType
		local tool = store.tools[breaktype]
		tool = tool and bedwars.ItemMeta[tool.itemType].breakBlock[breaktype] or 2
		return getBlockHealth(block, bedwars.BlockController:getBlockPosition(blockpos)) / tool
	end

	local function calculatePath(target, blockpos)
		if cache[blockpos] then
			return unpack(cache[blockpos])
		end
		local visited, unvisited, distances, air, path = {}, {{0, blockpos}}, {[blockpos] = 0}, {}, {}

		for _ = 1, 10000 do
			local _, node = next(unvisited)
			if not node then break end
			table.remove(unvisited, 1)
			visited[node[2]] = true

			for _, side in sides do
				side = node[2] + side
				if visited[side] then continue end

				local block = getPlacedBlock(side)
				if not block or block:GetAttribute('NoBreak') or block == target then
					if not block then
						air[node[2]] = true
					end
					continue
				end

				local curdist = getBlockHits(block, side) + node[1]
				if curdist < (distances[side] or math.huge) then
					table.insert(unvisited, {curdist, side})
					distances[side] = curdist
					path[side] = node[2]
				end
			end
		end

		local pos, cost = nil, math.huge
		for node in air do
			if distances[node] < cost then
				pos, cost = node, distances[node]
			end
		end

		if pos then
			cache[blockpos] = {
				pos,
				cost,
				path
			}
			return pos, cost, path
		end
	end

	bedwars.placeBlock = function(pos, item)
		if getItem(item) then
			store.blockPlacer.blockType = item
			return store.blockPlacer:placeBlock(bedwars.BlockController:getBlockPosition(pos))
		end
	end
	local CD = true
	bedwars.breakBlock = function(block, effects, anim, customHealthbar, autotool, wallcheck, nobreak)
		if lplr:GetAttribute('DenyBlockBreak') or not entitylib.isAlive then return end
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local cost, pos, target, path = math.huge
		local mag = 9e9

		local positions = (handler and handler:getContainedPositions(block) or {block.Position / 3})

		if not CD then
			pos = positions[2] or positions[1]
			target = positions[2]
			path = {}
			if positions[2] then
				path[positions[2]] = positions[2] - Vector3.new(0, 3, 0)
			end

			path[positions[1]] = positions[1] - Vector3.new(0, 3, 0)
		else
			for _, v in positions do
				local dpos, dcost, dpath = calculatePath(block, v * 3)
				local dmag = dpos and (entitylib.character.RootPart.Position - dpos).Magnitude
				if dpos and dcost < cost and dmag < mag then
					cost, pos, target, path, mag = dcost, dpos, v * 3, dpath, dmag
				end
			end
		end

		if pos then
			if (entitylib.character.RootPart.Position - pos).Magnitude > 30 then return end
			local dblock, dpos = getPlacedBlock(pos)
			if not dblock then return end

			if not nobreak and (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.2 then
				local breaktype = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				if tool then
					if autotool then
						for i, v in store.inventory.hotbar do
							if v.item and v.item.tool == tool.tool and i ~= (store.inventory.hotbarSlot + 1) then 
								hotbarSwitch(i - 1)
								break
							end
						end
					else
						switchItem(tool.tool)
					end
				end
			end

			if blockhealthbar.blockHealth == -1 or dpos ~= blockhealthbar.breakingBlockPosition then
				blockhealthbar.blockHealth = getBlockHealth(dblock, dpos)
				blockhealthbar.breakingBlockPosition = dpos
			end

			if not nobreak then
				bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
					blockRef = {blockPosition = dpos},
					hitPosition = pos,
					hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
				}):andThen(function(result)
					if result then
						if result == 'cancelled' then
							store.damageBlockFail = os.clock() + 1
							table.clear(cache)
							return
						end

						if effects then
							local blockdmg = (blockhealthbar.blockHealth - (result == 'destroyed' and 0 or getBlockHealth(dblock, dpos)))
							customHealthbar = customHealthbar or bedwars.BlockBreaker.updateHealthbar
							customHealthbar(bedwars.BlockBreaker, {blockPosition = dpos}, blockhealthbar.blockHealth, dblock:GetAttribute('MaxHealth'), blockdmg, dblock)
							blockhealthbar.blockHealth = math.max(blockhealthbar.blockHealth - blockdmg, 0)

							pcall(function()
								if blockhealthbar.blockHealth <= 0 then
									bedwars.BlockBreaker.breakEffect:playBreak(dblock.Name, dpos, lplr)
									bedwars.BlockBreaker.healthbarMaid:DoCleaning()
									blockhealthbar.breakingBlockPosition = Vector3.zero
								else
									bedwars.BlockBreaker.breakEffect:playHit(dblock.Name, dpos, lplr)
								end
							end)
						end

						if anim then
							local animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
							bedwars.ViewmodelController:playAnimation(15)
							task.wait(0.3)
							animation:Stop()
							animation:Destroy()
						end
					end
				end)
			end

			if effects then
				return pos, path, target
			end
		end

		return
	end

	for _, v in Enum.NormalId:GetEnumItems() do
		table.insert(sides, Vector3.FromNormalId(v) * 3)
	end
	local function updateStore(new, old)
		if new.Bedwars ~= old.Bedwars then
			store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
		end

		if new.Game ~= old.Game then
			store.matchState = new.Game.matchState
			store.queueType = new.Game.queueType or 'bedwars_test'
		end

		if new.Inventory ~= old.Inventory then
			local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
			local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
			store.inventory = newinv

			if newinv ~= oldinv then
				vapeEvents.InventoryChanged:Fire()
			end

			if newinv.inventory.items ~= oldinv.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
				store.tools.sword = getSword()
				for _, v in {'stone', 'wood', 'wool'} do
					store.tools[v] = getTool(v)
				end
			end

			if newinv.inventory.hand ~= oldinv.inventory.hand then
				local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
				if currentHand then
					local handData = bedwars.ItemMeta[currentHand.itemType]
					toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
				end

				store.hand = {
					tool = currentHand and currentHand.tool,
					amount = currentHand and currentHand.amount or 0,
					toolType = toolType
				}
			end
		end
	end


	local storeChanged = bedwars.Store.changed:connect(updateStore)
	updateStore(bedwars.Store:getState(), {})



	for _, event in {'MatchEndEvent', 'EntityDeathEvent', 'BedwarsBedBreak', 'BalloonPopped', 'AngelProgress', 'GrapplingHookFunctions'} do
		if not vape.Connections then return end
		bedwars.Client:WaitFor(event):andThen(function(connection)
			vape:Clean(connection:Connect(function(...)
				vapeEvents[event]:Fire(...)
			end))
		end)
	end

	vape:Clean(bedwars.ZapNetworking.EntityDamageEventZap.On(function(...)
		vapeEvents.EntityDamageEvent:Fire({
			entityInstance = ...,
			damage = select(2, ...),
			damageType = select(3, ...),
			fromPosition = select(4, ...),
			fromEntity = select(5, ...),
			knockbackMultiplier = select(6, ...),
			knockbackId = select(7, ...),
			disableDamageHighlight = select(13, ...)
		})
	end))


	for _, event in {'PlaceBlockEvent', 'BreakBlockEvent'} do
		vape:Clean(bedwars.ZapNetworking[event..'Zap'].On(function(...)
			local data = {
				blockRef = {
					blockPosition = ...,
				},
				player = select(5, ...)
			}
			for i, v in cache do
				if ((data.blockRef.blockPosition * 3) - v[1]).Magnitude <= 30 then
					table.clear(v[3])
					table.clear(v)
					cache[i] = nil
				end
			end
			vapeEvents[event]:Fire(data)
		end))
	end

	store.blocks = collection('block', gui)
	store.shop = collection({'BedwarsItemShop', 'TeamUpgradeShopkeeper'}, gui, function(tab, obj)
		table.insert(tab, {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag('BedwarsItemShop'),
			Upgrades = obj:HasTag('TeamUpgradeShopkeeper')
		})
	end)
	store.enchant = collection({'enchant-table', 'broken-enchant-table'}, gui, nil, function(tab, obj, tag)
		if obj:HasTag('enchant-table') and tag == 'broken-enchant-table' then return end
		obj = table.find(tab, obj)
		if obj then
			table.remove(tab, obj)
		end
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	task.spawn(function()
		pcall(function()
			repeat task.wait(0.1) until store.matchState ~= 0 or vape.Loaded == nil
			if vape.Loaded == nil then return end
			mapname = workspace:WaitForChild('Map', 5):WaitForChild('Worlds', 5):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, '_')[2] or mapname, '-', '') or 'Blank'
		end)
	end)

	vape:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
		if bedTable.player and bedTable.player.UserId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winTable)
		if (bedwars.Store:getState().Game.myTeam or {}).id == winTable.winningTeamId or lplr.Neutral then
			wins:Increment()
		end
	end))

	vape:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
		local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
		local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
		if not killed or not killer then return end

		if killed ~= lplr and killer == lplr then
			kills:Increment()
		end
	end))

	task.spawn(function()
		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end
			end
			task.wait(0.1)
		until vape.Loaded == nil
	end)

	pcall(function()
		if getthreadidentity and setthreadidentity then
			local old = getthreadidentity()
			setthreadidentity(2)

			bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
			bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
			bedwars.Shop.getShopItem('iron_sword', lplr)

			setthreadidentity(old)
			store.shopLoaded = true
		else
			task.spawn(function()
				repeat
					task.wait(0.1)
				until vape.Loaded == nil or bedwars.AppController:isAppOpen('BedwarsItemShopApp')

				bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
				bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
				store.shopLoaded = true
			end)
		end
	end)

	vape:Clean(function()
		Client.Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
		for _, v in vapeEvents do
			v:Destroy()
		end
		for _, v in cache do
			table.clear(v[3])
			table.clear(v)
		end
		table.clear(store.blockPlacer)
		table.clear(vapeEvents)
		table.clear(bedwars)
		table.clear(store)
		table.clear(cache)
		table.clear(sides)
		table.clear(remotes)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)	




local PR = {}
function PR:InvokeServer(tool,meta,pos,dir,CLP)
	CLP = CLP or false
			

	if tool and meta and pos and dir then
		local ID1 = bedwars.IdUtil.generateId(8)
		local ID2 = 'XXXXXXXX'
		if not meta.gravitationalAcceleration then 
			return nil
		end
		local hasArrow = meta.arrow or false
		if hasArrow then
			local arrowName = meta.projectileModel or 'arrow'
			local newpos2 = Vector3.new(pos.X,(pos.Y-2),pos.Z)
            local PF = bedwars.Client:WaitFor("ProjectileFire")
            local function cb(event)
				ID2 = bedwars.IdUtil.generateId(8)
				if CLP then
					bedwars.ProjectileController:createLocalProjectile(meta, tool, arrowName, pos, ID1, dir, {drawDurationSeconds = meta.drawDurationSeconds})
               		event:CallServerAsync(tool,arrowName,tostring(meta),pos,newpos2,ID2,{shotId=ID1,drawDurationSec=meta.drawDurationSeconds},workspace:GetServerTimeNow() - 0.045)
				else
                	event:CallServerAsync(tool,arrowName,tostring(meta),pos,newpos2,ID2,{shotId=ID1,drawDurationSec=meta.drawDurationSeconds},workspace:GetServerTimeNow() - 0.045)
				end
            end
            local await = bedwars.RuntimeLib.await(PF:andThen(cb))
            if await and await.PrimaryPart then
                return await
            else
                return nil
            end
		else
			local newpos2 = Vector3.new(pos.X,(pos.Y-2),pos.Z)
            local PF = bedwars.Client:WaitFor("ProjectileFire")
            local function cb(event)
				ID2 = bedwars.IdUtil.generateId(8)
				if CLP then
					bedwars.ProjectileController:createLocalProjectile(meta, tool, tool, pos, ID1, dir, {drawDurationSeconds = meta.drawDurationSeconds})
					event:CallServerAsync(tool,tostring(meta),pos,newpos2,ID2,{shotId=ID1,drawDurationSec=meta.drawDurationSeconds},workspace:GetServerTimeNow() - 0.045)
				else
                	event:CallServerAsync(tool,tostring(meta),pos,newpos2,ID2,{shotId=ID1,drawDurationSec=meta.drawDurationSeconds},workspace:GetServerTimeNow() - 0.045)
				end
            end
            local await = bedwars.RuntimeLib.await(PF:andThen(cb))
            if await and await.PrimaryPart then
                return await
            else
                return nil
            end
		end
	else
		return nil
	end
end




local KaidaController = {}
function KaidaController:request(target)
	if target then 
		return bedwars.Client:Get("SummonerClawAttackRequest"):SendToServer({
			["position"] = target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart").Position,
			["direction"] = (target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart").Position - lplr.Character.HumanoidRootPart.Position).unit, 
			["clientTime"] = workspace:GetServerTimeNow(), 
		})
	else return nil end
end

function KaidaController:requestBetter(v1,v2)
	if target then 
		return bedwars.Client:Get("SummonerClawAttackRequest"):SendToServer({
			["position"] = v1,
			["direction"] = v2, 
			["clientTime"] = workspace:GetServerTimeNow(), 
		})
	else return nil end
end

local WhisperController = {}
function WhisperController:request(type)
	if type == "Heal" then
		if bedwars.AbilityController:canUseAbility('OWL_HEAL') then
			bedwars.AbilityController:useAbility('OWL_HEAL')
		end
	elseif type == "Fly" then
		if bedwars.AbilityController:canUseAbility('OWL_LIFT') then
			bedwars.AbilityController:useAbility('OWL_LIFT')
		end
	end
end
local NazarController = {}
function NazarController:request(type)
	if type == "enabled" then
		if bedwars.AbilityController:canUseAbility('enable_life_force_attack') then
			bedwars.AbilityController:useAbility('enable_life_force_attack')
		end
	elseif type == "disabled" then
		if bedwars.AbilityController:canUseAbility('enable_life_force_attack') then
			bedwars.AbilityController:useAbility('disable_life_force_attack')
		end
	elseif type == "heal" then
		if bedwars.AbilityController:canUseAbility('consume_life_force') then
			bedwars.AbilityController:useAbility('consume_life_force')
		end
	end
end
for _, v in {'AntiRagdoll', 'TriggerBot', 'AutoRejoin', 'Rejoin', 'Disabler', 'Timer', 'ServerHop', 'MouseTP', 'MurderMystery','SilentAim','GetUnc','GetExecutor'} do
	vape:Remove(v)
end


run(function()
	local AimAssist
	local Limits
	local GUI
	local TweenStyles
	local Smoothness
	local Option
	local Priorty
	local MaxTargets
	local Targets
	local Shake
	local ShakeV
	local Sort
	local AimSpeed
	local Distance
	local AngleSlider
	local StrafeIncrease
	local KillauraTarget
	local ClickAim
	local priorityTarget = nil
	local shakeTime = 0
	local hasMouseMove = typeof(mousemoverel) == "function"
	local TweenOption
    local function isFirstPerson()
        return (gameCamera.Focus.Position - gameCamera.CFrame.Position).Magnitude < 1
    end

    local function optionAllowsAim()
        local opt = Option.Value
        if opt == "Both" then
            return true
        elseif opt == "First Person Only" then
            return isFirstPerson()
        elseif opt == "Third Person Only" then
            return not isFirstPerson()
        elseif opt == "Mouse" then
            return true
        end
        return true
    end

    local function aimWithMouse(targetPos, dt)
        if not hasMouseMove then return false end
        local screenPos, onScreen = gameCamera:WorldToViewportPoint(targetPos)
        if not onScreen then return true end
        local center = gameCamera.ViewportSize / 2
        local dx = (screenPos.X - center.X) * AimSpeed.Value * dt
        local dy = (screenPos.Y - center.Y) * AimSpeed.Value * dt
        mousemoverel(dx, dy)
        return true
    end

	local Easing = {}
    Easing.Linear = function(t) return t + 0.5 end
    Easing.Elastic = function(t) return math.sin(t * math.pi * (0.2 + 2.5 * t^3)) * (1 - t) + t end
    Easing.Sine = function(t) return 1 - math.cos(t * math.pi / 2) end
    Easing.Quad = function(t) return t^2 end
    Easing.Cubic = function(t) return t^3 end
    Easing.Quart = function(t) return t^4 end
    Easing.Back = function(t) return t^3 - t * math.sin(t * math.pi) end

    AimAssist = vape.Categories.Combat:CreateModule({
        Name = 'AimAssist',
        Tooltip = 'Smoothly aims to closest valid target',
        Function = function(callback)
            if callback then
                AimAssist:Clean(runService.Heartbeat:Connect(function(dt)
					if GUI.Enabled then
						if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
					end					
                    shakeTime += dt
                    if not entitylib.isAlive then return end
					if Limits.Enabled then
						if store.hand.toolType ~= 'sword' then
							return
						end
					end
                    if ClickAim.Enabled and (tick() - bedwars.SwordController.lastSwing) >= 0.4 then return end

                    local ent
                    if Priorty.Enabled and priorityTarget then
                        local root = entitylib.character.RootPart
                        local delta = priorityTarget.RootPart.Position - root.Position
                        if priorityTarget.RootPart and priorityTarget.Character and priorityTarget.Character:FindFirstChild("Humanoid") and priorityTarget.Character.Humanoid.Health > 0 and delta.Magnitude <= Distance.Value then
                            ent = priorityTarget
                        else
                            priorityTarget = nil
                        end
                    end

                    if not ent then
                        ent = not KillauraTarget.Enabled and entitylib.EntityPosition({
                            Range = Distance.Value,
                            Part = 'RootPart',
                            Wallcheck = Targets.Walls.Enabled,
                            Players = Targets.Players.Enabled,
                            NPCs = Targets.NPCs.Enabled,
                            Limit = MaxTargets.Value,
                            Sort = sortmethods[Sort.Value]
                        }) or store.KillauraTarget

                        if Priorty.Enabled and ent then
                            priorityTarget = ent
                        end
                    end

                    if not ent then return end
                    local root = entitylib.character.RootPart
                    local delta = ent.RootPart.Position - root.Position
                    local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                    local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
                    if KillauraTarget.Enabled then
						if angle >= (math.rad(AngleSlider.Value) / 2) then 
							task.wait()
						end
					else
						if angle >= (math.rad(AngleSlider.Value) / 2) then 
							return 
						end
					end
                    if not optionAllowsAim() then return end

                    local shakeOffset = Vector3.zero
                    if Shake.Enabled then
                        local freq = (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 16 or 10
                        local x = math.sin(shakeTime * freq + Smoothness.Value) * ShakeV.Value
                        shakeOffset = gameCamera.CFrame.RightVector * x * 0.05 * (500 + math.random(10,45) - (match.random(2,3) * math.random()))
                    end

                    local targetPos = ent.RootPart.Position + shakeOffset

                    if Option.Value == "Mouse" and hasMouseMove then
                        if aimWithMouse(targetPos, dt) then return end
                    else
                        local speed = Smoothness.Value * dt
                        local easeFunc = Easing[TweenStyles.Value] or Easing.Linear
                        local alpha = easeFunc(speed)
						if TweenOption.Enabled then
							alpha = alpha
						else
							alpha = (AimSpeed.Value + (StrafeIncrease.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 10 or 0)) * dt * Smoothness.Value
						end
                      	gameCamera.CFrame = gameCamera.CFrame:Lerp(CFrame.lookAt(gameCamera.CFrame.Position, targetPos), alpha)
                    end
                end))
            else
                priorityTarget = nil
            end
        end
    })

	Option = AimAssist:CreateDropdown({
        Name = "Types",
        List = { "First Person Only", "Third Person Only", "Both", "Mouse" }
    })

    Priorty = AimAssist:CreateToggle({
        Name = 'Priorty',
        Tooltip = 'Locks onto the first target until invalid'
    })

    MaxTargets = AimAssist:CreateSlider({
        Name = "Max Targets",
        Min = 1,
        Max = 8,
        Default = 5
    })

    Targets = AimAssist:CreateTargets({
        Players = true,
        Walls = true
    })

    local methods = { 'Damage', 'Distance' }
    for i in sortmethods do
        if not table.find(methods, i) then
            table.insert(methods, i)
        end
    end

    Sort = AimAssist:CreateDropdown({
        Name = 'Target Mode',
        List = methods
    })

    AimSpeed = AimAssist:CreateSlider({
        Name = 'Aim Speed',
        Min = 1,
        Max = 20,
        Default = getgenv().Closet and 4 or 6
    })

    Distance = AimAssist:CreateSlider({
        Name = 'Distance',
        Min = 1,
        Max = 30,
        Default = 30,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })

    AngleSlider = AimAssist:CreateSlider({
        Name = 'Max angle',
        Min = 1,
        Max = 360,
        Default = 70
    })

    ClickAim = AimAssist:CreateToggle({
        Name = 'Click Aim',
        Default = true
    })

    ShakeV = AimAssist:CreateSlider({
        Name = "Shake Power",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Visible = false,
        Decimal = 100
    })
    Shake = AimAssist:CreateToggle({
        Name = 'Shake',
        Default = false,
        Function = function(callback)
            ShakeV.Object.Visible = callback
        end
    })

	Limits = AimAssist:CreateToggle({
        Name = 'Limit to items',
        Default = false
    })

    KillauraTarget = AimAssist:CreateToggle({
        Name = 'Use killaura target'
    })

    StrafeIncrease = AimAssist:CreateToggle({
        Name = 'Strafe increase'
    })

    Smoothness = AimAssist:CreateSlider({
        Name = "Smoothness",
		Tooltip = 'Use 1 if u want the og AA',
        Min = 1,
        Max = 12,
        Default = 1
    })
	GUI = AimAssist:CreateToggle({Name = 'GUI Check'})
    TweenStyles = AimAssist:CreateDropdown({
        Name = "Tween Style",
        List = {"Linear", "Elastic", "Sine", "Quad", "Cubic", "Quart", "Back"},
        Default = "Linear",
		Visible = false
    })
	TweenOption = AimAssist:CreateToggle({
		Name = "Tween Option",
		Default = false,
		Function = function(v)
			TweenStyles.Object.Visible = v
		end,
		Tooltip = 'enables the tween styles.'
	})
end)

getgenv().swapping = os.clock()
	
run(function()
	local AutoClicker
	local CPS
	local Block
	local BlockCPS = {}
	local Thread
	
	local function AutoClick()
		if Thread then
			task.cancel(Thread)
		end
	
		Thread = task.delay(1 / (store.hand.toolType == 'block' and BlockCPS or CPS).GetRandomValue(), function()
			repeat
				if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
					local blockPlacer = bedwars.BlockPlacementController.blockPlacer
					if store.hand.toolType == 'block' and blockPlacer and Block.Enabled then
						if canDebug then
							if inputService.TouchEnabled then
								task.spawn(function()
									blockPlacer:autoBridge(workspace:GetServerTimeNow() - bedwars.KnockbackController:getLastKnockbackTime() >= 0.2)
								end)
							else
								if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) >= ((1 / 12) * 0.5) then
									local mouseinfo = blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
									if mouseinfo and mouseinfo.placementPosition == mouseinfo.placementPosition then
										task.spawn(blockPlacer.placeBlock, blockPlacer, mouseinfo.placementPosition)
									end
								end
							end
						else
							mouse1click()
						end
					elseif store.hand.toolType == 'sword' then
						if canDebug then
							bedwars.SwordController:swingSwordAtMouse(0.39)
						else
							mouse1click()
						end
					end
				end
	
				task.wait(1 / (store.hand.toolType == 'block' and BlockCPS or CPS).GetRandomValue())
			until not AutoClicker.Enabled
		end)
	end
	
	AutoClicker = vape.Categories.Combat:CreateModule({
		Name = 'Auto Clicker',
		Function = function(callback)
			if callback then
				AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						AutoClick()
					end
				end))
	
				AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread and (os.clock() - getgenv().swapping) > 0.12 then
						task.cancel(Thread)
						Thread = nil
					end
				end))
	
				if inputService.TouchEnabled then
					pcall(function()
						for _, v in {'2', '5'} do
							AutoClicker:Clean(lplr.PlayerGui.MobileUI[v].MouseButton1Down:Connect(AutoClick))
							AutoClicker:Clean(lplr.PlayerGui.MobileUI[v].MouseButton1Up:Connect(function()
								if Thread then
									task.cancel(Thread)
									Thread = nil
								end
							end))
						end
					end)
				end
			else
				if Thread then
					task.cancel(Thread)
					Thread = nil
				end
			end
		end,
		Tooltip = 'Hold attack button to automatically click'
	})
	CPS = AutoClicker:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 48,
		DefaultMin = 7,
		DefaultMax = 48
	})
	Block = AutoClicker:CreateToggle({
		Name = 'Place Blocks',
		Default = true,
		Function = function(callback)
			if BlockCPS.Object then
				BlockCPS.Object.Visible = callback
			end
		end
	})
	BlockCPS = AutoClicker:CreateTwoSlider({
		Name = 'Block CPS',
		Min = 1,
		Max = 48,
		DefaultMin = 12,
		DefaultMax = 48,
		Darker = true
	})
end)
	
run(function()
	local old
	local Delay
	local NoClickDelay
	NoClickDelay = vape.Categories.Combat:CreateModule({
		Name = 'NoClickDelay',
		Function = function(callback)
			if callback then
				old = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
				if Delay.Value == 0 then
					Delay.Value = os.clock()
				else
					Delay.Value = Delay.Value
				end
				
					self.lastSwing = Delay.Value
					return false
				end
			else
				bedwars.SwordController.isClickingTooFast = old
			end
		end,
		Tooltip = 'Remove the CPS cap'
	})
	Delay  = NoClickDelay:CreateSlider({
		Name = "Delay",
		Min = 0,
		Max = 1,
		Decimal = 100,
	})
end)

	
run(function()
	local Attack
	local Mine
	local Place
	local oldAttackReach, oldMineReach
	local oldIsAllowedPlacement

	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				oldAttackReach = bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE
				
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Attack.Value + 2
				
				task.spawn(function()
					repeat task.wait(0.1) until bedwars.BlockBreakController or not Reach.Enabled
					if not Reach.Enabled then return end
					
					pcall(function()
						local blockBreaker = bedwars.BlockBreakController:getBlockBreaker()
						if blockBreaker then
							oldMineReach = oldMineReach or blockBreaker:getRange()
							blockBreaker:setRange(Mine.Value)
						end
					end)
				end)
				
				task.spawn(function()
					repeat task.wait(0.1) until bedwars.BlockEngine or not Reach.Enabled
					if not Reach.Enabled then return end
					
					pcall(function()
						if not oldIsAllowedPlacement then
							oldIsAllowedPlacement = bedwars.BlockEngine.isAllowedPlacement
							bedwars.BlockEngine.isAllowedPlacement = function(self, player, blockType, position, rotation, mouseBlockInfo)
								local result = oldIsAllowedPlacement(self, player, blockType, position, rotation, mouseBlockInfo)
								
								if not result and player == game.Players.LocalPlayer then
									local blockExists = self:getStore():getBlockAt(position)
									if not blockExists then
										return true 
									end
								end
								
								return result
							end
						end
					end)
				end)
				
				task.spawn(function()
					repeat task.wait(0.1) until bedwars.BlockPlacementController or not Reach.Enabled
					if not Reach.Enabled then return end
					
					pcall(function()
						local blockPlacer = bedwars.BlockPlacementController:getBlockPlacer()
						if blockPlacer and blockPlacer.blockHighlighter then
							blockPlacer.blockHighlighter:setRange(Place.Value)
							blockPlacer.blockHighlighter.range = Place.Value
						end
					end)
				end)
				
				task.spawn(function()
					while Reach.Enabled do
						if bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE ~= Attack.Value + 2 then
							bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Attack.Value + 2
						end
						
						pcall(function()
							local blockBreaker = bedwars.BlockBreakController:getBlockBreaker()
							if blockBreaker and blockBreaker:getRange() ~= Mine.Value then
								blockBreaker:setRange(Mine.Value)
							end
						end)
						
						pcall(function()
							local blockPlacer = bedwars.BlockPlacementController:getBlockPlacer()
							if blockPlacer and blockPlacer.blockHighlighter then
								if blockPlacer.blockHighlighter.range ~= Place.Value then
									blockPlacer.blockHighlighter:setRange(Place.Value)
									blockPlacer.blockHighlighter.range = Place.Value
								end
							end
						end)
						
						task.wait(0.5)
					end
				end)
			else
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = oldAttackReach or 14.4
				
				pcall(function()
					local blockBreaker = bedwars.BlockBreakController:getBlockBreaker()
					if blockBreaker then
						blockBreaker:setRange(oldMineReach or 18)
					end
				end)
				
				pcall(function()
					local blockPlacer = bedwars.BlockPlacementController:getBlockPlacer()
					if blockPlacer and blockPlacer.blockHighlighter then
						blockPlacer.blockHighlighter:setRange(18)
						blockPlacer.blockHighlighter.range = 18
					end
				end)
				
				if oldIsAllowedPlacement then
					pcall(function()
						bedwars.BlockEngine.isAllowedPlacement = oldIsAllowedPlacement
					end)
				end
				
				oldAttackReach, oldMineReach, oldIsAllowedPlacement = nil, nil, nil
			end
		end,
		Tooltip = 'Extends reach for attacking, mining, and placing blocks'
	})
	
	Attack = Reach:CreateSlider({
		Name = 'Attack Range',
		Min = 0,
		Max = 30,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	
	Mine = Reach:CreateSlider({
		Name = 'Mine Range',
		Min = 0,
		Max = 30,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				pcall(function()
					local blockBreaker = bedwars.BlockBreakController:getBlockBreaker()
					if blockBreaker then
						blockBreaker:setRange(val)
					end
				end)
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	
	Place = Reach:CreateSlider({
		Name = 'Place Range',
		Min = 0,
		Max = 30,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				pcall(function()
					local blockPlacer = bedwars.BlockPlacementController:getBlockPlacer()
					if blockPlacer and blockPlacer.blockHighlighter then
						blockPlacer.blockHighlighter:setRange(val)
						blockPlacer.blockHighlighter.range = val
					end
				end)
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)


run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then 
					pcall(function() 
						lplr.PlayerGui.MobileUI['4'].Visible = false 
					end) 
				end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() 
					task.delay(0.1, function() 
						bedwars.SprintController:stopSprinting() 
					end) 
				end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then 
					pcall(function() 
						lplr.PlayerGui.MobileUI['4'].Visible = true 
					end) 
				end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	


	
run(function()
	local Velocity
	local Horizontal
	local Vertical
	local Air
	local Ground
	local Mode
	local Chance
	local TargetCheck
	local rand, old = Random.new()
	
	local TakeKnockback = Instance.new('BindableEvent')

	--local Attributes = bedwars.KnockbackUtilInstance:GetAttributes()

	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
					old = bedwars.KnockbackUtil.applyKnockback

					Velocity:Clean(TakeKnockback.Event:Connect(function(root, mass, dir, knockback, ...)
						local args = {...}

						local air, ground

						task.delay(Air:GetRandomValue() / 1000, function()
							local clone = table.clone(knockback)
							clone.horizontal = ground and 0.1 or 0
							air = true
							old(root, mass, dir, clone, unpack(args))
						end)
						task.delay(Ground:GetRandomValue() / 1000, function()
							local clone = table.clone(knockback)
							clone.vertical = air and 0.1 or 0
							ground = true
							old(root, mass, dir, clone, unpack(args))
						end)
					end))

					bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
						local chance = rand:NextNumber(0, 100)
						chance = math.floor(chance)
						if Mode.Value == 'Normal' then
							if chance >= Chance.Value then return old(root, mass, dir, knockback, ...) end
						end
						
						local check = (not TargetCheck.Enabled) or entitylib.EntityPosition({
							Range = 50,
							Part = 'RootPart',
							Players = true
						})
		
						if check then
							knockback = knockback or {}
							if Mode.Value == 'Lag' then
								if chance < Chance.Value then
									return TakeKnockback:Fire(root, mass, dir, knockback, ...)
								end
							else
								if Horizontal.Value == 0 and Vertical.Value == 0 then return end
								knockback.horizontal = (knockback.horizontal or 1) * (Horizontal.Value / 100)
								knockback.vertical = (knockback.vertical or 1) * (Vertical.Value / 100)
							end
						end
						
						return old(root, mass, dir, knockback, ...)
					end
			else
				bedwars.KnockbackUtil.applyKnockback = old
			end
		end,
		Tooltip = 'Reduces knockback taken',
		ExtraText = function()
			return Mode.Value or 'No Knockback'
		end
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Darker = true,
		Suffix = '%'
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Darker = true,
		Suffix = '%'
	})		
	Air = Velocity:CreateTwoSlider({
		Name = 'Air delay',
		Min = 0,
		Max = 500,
		Darker = true,
		DefaultMin = 50,
		DefaultMax = 150
	})
	Ground = Velocity:CreateTwoSlider({
		Name = 'Ground delay',
		Min = 0,
		Max = 500,
		Darker = true,
		DefaultMin = 200,
		DefaultMax = 250
	})
	Mode = Velocity:CreateDropdown({
		Name = 'Mode',
		Default = 'Normal',
		List = {'Lag', 'Normal'},
		Function = function(val)
			Vertical.Object.Visible = val == 'Normal'
			Horizontal.Object.Visible = val == 'Normal'
			Air.Object.Visible = val == 'Lag'
			Ground.Object.Visible = val == 'Lag'
		end
	})
	Vertical.Object.Visible = Mode.Value == 'Normal'
	Horizontal.Object.Visible = Mode.Value == 'Normal'
	Air.Object.Visible = Mode.Value == 'Lag'
	Ground.Object.Visible = Mode.Value == 'Lag'
	Chance = Velocity:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	TargetCheck = Velocity:CreateToggle({Name = 'Only when targeting'})
end)
	
	
local AntiFallDirection
run(function()
	local AntiFall
	local Mode
	local Material
	local Color
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	local function getLowGround()
		local mag = math.huge
		for _, pos in bedwars.BlockController:getStore():getAllBlockPositions() do
			pos = pos * 3
			if pos.Y < mag and not getPlacedBlock(pos + Vector3.new(0, 3, 0)) then
				mag = pos.Y
			end
		end
		return mag
	end

	AntiFall = vape.Categories.Blatant:CreateModule({
		Name = 'AntiFall',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AntiFall.Enabled)
				if not AntiFall.Enabled then return end

				local pos, debounce = getLowGround(), tick()
				if pos ~= math.huge then
					AntiFallPart = Instance.new('Part')
					AntiFallPart.Size = Vector3.new(10000, 1, 10000)
					AntiFallPart.Transparency = 1 - Color.Opacity
					AntiFallPart.Material = Enum.Material[Material.Value]
					AntiFallPart.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					AntiFallPart.Position = Vector3.new(0, pos - 2, 0)
					AntiFallPart.CanCollide = Mode.Value == 'Collide'
					AntiFallPart.Anchored = true
					AntiFallPart.CanQuery = false
					AntiFallPart.Parent = workspace
					AntiFall:Clean(AntiFallPart)
					AntiFall:Clean(AntiFallPart.Touched:Connect(function(touched)
						if touched.Parent == lplr.Character and entitylib.isAlive and debounce < tick() then
							debounce = tick() + 0.1
							if Mode.Value == 'Normal' then
								local top = getNearGround()
								if top then
									local lastTeleport = lplr:GetAttribute('LastTeleported')
									local connection
									connection = runService.PreSimulation:Connect(function()
										if vape.Modules.Fly.Enabled or vape.Modules.InfiniteFly.Enabled or vape.Modules.LongJump.Enabled then
											connection:Disconnect()
											AntiFallDirection = nil
											return
										end

										if entitylib.isAlive and lplr:GetAttribute('LastTeleported') == lastTeleport then
											local delta = ((top - entitylib.character.RootPart.Position) * Vector3.new(1, 0, 1))
											local root = entitylib.character.RootPart
											AntiFallDirection = delta.Unit == delta.Unit and delta.Unit or Vector3.zero
											root.Velocity *= Vector3.new(1, 0, 1)
											rayCheck.FilterDescendantsInstances = {gameCamera, lplr.Character}
											rayCheck.CollisionGroup = root.CollisionGroup

											local ray = workspace:Raycast(root.Position, AntiFallDirection, rayCheck)
											if ray then
												for _ = 1, 10 do
													local dpos = roundPos(ray.Position + ray.Normal * 1.5) + Vector3.new(0, 3, 0)
													if not getPlacedBlock(dpos) then
														top = Vector3.new(top.X, pos.Y, top.Z)
														break
													end
												end
											end

											root.CFrame += Vector3.new(0, top.Y - root.Position.Y, 0)
											if not frictionTable.Speed then
												root.AssemblyLinearVelocity = (AntiFallDirection * getSpeed()) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
											end

											if delta.Magnitude < 1 then
												connection:Disconnect()
												AntiFallDirection = nil
											end
										else
											connection:Disconnect()
											AntiFallDirection = nil
										end
									end)
									AntiFall:Clean(connection)
								end
							elseif Mode.Value == 'Velocity' then
								entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 100, entitylib.character.RootPart.Velocity.Z)
							end
						end
					end))
				end
			else
				AntiFallDirection = nil
			end
		end,
		Tooltip = 'Help\'s you with your Parkinson\'s\nPrevents you from falling into the void.'
	})
	Mode = AntiFall:CreateDropdown({
		Name = 'Move Mode',
		List = {'Normal', 'Collide', 'Velocity'},
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.CanCollide = val == 'Collide'
			end
		end,
	Tooltip = 'Normal - Smoothly moves you towards the nearest safe point\nVelocity - Launches you upward after touching\nCollide - Allows you to walk on the part'
	})
	local materials = {'ForceField'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'ForceField' then
			table.insert(materials, v.Name)
		end
	end
	Material = AntiFall:CreateDropdown({
		Name = 'Material',
		List = materials,
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.Material = Enum.Material[val]
			end
		end
	})
	Color = AntiFall:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.5,
		Function = function(h, s, v, o)
			if AntiFallPart then
				AntiFallPart.Color = Color3.fromHSV(h, s, v)
				AntiFallPart.Transparency = 1 - o
			end
		end
	})
end)
local FastBreak
run(function()
	local Time
	local Blacklist
	local blocks
	local old, event
	
	local function IgnoreFastBreak(block)
		if not block then return false end
		if block:GetAttribute("NoBreak") then return true end
		if block:GetAttribute("Team"..(lplr:GetAttribute("Team") or 0).."NoBreak") then return true end
		local name = block.Name:lower()
		for _, v in pairs(blocks.ListEnabled) do
			if name:find(v:lower(), 1, true) or (value == "bed" and workspace:FindFirstChild(name)) then
				return true
			end
		end
		return false
	end
	FastBreak = vape.Categories.Blatant:CreateModule({
		Name = 'FastBreak',
		Function = function(callback)
			if callback then
				if Blacklist.Enabled then
					event = Instance.new('BindableEvent')
					FastBreak:Clean(event)
					FastBreak:Clean(event.Event:Connect(function()
						contextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
					end))

					old = bedwars.BlockBreaker.hitBlock																			
						repeat
							bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
								local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
								local NewBlock = block and block.target and block.target.blockInstance or nil																				
								if IgnoreFastBreak(NewBlock) then 
									bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
								else
									bedwars.BlockBreakController.blockBreaker:setCooldown(Time.Value)
								end
								return old(self, maid, raycastparams, ...)
							end
							task.wait(0.1)
						until not FastBreak.Enabled
				else
					repeat
						bedwars.BlockBreakController.blockBreaker:setCooldown(Time.Value)
						task.wait(0.1)
					until not FastBreak.Enabled
				end
			else
				if Blacklist.Enabled then
					bedwars.BlockBreaker.hitBlock = old
					old = nil
				end
				bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
			end
		end,
		Tooltip = 'Decreases block hit cooldown'
	})
	blocks = FastBreak:CreateTextList({
		Name = "Blacklisted Blocks",
		Placeholder = "bed",
		Visible = false
	})
																				
	Time = FastBreak:CreateSlider({
		Name = 'Break speed',
		Min = 0,
		Max = 0.25,
		Default = 0.25,
		Decimal = 100,
		Suffix = 'seconds'
	})
	Blacklist = FastBreak:CreateToggle({
		Name = "Blacklist Blocks",
		Default = false,
		Tooltip = "when ur mining the selected block it uses normal break speed",
		Function = function(v)
			blocks.Object.Visible = v
		end
	})
end)
local LongJump

	
run(function()
	local Mode
	local Expand
	local objects, set = {}
	
	local function createHitbox(ent)
		if ent.Targetable and ent.Player then
			local hitbox = Instance.new('Part')
			hitbox.Size = Vector3.new(3, 6, 3) + Vector3.one * (Expand.Value / 5)
			hitbox.Position = ent.RootPart.Position
			hitbox.CanCollide = false
			hitbox.Massless = true
			hitbox.Transparency = 1
			hitbox.Parent = ent.Character
			local weld = Instance.new('Motor6D')
			weld.Part0 = hitbox
			weld.Part1 = ent.RootPart
			weld.Parent = hitbox
			objects[ent] = hitbox
		end
	end
	
	HitBoxes = vape.Categories.Blatant:CreateModule({
		Name = 'HitBoxes',
		Function = function(callback)
			if callback then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (Expand.Value / 3))
					set = true
				else
					HitBoxes:Clean(entitylib.Events.EntityAdded:Connect(createHitbox))
					HitBoxes:Clean(entitylib.Events.EntityRemoving:Connect(function(ent)
						if objects[ent] then
							objects[ent]:Destroy()
							objects[ent] = nil
						end
					end))
					for _, ent in entitylib.List do
						createHitbox(ent)
					end
				end
			else
				if set then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, 3.8)
					set = nil
				end
				for _, part in objects do
					part:Destroy()
				end
				table.clear(objects)
			end
		end,
		Tooltip = 'Expands attack hitbox'
	})
	Mode = HitBoxes:CreateDropdown({
		Name = 'Mode',
		List = {'Sword', 'Player'},
		Function = function()
			if HitBoxes.Enabled then
				HitBoxes:Toggle(false)
				HitBoxes:Toggle(true)
			end
		end,
		Tooltip = 'Sword - Increases the range around you to hit entities\nPlayer - Increases the players hitbox'
	})
	Expand = HitBoxes:CreateSlider({
		Name = 'Expand amount',
		Min = 0,
		Max = 14.4,
		Default = 14.4,
		Decimal = 10,
		Function = function(val)
			if HitBoxes.Enabled then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (val / 3))
				else
					for _, part in objects do
						part.Size = Vector3.new(3, 6, 3) + Vector3.one * (val / 5)
					end
				end
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	
run(function()
	vape.Categories.Blatant:CreateModule({
		Name = 'KeepSprint',
		Function = function(callback)
			debug.setconstant(bedwars.SprintController.startSprinting, 5, callback and 'blockSprinting' or 'blockSprint')
			bedwars.SprintController:stopSprinting()
		end,
		Tooltip = 'Lets you sprint with a speed potion.'
	})
end)

local Attacking

																	
	
run(function()
	local Value
	local CameraDir
	local start
	local JumpTick, JumpSpeed, Direction = tick(), 0
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	
	local function launchProjectile(item, pos, proj, speed, dir)
		if not pos then return end
	
		pos = pos - dir * 0.1
		local shootPosition = (CFrame.lookAlong(pos, Vector3.new(0, -speed, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ)))
		switchItem(item.tool, 0)
		task.wait(0.1)
		bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta[proj], proj, proj, shootPosition.Position, '', shootPosition.LookVector * speed, {drawDurationSeconds = 1})
		if PR:InvokeServer(item.tool, bedwars.ProjectileMeta[proj], shootPosition.Position,shootPosition.LookVector * speed) then
			local shoot = bedwars.ItemMeta[item.itemType].projectileSource.launchSound
			shoot = shoot and shoot[math.random(1, #shoot)] or nil
			if shoot then
				bedwars.SoundManager:playSound(shoot)
			end
		end
	end
	
	local LongJumpMethods = {
		cannon = function(_, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			bedwars.placeBlock(rounded, 'cannon', false)
	
			task.delay(0, function()
				local block, blockpos = getPlacedBlock(rounded)
				if block and block.Name == 'cannon' and (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
					local breaktype = bedwars.ItemMeta[block.Name].block.breakType
					local tool = store.tools[breaktype]
					if tool then
						switchItem(tool.tool)
					end
	
					bedwars.Client:Get(remotes.CannonAim):SendToServer({
						cannonBlockPos = blockpos,
						lookVector = dir
					})
	
					local broken = 0.1
					if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
						broken = 0.4
						bedwars.breakBlock(block, true, true)
					end
	
					task.delay(broken, function()
						for _ = 1, 3 do
							local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
							if call then
								bedwars.breakBlock(block, true, true)
								JumpSpeed = 5.25 * Value.Value
								JumpTick = tick() + 2.3
								Direction = Vector3.new(dir.X, 0, dir.Z).Unit
								break
							end
							task.wait(0.1)
						end
					end)
																																				LongJump:Toggle()
				end
			end)
		end,
		cat = function(_, _, dir)
			LongJump:Clean(vapeEvents.CatPounce.Event:Connect(function()
				JumpSpeed = 4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
				entitylib.character.RootPart.Velocity = Vector3.zero
			end))
	
			if not bedwars.AbilityController:canUseAbility('CAT_POUNCE') then
				repeat task.wait(0.1) until bedwars.AbilityController:canUseAbility('CAT_POUNCE') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility('CAT_POUNCE') and LongJump.Enabled then
				bedwars.AbilityController:useAbility('CAT_POUNCE')
			end
																																																																					LongJump:Toggle()
			LongJump:Toggle()
		end,
		fireball = function(item, pos, dir)
			launchProjectile(item, pos, 'fireball', 60, dir)
																																																																					LongJump:Toggle()
			LongJump:Toggle()
		end,
		grappling_hook = function(item, pos, dir)
			launchProjectile(item, pos, 'grappling_hook_projectile', 140, dir)
																																	LongJump:Toggle()
		end,
		jade_hammer = function(item, _, dir)
			if not bedwars.AbilityController:canUseAbility(item.itemType..'_jump') then
				repeat task.wait(0.1) until bedwars.AbilityController:canUseAbility(item.itemType..'_jump') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility(item.itemType..'_jump') and LongJump.Enabled then
				bedwars.AbilityController:useAbility(item.itemType..'_jump')
				JumpSpeed = 1.4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
			end
																																	LongJump:Toggle()
		end,
		tnt = function(item, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			start = Vector3.new(rounded.X, start.Y, rounded.Z) + (dir * (item.itemType == 'pirate_gunpowder_barrel' and 2.6 or 0.2))
			bedwars.placeBlock(rounded, item.itemType, false)
																																	LongJump:Toggle()
		end,
		wood_dao = function(item, pos, dir)
			if (lplr.Character:GetAttribute('CanDashNext') or 0) > workspace:GetServerTimeNow() or not bedwars.AbilityController:canUseAbility('dash') then
				repeat task.wait(0.1) until (lplr.Character:GetAttribute('CanDashNext') or 0) < workspace:GetServerTimeNow() and bedwars.AbilityController:canUseAbility('dash') or not LongJump.Enabled
			end
	
			if LongJump.Enabled then
				bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
				switchItem(item.tool, 0.1)
				replicatedStorage['events-@easy-games/game-core:shared/game-core-networking@getEvents.Events'].useAbility:FireServer('dash', {
					direction = dir,
					origin = pos,
					weapon = item.itemType
				})
				JumpSpeed = 4.5 * Value.Value
				JumpTick = tick() + 2.4
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit


			
			end
																																	LongJump:Toggle()
		end
	}
	for _, v in {'stone_dao', 'iron_dao', 'diamond_dao', 'emerald_dao'} do
		LongJumpMethods[v] = LongJumpMethods.wood_dao
	end
	LongJumpMethods.void_axe = LongJumpMethods.jade_hammer
	LongJumpMethods.siege_tnt = LongJumpMethods.tnt
	LongJumpMethods.pirate_gunpowder_barrel = LongJumpMethods.tnt
	
	LongJump = vape.Categories.Blatant:CreateModule({
		Name = 'LongJump',
		Function = function(callback)
			frictionTable.LongJump = callback or nil
			updateVelocity()
			if callback then
				LongJump:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and damageTable.fromEntity == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
							vertical = 0,
							horizontal = (damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal or 1)
						}).Magnitude * 1.1
	
						if knockbackBoost >= JumpSpeed then
							local pos = damageTable.fromPosition and Vector3.new(damageTable.fromPosition.X, damageTable.fromPosition.Y, damageTable.fromPosition.Z) or damageTable.fromEntity and damageTable.fromEntity.PrimaryPart.Position
							if not pos then return end
							local vec = (entitylib.character.RootPart.Position - pos)
							JumpSpeed = knockbackBoost
							JumpTick = tick() + 2.5
							Direction = Vector3.new(vec.X, 0, vec.Z).Unit
						end
					end
				end))
				LongJump:Clean(vapeEvents.GrapplingHookFunctions.Event:Connect(function(dataTable)
					if dataTable.hookFunction == 'PLAYER_IN_TRANSIT' then
						local vec = entitylib.character.RootPart.CFrame.LookVector
						JumpSpeed = 2.5 * Value.Value
						JumpTick = tick() + 2.5
						Direction = Vector3.new(vec.X, 0, vec.Z).Unit
					end
				end))
	
				start = entitylib.isAlive and entitylib.character.RootPart.Position or nil
				LongJump:Clean(runService.PreSimulation:Connect(function(dt)
					local root = entitylib.isAlive and entitylib.character.RootPart or nil
	
					if root and isnetworkowner(root) then
						if JumpTick > tick() then
							root.AssemblyLinearVelocity = Direction * (getSpeed() + ((JumpTick - tick()) > 1.1 and JumpSpeed or 0)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
							if entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and not start then
								root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - 23), 0)
							else
								root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
							end
							start = nil
						else
							if start then
								root.CFrame = CFrame.lookAlong(start, root.CFrame.LookVector)
							end
							root.AssemblyLinearVelocity = Vector3.zero
							JumpSpeed = 0
						end
					else
						start = nil
					end
				end))
	
				if store.hand and LongJumpMethods[store.hand.tool.Name] then
					task.spawn(LongJumpMethods[store.hand.tool.Name], getItem(store.hand.tool.Name), start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
					return
				end
	
				for i, v in LongJumpMethods do
					local item = getItem(i)
					if item or store.equippedKit == i then
						task.spawn(v, item, start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
						break
					end
				end
			else
				JumpTick = tick()
				Direction = nil
				JumpSpeed = 0
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Lets you jump farther'
	})
	Value = LongJump:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 37,
		Default = 37,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	CameraDir = LongJump:CreateToggle({
		Name = 'Camera Direction'
	})
end)
	
	
run(function()
	local NoFall
	local Chance
	local DamageAccuracy
	local rand = Random.new()
	local rayParams = RaycastParams.new()
	local groundHit = {}
	function groundHit:FireServer(...)
		bedwars.Client:Get("GroundHit"):SendToServer(...)
	end
	NoFall = vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Tooltip = 'Prevents or reduces fall damage.',
		Function = function(callback)
			if not callback then return end
			local tracked = 0
			repeat
				if not entitylib.isAlive then
					tracked = 0
					task.wait(0.2)
					continue
				end
				local char = entitylib.character
				local root = char.RootPart
				local humanoid = char.Humanoid
				if humanoid.FloorMaterial == Enum.Material.Air then
					tracked = math.min(tracked, root.AssemblyLinearVelocity.Y)
				else
					tracked = 0
				end
				if tracked < -85 then
					if rand:NextNumber(0, 100) <= Chance.Value then
						local scaled = tracked * (DamageAccuracy.Value / 100)
						groundHit:FireServer(nil,Vector3.new(0, scaled, 0),workspace:GetServerTimeNow())
					end
					tracked = 0
				end
				task.wait(0.03)
			until not NoFall.Enabled
		end
	})
	DamageAccuracy = NoFall:CreateSlider({
		Name = 'Damage Accuracy',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%',
		Decimal = 5
	})
	Chance = NoFall:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)

run(function()
	local old
	
	vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			local modifier = bedwars.SprintController:getMovementStatusModifier()
			if callback then
				old = modifier.addModifier
				modifier.addModifier = function(self, tab)
					if tab.moveSpeedMultiplier then
						tab.moveSpeedMultiplier = math.max(tab.moveSpeedMultiplier, 1)
					end
					return old(self, tab)
				end
	
				for i in modifier.modifiers do
					if (i.moveSpeedMultiplier or 1) < 1 then
						modifier:removeModifier(i)
					end
				end
			else
				modifier.addModifier = old
				old = nil
			end
		end,
		Tooltip = 'Prevents slowing down when using items.'
	})
end)

run(function()
	local ProjectileAimbot	
	local TargetPart
	local Blacklist
	local rand = Random.new()
	local HitChance
	local Targets
	local FOV
	local OtherProjectiles
	local Slowdown
	local AutoCharge
	local ChargePercent
	local BA
	local Ping
	local ForestPriority
	local FireRate
	local SlowSpeed
	local Rate
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild("Map")}
	local old
	local vanessaOLD
	local lumenOLD = {MAX = nil, MIN = nil}
	local function HasSeed(character)
		return character and character:FindFirstChild("Seed", true) ~= nil
	end
	local oldFireRates = {
		old = nil,
		fireRate = {}
	}
	ProjectileAimbot = vape.Categories.Combat:CreateModule({
		Name = "ProjectileAimbot",
		Function = function(callback)
			if callback then
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				task.spawn(function()
					if store.equippedKit == "triple_shot" then
						vanessaOLD = bedwars.TripleShotProjectileController.getChargeTime
						bedwars.TripleShotProjectileController.getChargeTime = function(self)
							if not AutoCharge.Enabled then
								return vanessaOLD(self)
							end
							local percent = math.clamp(ChargePercent.Value, 0, 100)
							return 1.6 * (1 - percent / 100)
						end
					end
					if store.equippedKit == "lumen" then
						local balance = require(game:GetService("ReplicatedStorage").TS.games.bedwars.kit.kits.lumen["lumen-balance"]).LumenBalance
						lumenOLD.MIN = balance.MIN_CHARGE_TIME
						lumenOLD.MAX = balance.MAX_CHARGE_TIME
						if AutoCharge.Enabled then
							local percent = math.clamp(ChargePercent.Value, 0, 100)
							balance.MAX_CHARGE_TIME = lumenOLD.MAX * (1 - percent / 100)
							balance.MIN_CHARGE_TIME = lumenOLD.MIN * (1 - percent / 100)
						end
					end
				end)
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
					local self, projmeta, worldmeta, origin, shootpos = ...
					local plr = entitylib.EntityMouse({
						Part = "RootPart",
						Range = FOV.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled,
						Origin = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					})
					if ForestPriority.Enabled then
						for _, ent in pairs(entitylib.List) do
							if ent.Character and ent.HumanoidRootPart and ent ~= entitylib.character and HasSeed(ent.Character) then
								local dist = (ent.HumanoidRootPart.Position - (shootpos or entitylib.character.RootPart.Position)).Magnitude
								if dist <= FOV.Value then
									plr = ent
									break
								end
							end
						end
					end
					if not plr then
						return old(...)
					end
					if (not OtherProjectiles.Enabled) and not projmeta.projectile:find("arrow") then
						return old(...)
					end
					if table.find(Blacklist.ListEnabled, projmeta.projectile) then
						return old(...)
					end

					if Slowdown.Enabled then
						local CS = 14
						if lplr:GetAttribute('Sprinting') == true then
							CS = 20
						else
							CS = 14
						end
						local percent = math.clamp(SlowSpeed.Value, 0, 100)
						local NewSpeed = CS * (1 - percent / 100)
						lplr.Character.Humanoid.WalkSpeed = NewSpeed
					end

					local meta = projmeta:getProjectileMeta()
					local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
					local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
					local projSpeed = (meta.launchVelocity or 100)
					local pos = shootpos or self:getLaunchPosition(origin)
					if not pos then
						return old(...)
					end
					local offsetpos = pos + (projmeta.projectile == "owl_projectile" and Vector3.zero or projmeta.fromPositionOffset)
					local playerGravity = workspace.Gravity
					local newlook = CFrame.new(offsetpos,plr[TargetPart.Value].Position) * CFrame.new(projmeta.projectile == "owl_projectile" and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX,bedwars.BowConstantsTable.RelY,bedwars.BowConstantsTable.RelZ))
					local calc
					if BA.Enabled then
						if Ping.Enabled then
							calc = prediction.SolveTrajectory(newlook.p,projSpeed,gravity,plr[TargetPart.Value].Position,plr[TargetPart.Value].Velocity,playerGravity,plr.HipHeight,plr.Jumping and 42.6 or nil,rayCheck,plr,plr[TargetPart.Value])
						else
							calc = prediction.SolveTrajectory(newlook.p,projSpeed,gravity,plr[TargetPart.Value].Position,plr[TargetPart.Value].Velocity,playerGravity,plr.HipHeight,plr.Jumping and 42.6 or nil,rayCheck)
						end
					else
						calc = oldpred.SolveTrajectory(newlook.p,projSpeed,gravity,plr[TargetPart.Value].Position,plr[TargetPart.Value].Velocity,playerGravity,	plr.HipHeight,	plr.Jumping and 42.6 or nil,rayCheck)
					end
					if not calc then
						return old(...)
					end
					local HC = HitChance.Value >= 100 and 0 or ((HitChance.Value / 500) + math.random(1,3) + math.random())
					local DDS = AutoCharge.Enabled and ((ChargePercent.Value / 100) * 0.58) or 5
					return {
						initialVelocity = CFrame.new(newlook.Position, calc).LookVector * projSpeed,
						positionFrom = offsetpos,
						deltaT = lifetime - HC,
						gravitationalAcceleration = gravity,
						drawDurationSeconds = DDS
					}
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = old

				if vanessaOLD then
					bedwars.TripleShotProjectileController.getChargeTime = vanessaOLD
				end

				if lumenOLD.MAX then
					local balance = require(game:GetService("ReplicatedStorage").TS.games.bedwars.kit.kits.lumen["lumen-balance"]).LumenBalance
					balance.MAX_CHARGE_TIME = lumenOLD.MAX
					balance.MIN_CHARGE_TIME = lumenOLD.MIN
				end

				if oldFireRates.old then
					
					for _, item in pairs(bedwars.ItemMeta) do
						if item.projectileSource and oldFireRates.fireRate[item] then
							local originalDelay = oldFireRates.fireRate[item]
							item.projectileSource.fireDelaySec = originalDelay
							oldFireRates.fireRate[item] = nil
						end
					end
				end
			end
		end,
		Tooltip = "Silently adjusts your aim towards the enemy"
	})

	Ping = ProjectileAimbot:CreateToggle({
		Name = "Ping Compensation",
		Default = true,
		Darker = true
	})

	BA = ProjectileAimbot:CreateToggle({
		Name = "Better Predictions",
		Default = true,
		Function = function(v)
			Ping.Object.Visible = v
		end
	})
	Targets = ProjectileAimbot:CreateTargets({
		Players = true,
		Walls = true
	})
	TargetPart = ProjectileAimbot:CreateDropdown({
		Name = "Part",
		List = {"RootPart", "Head"}
	})
	FOV = ProjectileAimbot:CreateSlider({
		Name = "FOV",
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	OtherProjectiles = ProjectileAimbot:CreateToggle({
		Name = "Other Projectiles",
		Default = true
	})
	Blacklist = ProjectileAimbot:CreateTextList({
		Name = "Blacklist",
		Darker = true,
		Default = {"telepearl", "glue_projectile"}
	})
	HitChance = ProjectileAimbot:CreateSlider({
		Name = "Hit Chance",
		Min = 0,
		Max = 100,
		Default = 100
	})
	ChargePercent = ProjectileAimbot:CreateSlider({
		Name = "Charge Percent",
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = "%",
		Visible = false,
		Darker = true
	})
	AutoCharge = ProjectileAimbot:CreateToggle({
		Name = "Auto Charge",
		Default = false,
		Function = function(v)
			ChargePercent.Object.Visible = v
		end
	})
	SlowSpeed = ProjectileAimbot:CreateSlider({
		Name = "Slow Speed",
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = "%",
		Visible = false,
		Darker = true,
		Tooltip = '100% = full speed when ur charging ur bow 0% = normal speed when ur charging ur bow '
	})
	Slowdown = ProjectileAimbot:CreateToggle({
		Name = "Slowdown",
		Default = false,
		Function = function(cb)
			SlowSpeed.Object.Visible = cb
		end
	})
	ForestPriority = ProjectileAimbot:CreateToggle({
		Name = "Forest Priority",
		Default = false
	})
	Rate = ProjectileAimbot:CreateSlider({
		Name = "Rate",
		Min = 0,
		Max = 1,
		Default = 0.1,
		Decimal = 100,
		Suffix = 's',
		Tooltip = 'how fast the bow will be in cooldown',
		Visible = false,
		Darker = true,
	})
	FireRate = ProjectileAimbot:CreateToggle({
		Name = "Fire Rate",
		Default = false,
		Function = function(cb)
			Rate.Object.Visible = cb
			if not cb then
				for _, item in pairs(bedwars.ItemMeta) do
					if item.projectileSource and oldFireRates.fireRate[item] then
						local originalDelay = oldFireRates.fireRate[item]
						item.projectileSource.fireDelaySec = originalDelay
						oldFireRates.fireRate[item] = nil
					end
				end
			end
		end
	})
end)

	
run(function()
	local ProjectileAura
	local Targets
	local Range
	local List
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	local projectileRemote = {InvokeServer = function() end}
	local FireDelays = {}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	
	local function getAmmo(check)
		for _, item in store.inventory.inventory.items do
			if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
				return item.itemType
			end
		end
	end
	
	local function getProjectiles()
		local items = {}
		for _, item in store.inventory.inventory.items do
			local proj = bedwars.ItemMeta[item.itemType].projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo and table.find(List.ListEnabled, ammo) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
		return items
	end
	
	ProjectileAura = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAura',
		Function = function(callback)
			if callback then
				repeat
					if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.5 then
						local ent = entitylib.EntityPosition({
							Part = 'RootPart',
							Range = Range.Value,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Wallcheck = Targets.Walls.Enabled
						})
	
						if ent then
							local pos = entitylib.character.RootPart.Position
							for _, data in getProjectiles() do
								local item, ammo, projectile, itemMeta = unpack(data)
								if (FireDelays[item.itemType] or 0) < tick() then
									rayCheck.FilterDescendantsInstances = {workspace.Map}
									local meta = bedwars.ProjectileMeta[projectile]
									local projSpeed, gravity = meta.launchVelocity, meta.gravitationalAcceleration or 196.2
									local calc = prediction.SolveTrajectory(pos, projSpeed, gravity, ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, ent.Jumping and 42.6 or nil, rayCheck)
									if calc then
										targetinfo.Targets[ent] = tick() + 1
										local switched = switchItem(item.tool)
	
										task.spawn(function()
											local dir, id = CFrame.lookAt(pos, calc).LookVector, httpService:GenerateGUID(true)
											local shootPosition = (CFrame.new(pos, calc) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
											bedwars.ProjectileController:createLocalProjectile(meta, ammo, projectile, shootPosition, id, dir * projSpeed, {drawDurationSeconds = 1})
											local res = PR:InvokeServer(item.tool, meta, shootPosition, dir * projSpeed)
											if not res then
												FireDelays[item.itemType] = tick()
											else
												local shoot = itemMeta.launchSound
												shoot = shoot and shoot[math.random(1, #shoot)] or nil
												if shoot then
													bedwars.SoundManager:playSound(shoot)
												end
											end
										end)
	
										FireDelays[item.itemType] = tick() + itemMeta.fireDelaySec
										if switched then
											task.wait(0.05)
										end
									end
								end
							end
						end
					end
					task.wait(0.1)
				until not ProjectileAura.Enabled
			end
		end,
		Tooltip = 'Shoots people around you'
	})
	Targets = ProjectileAura:CreateTargets({
		Players = true,
		Walls = true
	})
	List = ProjectileAura:CreateTextList({
		Name = 'Projectiles',
		Default = {'arrow', 'snowball'}
	})
	Range = ProjectileAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 50,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	

	
run(function()
	local BedESP
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function Added(bed)
		if not BedESP.Enabled then return end
		local BedFolder = Instance.new('Folder')
		BedFolder.Parent = Folder
		Reference[bed] = BedFolder
		local parts = bed:GetChildren()
		table.sort(parts, function(a, b)
			return a.Name > b.Name
		end)
	
		for _, part in parts do
			if part:IsA('BasePart') and part.Name ~= 'Blanket' then
				local handle = Instance.new('BoxHandleAdornment')
				handle.Size = part.Size + Vector3.new(.01, .01, .01)
				handle.AlwaysOnTop = true
				handle.ZIndex = 2
				handle.Visible = true
				handle.Adornee = part
				handle.Color3 = part.Color
				if part.Name == 'Legs' then
					handle.Color3 = Color3.fromRGB(167, 112, 64)
					handle.Size = part.Size + Vector3.new(.01, -1, .01)
					handle.CFrame = CFrame.new(0, -0.4, 0)
					handle.ZIndex = 0
				end
				handle.Parent = BedFolder
			end
		end
	
		table.clear(parts)
	end
	
	BedESP = vape.Categories.Render:CreateModule({
		Name = 'BedESP',
		Function = function(callback)
			if callback then
				BedESP:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(function(bed)
					task.delay(0.2, Added, bed)
				end))
				BedESP:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(bed)
					if Reference[bed] then
						Reference[bed]:Destroy()
						Reference[bed] = nil
					end
				end))
				for _, bed in collectionService:GetTagged('bed') do
					Added(bed)
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Render Beds through walls'
	})
end)
	
run(function()
	local Health
	
	Health = vape.Categories.Render:CreateModule({
		Name = 'Health',
		Function = function(callback)
			if callback then
				local label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(100, 20)
				label.Position = UDim2.new(0.5, 6, 0.5, 30)
				label.BackgroundTransparency = 1
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
				label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				label.TextSize = 18
				label.Font = Enum.Font.Arial
				label.Parent = vape.gui
				Health:Clean(label)
				Health:Clean(vapeEvents.AttributeChanged.Event:Connect(function()
					label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
					label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				end))
			end
		end,
		Tooltip = 'Displays your health in the center of your screen.'
	})
end)

run(function()
	local NameTags
	local Targets
	local Color
	local Background
	local DisplayName
	local Health
	local Distance
	local Equipment
	local DrawingToggle
	local Scale
	local FontOption
	local Teammates
	local DistanceCheck
	local DistanceLimit
	local Strings, Sizes, Reference = {}, {}, {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	local methodused
	local Added = {
		Normal = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
			local nametag = Instance.new('TextLabel')
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
			end
	
			if Distance.Enabled then
				Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
			end
	
			if Equipment.Enabled then
				for i, v in {'Hand', 'Helmet', 'Chestplate', 'Boots', 'Kit'} do
					local Icon = Instance.new('ImageLabel')
					Icon.Name = v
					Icon.Size = UDim2.fromOffset(30, 30)
					Icon.Position = UDim2.fromOffset(-60 + (i * 30), -30)
					Icon.BackgroundTransparency = 1
					Icon.Image = ''
					Icon.Parent = nametag
				end
			end
	
			nametag.TextSize = 14 * Scale.Value
			nametag.FontFace = FontOption.Value
			local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
			nametag.Name = ent.Player and ent.Player.Name or ent.Character.Name
			nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
			nametag.AnchorPoint = Vector2.new(0.5, 1)
			nametag.BackgroundColor3 = Color3.new()
			nametag.BackgroundTransparency = Background.Value
			nametag.BorderSizePixel = 0
			nametag.Visible = false
			nametag.Text = Strings[ent]
			nametag.TextColor3 = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.RichText = true
			nametag.Parent = Folder
			Reference[ent] = nametag
		end,
		Drawing = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
			local nametag = {}
			nametag.BG = Drawing.new('Square')
			nametag.BG.Filled = true
			nametag.BG.Transparency = 1 - Background.Value
			nametag.BG.Color = Color3.new()
			nametag.BG.ZIndex = 1
			nametag.Text = Drawing.new('Text')
			nametag.Text.Size = 15 * Scale.Value
			nametag.Text.Font = 0
			nametag.Text.ZIndex = 2
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
			end
	
			if Distance.Enabled then
				Strings[ent] = '[%s] '..Strings[ent]
			end
	
			nametag.Text.Text = Strings[ent]
			nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			Reference[ent] = nametag
		end
	}
	
	local Removed = {
		Normal = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				v:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				for _, obj in v do
					pcall(function()
						obj.Visible = false
						obj:Remove()
					end)
				end
			end
		end
	}
	
	local Updated = {
		Normal = function(ent)
			local nametag = Reference[ent]
			if nametag then
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
					Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
				end
	
				if Distance.Enabled then
					Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
				end
	
				if Equipment.Enabled and store.inventories[ent.Player] then
					local kit = ent.Player:GetAttribute('PlayingAsKits')
					local inventory = store.inventories[ent.Player]
					nametag.Hand.Image = bedwars.getIcon(inventory.hand or {itemType = ''}, true)
					nametag.Helmet.Image = bedwars.getIcon(inventory.armor[1] or {itemType = ''}, true)
					nametag.Chestplate.Image = bedwars.getIcon(inventory.armor[2] or {itemType = ''}, true)
					nametag.Boots.Image = bedwars.getIcon(inventory.armor[3] or {itemType = ''}, true)
					nametag.Kit.Image = bedwars.BedwarsKitMeta[kit].renderImage or bedwars.BedwarsKitMeta.none.renderImage
					--[[local FetchRank = bedwars.Client:Get("FetchRanks"):CallServerAsync({ent.Player.UserId}):andThen(function(self)
						self = self[1]
						local division = -1
						if self.rankDivision then
							division = self.rankDivision
						end
						local CurrentRank = 'RANDOM_KIT_RENDER'
						if division >= 0 and division <= 3 then
							CurrentRank = 'BRONZE_RANK'
						elseif division >= 4 and division <= 7 then
							CurrentRank = 'SILVER_RANK'
						elseif division >= 8 and division <= 11 then
							CurrentRank = 'GOLD_RANK'
						elseif division >= 12 and division <= 15 then
							CurrentRank = 'PLATINUM_RANK'
						elseif division >= 16 and division <= 19 then
							CurrentRank = 'DIAMOND_RANK'
						elseif division >= 20 and division <= 23 then
							CurrentRank = 'EMERALD_RANK'
						elseif division == 24 then
							CurrentRank = 'NIGHTMARE_RANK'
						else
							CurrentRank = 'RANDOM_KIT_RENDER'
						end
						local image = require(replicatedStorage.TS.image['image-id']).BedwarsImageId
						print(image[CurrentRank])
					end)--]]
					
				end
	
				local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
				nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
				nametag.Text = Strings[ent]
			end
		end,
		Drawing = function(ent)
			local nametag = Reference[ent]
			if nametag then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
				end
	
				if Distance.Enabled then
					Strings[ent] = '[%s] '..Strings[ent]
					nametag.Text.Text = entitylib.isAlive and string.format(Strings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or Strings[ent]
				else
					nametag.Text.Text = Strings[ent]
				end
	
				nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
				nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			end
		end
	}
	
	local ColorFunc = {
		Normal = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.TextColor3 = entitylib.getEntityColor(i) or color
			end
		end,
		Drawing = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.Text.Color = entitylib.getEntityColor(i) or color
			end
		end
	}
	
	local Loop = {
		Normal = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						nametag.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text = string.format(Strings[ent], mag)
						local ize = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
						nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
			end
		end,
		Drawing = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						nametag.Text.Visible = false
						nametag.BG.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Text.Visible = headVis
				nametag.BG.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text.Text = string.format(Strings[ent], mag)
						nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.BG.Position = Vector2.new(headPos.X - (nametag.BG.Size.X / 2), headPos.Y - nametag.BG.Size.Y)
				nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 3)
			end
		end
	}
	
	NameTags = vape.Categories.Render:CreateModule({
		Name = 'NameTags',
		Function = function(callback)
			if callback then
				methodused = DrawingToggle.Enabled and 'Drawing' or 'Normal'
				if Removed[methodused] then
					NameTags:Clean(entitylib.Events.EntityRemoved:Connect(function(ent)
						Removed[methodused](ent)
					end))
				end
				if Added[methodused] then
					for _, v in entitylib.List do
						if Reference[v] then
							Removed[methodused](v)
						end
						Added[methodused](v)
					end
					NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
						if Reference[ent] then
							Removed[methodused](ent)
						end
						Added[methodused](ent)
					end))
				end
				if Updated[methodused] then
					NameTags:Clean(entitylib.Events.EntityUpdated:Connect(function(ent)
						Updated[methodused](ent)
					end))
					for _, v in entitylib.List do
						Updated[methodused](v)
					end
				end
				if ColorFunc[methodused] then
					NameTags:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(function()
						ColorFunc[methodused](Color.Hue, Color.Sat, Color.Value)
					end))
				end
				if Loop[methodused] then
					NameTags:Clean(runService.RenderStepped:Connect(function()
						Loop[methodused]()
					end))
				end
			else
				if Removed[methodused] then
					for i in Reference do
						Removed[methodused](i)
					end
				end
			end
		end,
		Tooltip = 'Renders nametags on entities through walls.'
	})
	Targets = NameTags:CreateTargets({
		Players = true,
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	FontOption = NameTags:CreateFont({
		Name = 'Font',
		Blacklist = 'Arial',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Color = NameTags:CreateColorSlider({
		Name = 'Player Color',
		Function = function(hue, sat, val)
			if NameTags.Enabled and ColorFunc[methodused] then
				ColorFunc[methodused](hue, sat, val)
			end
		end
	})
	Scale = NameTags:CreateSlider({
		Name = 'Scale',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10
	})
	Background = NameTags:CreateSlider({
		Name = 'Transparency',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 10
	})
	Health = NameTags:CreateToggle({
		Name = 'Health',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Distance = NameTags:CreateToggle({
		Name = 'Distance',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Equipment = NameTags:CreateToggle({
		Name = 'Equipment',
		Default = true,
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	DisplayName = NameTags:CreateToggle({
		Name = 'Use Displayname',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	Teammates = NameTags:CreateToggle({
		Name = 'Teammates',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	DrawingToggle = NameTags:CreateToggle({
		Name = 'Drawing',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
	})
	DistanceCheck = NameTags:CreateToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Object.Visible = callback
		end
	})
	DistanceLimit = NameTags:CreateTwoSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		DefaultMin = 0,
		DefaultMax = 64,
		Darker = true,
		Visible = false
	})
end)
	
run(function()
	local StorageESP
	local Amount
	local TeamCheck
	local Notify
	local List
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	local BlockImages = {}

	local function nearStorageItem(item)
		for _, v in List.ListEnabled do
			if item:find(v) then return v end
		end
	end
	
	local function refreshAdornee(v)
		local chest = v.Adornee:FindFirstChild('ChestFolderValue')
		chest = chest and chest.Value or nil
		if not chest then
			v.Enabled = false
			return
		end
	
		local chestitems = chest and chest:GetChildren() or {}
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		v.Enabled = false
		local alreadygot = {}
		for _, item in chestitems do
			if not alreadygot[item.Name] and (table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new('ImageLabel')
				blockimage.Size = UDim2.fromOffset(32, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
				BlockImages[item] = blockimage
			end
			if Amount.Enabled then
				if not BlockImages[item] then return end
				local amount = item:GetAttribute('Amount') or 0
				if amount > 1 then
					local countLabel = Instance.new('TextLabel')
					countLabel.Size = UDim2.fromScale(1, 1)
					countLabel.BackgroundTransparency = 1
					countLabel.Text = tostring(amount)
					countLabel.TextColor3 = Color3.new(1, 1, 1)
					countLabel.TextStrokeTransparency = 0
					countLabel.TextScaled = true
					countLabel.Font = Enum.Font.GothamBold
					countLabel.Parent = BlockImages[item]
				end
			end
		end
		table.clear(chestitems)
	end
	
	local function Added(v)
		local chest = v:WaitForChild('ChestFolderValue', 3)
		if not (chest and StorageESP.Enabled) then return end
		chest = chest.Value
		if TeamCheck.Enabled then
			local currentTeam = v:GetAttribute('Team') or 0
			local lplrTeam = lplr.Character:GetAttribute('Team') or -1
			if currentTeam == lplrTeam then
				return
			end
		end		
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'chest'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		StorageESP:Clean(chest.ChildAdded:Connect(function(item)
			if Notify.Enabled then
				vape:CreateNotification("StorageESP",`New object is added {item.Name}`,6)
			end
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		StorageESP:Clean(chest.ChildRemoved:Connect(function(item)
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		task.spawn(refreshAdornee, billboard)
	end
	
	StorageESP = vape.Categories.Render:CreateModule({
		Name = 'StorageESP',
		Function = function(callback)
			if callback then
				StorageESP:Clean(collectionService:GetInstanceAddedSignal('chest'):Connect(Added))
				for _, v in collectionService:GetTagged('chest') do


					task.spawn(Added, v)
				end
			else
				table.clear(Reference)
				table.clear(BlockImages)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays items in chests'
	})
	Notify = StorageESP:CreateToggle({
		Name = "Notify",
		Default = false
	})

	TeamCheck = StorageESP:CreateToggle({
		Name = "Team Check",
		Default = false
	})

	Amount = StorageESP:CreateToggle({
		Name = "Amount",
		Default = true
	})	

	List = StorageESP:CreateTextList({
		Name = 'Item',
		Function = function()
			for _, v in Reference do
				task.spawn(refreshAdornee, v)
			end
		end
	})
	Background = StorageESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = StorageESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
	Loot = StorageESP:CreateToggle({
		Name = "Loot",
		Default = false,
		Tooltip = 'this shows how much loot is in iron or diamonds'
	})	
end)
	
run(function()
	local AutoBalloon
	
	AutoBalloon = vape.Categories.Utility:CreateModule({
		Name = 'AutoBalloon',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AutoBalloon.Enabled)
				if not AutoBalloon.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then 
						lowestpoint = point 
					end
				end
	
				repeat
					if entitylib.isAlive then
						if entitylib.character.RootPart.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) < 3 then
							local balloon = getItem('balloon')
							if balloon then
								for _ = 1, 3 do 
									bedwars.BalloonController:inflateBalloon() 
								end
							end
							task.wait(0.1)
						end
					end
					task.wait(0.1)
				until not AutoBalloon.Enabled
			end
		end,
		Tooltip = 'Inflates when you fall into the void'
	})
end)
		

	

	

	

run(function()
	local AutoVoidDrop
	local OwlCheck
	
	AutoVoidDrop = vape.Categories.Utility:CreateModule({
		Name = 'AutoVoidDrop',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AutoVoidDrop.Enabled)
				if not AutoVoidDrop.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then
						lowestpoint = point
					end
				end
	
				repeat
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						if root.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) <= 0 and not getItem('balloon') then
							if not OwlCheck.Enabled or not root:FindFirstChild('OwlLiftForce') then
								for _, item in {'iron', 'diamond', 'emerald', 'gold'} do
									item = getItem(item)
									if item then
										item = bedwars.Client:Get(remotes.DropItem):CallServer({
											item = item.tool,
											amount = item.amount
										})
	
										if item then
											item:SetAttribute('ClientDropTime', tick() + 100)
										end
									end
								end
							end
						end
					end
	
					task.wait(0.1)
				until not AutoVoidDrop.Enabled
			end
		end,
		Tooltip = 'Drops resources when you fall into the void'
	})
	OwlCheck = AutoVoidDrop:CreateToggle({
		Name = 'Owl check',
		Default = true,
		Tooltip = 'Refuses to drop items if being picked up by an owl'
	})
end)
	
run(function()
	local MissileTP
	
	MissileTP = vape.Categories.Utility:CreateModule({
		Name = 'MissileTP',
		Function = function(callback)
			if callback then
				MissileTP:Toggle()
				local plr = entitylib.EntityMouse({
					Range = 1000,
					Players = true,
					Part = 'RootPart'
				})
	
				if getItem('guided_missile') and plr then
					local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync('guided_missile'))
					if projectile then
						local projectilemodel = projectile.model
						if not projectilemodel.PrimaryPart then
							projectilemodel:GetPropertyChangedSignal('PrimaryPart'):Wait()
						end
	
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
						bodyforce.Name = 'AntiGravity'
						bodyforce.Parent = projectilemodel.PrimaryPart
	
						repeat
							projectile.model:SetPrimaryPartCFrame(CFrame.lookAlong(plr.RootPart.CFrame.p, gameCamera.CFrame.LookVector))
							task.wait(0.1)
						until not projectile.model or not projectile.model.Parent
					else
						notif('MissileTP', 'Missile on cooldown.', 3)
					end
				end
			end
		end,
		Tooltip = 'Spawns and teleports a missile to a player\nnear your mouse.'
	})
end)
	
run(function()
	local PickupRange
	local Range
	local Network
	local Lower
	
	PickupRange = vape.Categories.Utility:CreateModule({
		Name = 'PickupRange',
		Function = function(callback)
			if callback then
				local items = collection('ItemDrop', PickupRange)
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in items do
							if tick() - (v:GetAttribute('ClientDropTime') or 0) < 2 then continue end
							if isnetworkowner(v) and Network.Enabled and entitylib.character.Humanoid.Health > 0 then 
								v.CFrame = CFrame.new(localPosition - Vector3.new(0, 3, 0)) 
							end
							
							if (localPosition - v.Position).Magnitude <= Range.Value then
								if Lower.Enabled and (localPosition.Y - v.Position.Y) < (entitylib.character.HipHeight - 1) then continue end
								task.spawn(function()
									bedwars.Client:Get(remotes.PickupItem):CallServerAsync({
										itemDrop = v
									}):andThen(function(suc)
										if suc and bedwars.SoundList then
											bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											local sound = bedwars.ItemMeta[v.Name].pickUpOverlaySound
											if sound then
												bedwars.SoundManager:playSound(sound, {
													position = v.Position,
													volumeMultiplier = 0.9
												})
											end
										end
									end)
								end)
							end
						end
					end
					task.wait(0.1)
				until not PickupRange.Enabled
			end
		end,
		Tooltip = 'Picks up items from a farther distance'
	})
	Range = PickupRange:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 10,
		Default = 10,
		Suffix = function(val) 
			return val == 1 and 'stud' or 'studs' 
		end
	})
	Network = PickupRange:CreateToggle({
		Name = 'Network TP',
		Default = true
	})
	Lower = PickupRange:CreateToggle({Name = 'Feet Check'})
end)
	

run(function()
	local Expand
	local Tower
	local Downwards
	local Diagonal
	local LimitItem
	local Mouse
	local adjacent, lastpos, label = {}, Vector3.zero
	
	for x = -3, 3, 3 do
		for y = -3, 3, 3 do
			for z = -3, 3, 3 do
				local vec = Vector3.new(x, y, z)
				if vec ~= Vector3.zero then
					table.insert(adjacent, vec)
				end
			end
		end
	end
	
	local function nearCorner(poscheck, pos)
		local startpos = poscheck - Vector3.new(3, 3, 3)
		local endpos = poscheck + Vector3.new(3, 3, 3)
		local check = poscheck + (pos - poscheck).Unit * 100
		return Vector3.new(math.clamp(check.X, startpos.X, endpos.X), math.clamp(check.Y, startpos.Y, endpos.Y), math.clamp(check.Z, startpos.Z, endpos.Z))
	end
	
	local function blockProximity(pos)
		local mag, returned = 60
		local tab = getBlocksInPoints(bedwars.BlockController:getBlockPosition(pos - Vector3.new(21, 21, 21)), bedwars.BlockController:getBlockPosition(pos + Vector3.new(21, 21, 21)))
		for _, v in tab do
			local blockpos = nearCorner(v, pos)
			local newmag = (pos - blockpos).Magnitude
			if newmag < mag then
				mag, returned = newmag, blockpos
			end
		end
		table.clear(tab)
		return returned
	end
	
	local function checkAdjacent(pos)
		for _, v in adjacent do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end
	
	local function getScaffoldBlock()
		if store.hand.toolType == 'block' then
			return store.hand.tool.Name, store.hand.amount
		elseif (not LimitItem.Enabled) then
			local wool, amount = getWool()
			if wool then
				return wool, amount
			else
				for _, item in store.inventory.inventory.items do
					if bedwars.ItemMeta[item.itemType].block then
						return item.itemType, item.amount
					end
				end
			end
		end
	
		return nil, 0
	end
	
	Scaffold = vape.Categories.Utility:CreateModule({
		Name = 'Scaffold',
		Function = function(callback)
			if label then
				label.Visible = callback
			end
	
			if callback then
				repeat
					if entitylib.isAlive then
						local wool, amount = getScaffoldBlock()
	
						if Mouse.Enabled then
							if not inputService:IsMouseButtonPressed(0) then
								wool = nil
							end
						end
	
						if label then
							amount = amount or 0
							label.Text = amount..' <font color="rgb(170, 170, 170)">(Scaffold)</font>'
							label.TextColor3 = Color3.fromHSV((amount / 128) / 2.8, 0.86, 1)
						end
	
						if wool then
							local root = entitylib.character.RootPart
							if Tower.Enabled and inputService:IsKeyDown(Enum.KeyCode.Space) and (not inputService:GetFocusedTextBox()) then
								root.Velocity = Vector3.new(root.Velocity.X, 38, root.Velocity.Z)
							end
	
							for i = Expand.Value, 1, -1 do
								local currentpos = roundPos(root.Position - Vector3.new(0, entitylib.character.HipHeight + (Downwards.Enabled and inputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4.5 or 1.5), 0) + entitylib.character.Humanoid.MoveDirection * (i * 3))
								if Diagonal.Enabled then
									if math.abs(math.round(math.deg(math.atan2(-entitylib.character.Humanoid.MoveDirection.X, -entitylib.character.Humanoid.MoveDirection.Z)) / 45) * 45) % 90 == 45 then
										local dt = (lastpos - currentpos)
										if ((dt.X == 0 and dt.Z ~= 0) or (dt.X ~= 0 and dt.Z == 0)) and ((lastpos - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
											currentpos = lastpos
										end
									end
								end
	
								local block, blockpos = getPlacedBlock(currentpos)
								if not block then
									blockpos = checkAdjacent(blockpos * 3) and blockpos * 3 or blockProximity(currentpos)
									if blockpos then
										task.spawn(bedwars.placeBlock, blockpos, wool, false)
									end
								end
								lastpos = currentpos
							end
						end
					end
	
					task.wait(0.03)
				until not Scaffold.Enabled
			else
				Label = nil
			end
		end,
		Tooltip = 'Helps you make bridges/scaffold walk.'
	})
	Expand = Scaffold:CreateSlider({
		Name = 'Expand',
		Min = 1,
		Max = 6
	})
	Tower = Scaffold:CreateToggle({
		Name = 'Tower',
		Default = true
	})
	Downwards = Scaffold:CreateToggle({
		Name = 'Downwards',
		Default = true
	})
	Diagonal = Scaffold:CreateToggle({
		Name = 'Diagonal',
		Default = true
	})
	LimitItem = Scaffold:CreateToggle({Name = 'Limit to items'})
	Mouse = Scaffold:CreateToggle({Name = 'Require mouse down'})
	Count = Scaffold:CreateToggle({
		Name = 'Block Count',
		Function = function(callback)
			if callback then
				label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(100, 20)
				label.Position = UDim2.new(0.5, 6, 0.5, 60)
				label.BackgroundTransparency = 1
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Text = '0'
				label.TextColor3 = Color3.new(0, 1, 0)
				label.TextSize = 18
				label.RichText = true
				label.Font = Enum.Font.Arial
				label.Visible = Scaffold.Enabled
				label.Parent = vape.gui
			else
				label:Destroy()
				label = nil
			end
		end
	})
end)


run(function()
    local ShopTierBypass
    local tiered, nexttier = {}, {}
    local originalGetShop
    local shopItemsTracked = {}
    
    local function applyBypassToItem(item)
        if item and type(item) == "table" then
            if not tiered[item] then 
                tiered[item] = item.tiered 
            end
            if not nexttier[item] then 
                nexttier[item] = item.nextTier 
            end
            item.nextTier = nil
            item.tiered = nil
            shopItemsTracked[item] = true
        end
    end
    
    local function applyBypassToTable(tbl)
        if tbl and type(tbl) == "table" then
            for _, item in pairs(tbl) do
                if type(item) == "table" then
                    applyBypassToItem(item)
                end
            end
        end
    end
    
    local function getShopController()
        local success, result = pcall(function()
            local RuntimeLib = require(game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
            if RuntimeLib then
                return RuntimeLib.import(script, game:GetService("ReplicatedStorage"), "TS", "games", "bedwars", "shop", "bedwars-shop")
            end
        end)
        
        if success then
            return result
        end
        
        local shopModule = game:GetService("ReplicatedStorage"):FindFirstChild("TS"):FindFirstChild("games"):FindFirstChild("bedwars"):FindFirstChild("shop"):FindFirstChild("bedwars-shop")
        if shopModule and shopModule:IsA("ModuleScript") then
            return require(shopModule)
        end
        
        return nil
    end
    
    ShopTierBypass = vape.Categories.Utility:CreateModule({
        Name = 'ShopTierBypass',
        Function = function(callback)
            if callback then
                repeat task.wait() until store.shopLoaded or not ShopTierBypass.Enabled
                if ShopTierBypass.Enabled then
                    for _, v in pairs(bedwars.Shop.ShopItems) do
                        tiered[v] = v.tiered
                        nexttier[v] = v.nextTier
                        v.nextTier = nil
                        v.tiered = nil
                        shopItemsTracked[v] = true
                    end
                    
                    if bedwars.Shop.getShop and not originalGetShop then
                        originalGetShop = bedwars.Shop.getShop
                        bedwars.Shop.getShop = function(...)
                            local result = originalGetShop(...)
                            
                            if type(result) == "table" then
                                applyBypassToTable(result)
                            end
                            
                            return result
                        end
                    end
                    
                    local shopController = getShopController()
                    if shopController and shopController.BedwarsShop and shopController.BedwarsShop.getShop then
                        if not tiered["shopControllerHooked"] then
                            tiered["shopControllerHooked"] = true
                            local originalControllerGetShop = shopController.BedwarsShop.getShop
                            shopController.BedwarsShop.getShop = function(...)
                                local result = originalControllerGetShop(...)
                                if type(result) == "table" then
                                    applyBypassToTable(result)
                                end
                                return result
                            end
                        end
                    end
                end
            else
                for item, _ in pairs(shopItemsTracked) do
                    if item and type(item) == "table" then
                        if tiered[item] ~= nil then
                            item.tiered = tiered[item]
                        end
                        if nexttier[item] ~= nil then
                            item.nextTier = nexttier[item]
                        end
                    end
                end
                
                if tiered["shopControllerHooked"] then
                    local shopController = getShopController()
                    if shopController and shopController.BedwarsShop and shopController.BedwarsShop.getShop then
                    end
                    tiered["shopControllerHooked"] = nil
                end
                
                if originalGetShop then
                    bedwars.Shop.getShop = originalGetShop
                    originalGetShop = nil
                end
                
                table.clear(tiered)
                table.clear(nexttier)
                table.clear(shopItemsTracked)
            end
        end,
        Tooltip = 'Lets you buy things like armor and tools early.'
    })
end)


run(function()
	local StaffDetector
	local Mode
	local LeaveDetection
	local ImpossibleJoinsTBL = {}
	local Clans
	local Party
	local Profile
	local Users
	local blacklistedclans = {'gg', 'gg2', 'DV', 'DV2'}
	local blacklisteduserids = {1502104539, 3826146717, 4531785383, 1049767300, 4926350670, 653085195, 184655415, 2752307430, 5087196317, 5744061325, 1536265275}
	local joined = {}
	
	local function getRole(plr, id)
		local suc, res = pcall(function()
			return plr:GetRankInGroup(id)
		end)
		if not suc then
			notif('StaffDetector', res, 30, 'alert')
		end
		return suc and res or 0
	end
	
	local function staffFunction(plr, checktype)
		if not vape.Loaded then
			repeat task.wait(0.1) until vape.Loaded
		end
	
		notif('StaffDetector', 'Staff Detected ('..checktype..'): '..plr.Name..' ('..plr.UserId..')', 60, 'alert')
		whitelist.customtags[plr.Name] = {{text = 'GAME STAFF', color = Color3.new(1, 0, 0)}}
		if LeaveDetection.Enabled then
			ImpossibleJoinsTBL[plr] = true
		end
		if Party.Enabled and not checktype:find('clan') then
			bedwars.PartyController:leaveParty()
		end
	
		if Mode.Value == 'Uninject' then
			task.spawn(function()
				vape:Uninject()
			end)
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'StaffDetector',
				Text = 'Staff Detected ('..checktype..')\n'..plr.Name..' ('..plr.UserId..')',
				Duration = 60,
			})
		elseif Mode.Value == 'Requeue' then
			bedwars.QueueController:joinQueue(store.queueType)
		elseif Mode.Value == 'Profile' then
			vape.Save = function() end
			if vape.Profile ~= Profile.Value then
				vape:Load(true, Profile.Value)
			end
		elseif Mode.Value == 'AutoConfig' then
			local safe = {'AutoClicker', 'Reach', 'Sprint', 'HitFix', 'StaffDetector'}
			vape.Save = function() end
			for i, v in vape.Modules do
				if not (table.find(safe, i) or v.Category == 'Render') then
					if v.Enabled then
						v:Toggle()
					end
					v:SetBind('')
				end
			end
		end
		StaffDetector:Clean(playersService.PlayerRemoving:Connect(function(p)
			if LeaveDetection.Enabled then
				if ImpossibleJoinsTBL[p] then
					ImpossibleJoinsTBL[p] = nil
					notif('StaffDetector', `Staff {p.Name} ({checktype}) has just left.`, 10,'warning')
				end
			end
		end))
	end
	
	local function checkFriends(list)
		for _, v in list do
			if joined[v] then
				return joined[v]
			end
		end
		return nil
	end
	
	local function checkJoin(plr, connection)
		if not plr:GetAttribute('Team') and plr:GetAttribute('Spectator') and not bedwars.Store:getState().Game.customMatch then
			connection:Disconnect()
			local tab, pages = {}, playersService:GetFriendsAsync(plr.UserId)
			for _ = 1, 56 do
				for _, v in pages:GetCurrentPage() do
					table.insert(tab, v.Id)
				end
				if pages.IsFinished then break end
				pages:AdvanceToNextPageAsync()
			end
	
			local friend = checkFriends(tab)
			if not friend then
				staffFunction(plr, 'impossible_join')
				return true
			else
				notif('StaffDetector', string.format('Spectator %s joined from %s', plr.Name, friend), 20, 'warning')
			end
		end
	end
	
	local function playerAdded(plr)
		joined[plr.UserId] = plr.Name
		if plr == lplr then return end
	
		if table.find(blacklisteduserids, plr.UserId) or table.find(Users.ListEnabled, tostring(plr.UserId)) then
			staffFunction(plr, 'blacklisted_user')
		elseif getRole(plr, 5774246) >= 100 then
			staffFunction(plr, 'staff_role')
		else
			local connection
			connection = plr:GetAttributeChangedSignal('Spectator'):Connect(function()
				checkJoin(plr, connection)
			end)
			StaffDetector:Clean(connection)
			if checkJoin(plr, connection) then
				return
			end
	
			if not plr:GetAttribute('ClanTag') then
				plr:GetAttributeChangedSignal('ClanTag'):Wait()
			end
	
			if table.find(blacklistedclans, plr:GetAttribute('ClanTag')) and vape.Loaded and Clans.Enabled then
				connection:Disconnect()
				staffFunction(plr, 'blacklisted_clan_'..plr:GetAttribute('ClanTag'):lower())
			end
		end
	end
	
	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then
				StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
				for _, v in playersService:GetPlayers() do
					task.spawn(playerAdded, v)
				end
			else
				table.clear(joined)
			end
		end,
		Tooltip = 'Detects people with a staff rank ingame'
	})
	Mode = StaffDetector:CreateDropdown({
		Name = 'Mode',
		List = {'Notify', 'Profile', 'Requeue', 'AutoConfig', 'Uninject'},
		Function = function(val)
			if Profile.Object then
				Profile.Object.Visible = val == 'Profile'
			end
		end
	})
	Clans = StaffDetector:CreateToggle({
		Name = 'Blacklist clans',
		Default = false
	})
	Party = StaffDetector:CreateToggle({
		Name = 'Leave party'
	})
	Profile = StaffDetector:CreateTextBox({
		Name = 'Profile',
		Default = 'default',
		Darker = true,
		Visible = false
	})
	Users = StaffDetector:CreateTextList({
		Name = 'Users',
		Placeholder = 'player (userid)'
	})
	LeaveDetection = StaffDetector:CreateToggle({
		Name = 'Leave Detection',
		Tooltip = 'when an impossible/blacklisted/staff detection has happend and when they leave it notifs you.'
	})

end)
	
	
run(function()
	local afk
	local Customize
	local Custom = {
		MovementTick = nil,
		Jumps = nil,
		JumpTick = nil,
		Movement = {
			X = 0,
			Y = 0,
			Z = 0
		}
	}
	afk = vape.Categories.World:CreateModule({
			Name = 'Anti-AFK',
			Function = function(callback)
				if callback then
					if not Customize.Enabled then
						for _, v in getconnections(lplr.Idled) do
							v:Disconnect()
						end
			
						for _, v in getconnections(runService.Heartbeat) do
							if type(v.Function) == 'function' and table.find(debug.getconstants(v.Function), remotes.AfkStatus) then
								v:Disconnect()
							end
						end
			
						repeat 
							bedwars.Client:Get(remotes.AfkStatus):SendToServer({
								afk = false
							}) 
							task.wait(0.001)
						until not afk.Enabled
					else
						task.spawn(function()
							local target
							repeat
								Custom.Movement.X = math.random(1,5)
								Custom.Movement.Y = math.random(1,5)
								Custom.Movement.Z = math.random(1,5)
								target = CFrame.new(Custom.Movement.X,Custom.Movement.Y,Custom.Movement.Z)
								lplr.Character.Humanoid:MoveTo(target.Position)
								task.wait(1 / Custom.MovementTick.GetRandomValue())
							until not afk.Enabled
						end)
						task.spawn(function()
							repeat
								if Custom.Jumps.Enabled then
									entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
								task.wait(1 / Custom.JumpTick.GetRandomValue())
							until not afk.Enabled
						end)					
						task.spawn(function()
							for _, v in getconnections(lplr.Idled) do
								v:Disconnect()
							end
				
							for _, v in getconnections(runService.Heartbeat) do
								if type(v.Function) == 'function' and table.find(debug.getconstants(v.Function), remotes.AfkStatus) then
									v:Disconnect()
								end
							end
				
							repeat 
								bedwars.Client:Get(remotes.AfkStatus):SendToServer({
									afk = false
								}) 
								task.wait(0.001)
							until not afk.Enabled
						end)
					end
				end
			end,
			Tooltip = 'Lets you stay ingame without getting kicked'
	})
	Custom.MovementTick = afk:CreateTwoSlider({
		Name = 'Movement Tick',
		Visible = false,
		Min = 2,
		Max = 10,
		DefaultMin = 5,
		DefaultMax = 8,
	})
	Custom.JumpTick = afk:CreateTwoSlider({
		Name = 'Jump Tick',
		Visible = false,
		Min = 2,
		Max = 10,
		DefaultMin = 5,
		DefaultMax = 8,
	})
	Custom.Jumps = afk:CreateToggle({
		Name = 'Jump',
		Visible = false,
		Default = false,
		Function = function()
			Custom.JumpTick.Object.Visible = Custom.Jumps.Enabled
		end
	})
	Customize = afk:CreateToggle({
		Name = 'Customize',
		Default = false,
		Function = function()
			Custom.MovementTick.Enabled = Customize.Enabled
			Custom.Jumps.Enabled = Customize.Enabled
		end
	})

end)
	

	
run(function()

	local old, event
	
	local function hotbarSwitchItem(block)
		if block and not block:GetAttribute('NoBreak') and not block:GetAttribute('Team'..(lplr:GetAttribute('Team') or 0)..'NoBreak') then
			local tool, slot = store.tools[bedwars.ItemMeta[block.Name].block.breakType], nil
			if tool then
				for i, v in store.inventory.hotbar do
					if v.item and v.item.itemType == tool.itemType then slot = i - 1 break end
				end
	
				if hotbarSwitch(slot) then
					if inputService:IsMouseButtonPressed(0) then 
						event:Fire() 
					end
					return true
				end
			end
		end
	end

	AutoTool = vape.Categories.World:CreateModule({
		Name = 'AutoTool',
		Function = function(callback)
			if callback then
				event = Instance.new('BindableEvent')
				AutoTool:Clean(event)
				AutoTool:Clean(event.Event:Connect(function()
					contextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
				end))
				old = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
					if hotbarSwitchItem(block and block.target and block.target.blockInstance or nil) then return end
					return old(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = old
				old = nil
			end
		end,
		Tooltip = 'Automatically selects the correct tool'
	})
end)
	
run(function()
	local ChestSteal
	local Range
	local Open
	local Skywars
	local Delay
	local Delays = {}
	local AnimPlayer
	local BoxColor
	local currentBox
	local currentStroke
	local currentChest
	local boxPart
	local Visualiser
	local function createBox(chest)
		if not boxPart then
			boxPart = Instance.new('Part')
			boxPart.Anchored = true
			boxPart.CanCollide = false
			boxPart.Transparency = 1
			boxPart.Size = chest.Size
			boxPart.CFrame = chest.CFrame
			boxPart.Parent = workspace
			local box = Instance.new('BoxHandleAdornment')
			box.Adornee = boxPart
			box.AlwaysOnTop = true
			box.Size = chest.Size + Vector3.new(0.1, 0.1, 0.1)
			box.Color3 = Color3.fromHSV(BoxColor.Hue, BoxColor.Sat, BoxColor.Value)
			box.Transparency = 1 - BoxColor.Opacity
			box.ZIndex = 10
			box.Parent = vape.gui
			local stroke = Instance.new('BoxHandleAdornment')
			stroke.Adornee = boxPart
			stroke.AlwaysOnTop = true
			stroke.Size = chest.Size + Vector3.new(0.3, 0.3, 0.3)
			stroke.Color3 = Color3.fromRGB(255, 255, 255)
			stroke.Transparency = 0.3
			stroke.ZIndex = 9
			stroke.Parent = vape.gui
			currentBox = box
			currentStroke = stroke
		else
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = tweenService:Create(boxPart, tweenInfo, {
				CFrame = chest.CFrame,
				Size = chest.Size
			})
			tween:Play()
			task.delay(0.3, function()
				if currentBox then
					currentBox.Size = chest.Size + Vector3.new(0.1, 0.1, 0.1)
				end
				if currentStroke then
					currentStroke.Size = chest.Size + Vector3.new(0.3, 0.3, 0.3)
				end
			end)
		end
	end
	
	local function lootChest(chest)
		chest = chest and chest.Value or nil
		local chestitems = chest and chest:GetChildren() or {}
		if #chestitems > 1 and (Delays[chest] or 0) < tick() then
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest:FindFirstChild("ChestFolderValue") and chest:FindFirstChild("ChestFolderValue").Value)
			Delays[chest] = tick() + (Delay.Value)
			if AnimPlayer.Enabled then bedwars.ChestController.playChestOpenAnimation(chest) end
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)
			for _, v in chestitems do
				if v:IsA('Accessory') then
					task.spawn(function()
						pcall(function()
							bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						end)
					end)
				end
				task.wait(Delay.Value)
			end
		end
	end

	ChestSteal = vape.Categories.World:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				local chests = collection('chest', ChestSteal)
				repeat task.wait(0.1) until store.queueType ~= 'bedwars_test'
				if (not Skywars.Enabled) or store.queueType:find('skywars') then
					repeat
						if entitylib.isAlive and store.matchState ~= 2 then
							if Open.Enabled then
								if bedwars.AppController:isAppOpen('ChestApp') then
									lootChest(lplr.Character:FindFirstChild('ObservedChestFolder'))
								end
							else
								local localPosition = entitylib.character.RootPart.Position
								local nearestChest = nil
								local nearestDistance = math.huge
								for _, v in chests do
									local distance = (localPosition - v.Position).Magnitude
									if distance <= Range.Value and distance < nearestDistance then
										nearestChest = v
										nearestDistance = distance
									end
								end
								if nearestChest then
									if nearestChest ~= currentChest then
										currentChest = nearestChest
										if Visualiser.Enabled then
											createBox(nearestChest)
										end
										lootChest(nearestChest:FindFirstChild('ChestFolderValue'))
									end
								elseif currentBox then
									currentBox:Destroy()
									if currentStroke then
										currentStroke:Destroy()
									end
									if boxPart then
										boxPart:Destroy()
									end
									currentBox = nil
									currentStroke = nil
									boxPart = nil
									currentChest = nil
								end
							end
						end
						task.wait(0.1)
					until not ChestSteal.Enabled
				end
			else
				if currentBox then
					currentBox:Destroy()
					currentBox = nil
				end
				if currentStroke then
					currentStroke:Destroy()
					currentStroke = nil
				end
				if boxPart then
					boxPart:Destroy()
					boxPart = nil
				end
				currentChest = nil
			end
		end,
		Tooltip = 'Grabs items from near chests.'
	})
	Range = ChestSteal:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Delay = ChestSteal:CreateSlider({
		Name = 'Delay',
		Min = 0.05,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Suffix = 's'
	})
	Visualiser = ChestSteal:CreateToggle({Name='Visualisers'})
	BoxColor = ChestSteal:CreateColorSlider({
		Name = 'Box Color',
		DefaultHue = 0.8,
		DefaultSat = 0.8,
		DefaultValue = 1,
		DefaultOpacity = 0.5
	})
	AnimPlayer = ChestSteal:CreateToggle({Name = 'Animation Player'})
	Open = ChestSteal:CreateToggle({Name = 'GUI Check'})
	Skywars = ChestSteal:CreateToggle({
		Name = 'Only Skywars',
		Function = function()
			if ChestSteal.Enabled then
				ChestSteal:Toggle()
				ChestSteal:Toggle()
			end
		end,
		Default = false
	})
end)
	

	

	
run(function()
	local AutoBuy
	local Sword
	local Armor
	local Upgrades
	local TierCheck
	local BedwarsCheck
	local GUI
	local SmartCheck
	local Custom = {}
	local CustomPost = {}
	local UpgradeToggles = {}
	local Functions, id = {}
	local Callbacks = {Custom, Functions, CustomPost}
	local npctick = tick()
	local swords = {
		'wood_sword',
		'stone_sword',
		'iron_sword',
		'diamond_sword',
		'emerald_sword'
	}
	
	local armors = {
		'none',
		'leather_chestplate',
		'iron_chestplate',
		'diamond_chestplate',
		'emerald_chestplate'
	}
	
	local axes = {
		'none',
		'wood_axe',
		'stone_axe',
		'iron_axe',
		'diamond_axe'
	}
	
	local pickaxes = {
		'none',
		'wood_pickaxe',
		'stone_pickaxe',
		'iron_pickaxe',
		'diamond_pickaxe'
	}
	
	local function getShopNPC()
		local shop, items, upgrades, newid = nil, false, false, nil
		if entitylib.isAlive then
			local localPosition = entitylib.character.RootPart.Position
			for _, v in store.shop do
				if (v.RootPart.Position - localPosition).Magnitude <= 20 then
					shop = v.Upgrades or v.Shop or nil
					upgrades = upgrades or v.Upgrades
					items = items or v.Shop
					newid = v.Shop and v.Id or newid
				end
			end
		end
		return shop, items, upgrades, newid
	end
	
	local function canBuy(item, currencytable, amount)
		amount = amount or 1
		if not currencytable[item.currency] then
			local currency = getItem(item.currency)
			currencytable[item.currency] = currency and currency.amount or 0
		end
		if item.ignoredByKit and table.find(item.ignoredByKit, store.equippedKit or '') then return false end
		if item.lockedByForge or item.disabled then return false end
		if item.require and item.require.teamUpgrade then
			if (bedwars.Store:getState().Bedwars.teamUpgrades[item.require.teamUpgrade.upgradeId] or -1) < item.require.teamUpgrade.lowestTierIndex then
				return false
			end
		end
		return currencytable[item.currency] >= (item.price * amount)
	end
	
	local function buyItem(item, currencytable)
		if not id then return end
		notif('AutoBuy', 'Bought '..bedwars.ItemMeta[item.itemType].displayName, 3)
		bedwars.Client:Get('BedwarsPurchaseItem'):CallServerAsync({
			shopItem = item,
			shopId = id
		}):andThen(function(suc)
			if suc then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.Store:dispatch({
					type = 'BedwarsAddItemPurchased',
					itemType = item.itemType
				})
				bedwars.BedwarsShopController.alreadyPurchasedMap[item.itemType] = true
			end
		end)
		currencytable[item.currency] -= item.price
	end
	
	local function buyUpgrade(upgradeType, currencytable)

		return
	end
	
	local function buyTool(tool, tools, currencytable)
		local bought, buyable = false
		tool = tool and table.find(tools, tool.itemType) and table.find(tools, tool.itemType) + 1 or math.huge
	
		for i = tool, #tools do
			local v = bedwars.Shop.getShopItem(tools[i], lplr)
			if canBuy(v, currencytable) then
				if SmartCheck.Enabled and bedwars.ItemMeta[tools[i]].breakBlock and i > 2 then
					if Armor.Enabled then
						local currentarmor = store.inventory.inventory.armor[2]
						currentarmor = currentarmor and currentarmor ~= 'empty' and currentarmor.itemType or 'none'
						if (table.find(armors, currentarmor) or 3) < 3 then break end
					end
					if Sword.Enabled then
						if store.tools.sword and (table.find(swords, store.tools.sword.itemType) or 2) < 2 then break end
					end
				end
				bought = true
				buyable = v
			end
			if TierCheck.Enabled and v.nextTier then break end
		end
	
		if buyable then
			buyItem(buyable, currencytable)
		end
	
		return bought
	end
	
	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.queueType ~= 'bedwars_test'
				if BedwarsCheck.Enabled and not store.queueType:find('bedwars') then return end
	
				local lastupgrades
				AutoBuy:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(function()
					if (npctick - tick()) > 1 then npctick = tick() end
				end))
	
				repeat
					local npc, shop, upgrades, newid = getShopNPC()
					id = newid
					if GUI.Enabled then
						if not (bedwars.AppController:isAppOpen('BedwarsItemShopApp') or bedwars.AppController:isAppOpen('TeamUpgradeApp')) then
							npc = nil
						end
					end
	
					if npc and lastupgrades ~= upgrades then
						if (npctick - tick()) > 1 then npctick = tick() end
						lastupgrades = upgrades
					end
	
					if npc and npctick <= tick() and store.matchState ~= 2 and store.shopLoaded then
						local currencytable = {}
						local waitcheck
						for _, tab in Callbacks do
							for _, callback in tab do
								if callback(currencytable, shop, upgrades) then
									waitcheck = true
								end
							end
						end
						npctick = tick() + (waitcheck and 0.4 or math.huge)
					end
	
					task.wait(0.1)
				until not AutoBuy.Enabled
			else
				npctick = tick()
			end
		end,
		Tooltip = 'Automatically buys items when you go near the shop'
	})
	Sword = AutoBuy:CreateToggle({
		Name = 'Buy Sword',
		Function = function(callback)
			npctick = tick()
			Functions[2] = callback and function(currencytable, shop)
				if not shop then return end
	
				if store.equippedKit == 'dasher' then
					swords = {
						[1] = 'wood_dao',
						[2] = 'stone_dao',
						[3] = 'iron_dao',
						[4] = 'diamond_dao',
						[5] = 'emerald_dao'
					}
				elseif store.equippedKit == 'ice_queen' then
					swords[5] = 'ice_sword'
				elseif store.equippedKit == 'ember' then
					swords[5] = 'infernal_saber'
				elseif store.equippedKit == 'lumen' then
					swords[5] = 'light_sword'
				end
	
				return buyTool(store.tools.sword, swords, currencytable)
			end or nil
		end
	})
	Armor = AutoBuy:CreateToggle({
		Name = 'Buy Armor',
		Function = function(callback)
			npctick = tick()
			Functions[1] = callback and function(currencytable, shop)
				if not shop then return end
				local currentarmor = store.inventory.inventory.armor[2] ~= 'empty' and store.inventory.inventory.armor[2] or getBestArmor(1)
				currentarmor = currentarmor and currentarmor.itemType or 'none'
				return buyTool({itemType = currentarmor}, armors, currencytable)
			end or nil
		end,
		Default = true
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Axe',
		Function = function(callback)
			npctick = tick()
			Functions[3] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.wood or {itemType = 'none'}, axes, currencytable)
			end or nil
		end
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Pickaxe',
		Function = function(callback)
			npctick = tick()
			Functions[4] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.stone, pickaxes, currencytable)
			end or nil
		end
	})
	local count = 0
	for i, v in bedwars.TeamUpgradeMeta do
		local toggleCount = count
		table.insert(UpgradeToggles, AutoBuy:CreateToggle({
			Name = 'Buy '..(v.name == 'Armor' and 'Protection' or v.name),
			Function = function(callback)
				npctick = tick()
				Functions[5 + toggleCount + (v.name == 'Armor' and 20 or 0)] = callback and function(currencytable, shop, upgrades)
					if not upgrades then return end
					if v.disabledInQueue and table.find(v.disabledInQueue, store.queueType) then return end
					return buyUpgrade(i, currencytable)
				end or nil
			end,
			Darker = true,
			Default = (i == 'ARMOR' or i == 'DAMAGE')
		}))
		count += 1
	end
	TierCheck = AutoBuy:CreateToggle({Name = 'Tier Check'})
	BedwarsCheck = AutoBuy:CreateToggle({
		Name = 'Only Bedwars',
		Function = function()
			if AutoBuy.Enabled then
				AutoBuy:Toggle()
				AutoBuy:Toggle()
			end
		end,
		Default = true
	})
	GUI = AutoBuy:CreateToggle({Name = 'GUI check'})
	SmartCheck = AutoBuy:CreateToggle({
		Name = 'Smart check',
		Default = true,
		Tooltip = 'Buys iron armor before iron axe'
	})
	AutoBuy:CreateTextList({
		Name = 'Item',
		Placeholder = 'priority/item/amount/after',
		Function = function(list)
			table.clear(Custom)
			table.clear(CustomPost)
			for _, entry in list do
				local tab = entry:split('/')
				local ind = tonumber(tab[1])
				if ind then
					(tab[4] and CustomPost or Custom)[ind] = function(currencytable, shop)
						if not shop then return end
	
						local v = bedwars.Shop.getShopItem(tab[2], lplr)
						if v then
							local item = getItem(tab[2] == 'wool_white' and bedwars.Shop.getTeamWool(lplr:GetAttribute('Team')) or tab[2])
							item = (item and tonumber(tab[3]) - item.amount or tonumber(tab[3])) // v.amount
							if item > 0 and canBuy(v, currencytable, item) then
								for _ = 1, item do
									buyItem(v, currencytable)
								end
								return true
							end
						end
					end
				end
			end
		end
	})
end)
	
run(function()
	local AutoConsume
	local Health
	local SpeedPotion
	local Apple
	local ShieldPotion
	
	local function consumeCheck(attribute)
		if entitylib.isAlive then
			if SpeedPotion.Enabled and (not attribute or attribute == 'StatusEffect_speed') then
				local speedpotion = getItem('speed_potion')
				if speedpotion and (not lplr.Character:GetAttribute('StatusEffect_speed')) then
					for _ = 1, 4 do
						if bedwars.Client:Get(remotes.ConsumeItem):CallServer({item = speedpotion.tool}) then break end
					end
				end
			end
	
			if Apple.Enabled and (not attribute or attribute:find('Health')) then
				if (lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) <= (Health.Value / 100) then
					local apple = getItem('orange') or (not lplr.Character:GetAttribute('StatusEffect_golden_apple') and getItem('golden_apple')) or getItem('apple')
					
					if apple then
						bedwars.Client:Get(remotes.ConsumeItem):CallServerAsync({
							item = apple.tool
						})
					end
				end
			end
	
			if ShieldPotion.Enabled and (not attribute or attribute:find('Shield')) then
				if (lplr.Character:GetAttribute('Shield_POTION') or 0) == 0 then
					local shield = getItem('big_shield') or getItem('mini_shield')
	
					if shield then
						bedwars.Client:Get(remotes.ConsumeItem):CallServerAsync({
							item = shield.tool
						})
					end
				end
			end
		end
	end
	
	AutoConsume = vape.Categories.Inventory:CreateModule({
		Name = 'AutoConsume',
		Function = function(callback)
			if callback then
				AutoConsume:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(consumeCheck))
				AutoConsume:Clean(vapeEvents.AttributeChanged.Event:Connect(function(attribute)
					if attribute:find('Shield') or attribute:find('Health') or attribute == 'StatusEffect_speed' then
						consumeCheck(attribute)
					end
				end))
				consumeCheck()
			end
		end,
		Tooltip = 'Automatically heals for you when health or shield is under threshold.'
	})
	Health = AutoConsume:CreateSlider({
		Name = 'Health Percent',
		Min = 1,
		Max = 99,
		Default = 70,
		Suffix = '%'
	})
	SpeedPotion = AutoConsume:CreateToggle({
		Name = 'Speed Potions',
		Default = true
	})
	Apple = AutoConsume:CreateToggle({
		Name = 'Apple',
		Default = true
	})
	ShieldPotion = AutoConsume:CreateToggle({
		Name = 'Shield Potions',
		Default = true
	})
end)

	
run(function()
	local Value
	local oldclickhold, oldshowprogress
	
	local FastConsume = vape.Categories.Inventory:CreateModule({
		Name = 'FastConsume',
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldshowprogress = bedwars.ClickHold.showProgress
				bedwars.ClickHold.startClick = function(self)
					self.startedClickTime = tick()
					local handle = self:showProgress()
					local clicktime = self.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(self.durationSeconds * (Value.Value / 40))
						if handle == self.handle and clicktime == self.startedClickTime and self.closeOnComplete then
							self:hideProgress()
							if self.onComplete then self.onComplete() end
							if self.onPartialComplete then self.onPartialComplete(1) end
							self.startedClickTime = -1
						end
					end)
				end
	
				bedwars.ClickHold.showProgress = function(self)
					local roact = debug.getupvalue(oldshowprogress, 1)
					local countdown = roact.mount(roact.createElement('ScreenGui', {}, { roact.createElement('Frame', {
						[roact.Ref] = self.wrapperRef,
						Size = UDim2.new(),
						Position = UDim2.fromScale(0.5, 0.55),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement('Frame', {
						[roact.Ref] = self.progressRef,
						Size = UDim2.fromScale(0, 1),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.5
					}) }) }), lplr:FindFirstChild('PlayerGui'))
	
					self.handle = countdown
					local sizetween = tweenService:Create(self.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.fromScale(0.11, 0.005)
					})
					local countdowntween = tweenService:Create(self.progressRef:getValue(), TweenInfo.new(self.durationSeconds * (Value.Value / 100), Enum.EasingStyle.Linear), {
						Size = UDim2.fromScale(1, 1)
					})
	
					sizetween:Play()
					countdowntween:Play()
					table.insert(self.tweens, countdowntween)
					table.insert(self.tweens, sizetween)
					
					return countdown
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldshowprogress
				oldclickhold = nil
				oldshowprogress = nil
			end
		end,
		Tooltip = 'Use/Consume items quicker.'
	})
	Value = FastConsume:CreateSlider({
		Name = 'Multiplier',
		Min = 0,
		Max = 100
	})
end)
	
run(function()
	local FastDrop
	
	FastDrop = vape.Categories.Inventory:CreateModule({
		Name = 'FastDrop',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and (not store.inventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.H) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
						task.spawn(bedwars.ItemDropController.dropItemInHand)
						task.wait(0.1)
					else
						task.wait(0.1)
					end
				until not FastDrop.Enabled
			end
		end,
		Tooltip = 'Drops items fast when you hold Q'
	})
end)
	
run(function()
	local BedPlates
	local MutiLayerChecker
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	local SCAN_PASSES = 3
	local function scanSide(self, start, tab)
		for _, side in sides do
			for i = 1, 15 do
				local block = getPlacedBlock(start + (side * i))
				if not block or block == self then break end
				if not block:GetAttribute('NoBreak') then
					tab[block.Name] = tab[block.Name] or {}
					tab[block.Name][i] = true
				end
			end
		end
	end
	local function refreshAdornee(v)
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') then
				obj:Destroy()
			end
		end
		local start = v.Adornee.Position
		local blockLayers = {}
		scanSide(v.Adornee, start, blockLayers)
		scanSide(v.Adornee, start + Vector3.new(0, 0, 3), blockLayers)
		local blocks = {}
		for name, layers in blockLayers do
			local raw = 0
			for _ in layers do
				raw += 1
			end
			local count = math.max(1, math.floor(raw / SCAN_PASSES))
			table.insert(blocks, {name = name,count = count})
		end
		table.sort(blocks, function(a, b)
			return (bedwars.ItemMeta[a.name].block and bedwars.ItemMeta[a.name].block.health or 0) > (bedwars.ItemMeta[b.name].block and bedwars.ItemMeta[b.name].block.health or 0)
		end)
		v.Enabled = #blocks > 0
		for _, data in blocks do
			local blockimage = Instance.new('ImageLabel')
			blockimage.Size = UDim2.fromOffset(32, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = data.name}, true)
			blockimage.Parent = v.Frame
			if MutiLayerChecker.Enabled and data.count > 1 then
				local countLabel = Instance.new('TextLabel')
				countLabel.Size = UDim2.fromScale(1, 1)
				countLabel.BackgroundTransparency = 1
				countLabel.Text = tostring(data.count)
				countLabel.TextColor3 = Color3.new(1, 1, 1)
				countLabel.TextStrokeTransparency = 0
				countLabel.TextScaled = true
				countLabel.Font = Enum.Font.GothamBold
				countLabel.Parent = blockimage
			end
		end
	end

	local function Added(v)
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'bed'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Name = 'Frame'
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		refreshAdornee(billboard)
	end
	local function refreshNear(data)
		data = data.blockRef.blockPosition * 3
		for i, v in Reference do
			if (data - i.Position).Magnitude <= 30 then
				refreshAdornee(v)
			end
		end
	end
	BedPlates = vape.Categories.Utility:CreateModule({
		Name = 'BedPlates',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('bed') do
					task.spawn(Added, v)
				end
				BedPlates:Clean(vapeEvents.PlaceBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(vapeEvents.BreakBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(Added))
				BedPlates:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v] = nil
					end
				end))
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays blocks over the bed'
	})

	Background = BedPlates:CreateToggle({
		Name = 'Background',
		Default = true,
		Function = function(callback)
			if Color.Object then
				Color.Object.Visible = callback
			end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end
	})
	MutiLayerChecker = BedPlates:CreateToggle({
		Name = 'Mutiple Layers',
		Default = false,
		Function = function()
			for _, v in Reference do
				refreshAdornee(v)
			end
		end
	})
	Color = BedPlates:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)
	



run(function()
	local BedBreakEffect
	local Mode
	local List
	local NameToId = {}
	
	BedBreakEffect = vape.Categories.Legit:CreateModule({
		Name = 'Bed Break Effect',
		Function = function(callback)
			if callback then
	            BedBreakEffect:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(data)
	                firesignal(bedwars.Client:Get('BedBreakEffectTriggered').instance.OnClientEvent, {
	                    player = data.player,
	                    position = data.bedBlockPosition * 3,
	                    effectType = NameToId[List.Value],
	                    teamId = data.brokenBedTeam.id,
	                    centerBedPosition = data.bedBlockPosition * 3
	                })
	            end))
	        end
		end,
		Tooltip = 'Custom bed break effects'
	})
	local BreakEffectName = {}
	for i, v in bedwars.BedBreakEffectMeta do
		table.insert(BreakEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(BreakEffectName)
	List = BedBreakEffect:CreateDropdown({
		Name = 'Effect',
		List = BreakEffectName
	})
end)
	

	
run(function()
	local old
	local Image
	local Crosshair = vape.Categories.Legit:CreateModule({
		Name = 'Crosshair',
		Function = function(callback)
			if callback then 
				old = debug.getconstant(bedwars.ViewmodelController.show, 25)
				debug.setconstant(bedwars.ViewmodelController.show, 25, Image.Value)
				debug.setconstant(bedwars.ViewmodelController.show, 37, Image.Value)
			else
				debug.setconstant(bedwars.ViewmodelController.show, 25, old)
				debug.setconstant(bedwars.ViewmodelController.show, 37, old)
				old = nil
			end
			if bedwars.CameraPerspectiveController:getCameraPerspective() == 0 then
				bedwars.ViewmodelController:hide()
				bedwars.ViewmodelController:show()
			end
		end,
		Tooltip = 'Custom first person crosshair depending on the image choosen.'
	})
	Image = Crosshair:CreateTextBox({
		Name = 'Image',
		Placeholder = 'image id (roblox)',
		Function = function(enter)
			if enter and Crosshair.Enabled then 
				Crosshair:Toggle()
				Crosshair:Toggle()
			end
		end
	})
end)

run(function()
	local FOV
	local Value
	local old, old2
	
	FOV = vape.Categories.Legit:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				old = bedwars.FovController.setFOV
				old2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self) 
					return old(self, Value.Value) 
				end
				bedwars.FovController.getFOV = function() 
					return Value.Value 
				end
			else
				bedwars.FovController.setFOV = old
				bedwars.FovController.getFOV = old2
			end
			
			bedwars.FovController:setFOV(bedwars.Store:getState().Settings.fov)
		end,
		Tooltip = 'Adjusts camera vision'
	})
	Value = FOV:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)
	
run(function()
	local FPSBoost
	local Kill
	local Visualizer
	local effects, util = {}, {}
	
	FPSBoost = vape.Categories.Legit:CreateModule({
		Name = 'FPS Boost',
		Function = function(callback)
			if callback then
				if Kill.Enabled then
					for i, v in bedwars.KillEffectController.killEffects do
						if not i:find('Custom') then
							effects[i] = v
							bedwars.KillEffectController.killEffects[i] = {
								new = function() 
									return {
										onKill = function() end, 
										isPlayDefaultKillEffect = function() 
											return true 
										end
									} 
								end
							}
						end
					end
				end
	
				if Visualizer.Enabled then
					for i, v in bedwars.VisualizerUtils do
						util[i] = v
						bedwars.VisualizerUtils[i] = function() end
					end
				end
	
				repeat task.wait(0.1) until store.matchState ~= 0
				if not bedwars.AppController then return end
				bedwars.NametagController.addGameNametag = function() end
				for _, v in bedwars.AppController:getOpenApps() do
					if tostring(v):find('Nametag') then
						bedwars.AppController:closeApp(tostring(v))
					end
				end
			else
				for i, v in effects do 
					bedwars.KillEffectController.killEffects[i] = v 
				end
				for i, v in util do 
					bedwars.VisualizerUtils[i] = v 
				end
				table.clear(effects)
				table.clear(util)
			end
		end,
		Tooltip = 'Improves the framerate by turning off certain effects'
	})
	Kill = FPSBoost:CreateToggle({
		Name = 'Kill Effects',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
	Visualizer = FPSBoost:CreateToggle({
		Name = 'Visualizer',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
end)
	
run(function()
	local HitColor
	local Color
	local done = {}
	
	HitColor = vape.Categories.Legit:CreateModule({
		Name = 'Hit Color',
		Function = function(callback)
			if callback then 
				repeat
					for i, v in entitylib.List do 
						local highlight = v.Character and v.Character:FindFirstChild('_DamageHighlight_')
						if highlight then 
							if not table.find(done, highlight) then 
								table.insert(done, highlight) 
							end
							highlight.FillColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
							highlight.FillTransparency = Color.Opacity
						end
					end
					task.wait(0.1)
				until not HitColor.Enabled
			else
				for i, v in done do 
					v.FillColor = Color3.new(1, 0, 0)
					v.FillTransparency = 0.4
				end
				table.clear(done)
			end
		end,
		Tooltip = 'Customize the hit highlight options'
	})
	Color = HitColor:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.4
	})
end)
	
	
run(function()
	local Interface
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local HotbarHealthbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar['hotbar-healthbar']).HotbarHealthbar
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local old, new = {}, {}
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not func then return end
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) then return end
		new[func][ind] = val
	
		if Interface.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	Interface = vape.Categories.Legit:CreateModule({
		Name = 'Interface',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
		end,
		Tooltip = 'Customize bedwars UI'
	})
	local fontitems = {'LuckiestGuy'}
	for _, v in Enum.Font:GetEnumItems() do
		if v.Name ~= 'LuckiestGuy' then
			table.insert(fontitems, v.Name)
		end
	end
	Interface:CreateDropdown({
		Name = 'Health Font',
		List = fontitems,
		Function = function(val)
			modifyconstant(HotbarHealthbar.render, 77, val)
		end
	})
	Interface:CreateColorSlider({
		Name = 'Health Color',
		Function = function(hue, sat, val)
			modifyconstant(HotbarHealthbar.render, 16, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			if Interface.Enabled then
				local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
				hotbar = hotbar and hotbar:FindFirstChild('HealthbarProgressWrapper', true)
				if hotbar then
					hotbar['1'].BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				end
			end
		end
	})
	Interface:CreateColorSlider({
		Name = 'Hotbar Color',
		DefaultOpacity = 0.8,
		Function = function(hue, sat, val, opacity)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 51, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 58, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 54, 1 - opacity)
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 55, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 31, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(func, 32, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 34, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
		end
	})
end)
	
run(function()
	local KillEffect
	local Mode
	local List
	local NameToId = {}
	
	local killeffects = {
		Gravity = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			local nametag = char:FindFirstChild('Nametag', true)
			if highlight then
				highlight:Destroy()
			end
			if nametag then
				nametag:Destroy()
			end
	
			task.spawn(function()
				local partvelo = {}
				for _, v in char:GetDescendants() do
					if v:IsA('BasePart') then
						partvelo[v.Name] = v.Velocity
					end
				end
				char.Archivable = true
				local clone = char:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				game:GetService('Debris'):AddItem(clone, 30)
				char:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for _, v in clone:GetDescendants() do
					if v:IsA('BasePart') then
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			if highlight then
				highlight:Destroy()
			end
			local startpos = 1125
			local startcf = char.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
	
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new('Part')
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService('Debris'):AddItem(part, 0.5)
				game:GetService('Debris'):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new('Part')
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new('Sound')
					sound.SoundId = 'rbxassetid://6993372814'
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end,
		Delete = function(_, _, char, _)
			char:Destroy()
		end
	}
	
	KillEffect = vape.Categories.Legit:CreateModule({
		Name = 'Kill Effect',
		Function = function(callback)
			if callback then
				for i, v in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = {
						new = function()
							return {
								onKill = v,
								isPlayDefaultKillEffect = function()
									return false
								end
							}
						end
					}
				end
				KillEffect:Clean(lplr:GetAttributeChangedSignal('KillEffectType'):Connect(function()
					lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
				end))
				lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
			else
				for i in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = nil
				end
				lplr:SetAttribute('KillEffectType', 'default')
			end
		end,
		Tooltip = 'Custom final kill effects'
	})
	local modes = {'Bedwars'}
	for i in killeffects do
		table.insert(modes, i)
	end
	Mode = KillEffect:CreateDropdown({
		Name = 'Mode',
		List = modes,
		Function = function(val)
			List.Object.Visible = val == 'Bedwars'
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', val == 'Bedwars' and NameToId[List.Value] or 'Custom'..val)
			end
		end
	})
	local KillEffectName = {}
	for i, v in bedwars.KillEffectMeta do
		table.insert(KillEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(KillEffectName)
	List = KillEffect:CreateDropdown({
		Name = 'Bedwars',
		List = KillEffectName,
		Function = function(val)
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', NameToId[val])
			end
		end,
		Darker = true
	})
end)
	
run(function()
	local ReachDisplay
	local label
	
	ReachDisplay = vape.Categories.Legit:CreateModule({
		Name = 'Reach Display',
		Function = function(callback)
			if callback then
				repeat
					label.Text = (store.attackReachUpdate > tick() and store.attackReach or '0.00')..' studs'
					task.wait(0.4)
				until not ReachDisplay.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41)
	})
	ReachDisplay:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	ReachDisplay:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0.00 studs'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = ReachDisplay.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local SongBeats
	local List
	local FOV
	local FOVValue = {}
	local Volume
	local alreadypicked = {}
	local beattick = tick()
	local oldfov, songobj, songbpm, songtween
	
	local function choosesong()
		local list = List.ListEnabled
		if #alreadypicked >= #list then 
			table.clear(alreadypicked) 
		end
	
		if #list <= 0 then
			notif('SongBeats', 'no songs', 10)
			SongBeats:Toggle()
			return
		end
	
		local chosensong = list[math.random(1, #list)]
		if #list > 1 and table.find(alreadypicked, chosensong) then
			repeat 
				task.wait(0.1) 
				chosensong = list[math.random(1, #list)] 
			until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
		end
		if not SongBeats.Enabled then return end
	
		local split = chosensong:split('/')
		if not isfile(split[1]) then
			notif('SongBeats', 'Missing song ('..split[1]..')', 10)
			SongBeats:Toggle()
			return
		end
	
		songobj.SoundId = assetfunction(split[1])
		repeat task.wait(0.1) until songobj.IsLoaded or not SongBeats.Enabled
		if SongBeats.Enabled then
			beattick = tick() + (tonumber(split[3]) or 0)
			songbpm = 60 / (tonumber(split[2]) or 50)
			songobj:Play()
		end
	end
	
	SongBeats = vape.Categories.Legit:CreateModule({
		Name = 'Song Beats',
		Function = function(callback)
			if callback then
				songobj = Instance.new('Sound')
				songobj.Volume = Volume.Value / 100
				songobj.Parent = workspace
				repeat
					if not songobj.Playing then choosesong() end
					if beattick < tick() and SongBeats.Enabled and FOV.Enabled then
						beattick = tick() + songbpm
						oldfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
						gameCamera.FieldOfView = oldfov - FOVValue.Value
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {FieldOfView = oldfov})
						songtween:Play()
					end
					task.wait(0.1)
				until not SongBeats.Enabled
			else
				if songobj then
					songobj:Destroy()
				end
				if songtween then
					songtween:Cancel()
				end
				if oldfov then
					gameCamera.FieldOfView = oldfov
				end
				table.clear(alreadypicked)
			end
		end,
		Tooltip = 'Built in mp3 player'
	})
	List = SongBeats:CreateTextList({
		Name = 'Songs',
		Placeholder = 'filepath/bpm/start'
	})
	FOV = SongBeats:CreateToggle({
		Name = 'Beat FOV',
		Function = function(callback)
			if FOVValue.Object then
				FOVValue.Object.Visible = callback
			end
			if SongBeats.Enabled then
				SongBeats:Toggle()
				SongBeats:Toggle()
			end
		end,
		Default = true
	})
	FOVValue = SongBeats:CreateSlider({
		Name = 'Adjustment',
		Min = 1,
		Max = 30,
		Default = 5,
		Darker = true
	})
	Volume = SongBeats:CreateSlider({
		Name = 'Volume',
		Function = function(val)
			if songobj then 
				songobj.Volume = val / 100 
			end
		end,
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
	
run(function()
	local SoundChanger
	local List
	local soundlist = {}
	local old
	
	SoundChanger = vape.Categories.Legit:CreateModule({
		Name = 'SoundChanger',
		Function = function(callback)
			if callback then
				old = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(self, id, ...)
					if soundlist[id] then
						id = soundlist[id]
					end
	
					return old(self, id, ...)
				end
			else
				bedwars.SoundManager.playSound = old
				old = nil
			end
		end,
		Tooltip = 'Change ingame sounds to custom ones.'
	})
	List = SoundChanger:CreateTextList({
		Name = 'Sounds',
		Placeholder = '(DAMAGE_1/ben.mp3)',
		Function = function()
			table.clear(soundlist)
			for _, entry in List.ListEnabled do
				local split = entry:split('/')
				local id = bedwars.SoundList[split[1]]
				if id and #split > 1 then
					soundlist[id] = split[2]:find('rbxasset') and split[2] or isfile(split[2]) and assetfunction(split[2]) or ''
				end
			end
		end
	})
end)
	
run(function()
	local UICleanup
	local OpenInv
	local KillFeed
	local OldTabList
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local old, new = {}, {}
	local oldkillfeed
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			local typing = type(old[func][ind])
			if typing == 'function' or typing == 'userdata' then return end
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) and val ~= nil then return end
	
		new[func][ind] = val
		if UICleanup.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	UICleanup = vape.Categories.Legit:CreateModule({
		Name = 'UI Cleanup',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
			if callback then
				if OpenInv.Enabled then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				end
	
				if KillFeed.Enabled then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
				end
			else
				if oldinvrender then
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
	
				if KillFeed.Enabled then
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				end
			end
		end,
		Tooltip = 'Cleans up the UI for kits & main'
	})
	UICleanup:CreateToggle({
		Name = 'Resize Health',
		Function = function(callback)
			modifyconstant(HotbarApp, 60, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 15).render, 30, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 23).tweenPosition, 16, callback and 0 or nil)
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'No Hotbar Numbers',
		Function = function(callback)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 90, callback and 0 or nil)
			modifyconstant(func, 71, callback and 0 or nil)
		end,
		Default = true
	})
	OpenInv = UICleanup:CreateToggle({
		Name = 'No Inventory Button',
		Function = function(callback)
			modifyconstant(HotbarApp, 78, callback and 0 or nil)
			if UICleanup.Enabled then
				if callback then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				else
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
			end
		end,
		Default = true
	})
	KillFeed = UICleanup:CreateToggle({
		Name = 'No Kill Feed',
		Function = function(callback)
			if UICleanup.Enabled then
				if callback then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				else
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
			end
		end,
		Default = true
	})
	OldTabList = UICleanup:CreateToggle({
		Name = 'Old Player List',
		Function = function(callback)
			if UICleanup.Enabled then
				starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, callback)
			end
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'Fix Queue Card',
		Function = function(callback)
			modifyconstant(bedwars.QueueCard.render, 15, callback and 0.1 or nil)
		end,
		Default = true
	})
end)
	

	
run(function()
	local WinEffect
	local List
	local NameToId = {}
	
	WinEffect = vape.Categories.Legit:CreateModule({
		Name = 'WinEffect',
		Function = function(callback)
			if callback then
				WinEffect:Clean(vapeEvents.MatchEndEvent.Event:Connect(function()
					for i, v in getconnections(bedwars.Client:Get('WinEffectTriggered').instance.OnClientEvent) do
						if v.Function then
							v.Function({
								winEffectType = NameToId[List.Value],
								winningPlayer = lplr
							})
						end
					end
				end))
			end
		end,
		Tooltip = 'Allows you to select any clientside win effect'
	})
	local WinEffectName = {}
	for i, v in bedwars.WinEffectMeta do
		table.insert(WinEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(WinEffectName)
	List = WinEffect:CreateDropdown({
		Name = 'Effects',
		List = WinEffectName
	})
end)


run(function()
	local AutoAim
	local AimSpeed	
	local Range
	local Cache
	local UpdateRate
	local Custom
	local Bed
	local LuckyBlock
	local AutoTool
	local IronOre
	local Effect
	local CustomHealth = {}
	local Animation
	local SelfBreak
	local WallCheck
	local LimitItem
	local TelasCoils
	local BeeHive
	local BS
	local BM
	local customlist, parts = {}, {}
	local hit = 0
	local targetting = nil
	local mouse = cloneref(lplr:GetMouse())
	local function getBlockHealth(block)
		return block:GetAttribute("Health") or block:GetAttribute("BlockHealth") or math.huge
	end
	local function getBreakOrigin(localPosition)
		if BM.Value == "Mouse" then
			return mouse.Hit and mouse.Hit.Position or localPosition
		end
		return localPosition
	end
	local function customHealthbar(self, blockRef, health, maxHealth, changeHealth, block)
		pcall(function()
			if block:GetAttribute('NoHealthbar') then return end
			if not self.healthbarPart or not self.healthbarBlockRef or self.healthbarBlockRef.blockPosition ~= blockRef.blockPosition then
				self.healthbarMaid:DoCleaning()
				self.healthbarBlockRef = blockRef
				local percent = math.clamp(health / maxHealth, 0, 1)
				local cleanCheck = true
				local part = Instance.new('Part')
				part.Size = Vector3.one
				part.CFrame = CFrame.new(bedwars.BlockController:getWorldPosition(blockRef.blockPosition))
				part.Transparency = 1
				part.Anchored = true
				part.CanCollide = false
				part.Parent = workspace
				self.healthbarPart = part
				bedwars.QueryUtil:setQueryIgnored(part, true)
				local mounted = bedwars.Roact.mount(
					bedwars.Roact.createElement("BillboardGui", {
						Size = UDim2.fromOffset(249, 102),
						StudsOffset = Vector3.new(0, 2.5, 0),
						Adornee = part,
						MaxDistance = 40,
						AlwaysOnTop = true
					}, {
						bedwars.Roact.createElement("Frame", {
							Size = UDim2.fromOffset(160, 50),
							Position = UDim2.fromOffset(44, 32),
							BackgroundColor3 = Color3.new(),
							BackgroundTransparency = 0.5
						}, {
							bedwars.Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
							bedwars.Roact.createElement("TextLabel", {
								Size = UDim2.fromOffset(145, 14),
								Position = UDim2.fromOffset(13, 12),
								BackgroundTransparency = 1,
								Text = bedwars.ItemMeta[block.Name].displayName or block.Name,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextScaled = true,
								TextColor3 = Color3.new(),
								Font = Enum.Font.Arial
							}),
							bedwars.Roact.createElement("Frame", {
								Size = UDim2.fromOffset(138, 4),
								Position = UDim2.fromOffset(12, 32),
								BackgroundColor3 = uipallet.Main
							}, {
								bedwars.Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
								bedwars.Roact.createElement("Frame", {
									[bedwars.Roact.Ref] = self.healthbarProgressRef,
									Size = UDim2.fromScale(percent, 1),
									BackgroundColor3 = Color3.fromHSV(percent / 2.5, 0.89, 0.75)
								}, {
									bedwars.Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
								})
							})
						})
					}),
					part
				)
				self.healthbarMaid:GiveTask(function()
					cleanCheck = false
					self.healthbarBlockRef = nil
					bedwars.Roact.unmount(mounted)
					if self.healthbarPart then
						self.healthbarPart:Destroy()
					end
					self.healthbarPart = nil
				end)
				bedwars.RuntimeLib.Promise.delay(5):andThen(function()
					if cleanCheck then
						self.healthbarMaid:DoCleaning()
					end
				end)
			end
			local newpercent = math.clamp((health - changeHealth) / maxHealth, 0, 1)
			tweenService:Create(self.healthbarProgressRef:getValue(),TweenInfo.new(0.3),
				{
					Size = UDim2.fromScale(newpercent, 1),
					BackgroundColor3 = Color3.fromHSV(newpercent / 2.5, 0.89, 0.75)
				}
			):Play()
		end)
	end
	local function attemptBreak(tab, localPosition)
		if not tab then return end
		local origin = getBreakOrigin(localPosition)
		if BS.Value == "Nearest" then
			table.sort(tab, function(a, b)
				return (a.Position - origin).Magnitude < (b.Position - origin).Magnitude
			end)
		else
			table.sort(tab, function(a, b)
				return getBlockHealth(a) < getBlockHealth(b)
			end)
		end
		for _, v in tab do
			if (v.Position - origin).Magnitude < Range.Value
				and bedwars.BlockController:isBlockBreakable({ blockPosition = v.Position / 3 }, lplr) then
				if not SelfBreak.Enabled and v:GetAttribute("PlacedByUserId") == lplr.UserId then continue end
				local blockTeam = v:GetAttribute("Team") or 0
				local myTeam = lplr.Character:GetAttribute("Team") or -1
				if not SelfBreak.Enabled and blockTeam == myTeam then continue end
				if (v:GetAttribute("BedShieldEndTime") or 0) > workspace:GetServerTimeNow() then continue end
				if LimitItem.Enabled and not (store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name].breakBlock) then continue end
				hit += 1
				local target, path, endpos = bedwars.breakBlock(v,Effect.Enabled,Animation.Enabled,CustomHealth.Enabled and customHealthbar or nil,AutoTool.Enabled,WallCheck.Enabled,Cache.Enabled)
				if path then
					local currentnode = target
					targetting = currentnode
					for _, part in parts do
						part.Position = currentnode or Vector3.zero
						if currentnode then
							part.BoxHandleAdornment.Color3 =
								currentnode == endpos and Color3.new(1, 0.2, 0.2)
								or currentnode == target and Color3.new(0.2, 0.2, 1)
								or Color3.new(0.2, 1, 0.2)
						end
						currentnode = path[currentnode]
					end
				end

				task.wait(Delay.Value)
				targetting = nil
				return true
			end
		end
		return false
	end
	Breaker = vape.Categories.Utility:CreateModule({
		Name = "Nuker",
		Tooltip = "Break blocks around you automatically",
		Function = function(callback)
			if callback then
				local CheckExecutor = ({identifyexecutor()})[1]
				if CheckExecutor == nil or CheckExecutor == '' then
					CheckExecutor = 'shitsploit'
				end
				if CheckExecutor ~= 'Potassium' and CheckExecutor ~= 'shitsploit' then
					repeat task.wait() until store.matchState ~= 0 or not Breaker.Enabled
				end
				for _ = 1, 30 do
					local part = Instance.new("Part")
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.Parent = gameCamera

					local box = Instance.new("BoxHandleAdornment")
					box.Size = Vector3.one
					box.AlwaysOnTop = true
					box.Transparency = 0.5
					box.Adornee = part
					box.Parent = part

					table.insert(parts, part)
				end

				local beds = collection("bed", Breaker)
				local luckyblock = collection("LuckyBlock", Breaker)
				local ironores = collection("iron-ore", Breaker)
				local bees = collection("beehive", Breaker)
				local coils = collection("tesla-trap", Breaker)

				customlist = collection("block", Breaker, function(tab, obj)
					if table.find(Custom.ListEnabled, obj.Name) then
						table.insert(tab, obj)
					end
				end)

				Breaker:Clean(runService.PreSimulation:Connect(function(dt)
					if AutoAim.Enabled and targetting then
						gameCamera.CFrame =
							gameCamera.CFrame:Lerp(
								CFrame.lookAt(gameCamera.CFrame.Position, targetting),
								AimSpeed.Value * dt
							)
					end
				end))

				repeat
					task.wait(1 / UpdateRate.Value)
					if entitylib.isAlive then
						local pos = entitylib.character.RootPart.Position
						if attemptBreak(Bed.Enabled and beds, pos) then continue end
						if attemptBreak(customlist, pos) then continue end
						if attemptBreak(LuckyBlock.Enabled and luckyblock, pos) then continue end
						if attemptBreak(IronOre.Enabled and ironores, pos) then continue end
						if attemptBreak(TelasCoils.Enabled and coils, pos) then continue end
						if attemptBreak(BeeHive.Enabled and bees, pos) then continue end
					end
				until not Breaker.Enabled
			else
				for _, v in parts do
					v:Destroy()
				end
				table.clear(parts)
			end
		end
	})
	BS = Breaker:CreateDropdown({
		Name = "Break Sorting",
		List = {"Nearest", "Health"},
		Default = "Health"
	})
	BM = Breaker:CreateDropdown({
		Name = "Break Mode",
		List = {"Position", "Mouse"},
		Default = "Position"
	})
	Range = Breaker:CreateSlider({ 
		Name = "Break range", 
		Min = 1, 
		Max = 30, 
		Default = 30 
	})
	Delay = Breaker:CreateSlider({ 
		Name = "Break Delay", 
		Min = 0, 
		Max = 0.3, 
		Default = 0.25, 
		Decimal = 5 
	})
	AimSpeed = Breaker:CreateSlider({ 
		Name = "Aim Speed", 
		Min = 1, 
		Max = 20, 
		Default = 20 
	})
	AimSpeed.Object.Visible = false
	UpdateRate = Breaker:CreateSlider({ 
		Name = "Update rate", 
		Min = 1, 
		Max = 120, 
		Default = 60, 
		Suffix = "hz" 
	})
	Custom = Breaker:CreateTextList({ 
		Name = "Custom" 
	})
	Bed = Breaker:CreateToggle({ 
		Name = "Break Bed", 
		Default = true 
	})
	AutoAim = Breaker:CreateToggle({
		Name = "Auto Aim",
		Function = function(v) 
			AimSpeed.Object.Visible = v 
		end
	})
	LuckyBlock = Breaker:CreateToggle({ 
		Name = "Break Lucky Block", 
		Default = true 
	})
	IronOre = Breaker:CreateToggle({ 
		Name = "Break Iron Ore", 
		Default = true 
	})
	BeeHive = Breaker:CreateToggle({ 
		Name = "Break Bee Hives" 
	})
	TelasCoils = Breaker:CreateToggle({ 
		Name = "Break Telas Coils", 
		Default = true 
	})
	Effect = Breaker:CreateToggle({ 
		Name = "Show Healthbar & Effects", 
		Default = true 
	})
	CustomHealth = Breaker:CreateToggle({ 
		Name = "Custom Healthbar",
		Default = true,
		Darker = true 
	})
	Animation = Breaker:CreateToggle({ 
		Name = "Animation" 
	})
	SelfBreak = Breaker:CreateToggle({
		 Name = "Self Break" 
	})
	WallCheck = Breaker:CreateToggle({ 
		Name = "Wall Check" 
	})
	Cache = Breaker:CreateToggle({ 
		Name = "Break through block" 
	})
	AutoTool = Breaker:CreateToggle({ 
		Name = "Auto Tool" 
	})
	LimitItem = Breaker:CreateToggle({ 
		Name = "Limit to items" 
	})
end)


run(function()
	local Viewmodel
	local Depth
	local Horizontal
	local Vertical
	local NoBob
	local Rots = {}
	local old, oldc1
	
	Viewmodel = vape.Categories.Combat:CreateModule({
		Name = 'NoBob',
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if callback then
				old = bedwars.ViewmodelController.playAnimation
				oldc1 = viewmodel and viewmodel.RightHand.RightWrist.C1 or CFrame.identity
				if NoBob.Enabled then
					bedwars.ViewmodelController.playAnimation = function(self, animtype, ...)
						if bedwars.AnimationType and animtype == bedwars.AnimationType.FP_WALK then return end
						return old(self, animtype, ...)
					end
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				if viewmodel then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -Depth.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', Horizontal.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', Vertical.Value)
			else
				bedwars.ViewmodelController.playAnimation = old
				if viewmodel then
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', 0)
				old = nil
			end
		end,
		Tooltip = 'Changes the viewmodel animations'
	})
	Depth = Viewmodel:CreateSlider({
		Name = 'Depth',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -val)
			end
		end
	})
	Horizontal = Viewmodel:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', val)
			end
		end
	})
	Vertical = Viewmodel:CreateSlider({
		Name = 'Vertical',
		Min = -0.2,
		Max = 2,
		Default = -0.2,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', val)
			end
		end
	})
	for _, name in {'Rotation X', 'Rotation Y', 'Rotation Z'} do
		table.insert(Rots, Viewmodel:CreateSlider({
			Name = name,
			Min = 0,
			Max = 360,
			Function = function(val)
				if Viewmodel.Enabled then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
			end
		}))
	end
	NoBob = Viewmodel:CreateToggle({
		Name = 'No Bobbing',
		Default = true,
		Function = function()
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
end)

run(function()
	local Mode
	local Value
	local WallCheck
	local AutoJump
	local AlwaysJump
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			frictionTable.Speed = callback or nil
			updateVelocity()
			pcall(function()
				debug.setconstant(bedwars.WindWalkerController.updateSpeed, 7, callback and 'constantSpeedMultiplier' or 'moveSpeedMultiplier')
			end)
	
			if callback then
				Speed:Clean(runService.PreSimulation:Connect(function(dt)
					bedwars.StatefulEntityKnockbackController.lastImpulseTime = callback and math.huge or time()
					if entitylib.isAlive then
						if not Fly.Enabled and not (InfiniteFly or {}).Enabled and not LongJump.Enabled then
							bedwars.SprintController:setSpeed(Value.Value)
							if Mode.Value == 'CFrame' then
								local state = entitylib.character.Humanoid:GetState()
								if state == Enum.HumanoidStateType.Climbing then return end
			
								local root, velo = entitylib.character.RootPart, getSpeed()
								local moveDirection = AntiFallDirection or entitylib.character.Humanoid.MoveDirection
								local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
			
								if WallCheck.Enabled then
									rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
									rayCheck.CollisionGroup = root.CollisionGroup
									local ray = workspace:Raycast(root.Position, destination, rayCheck)
									if ray then
										destination = ((ray.Position + ray.Normal) - root.Position)
									end
								end
			
								root.CFrame += destination
								root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
								if AutoJump.Enabled and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed) and moveDirection ~= Vector3.zero and (Attacking or AlwaysJump.Enabled) then
									entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
							end
						end
					end
				end))
			else
				bedwars.SprintController:setSpeed(bedwars.SprintController:isSprinting() and 20 or 14)
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Increases your movement with various methods.'
	})
	Mode = Speed:CreateDropdown({
		Name = 'Mode',
		List = {'Bedwars', 'CFrame'},
		Default = 'CFrame'
	})
	Value = Speed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 45,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Speed:CreateToggle({
		Name = 'Wall Check',
		Default = false
	})
	AutoJump = Speed:CreateToggle({
		Name = 'AutoJump',
		Function = function(callback)
			AlwaysJump.Object.Visible = callback
		end
	})
	AlwaysJump = Speed:CreateToggle({
		Name = 'Always Jump',
		Visible = false,
		Darker = true
	})
end)

run(function()
	local Value
	local VerticalValue
	local WallCheck
	local PopBalloons
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local up, down, old = 0, 0

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end    																																																							
			frictionTable.Fly = callback or nil
			updateVelocity()
			if callback then
				up, down, old = 0, 0, bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end
				local tpTick, tpToggle, oldy = tick(), true

				if lplr.Character and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
					bedwars.BalloonController:inflateBalloon()
				end
				Fly:Clean(vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed == 'InflatedBalloons' and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
						bedwars.BalloonController:inflateBalloon()
					end
				end))
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not InfiniteFly.Enabled and isnetworkowner(entitylib.character.RootPart) then
						local flyAllowed = (lplr.Character:GetAttribute('InflatedBalloons') and lplr.Character:GetAttribute('InflatedBalloons') > 0) or store.matchState == 2
						local mass = (1.5 + (flyAllowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)) + ((up + down) * VerticalValue.Value)
						local root, moveDirection = entitylib.character.RootPart, entitylib.character.Humanoid.MoveDirection
						local velo = getSpeed()
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
						rayCheck.CollisionGroup = root.CollisionGroup

						if WallCheck.Enabled then
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end

						if not flyAllowed then
							if tpToggle then
								local airleft = (tick() - entitylib.character.AirTime)
								if airleft > 2 then
									if not oldy then
										local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
										if ray and TP.Enabled then
											tpToggle = false
											oldy = root.Position.Y
											tpTick = tick() + 0.11
											root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
										end
									end
								end
							else
								if oldy then
									if tpTick < tick() then
										local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
										root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
										tpToggle = true
										oldy = nil
									else
										mass = 0
									end
								end
							end
						end

						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, mass, 0)
					end
				end))
				Fly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				Fly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			else
				bedwars.BalloonController.deflateBalloon = old
				if PopBalloons.Enabled and entitylib.isAlive and (lplr.Character:GetAttribute('InflatedBalloons') or 0) > 0 then
					for _ = 1, 3 do
						bedwars.BalloonController:deflateBalloon()
					end
				end
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Fly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	PopBalloons = Fly:CreateToggle({
		Name = 'Pop Balloons',
		Default = true
	})
	TP = Fly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)
																																																						
run(function()	

	NM = vape.Categories.Render:CreateModule({
		Name = 'Nightmare Emote',
		Tooltip = 'Client-Sided nightmare emote, animation is Server-Side visuals are Client-Sided',
		Function = function(callback)
			if callback then				
				local CharForNM = lplr.Character
				
				if not CharForNM then return end
				
				local NightmareEmote = replicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone()
				asset = NightmareEmote
				NightmareEmote.Parent = game.Workspace
				lastPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NM:Toggle()
							break
						end
						lastPosition = currentPosition
						NightmareEmote:SetPrimaryPartCFrame(CharForNM.LowerTorso.CFrame + Vector3.new(0, -2, 0))
						task.wait(0.1)
					end
				end)
				
				local NMDescendants = NightmareEmote:GetDescendants()
				local function PartStuff(Prt)
					if Prt:IsA("BasePart") then
						Prt.CanCollide = false
						Prt.Anchored = true
					end
				end
				for i, v in ipairs(NMDescendants) do
					PartStuff(v, i - 1, NMDescendants)
				end
				local Outer = NightmareEmote:FindFirstChild("Outer")
				if Outer then
					tweenService:Create(Outer, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Outer.Orientation + Vector3.new(0, 360, 0)
					}):Play()
				end
				local Middle = NightmareEmote:FindFirstChild("Middle")
				if Middle then
					tweenService:Create(Middle, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Middle.Orientation + Vector3.new(0, -360, 0)
					}):Play()
				end
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = CharForNM.Humanoid:LoadAnimation(anim)
				anim:Play()
			else 
                if anim then 
					anim:Stop()
					anim = nil
				end
				if asset then
					asset:Destroy() 
					asset = nil
				end
			end
		end
	})
end)


run(function()
	local GetHost = {}
	GetHost = vape.Categories.Render:CreateModule({
		Name = "GetHost",
		Tooltip = "this module is only for show. None of the settings will work.",
		Function = function(callback) 
			if callback then
				lplr:SetAttribute("CustomMatchRole", "host")
			else
				lplr:SetAttribute("CustomMatchRole", nil)
			end	
		end
	})
end)

run(function()
	local KitESP
	local Notify
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local ESPKits = {
		alchemist = {'alchemist_ingedients', 'wild_flower'},
		beekeeper = {'bee', 'bee'},
		bigman = {'treeOrb', 'natures_essence_1'},
		ghost_catcher = {'ghost', 'ghost_orb'},
		metal_detector = {'hidden-metal', 'iron'},
		sheep_herder = {'SheepModel', 'purple_hay_bale'},
		sorcerer = {'alchemy_crystal', 'wild_flower'},
		star_collector = {'stars', 'crit_star'},
		black_market_trader = {'shadow_coin', 'shadow_coin'},
		miner = {'petrified-player', 'large_rock'},
		trapper = {'snap_trap', 'snap_trap'},
		spirit_gardener = {'spirit_gardener_energy', 'telepearl'}
	}
	local NONTaggedKits = {
        necromancer = {'Gravestone', true},
        battery = {'Open', true},
	}

	local function Added(v, icon,non)
		if Notify.Enabled then
			vape:CreateNotification("KitESP",`New object is added {v.Name}`,2)
		end
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = icon
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local image = Instance.new('ImageLabel')
		image.Size = UDim2.fromOffset(36, 36)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		image.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		image.BorderSizePixel = 0
		local result = nil
		if non then
			result = icon
		else
			result = bedwars.getIcon({itemType = icon}, true)
		end
		image.Image = result
		image.Parent = billboard
		local uicorner = Instance.new('UICorner')
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		Reference[v] = billboard
	end
	
	local function addKit(tag, icon)
		KitESP:Clean(collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			Added(v.PrimaryPart, icon,false)
		end))
		KitESP:Clean(collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if Reference[v.PrimaryPart] then
				Reference[v.PrimaryPart]:Destroy()
				Reference[v.PrimaryPart] = nil
			end
		end))
		for _, v in collectionService:GetTagged(tag) do
			Added(v.PrimaryPart, icon,false)
		end
	end

	local function addKitNon(objName,icon)
		if typeof(icon) == "boolean" then
			if objName == "Gravestone" then
				icon = "rbxassetid://6307844310"
			elseif objName == "Open" then
				icon = "rbxassetid://10159166528"
			else
				icon = bedwars.getIcon({itemType = icon}, true) or ''
			end
		else
			icon = bedwars.getIcon({itemType = icon}, true)
		end
        KitESP:Clean(workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") and child.Name == objName then
                task.wait(0.1)
                if child.PrimaryPart then
                    Added(child,icon,true)
                end
            end
        end))
        KitESP:Clean(workspace.ChildRemoved:Connect(function(child)
            if child:IsA("Model") and child.Name == objName then
                if Reference[child] then
                    Reference[child]:Destroy()
                    Reference[child] = nil
                end
            end
        end))
	end
	
	KitESP = vape.Categories.Kits:CreateModule({
		Name = 'KitESP',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.equippedKit ~= '' or (not KitESP.Enabled)
				local kit = KitESP.Enabled and ESPKits[store.equippedKit] or nil
				local nontag = KitESP.Enabled and NONTaggedKits[store.equippedKit] or nil
				if kit then
					addKit(kit[1], kit[2])
				end
				if nontag then
					addKitNon(nontag[1], nontag[2])
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'ESP for certain kit related objects'
	})
	Notify = KitESP:CreateToggle({
		Name = "Notify",
		Default = false
	})
	Background = KitESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.ImageLabel.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = KitESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.ImageLabel.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.ImageLabel.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)																																
																																																								
run(function()
    local PlayerLevel
	local level 
	local old

	PlayerLevel = vape.Categories.Utility:CreateModule({
        Name = 'SetPlayerLevel',
		Tooltip = "Sets your player level to 1000 (client sided)",
        Function = function(callback)
			if callback then
				old = lplr:GetAttribute("PlayerLevel")
				lplr:SetAttribute("PlayerLevel", level.Value)
			else
				lplr:SetAttribute("PlayerLevel", old)
				old = nil
			end
		end
	})

	level = PlayerLevel:CreateSlider({
		Name = 'Player Level',
		Min = 1,
		Max = 1000,
		Default = 100,
		Function = function(val)
			if PlayerLevel.Enabled then
				lplr:SetAttribute("PlayerLevel", val)
			end
		end
	})
end)

run(function()
    local activeConnections = {}
    local kitLabels = {}
    local updateDebounce = {}
    local retryThread = nil
    local playerMonitorThread = nil
    local processedPlayers = {}
    
    KitRender = vape.Categories.Utility:CreateModule({
        Name = "KitRender",
        Function = function(callback)   
            if callback then
                local function createKitLabel(parent, kitImage)
                    if kitLabels[parent] then
                        kitLabels[parent]:Destroy()
                    end
                    
                    local kitLabel = Instance.new("ImageLabel")
                    kitLabel.Name = "OnyxKitIcon"
                    kitLabel.Size = UDim2.new(1, 0, 1, 0)
                    kitLabel.Position = UDim2.new(1.1, 0, 0, 0)
                    kitLabel.BackgroundTransparency = 1
                    kitLabel.Image = kitImage
                    kitLabel.Parent = parent
                    
                    kitLabels[parent] = kitLabel
                    return kitLabel
                end
                
                local function setupKitRender(obj)
                    if obj.Name == "PlayerRender" and obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Parent and obj.Parent.Parent.Parent.Parent and obj.Parent.Parent.Parent.Parent.Parent and obj.Parent.Parent.Parent.Parent.Parent.Name == "MatchDraftTeamCardRow" then
                        local Rank = obj.Parent:FindFirstChild('3')
                        if not Rank then return end
                        
                        local userId = string.match(obj.Image, "id=(%d+)")
                        if not userId then return end
                        
                        local id = tonumber(userId)
                        if not id then return end
                        
                        local plr = playersService:GetPlayerByUserId(id)
                        if not plr then return end
                        
                        local loopKey = plr.UserId
                        
                        processedPlayers[loopKey] = true
                        
                        if activeConnections[loopKey] then
                            activeConnections[loopKey]:Disconnect()
                            activeConnections[loopKey] = nil
                        end
                        
                        local function updateKit()
                            if not KitRender.Enabled then return end
                            if not Rank or not Rank.Parent then
                                if activeConnections[loopKey] then
                                    activeConnections[loopKey]:Disconnect()
                                    activeConnections[loopKey] = nil
                                end
                                if kitLabels[Rank] then
                                    kitLabels[Rank]:Destroy()
                                    kitLabels[Rank] = nil
                                end
                                return
                            end
                            
                            local kitName = plr:GetAttribute("PlayingAsKits")
                            if not kitName then
                                kitName = "none"
                            end
                            
                            local render = bedwars.BedwarsKitMeta[kitName] or bedwars.BedwarsKitMeta.none
                            
                            if kitLabels[Rank] then
                                kitLabels[Rank].Image = render.renderImage
                            else
                                createKitLabel(Rank, render.renderImage)
                            end
                        end
                        
                        updateKit()
                        
                        local connection = plr:GetAttributeChangedSignal("PlayingAsKits"):Connect(function()
                            local currentTick = tick()
                            
                            if not updateDebounce[loopKey] or (currentTick - updateDebounce[loopKey]) >= 0.1 then
                                updateDebounce[loopKey] = currentTick
                                updateKit()
                            end
                        end)
                        
                        activeConnections[loopKey] = connection
                        KitRender:Clean(connection)
                    end
                end
                
                local function setupSquadsRender()
                    local teams = lplr.PlayerGui:FindFirstChild("MatchDraftApp")
                    if not teams then
                        return false
                    end
                    
                    task.wait(0.5)
                    
                    for _, obj in teams:GetDescendants() do
                        if KitRender.Enabled then
                            task.spawn(function()
                                setupKitRender(obj)
                            end)
                        end
                    end
                    
                    KitRender:Clean(teams.DescendantAdded:Connect(function(obj)
                        if KitRender.Enabled then
                            task.wait(0.1)
                            setupKitRender(obj)
                        end
                    end))
                    
                    return true
                end
                
                playerMonitorThread = task.spawn(function()
                    while KitRender.Enabled do
                        task.wait(0.5)
                        
                        local teams = lplr.PlayerGui:FindFirstChild("MatchDraftApp")
                        if teams then
                            for _, obj in teams:GetDescendants() do
                                if obj.Name == "PlayerRender" and KitRender.Enabled then
                                    local userId = string.match(obj.Image, "id=(%d+)")
                                    if userId then
                                        local id = tonumber(userId)
                                        if id and not processedPlayers[id] then
                                            task.spawn(function()
                                                setupKitRender(obj)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                
                task.spawn(function()
                    local success = setupSquadsRender()
                    
                    if not success then
                        retryThread = task.spawn(function()
                            while KitRender.Enabled do
                                task.wait(1)
                                if setupSquadsRender() then
                                    break
                                end
                            end
                        end)
                    end
                end)
            else
                if retryThread then
                    task.cancel(retryThread)
                    retryThread = nil
                end
                
                if playerMonitorThread then
                    task.cancel(playerMonitorThread)
                    playerMonitorThread = nil
                end
                
                for key, connection in pairs(activeConnections) do
                    if connection then
                        connection:Disconnect()
                    end
                    activeConnections[key] = nil
                end
                
                for parent, label in pairs(kitLabels) do
                    if label then
                        label:Destroy()
                    end
                    kitLabels[parent] = nil
                end
                
                table.clear(updateDebounce)
                table.clear(processedPlayers)
            end
        end,
        Tooltip = "Shows everyone's kit next to their rank during kit phase (squads ranked!)"
    })
end)

run(function()
    local aim = 0.158
    local tnt = 0.0045
    local aunchself = 0.395

    local defaultaim = 0.4
    local defaulttnt = 0.2
    local defaultself = 0.4

	local A
	local T
	local L
	local C
	local AJ
	local AS
    local function getWorldFolder()
        local Map = workspace:WaitForChild("Map", math.huge)
        local Worlds = Map:WaitForChild("Worlds", math.huge)
        if not Worlds then return nil end

        return Worlds:GetChildren()[1] 
    end

    local function setCannonSpeeds(blocksFolder, aimDur, tntDur, selfDur)
        for _, v in ipairs(blocksFolder:GetChildren()) do 
            if v:IsA("BasePart") and v.Name == "cannon" then
                local AimPrompt = v:FindFirstChild("AimPrompt")
                local FirePrompt = v:FindFirstChild("FirePrompt")
                local LaunchSelfPrompt = v:FindFirstChild("LaunchSelfPrompt")
                if AimPrompt and FirePrompt and LaunchSelfPrompt then
                    AimPrompt.HoldDuration = aimDur
                    FirePrompt.HoldDuration = tntDur
                    LaunchSelfPrompt.HoldDuration = selfDur
                end
            end
        end
    end

    BetterDavey = vape.Categories.Kits:CreateModule({
        Name = "AutoDavey",
        Tooltip = "makes u look better with davey makes u play like me(i main davey everyday kush)",
        Function = function(callback)
				if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
					vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
					return
				end       
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
			if store.equippedKit ~= "davey" then
				vape:CreateNotification("AutoDavey","Kit required only!",8,"warning")
				return
			end

            if callback then
                setCannonSpeeds(blocks, aim, tnt, aunchself)

               BetterDavey:Clean(blocks.ChildAdded:Connect(function(child)
                    if child:IsA("BasePart") and child.Name == "cannon" and BetterDavey.Enabled then
                        local AimPrompt = child:WaitForChild("AimPrompt")
                        local FirePrompt = child:WaitForChild("FirePrompt")
                        local LaunchSelfPrompt = child:WaitForChild("LaunchSelfPrompt")

                        AimPrompt.HoldDuration = aim
                        FirePrompt.HoldDuration = tnt
                        LaunchSelfPrompt.HoldDuration = aunchself
						BetterDavey:Clean(LaunchSelfPrompt.Triggered:Connect(function(p)
							local humanoid = entitylib.character.Humanoid
						
							if not humanoid then return end
						
							if Speed.Enabled and Fly.Enabled then
								Fly:Toggle(false)
								task.wait(0.025)
								Speed:Toggle(false)
							elseif Speed.Enabled then
								Speed:Toggle(false)
							elseif Fly.Enabled then
								Fly:Toggle(false)
							end
							if AS.Enabled then
								local pickaxe = getPickaxeSlot()
								if hotbarSwitch(pickaxe) or store.hand.tool.Name:lower():find("pickaxe") then
									print('broken')
									bedwars.breakBlock(child)
									bedwars.breakBlock(child)
								end
							else
								bedwars.breakBlock(child)
								bedwars.breakBlock(child)
							end
							if AJ.Enabled then
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
							end
						end))
                    end
                end))
				
				for i, child in blocks:GetChildren() do
                    if child:IsA("BasePart") and child.Name == "cannon" and BetterDavey.Enabled then
                        local AimPrompt = child:WaitForChild("AimPrompt")
                        local FirePrompt = child:WaitForChild("FirePrompt")
                        local LaunchSelfPrompt = child:WaitForChild("LaunchSelfPrompt")

                        AimPrompt.HoldDuration = aim
                        FirePrompt.HoldDuration = tnt
                        LaunchSelfPrompt.HoldDuration = aunchself
						BetterDavey:Clean(LaunchSelfPrompt.Triggered:Connect(function(p)
							local humanoid = entitylib.character.Humanoid
						
							if not humanoid then return end
						
							if Speed.Enabled and Fly.Enabled then
								Fly:Toggle(false)
								task.wait(0.025)
								Speed:Toggle(false)
							elseif Speed.Enabled then
								Speed:Toggle(false)
							elseif Fly.Enabled then
								Fly:Toggle(false)
							end
							if AS.Enabled then
								local pickaxe = getPickaxeSlot()
								if hotbarSwitch(pickaxe) or store.hand.tool.Name:lower():find("pickaxe") then
									bedwars.breakBlock(child)
									bedwars.breakBlock(child)
								end
							else
								bedwars.breakBlock(child)
								bedwars.breakBlock(child)
							end
							if AJ.Enabled then
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
							end
						end))
                    end
				end
			else
                setCannonSpeeds(blocks, defaultaim, defaulttnt, defaultself)
            end
        end
    })
	AJ = BetterDavey:CreateToggle({
		Name = "Auto-Jump",
		Default = true																																																						
	})	
	AS = BetterDavey:CreateToggle({
		Name = "Auto-Switch",
		Default = false																																																						
	})																																																				
	A = BetterDavey:CreateSlider({
		Name = "Aim",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = aim,
		Decimal = 10,
		Function = function(v)
			aim = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	T = BetterDavey:CreateSlider({
		Name = "Tnt",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = tnt,
		Decimal = 10,
		Function = function(v)
			tnt = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	L = BetterDavey:CreateSlider({
		Name = "Launch Self",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = aunchself,
		Decimal = 10,
		Function = function(v)
			aunchself = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	C = BetterDavey:CreateToggle({
		Name = "Customize",
		Default = false,
		Function = function(v)
			A.Object.Visible = v
			T.Object.Visible = v
			L.Object.Visible = v
			if not v then
				aim = 0.158
				tnt = 0.0045
				aunchself = 0.395
			end
		end
	})

end)
run(function() 
    local MatchHistory
    
    MatchHistory = vape.Categories.AltFarm:CreateModule({
        Name = "MatchHistory",
        Tooltip = "Resets your match history",
        Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end      
            if callback then 
                MatchHistory:Toggle(false)
                local TeleportService = game:GetService("TeleportService")
                local data = TeleportService:GetLocalPlayerTeleportData()
                MatchHistory:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
            end
        end,
    }) 
end)

run(function() 
	local AutoBan
	local Mode
	local Delay

	local function AltFarmBAN(cb,delay)
		while cb do
			local kits = {"berserker", "hatter", "flower_bee", "glacial_skater",'void_dragon','card','cat'}
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			for i = 0, 1 do
				local args = {"none", i}
				game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SelectKit"):InvokeServer(unpack(args))		
			end
			task.wait(delay)
		end
	end

	local function SmartBAN(cb,delay)
		local kits = {'metal_detector','berserker','regent','cowgirl','wizard','summoner','pinata','davey','fisherman','gingerbread_man','airbender','ninja','star_collector','winter_lady','blood_assassin','owl','elk_master','seahorse','shielder','bigman','archer','black_market_trader'}
		while cb do
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			task.wait(delay)
		end
	end


	local function NormalBAN(cb,delay)
		local kits = {'metal_detector','cowgirl','wizard','summoner','airbender','ninja','star_collector','blood_assassin','seahorse','agni','dasher','elektra','davey','black_market_trader'}
		while cb do
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			task.wait(delay)
		end
	end

	local function MainBranch(callback,type,delay)
		if type == "Alt Farm" then
			AltFarmBAN(callback,0.1)
		elseif type == "Smart" then
			SmartBAN(callback,delay)
		elseif type == "Normal" then
			NormalBAN(callback,delay)
		else
			AltFarmBAN(callback,0.1)
		end
	end

	AutoBan = vape.Categories.AltFarm:CreateModule({
		Name = "AutoBan",
		Tooltip = 'Automatically bans a kit for you(5v5, ranked only)',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end      
			MainBranch(callback, Mode.Value,(Delay.Value / 1000))
		end,
	})
	Mode = AutoBan:CreateDropdown({
		Name = "Mode",
		Tooltip = "Alt Farm=AutoBans And Auto Selects ur kit used for alt farming insta bans and selection\nSmart=Selects a good/op kit depending on the match\nNormal=Selects basic/good kits for the match",
		List = {"Alt Farm","Smart","Normal"},
		Function = function()
			if Mode.Value == "Smart" or Mode.Value == "Normal" then
				Delay.Object.Visible = true
			else
				Delay.Object.Visible = false
			end
		end
	})
	Delay = AutoBan:CreateSlider({
		Name = "Delay",
		Visible = false,
		Min = 1,
		Max = 1000,
		Suffix = "ms",
	})
end)


run(function()
	local AutoQueue
	local Bypass
	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end       
			if callback then
				if Bypass.Enabled then
					bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
					task.wait(0.025)
					AutoQueue:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
							joinQueue()
						end
					end))
					AutoQueue:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(...)
						bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
						joinQueue()
					end))
				else
					AutoQueue:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							joinQueue()
						end
					end))
					AutoQueue:Clean(vapeEvents.MatchEndEvent.Event:Connect(joinQueue))
				end
			end
		end,
		Tooltip = 'Automatically queues for the next match'
	})
	Bypass = AutoQueue:CreateToggle({
		Name = "Bypass",
		Default = true
	})
end)

run(function()
	local SetFPS
	local FPS
	
	SetFPS = vape.Categories.Utility:CreateModule({
		Name = "SetFPS",
		Function = function(callback)
			if callback then
				setfpscap(FPS.Value)
			else
				setfpscap(240)
			end
		end,
		Tooltip = "Removes or customizes the Frame-Per-Second limit",
	})
	
	FPS = SetFPS:CreateSlider({
		Name = "Frames Per Second",
		Min = 0,
		Max = 420,
		Default = 240,
		Function = function(value)
			setfpscap(value)
		end
	})
end)


local Killaura
local ChargeTime



run(function()
	local CanHit = true
	local MutiAura
	local SophiaCheck
	local MutiAuraDelay
	local SyncHit
	local Targets
	local Sort
	local SwingRange
	local AttackRange
	local AfterSwing
	local UpdateRate
	local AngleSlider
	local MaxTargets
	local Mouse
	local Swing
	local GUI
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local Limit
	local SC 
	local RV
	local HR
	local FastHits
	local HitsDelay
	local AirHit
	local AirHitsChance
	local AfterSwing
	local AfterSwingTime
	local HitRegOption
	local ACheck
	local VisualiserRange
	local HRTR = {
		[1] = 0.042,
		[2] = 0.0042,
	}
	local ClosetMode
	local AttackMode
	local LegitAura = {}
	local Particles, Boxes = {}, {}
	local rand = Random.new()
	local anims, AnimDelay, AnimTween, armC0 = vape.Libraries.auraanims, tick()
	local SwitchIndex = 1
	local LastSwitchTime = 0
	local SwitchDelay
	local Visualiser
	local AttackRemote = {}
	local ASOPT
	local ASMS
	local LastAuraTarget = nil
	local AfterSwingDone = false
	local FROZEN_THRESHOLD = 10
	local CURRENT_LEVEL_FROZEN = 0
	local CurrentSwingTICK = 0
    task.spawn(function()
        AttackRemote = bedwars.Client:Get(remotes.AttackEntity)
    end)
	local lastCustomHitTime = 0

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		if GUI.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end

		local sword = Limit.Enabled and store.hand or store.tools.sword
		if not sword or not sword.tool then return false end

		local meta = bedwars.ItemMeta[sword.tool.Name]
		if Limit.Enabled then
			if store.hand.toolType ~= 'sword' or bedwars.DaoController.chargingMaid then return false end
		end

		if LegitAura.Enabled or ClosetMode.Enabled then
			if (tick() - bedwars.SwordController.lastSwing) >= 0.2 then
				CanHit = false
				return false 
			else
				CanHit = true
			end
		end

		return sword, meta
	end

	local function MutiAuraFunction(Delay,Ade,v,pos,dir,actualRoot,sword)
		if Ade then
			task.wait(Delay)
			for i, v in store.inventory.inventory.items do
				local toolName = tostring(v.itemType)
				local toolMeta = bedwars.ItemMeta[toolName]
				if toolMeta and toolMeta.projectileSource then
					local Slot = getObjSlot(toolName)
					if Slot then
						local switched = hotbarSwitch(Slot)
						if switched then
							mouse1click()
						end
					end
				end
				task.wait(Delay)
			end
		else
			task.wait(Delay)
			for i, v in store.inventory.inventory.items do
				local toolName = tostring(v.itemType)
				local toolMeta = bedwars.ItemMeta[toolName]
				if toolMeta and toolMeta.projectileSource then
					local Slot = getObjSlot(toolName)
					
					if Slot then
						local switched = hotbarSwitch(Slot)
						if switched then
							mouse1click()
						end
					end
				end
				task.wait(Delay)
			end
		end
	end

	local function canHitWithCustomReg()
		if not HitRegOption.Enabled then
			return true
		end
		local currentTime = tick()
		local delayBetweenHits = (10 / HR.Value) * 0.98
		if HR.Value >= 36 then
			return true
		end
		if currentTime - lastCustomHitTime >= delayBetweenHits then
			lastCustomHitTime = currentTime
			return true
		end
		return false
	end


	local function OptimizedAttackData(attackTable)
        if not AttackRemote then return end
        if not canHitWithCustomReg() then return end
		local CanAttackAC = bedwars.SwordController:getTargetInRegion(AttackRange.Value * 3, 0)
		if not ACheck.Enabled then
			CanAttackAC = true
		end
		if not CanAttackAC then return end
        local suc, plr = pcall(function()
            return playersService:GetPlayerFromCharacter(attackTable.entityInstance)
        end)

        local selfpos = attackTable.validate.selfPosition.value
        local targetpos = attackTable.validate.targetPosition.value
        local actualDistance = (selfpos - targetpos).Magnitude

        store.attackReach = (actualDistance * 100) // 1 / 100
        store.attackReachUpdate = tick() + 1

        if actualDistance > 14.4 and actualDistance <= 30 then
            local direction = (targetpos - selfpos).Unit
            
            local moveDistance = math.min(actualDistance - 14.3, 8) 
            attackTable.validate.selfPosition.value = selfpos + (direction * moveDistance)
            
            local pullDistance = math.min(actualDistance - 14.3, 4)
            attackTable.validate.targetPosition.value = targetpos - (direction * pullDistance)
            
            attackTable.validate.raycast = attackTable.validate.raycast or {}
            attackTable.validate.raycast.cameraPosition = attackTable.validate.raycast.cameraPosition or {}
            attackTable.validate.raycast.cursorDirection = attackTable.validate.raycast.cursorDirection or {}
            
            local extendedOrigin = selfpos + (direction * math.min(actualDistance - 12, 15))
            attackTable.validate.raycast.cameraPosition.value = extendedOrigin
            attackTable.validate.raycast.cursorDirection.value = direction
            
            attackTable.validate.targetPosition = attackTable.validate.targetPosition or {value = targetpos}
            attackTable.validate.selfPosition = attackTable.validate.selfPosition or {value = selfpos}
        end

        if suc and plr then
            if not select(2, whitelist:get(plr)) then return end
        end

        return AttackRemote:SendToServer(attackTable)
	end

	local function resolveAttackTargets(plrs)
		if #plrs == 0 then return {} end
		if AttackMode.Value == "Multi" then
			return plrs
		end
		if AttackMode.Value == "Single" then
			local rng = math.random(1,#plrs)
			local index = plrs[rng]
			return {index}
		end
		if AttackMode.Value == "Switch" then
			local now = tick()
			if now - LastSwitchTime >= SwitchDelay.Value then
				SwitchIndex += 1
				if SwitchIndex > #plrs then
					SwitchIndex = 1
				end
				LastSwitchTime = now
			end
			return {plrs[SwitchIndex]}
		end
		return plrs
	end

    local function createRangeCircle()
        Visualiser = Instance.new("MeshPart")
        Visualiser.MeshId = "rbxassetid://3726303797"
        Visualiser.Color = Color3.fromRGB(155,155,155)
        Visualiser.CanCollide = false
        Visualiser.Anchored = true
        Visualiser.Material = Enum.Material.Neon
        Visualiser.Size = Vector3.new(SwingRange.Value * 0.7, 0.01, SwingRange.Value * 0.7)
        if Killaura.Enabled then
            Visualiser.Parent = gameCamera
        end
		bedwars.QueryUtil:setQueryIgnored(Visualiser, true)
    end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = Limit.Enabled
					end)
				end

				if Animation.Enabled and not (identifyexecutor and table.find({'Argon', 'Delta','Codex'}, ({identifyexecutor()})[1])) then
					local fake = {
						Controllers = {
							ViewmodelController = {
								isVisible = function()
									return not Attacking
								end,
								playAnimation = function(...)
									if not Attacking then
										bedwars.ViewmodelController:playAnimation(select(2, ...))
									end
								end
							}
						}
					}
					debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, fake)
					debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, fake)

					task.spawn(function()
						local started = false
						repeat
							if Attacking then
								if not armC0 then
									armC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								local first = not started
								started = true

								if AnimationMode.Value == 'Random' then
									anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
								end

								for _, v in anims[AnimationMode.Value] do
									AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and (AnimationTween.Enabled and 0.001 or 0.1) or v.Time / AnimationSpeed.Value, Enum.EasingStyle.Linear), {
										C0 = armC0 * v.CFrame
									})
									AnimTween:Play()
									AnimTween.Completed:Wait()
									first = false
									if (not Killaura.Enabled) or (not Attacking) then break end
								end
							elseif started then
								started = false
								AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
									C0 = armC0
								})
								AnimTween:Play()
							end

							if not started then
								task.wait(1 / UpdateRate.Value)
							end
						until (not Killaura.Enabled) or (not Animation.Enabled)
					end)
				end

				local swingCooldown = 0
				repeat
					if SophiaCheck.Enabled then
						CURRENT_LEVEL_FROZEN = lplr.Character:GetAttribute("ColdStacks") or lplr.Character:GetAttribute("FrostStacks") or lplr.Character:GetAttribute("FreezeStacks") or 0
						if CURRENT_LEVEL_FROZEN >= FROZEN_THRESHOLD then
							Attacking = false
							store.KillauraTarget = nil
							task.wait(0.3)
							continue
						end
						if not entitylib.isAlive then
							CURRENT_LEVEL_FROZEN = 0
						end
					end					
					local attacked, sword, meta = {}, getAttackData()
                    pcall(function()
                        if entitylib.isAlive and entitylib.character.HumanoidRootPart then
                            tweenService:Create(Visualiser, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = entitylib.character.HumanoidRootPart.Position - Vector3.new(0, entitylib.character.Humanoid.HipHeight, 0)}):Play()
                        end
                    end)
					Attacking = false
					store.KillauraTarget = nil
					if sword then
						if SC.Enabled and entitylib.isAlive and lplr.Character:FindFirstChild("elk") then task.wait(math.max(ChargeTime.Value, 0.08)) continue end
						local isAde = string.find(string.lower(tostring(sword and sword.itemType or "")), "frost_hammer")	
						local nonplrs = entitylib.AllPosition({
							Range = ClosetMode.Enabled and 20 or SwingRange.Value,
							Wallcheck = ClosetMode.Enabled and true or Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = ClosetMode.Enabled and true or Targets.Players.Enabled,
							NPCs = ClosetMode.Enabled and false or Targets.NPCs.Enabled,
							Limit = ClosetMode.Enabled and 1 or MaxTargets.Value,
							Sort = sortmethods[Sort.Value]
						})
						local plrs = resolveAttackTargets(nonplrs)
						if #plrs > 0 then
							if store.equippedKit == "ember" and sword.itemType == "infernal_saber" then
								bedwars.Client:Get('HellBladeRelease'):FireServer({chargeTime = 1, player = lplr, weapon = sword.tool})
							end
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

							for _, v in plrs do
								local delta = (v.RootPart.Position - selfpos)
								local flatDelta = delta * Vector3.new(1, 0, 1)
								if flatDelta.Magnitude < 0.01 then continue end
								local dir = flatDelta.Unit
								local dot = localfacing:Dot(dir)
								local minDot = math.cos(math.rad(AngleSlider.Value) * 0.5)
								if dot < minDot then continue end

								local num = 0
								num = ClosetMode.Enabled and 13 or AttackRange.Value 
								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > num and BoxSwingColor or BoxAttackColor
								})
								targetinfo.Targets[v] = tick() + 1 - 0.005

								if not Attacking then
									Attacking = true
									store.KillauraTarget = v
									LastAuraTarget = v
									AfterSwingDone = false
									if not Swing.Enabled and AnimDelay < tick() and not LegitAura.Enabled then
										AnimDelay = tick() + (meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed or math.max(ChargeTime.Value, 0.11))
										if not ClosetMode.Enabled or not LegitAura.Enabled then
											bedwars.SwordController:playSwordEffect(meta, false)
										end
										if meta.displayName:find(' Scythe') then
											bedwars.ScytheController:playLocalAnimation()
										end

										if vape.ThreadFix then
											setthreadidentity(8)
										end
									end
								end

								if delta.Magnitude > num then continue end

  								if SyncHit.Enabled then
                                    local swingSpeed =  ChargeTime.Value
                                    if (tick() - CurrentSwingTICK) < (swingSpeed * 0.7) then 
                                        continue 
                                    end
                                    local timeSinceLastSwing = tick() - CurrentSwingTICK * (1.98 / (meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed + math.max(ChargeTime.Value, 0.08)))
                                    local requiredDelay = math.max(swingSpeed * 0.8, 0.1) 
                                    if timeSinceLastSwing < requiredDelay then 
                                        continue 
                                    end
                                end


								local actualRoot = v.Character.PrimaryPart
								if actualRoot then
									--CurrentSwingTICK = tick()
									local dir = CFrame.lookAt(selfpos, actualRoot.Position).LookVector
									local pos = selfpos + dir * math.max(delta.Magnitude - 14.399, 0)
									swingCooldown = SyncHit.Enabled and (tick() - HRTR[1]) or tick()
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									bedwars.SwordController.lastSwingServerTime = SyncHit.Enabled and workspace:GetServerTimeNow() - HRTR[2] or workspace:GetServerTimeNow() - tick()
									store.attackReach = SyncHit.Enabled and ((delta.Magnitude * 100) // 1 / 100 - HRTR[1] - 0.055) or (delta.Magnitude * 100) // 1 / 100
									store.attackReachUpdate = SyncHit.Enabled and (tick() + 1 - HRTR[2]) or tick() 
									if not SyncHit.Enabled or (tick() - CurrentSwingTICK) >= 0.1 then
                                        CurrentSwingTICK = tick()
                                    end
									if delta.Magnitude < 14.4 and ChargeTime.Value > 0.11 then
										AnimDelay =  tick()
									end
									local Q = 0.5
									if MutiAura.Enabled and not ClosetMode.Enabled then
										if AirHit.Enabled or ClosetMode.Enabled then
											local chance =  math.random(0,100)
											local state = v.Character.Humanoid:GetState()
											if state == Enum.HumanoidStateType.Jumping then
												if chance > AirHitsChance.Value then 
													CanHit = false
													continue
												else
													CanHit = true
												end
											elseif state == Enum.HumanoidStateType.Freefall then
												if chance > AirHitsChance.Value then
													CanHit = false 
													continue 
												else
													CanHit = true
												end
											else
												CanHit = true
											end
										else
											CanHit = true
										end
										if CanHit then
											local Delay = (MutiAuraDelay.Value / 1000)
											local rng = math.random(0,100)
											if rng >= 58 then -- TEMP NUMBER FOR NOW
												if isAde then
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												else
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												end
												MutiAuraFunction(Delay,isAde,v,pos,dir,actualRoot,sword)
											else
												if isAde then
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												else
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												end
											end
										end
									else
										if SyncHit.Enabled  then Q = 0.35 else Q = 0.5 end
										if AirHit.Enabled or ClosetMode.Enabled then
												local chance = math.random(0,100)
												local state = v.Character.Humanoid:GetState()
												if state == Enum.HumanoidStateType.Jumping then
													if chance > AirHitsChance.Value then 
														CanHit = false
														continue
													else
														CanHit = true
													end
												elseif state == Enum.HumanoidStateType.Freefall then
													if chance > AirHitsChance.Value then
														CanHit = false 
														continue 
													else
														CanHit = true
													end
												else
													CanHit = true
												end
											else
												CanHit = true
											end
											if CanHit then
												if isAde then
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												else
													local Data = {
														weapon = sword.tool,
														chargedAttack = {chargeRatio = 0},
														entityInstance = v.Character,
														validate = {
															raycast = {cameraPosition = {value = pos + Vector3.new(0, 2, 0)}, cursorDirection = {value = dir}},
															targetPosition = {value = actualRoot.Position},
															selfPosition = {value = pos+ Vector3.new(0, 1, 0)}
														}
													}
													OptimizedAttackData(Data)
												end
												local currentSwingSpeed = ChargeTime.Value
												local minSwingDelay = math.max(currentSwingSpeed, 0.05)
												
												if not SyncHit.Enabled or (tick() - CurrentSwingTICK) >= minSwingDelay then
													CurrentSwingTICK = tick()
												end
											end
									end
								end
							end
						else
							if LastAuraTarget and not AfterSwingDone and ASOPT.Enabled and meta then
								AfterSwingDone = true
								task.spawn(function()
									for i = 1, ASMS.GetRandomValue() do
										if not Killaura.Enabled then break end
										if not entitylib.isAlive then break end
										bedwars.SwordController:playSwordEffect(meta, false)
										task.wait(math.max(ChargeTime.Value * 0.35, 0.045))
									end
								end)
							end
							LastAuraTarget = nil
						end
					end

					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end

					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end

					if Face.Enabled and attacked[1] then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.001, vec.Z))
					end
					local tme = 0
					if SyncHit.Enabled then
						tme = math.random()
					elseif ClosetMode.Enabled then
						tme = (-0.0042)
					else
						tme = 0
					end
					task.wait(1 / UpdateRate.Value - (tme))
				until not Killaura.Enabled
			else
				CURRENT_LEVEL_FROZEN = 0
				store.KillauraTarget = nil
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = true
					end)
				end
				debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, bedwars.Knit)
				debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, bedwars.Knit)
				Attacking = false
				if armC0 then
					AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
						C0 = armC0
					})
					AnimTween:Play()
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end

	HR = Killaura:CreateSlider({
		Name = 'Hit Registration',
		Min = 1,
		Max = 36,
		Default = 36,
		Darker = true,
		Function = function(val)
			local function RegMath(sliderValue)
				local minValue1 = 0.022
				local maxValue1 = 0.025

				local minValue2 = 0.0022
				local maxValue2 = 0.0025

				local steps = 52

				local value1 = minValue1 + ((sliderValue - 1) * ((maxValue1 - minValue1) / steps * 0.98))
				local value2 = minValue2 + ((sliderValue - 1) * ((maxValue2 - minValue2) / steps * 0.98))

				return math.abs(value1), math.abs(value2)
			end

			if Killaura.Enabled then
				local v1,v2 = RegMath(val)
				HRTR[1] = v1
				HRTR[2] = v2
			end
		end
	})
	HitRegOption = Killaura:CreateToggle({
		Name = "Hit Registration Option",
		Default = true,
		Tooltip = 'enables the custom hit registration feature',
		Function = function(v)
			HR.Object.Visible = v
		end
	})
	AirHitsChance = Killaura:CreateSlider({
		Name = 'Air Hits Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = "%",
		Decimal = 5,
		Tooltip = 'checks if it can hit someone when they are in the air',
		Darker = true
	})
	AirHit = Killaura:CreateToggle({
		Name = "Air Hits",
		Default = true,
		Tooltip = 'enables the air hits feature',
		Function = function(v)
			AirHitsChance.Object.Visible = v
		end
	})
	ASMS = Killaura:CreateTwoSlider({
		Name = 'After Swing Amount',
		Min = 0,
		Max = 12,
		DefaultMin = 4,
		DefaultMax = 10,
		Tooltip = 'keeps swinging based X amount of times',
		Darker = true,
		Visible = false
	})
	ASOPT = Killaura:CreateToggle({
		Name = "After Swing",
		Default = false,
		Tooltip = 'enables the after swing feature',
		Function = function(v)
			ASMS.Object.Visible = v
		end
	})
	local MaxRange = 0
	local CE = false
	if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"  then
		MaxRange = 12
		CE = false
		SyncHit = {Enabled = false}
	elseif role == "user" then
		MaxRange = 16
		CE = false
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false,
		})
	elseif role == "premium" then
		MaxRange = 17
		CE = true
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false,
		})
	elseif role == "friend" or role == "admin" or role == "coowner" or role == "owner" then
		MaxRange = 20
		CE = true
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false,
		})
	else
		MaxRange = 12
		SyncHit = {Enabled = false}
	end

	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Edit = CE,
		Max = 32,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Function = function(val)
			if Visualiser and VisualiserRange.Enabled then
				Visualiser.Size = Vector3.new(val * 0.7, 0.01, val * 0.7)
			else
				--warn('jewish boy')
			end
		end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = MaxRange,
		Edit = CE,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	ChargeTime = Killaura:CreateSlider({
		Name = 'Swing time',
		Min = 0,
		Max = 1.5,
		Default = 0.3,
		Decimal = 100
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	MutiAuraDelay = Killaura:CreateSlider({
		Name = "Muti Aura Delay",
		Min = 0,
		Max = 1000,
		Default = 250,
		Darker = true,
		Suffix = 'ms',
		Visible = false
	})
	MutiAura = Killaura:CreateToggle({
		Name = "MutiAura",
		Tooltip = 'you need projectiles for this',
		Default = false,

		Function = function(v)
			MutiAuraDelay.Object.Visible = v
		end
	})
	SwitchDelay = Killaura:CreateSlider({
		Name = 'Switch Delay',
		Min = 0,
		Max = 3,
		Default = 0.15,
		Decimal = 5,
		Suffix = 'ms',
		Visible = false
	})				
	AttackMode = Killaura:CreateDropdown({
		Name = "AttackMode",
		List = {'Single','Multi','Switch'},
		Default = 'Multi',
		Tooltip = 'Single only attacks one player\nMulti is just the legacy act in ka\nSwitch cycles between targets',
		Function = function()
			local v = AttackMode.Value
			SwitchDelay.Object.Visible = v == "Switch"
			print(SwitchDelay.Object.Visible)
		end
	})
	UpdateRate = Killaura:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 360,
		Default = 60,
		Suffix = 'hz'
	})
	MaxTargets = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 8,
		Default = 5
	})
	Sort = Killaura:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	ACheck = Killaura:CreateToggle({Name = 'Attackable Check',Tooltip='checks if the current target is possible to hit'})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	GUI = Killaura:CreateToggle({Name = 'GUI check'})
	VisualiserRange = Killaura:CreateToggle({
        Name = "Range Visualiser",
        Function = function(cb)
            if cb then
                createRangeCircle()
            else
                if Visualiser then
                    Visualiser:Destroy()
                    Visualiser = nil
                end
            end
        end
    })
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	Face = Killaura:CreateToggle({Name = 'Face target'})
	Animation = Killaura:CreateToggle({
		Name = 'Custom Animation',
		Function = function(callback)
			AnimationMode.Object.Visible = callback
			AnimationTween.Object.Visible = callback
			AnimationSpeed.Object.Visible = callback
			if Killaura.Enabled then
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = Killaura:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true,
		Visible = false
	})
	AnimationSpeed = Killaura:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true,
		Visible = false
	})
	AnimationTween = Killaura:CreateToggle({
		Name = 'No Tween',
		Darker = true,
		Visible = false
	})
	Limit = Killaura:CreateToggle({
		Name = 'Limit to items',
		Function = function(callback)
			if inputService.TouchEnabled and Killaura.Enabled then
				pcall(function()
					lplr.PlayerGui.MobileUI['2'].Visible = callback
				end)
			end
		end,
		Tooltip = 'Only attacks when the sword is held'
	})

	LegitAura = Killaura:CreateToggle({
		Name = 'Legit Aura',
		Tooltip = 'Only attacks when the mouse is clicking'
	})
	SC = Killaura:CreateToggle({Name='Sigird Check',Default=true})
	ClosetMode = Killaura:CreateToggle({Name='Closet Mode',Default=false})
	SophiaCheck = Killaura:CreateToggle({
		Name='Sophia Check',
		Default=true,
		Function = function(v)
			if not v then
				CURRENT_LEVEL_FROZEN = 0
			end
		end
	})

end)


run(function()
    local TypeData
    local PlayerData
    local includeEmptyMatches
	local Clean
    PlayerData = vape.Categories.Exploits:CreateModule({
        Name = "PlayerData",
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
	    	if not callback then return end

            local http = httpService
            local store = bedwars.Store:getState()

            if TypeData.Value == "important" then
                local stats = {}
                local totals = {
                    TotalWins = 0,
                    TotalLosses = 0,
                    TotalMatches = 0,
                    TotalBedBreaks = 0,
                    TotalFinalKills = 0
                }

                local leaderboard = store and store.Leaderboard and store.Leaderboard.queues

                if leaderboard then
                    for mode, data in pairs(leaderboard) do
                        local wins = data.wins or 0																
                        local losses = data.losses or 0
						local ties = data.ties or 0
                        local matches = data.matches or (wins + losses + tie)
                        local winrate = (wins + losses + ties > 0) and ((wins / (wins + losses + ties)) * 100) or 0
						local earlyleaves = data.earlyLeaves or 0
                        local bedBreaks = data.bedBreaks or 0
                        local finalKills = data.finalKills or 0

                        totals.TotalWins += wins
                        totals.TotalLosses += losses
                        totals.TotalMatches += matches
                        totals.TotalBedBreaks += bedBreaks
                        totals.TotalFinalKills += finalKills

                        if includeEmptyMatches.Value or (wins > 0 or losses > 0 or matches > 0 ) then
                            stats[mode] = {
                                Winrate = string.format("%.2f%%", winrate),
                                Wins = wins,
                                Losses = losses,
								Ties = ties,
                                Matches = matches,
								EarlyLeaves = earlyleaves,
                                BedBreaks = bedBreaks,
                                FinalKills = finalKills
                            }
                        end
                    end
                end

                local achievements = {}
                if store and store.Bedwars and store.Bedwars.achievements then
                    for _, ach in pairs(store.Bedwars.achievements) do
                        table.insert(achievements, ach)
                    end
                elseif leaderboard and leaderboard.bedwars_duels and leaderboard.bedwars_duels.obtainedAchievements then
                    achievements = leaderboard.bedwars_duels.obtainedAchievements
                end

                local dataOut = {
					GameModes = stats,
                    Totals = totals,
                    Achievements = achievements
                }
				if Clean then
					local json = http:JSONEncode(dataOut)
	                json = json:gsub(',"', ',\n    "')
	                json = json:gsub('{', '{\n    ')
	                json = json:gsub('}', '\n}')
	
	                writefile("ReVape/profiles/PlayerData.txt", json)
	                vape:CreateNotification("PlayerData", "Created PlayerData.txt file at profiles", 10)
					else
						local json = dataOut
						
                		writefile("ReVape/profiles/PlayerData.txt", json)
                		vape:CreateNotification("PlayerData", "Created PlayerData.txt file at profiles", 10)
					end
            elseif TypeData.Value == "full" then

				if Clean then
					local json = http:JSONEncode(bedwars.Store:getState())
	                json = json:gsub(',"', ',\n    "')
	                json = json:gsub('{', '{\n    ')
	                json = json:gsub('}', '\n}')
	
	                writefile("ReVape/profiles/PlayerDataJSON.txt", json)
	                vape:CreateNotification("PlayerData", "Created PlayerData.json file at profiles", 10)
					else
						local json = http:JSONEncode(bedwars.Store:getState())
						
                		writefile("ReVape/profiles/PlayerDataJSON.txt", json)
                		vape:CreateNotification("PlayerData", "Created PlayerData.json file at profiles", 10)
					end
            end
		PlayerData:Toggle()
        end,
        Tooltip = "Creates a file that has your data"
    })

    TypeData = PlayerData:CreateDropdown({
        Name = "Type",
        List = {"important", "full"}
    })

    includeEmptyMatches = PlayerData:CreateToggle({
        Name = "EmptyMatches",
        Default = false,
        Tooltip = "ONLY FOR IMPORTANT TYPE (adds 0-stats matches to your file)"
    })
	Clean = PlayerData:CreateToggle({
        Name = "Clean",
        Default = true,
        Tooltip = "Cleans up the JSON file"
    })
end)



run(function()
	local LP 
	 LP = vape.Categories.Exploits:CreateModule({
		Name = "LeaveParty",
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end   																															
			if callback then
				LP:Toggle(false)
				bedwars.PartyController:leaveParty()
			end
		end,
		Tooltip = "Makes u leave ur current party",
	})
end)

run(function()
	local Desync
	local New
	Desync = vape.Categories.World:CreateModule({
		Name = 'Desync',
		Function = function(callback)
			local function cb1()

				if not setfflag then vape:CreateNotification("Onyx", "Your current executor '"..identifyexecutor().."' does not support setfflag", 6, "warning"); return end     
				if New.Enabled then
					repeat
						setfflag('DFIntDebugDefaultTargetWorldStepsPerFrame', '-2147483648')
						setfflag('DFIntMaxMissedWorldStepsRemembered', '-2147483648')
						setfflag('DFIntWorldStepsOffsetAdjustRate', '2147483648')
						setfflag('DFIntDebugSendDistInSteps', '-2147483648')
						setfflag('DFIntWorldStepMax', '-2147483648')
						setfflag('DFIntWarpFactor', '2147483648')
						task.wait()
					until not Desync.Enabled
				else
					if callback then
						setfflag('NextGenReplicatorEnabledWrite4', 'true')
					else
						setfflag('NextGenReplicatorEnabledWrite4', 'false')
					end
				end

			end
			local function cb2()
				vape:CreateNotification("Desync","Disabled...",8,'warning')
				setfflag('NextGenReplicatorEnabledWrite4', 'false')

			end
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			vape:CreatePoll("Desync","Are you sure you want to use this?",8,"warning",cb1,cb2)
		end,
		Tooltip = 'Note this will ban you for client modifications.'
	})
	New = Desync:CreateToggle({Name="New",Tooltip='this uses the new method(u can hit people)',Default=false})
end)



run(function()
    local Antihit = {Enabled = false}
    local Range, TimeUp, Down = 16, 0.2,0.05

    Antihit = vape.Categories.Blatant:CreateModule({
        Name = "AntiHit",
        Function = function(call)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
            if call then
                task.spawn(function()
                    while Antihit.Enabled do
                        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local orgPos = root.Position
                            local foundEnemy = false

                            for _, v in next, playersService:GetPlayers() do
                                if v ~= lplr and v.Team ~= lplr.Team then
                                    local enemyChar = v.Character
                                    local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
                                    local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
                                    if enemyRoot and enemyHum and enemyHum.Health > 0 then
                                        local dist = (root.Position - enemyRoot.Position).Magnitude
                                        if dist <= Range.Value then
                                            foundEnemy = true
                                            break
                                        end
                                    end
                                end
                            end

                            if foundEnemy then
                                root.CFrame = CFrame.new(orgPos + Vector3.new(0, -230, 0))
                                task.wait(TimeUp.Value)
                                if Antihit.Enabled and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") then
                                    lplr.Character.HumanoidRootPart.CFrame = CFrame.new(orgPos)
                                end
                            end
                        end
                        task.wait(Down.Value)
                    end
                end)
            end
        end,
        Tooltip = "Prevents you from dying"
    })

    Range = Antihit:CreateSlider({
        Name = "Range",
        Min = 0,
        Max = 50,
        Default = 15,
        Function = function(val) Range.Value = val end
    })

    TimeUp = Antihit:CreateSlider({
        Name = "Time Up",
        Min = 0,
        Max = 1,
        Default = 0.2,
        Function = function(val) TimeUp.Value = val end
    })

    Down = Antihit:CreateSlider({
        Name = "Time Down",
        Min = 0,
        Max = 1,
        Default = 0.05,
        Function = function(val) Down.Value = val end
    })
end)




run(function()
    local DamageAffect = {Enabled = false}
	local Color
    local connection
	local Fonts
	local customMSG
	local DamageMessages = {
		'Pow!',
		'Pop!',
		'Hit!',
		'Smack!',
		'Bang!',
		'Boom!',
		'Whoop!',
		'Damage!',
		'-9e9!',
		'Whack!',
		'Crash!',
		'Slam!',
		'Zap!',
		'Snap!',
		'Thump!',
		'Ouch!',
		'Crack!',
		'Bam!',
		'Clap!',
		'Blitz!',
		'Crunch!',
		'Shatter!',
		'Blast!',
		'Womp!',
		'Thunk!',
		'Zing!',
		'Rip!',
		'Rattle!',
		'Kaboom!',
		'Wack!',
		'Boomer!',
		'Slammer!',
		'Powee!',
		'Zappp!',
		'Thunker!',
		'Rippler!',
		'Bap!',
		'Bomp!',
		'Sock!',
		'Chop!',
		'Sting!',
		'Slice!',
		'Swipe!',
		'Punch!',
		'Tonk!',
		'Bonk!',
		'Jolt!',
		'Spike!',
		'Pierce!',
		'Crush!',
		'Bruise!',
		'Ding!',
	    'Clang!',
		'Crashhh!',
		'Kablam!',
		'Zapshot!',
		'Oynx On top!'
	}
	
	local RGBColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 127, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(148, 0, 211)
	}
	
	local function randomizer(tbl)
	    if not typeof(tbl) == "table" then return end
	    local index = math.random(1,#tbl)
	    local value = tbl[index]
	    return value,index
	end
	local font  = 'Arial'
    DamageAffect = vape.Categories.Render:CreateModule({
        Name = "DamageAffects",
        Function = function(call)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
			if call then
				DamageAffect:Clean(workspace.DescendantAdded:Connect(function(part)
				    if part.Name == "DamageIndicatorPart" and part:IsA("BasePart") then
				        for i, v in part:GetDescendants() do
				            if v:IsA("TextLabel") then
				                local txt = randomizer(DamageMessages)
				                local clr = randomizer(RGBColors)
								if customMSG.Enabled then
				                	v.Text = txt
								end
								if Color.Enabled then
				              	  	v.TextColor3 = clr
								end
								v.FontFace = font
				            end
				        end
				    end
				end))
			else

			end
        end,
        Tooltip = "Customizes Damage Affects"
    })
	customMSG = DamageAffect:CreateToggle({
		Name = "Custom Messages",
		Default = true
	})
	Color = DamageAffect:CreateToggle({
		Name = "Custom Colors",
		Default = true
	})
	Fonts = DamageAffect:CreateFont({
		Name = 'Font',
		Function = function(val)
			font = val
		end
	})
end)

	
run(function()
	local FlyY 
	local Fly
	local Heal
	local HealthHP
	local AutoSummon
	local PlrUserTxt
	local isWhispering = false
	local BetterWhisper
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

    BetterWhisper = vape.Categories.Kits:CreateModule({
        Name = 'AutoWhisper',
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end	
            if callback then
			if store.equippedKit ~= "owl" then
				vape:CreateNotification("AutoWhisper","Kit required only!",8,"warning")
				return
			end
				BetterWhisper:Clean(bedwars.Client:Get("OwlSummoned"):Connect(function(plr,target)
					if plr == lplr then
						local chr = target.Character
						local hum = chr:FindFirstChild('Humanoid')
						local root = chr:FindFirstChild('HumanoidRootPart')
						isWhispering = true
						repeat
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
							rayCheck.CollisionGroup = root.CollisionGroup

							if Fly.Enabled and root.Velocity.Y <= FlyY.Value and not workspace:Raycast(root.Position, Vector3.new(0, -100, 0), rayCheck) then
								WhisperController:request("Fly")
							end
							if Heal.Enabled and hum.Health <= HealthHP.Value then
								WhisperController:request("Heal")
							end
							task.wait(0.05)
						until not isWhispering or not BetterWhisper.Enabled
					end
				end))
				BetterWhisper:Clean(bedwars.Client:Get("OwlDeattached"):Connect(function(plr)
					if plr == lplr then
						isWhispering = false
					end
				end))
			else
				isWhispering = false
			end
        end,
        Tooltip = "Better whisper skills and u look like u play like therac!"
    })
	FlyY = BetterWhisper:CreateSlider({
		Name = 'Y-Level fly',																																																																							
		Min = -50,
		Max = -100,
		Default = -90,
	})	
	HealthHP = BetterWhisper:CreateSlider({
		Name = 'Heal HP',																																																																							
		Min = 1,
		Max = 99,
		Default = 80,
	})	
	Fly = BetterWhisper:CreateToggle({
		Name = 'Fly',
		Default = true,
	})
	Heal = BetterWhisper:CreateToggle({
		Name = 'Heal',
		Default = true,
	})
end)
	



run(function()
	local BCR
	local Value
	local old
	local inf = math.huge or 9e9
	BCR = vape.Categories.Blatant:CreateModule({
		Name = "BlockCPSRemover",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
			if callback then
				old = bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS']
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
			else
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = old
				old = nil
			end
		end,
	})
	Value = BCR:CreateSlider({
		Name = "CPS",
		Suffix = "s",
		Tooltip = "Changes the limit to the CPS cap(0 = remove)",
		Default = 13.5,
		Min = 0,
		Max = 100,
		Function = function()
			if BCR.Enabled then
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
			else
				if old == nil then old = 12 end
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = old
				old = nil
			end
		end,
		
	})
	BCR:CreateButton({
		Name = "Reset CPS",
		Function = function()
			if old then
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = old
				old = nil				
			end
			Value:SetValue(12)
		end
	})
end)

run(function()
	local FlySpeed
	local VerticalSpeed
	local SafeMode
	local rayCheck = RaycastParams.new()
	local oldroot
	local clone
	local FlyLandTick = tick()
	local performanceStats = game:GetService('Stats'):FindFirstChild('PerformanceStats')
	local hip = 2.6

	local function createClone()
		if entitylib.isAlive and entitylib.character.Humanoid.Health > 0 and (not oldroot or not oldroot.Parent) then
			hip = entitylib.character.Humanoid.HipHeight
			oldroot = entitylib.character.HumanoidRootPart
			if not lplr.Character.Parent then return false end
			lplr.Character.Parent = game
			clone = oldroot:Clone()
			clone.Parent = lplr.Character
			--oldroot.CanCollide = false
			oldroot.Transparency = 0
			Instance.new('Highlight', oldroot)
			oldroot.Parent = gameCamera
			store.rootpart = clone
			bedwars.QueryUtil:setQueryIgnored(oldroot, true)
			lplr.Character.PrimaryPart = clone
			lplr.Character.Parent = workspace
			for _, v in lplr.Character:GetDescendants() do
				if v:IsA('Weld') or v:IsA('Motor6D') then
					if v.Part0 == oldroot then v.Part0 = clone end
					if v.Part1 == oldroot then v.Part1 = clone end
				end
			end
			return true
		end
		return false
	end
	local function destroyClone()
		if not oldroot or not oldroot.Parent or not entitylib.isAlive then return false end
		lplr.Character.Parent = game
		oldroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldroot
		lplr.Character.Parent = workspace
		for _, v in lplr.Character:GetDescendants() do
			if v:IsA('Weld') or v:IsA('Motor6D') then
				if v.Part0 == clone then v.Part0 = oldroot end
				if v.Part1 == clone then v.Part1 = oldroot end
			end
		end
		oldroot.CanCollide = true
		if clone then
			clone:Destroy()
			clone = nil
		end
		entitylib.character.Humanoid.HipHeight = hip or 2.6
		oldroot.Transparency = 1
		oldroot = nil
		store.rootpart = nil
		FlyLandTick = tick() + 0.01
	end
	local up = 0
	local down = 0
	local startTick = tick()
	InfiniteFly = vape.Categories.Blatant:CreateModule({
		Name = 'InfiniteFly',
		Tooltip = 'Makes you go zoom.',
		Function = function(callback)
			if callback then
				task.wait()
				startTick = tick()
				if not entitylib.isAlive or FlyLandTick > tick() or not isnetworkowner(entitylib.character.RootPart) then
					return InfiniteFly:Toggle(false)
				end
				local a, b = pcall(createClone)
				if not a then
					return InfiniteFly:Toggle(false)
				end
				rayCheck.FilterDescendantsInstances = {lplr.Character, oldroot, clone, gameCamera}
				InfiniteFly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				InfiniteFly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				local lastY = entitylib.character.RootPart.Position.Y
				local lastVelo = 0
				local cancelThread = false
				InfiniteFly:Clean(runService.PreSimulation:Connect(function(delta)
					if not entitylib.isAlive or not clone or not clone.Parent or not isnetworkowner(oldroot) or (workspace:GetServerTimeNow() - lplr:GetAttribute('LastTeleported')) < 2 then
						if not isnetworkowner(oldroot) then
							notif('InfiniteFly', 'AC detected, Landing', 1.1, 'alert')
						end
						return InfiniteFly:Toggle(false)
					end
					FlyLandTick = tick() + 0.1
					local mass = 1.3 + ((up + down) * VerticalSpeed.Value)
					local moveDir = entitylib.character.Humanoid.MoveDirection
					local velo = getSpeed()
					local destination = (moveDir * math.max(FlySpeed.Value - velo, 0) * delta)
					clone.CFrame = clone.CFrame + destination
					clone.AssemblyLinearVelocity = (moveDir * velo) + Vector3.new(0, mass, 0)
					rayCheck.FilterDescendantsInstances = {lplr.Character, oldroot, clone, gameCamera}
					local raycast = workspace:Blockcast(oldroot.CFrame + Vector3.new(0, 250, 0), Vector3.new(3, 3, 3), Vector3.new(0, -500, 0), rayCheck)
					local groundcast = workspace:Blockcast(clone.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, -3, 0), rayCheck)
					local upperRay = not workspace:Blockcast(oldroot.CFrame + (oldroot.CFrame.LookVector * 17), Vector3.new(3, 3, 3), Vector3.new(0, -150, 0), rayCheck) and workspace:Blockcast(oldroot.CFrame + (oldroot.CFrame.LookVector * 17), Vector3.new(3, 3, 3), Vector3.new(0, 150, 0), rayCheck)
					local changeYLevel = 300
					local yLevel = 0
					if lastVelo - oldroot.AssemblyLinearVelocity.Y > 1200 then
						oldroot.CFrame = oldroot.CFrame + Vector3.new(0, 200, 0)
					end
					for i,v in {50, 1000, 2000, 3000, 4000, 5000, 6000, 7000} do
						if oldroot.AssemblyLinearVelocity.Y < -v then
							changeYLevel = changeYLevel + 100
							yLevel = yLevel - 15
						end
					end
					lastVelo = oldroot.AssemblyLinearVelocity.Y
					if raycast then
						oldroot.AssemblyLinearVelocity = Vector3.zero
						oldroot.CFrame = groundcast and clone.CFrame or CFrame.lookAlong(Vector3.new(clone.Position.X, raycast.Position.Y + hip, clone.Position.Z), clone.CFrame.LookVector)
					elseif (oldroot.Position.Y < (lastY - (200 + yLevel))) and not cancelThread and (oldroot.AssemblyLinearVelocity.Y < -200 or not upperRay) then
						if upperRay then
							oldroot.CFrame = CFrame.lookAlong(Vector3.new(oldroot.CFrame.X, upperRay.Position.Y, oldroot.CFrame.Z), clone.CFrame.LookVector)
						else
							oldroot.CFrame = oldroot.CFrame + Vector3.new(0, changeYLevel, 0)
						end
						if oldroot.AssemblyLinearVelocity.Y < -800 then
							oldroot.AssemblyLinearVelocity = oldroot.AssemblyLinearVelocity + Vector3.new(0, 1, 0)
						end
					end
					oldroot.CFrame = CFrame.lookAlong(Vector3.new(clone.Position.X, oldroot.Position.Y, clone.Position.Z), clone.CFrame.LookVector)
				end))
			else
				notif('InfiniteFly', tostring(tick() - startTick):sub(1, 4).. 's', 4, 'alert')
				if (SafeMode.Enabled and (tick() - startTick) > 3) or performanceStats.Ping:GetValue() > 180 then
					oldroot.CFrame = CFrame.new(-9e9, 0, -9e9)
					clone.CFrame = CFrame.new(-9e9, 0, -9e9)
				end
				destroyClone()
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end
	})
	FlySpeed = InfiniteFly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23
	})
	VerticalSpeed = InfiniteFly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 70
	})
	SafeMode = InfiniteFly:CreateToggle({
		Name = 'Safe Mode'
	})
end)

run(function()
	local InfiniteJump
	local Mode
	local jumps = 0
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	InfiniteJump = vape.Categories.Blatant:CreateModule({
		Name = "Infinite Jump",
		Tooltip = "Allows you to jump infinitely.",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
			if callback then
				local tpTick, tpToggle, oldy = tick(), true
				jumps = 0														
				InfiniteJump:Clean(inputService.JumpRequest:Connect(function()
					jumps += 1
					if jumps > 1 and Mode.Value == "Velocity" then
						local power = math.sqrt(2 * workspace.Gravity * entitylib.character.Humanoid.JumpHeight)
						entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, power, entitylib.character.RootPart.Velocity.Z)
						if tpToggle then
							local airleft = (tick() - entitylib.character.AirTime)
							if airleft > 2 then
								if not oldy then
									local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
									if ray and TP.Enabled then
										tpToggle = false
										oldy = root.Position.Y
										tpTick = tick() + 0.11
										root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
									end
								end
							end
						else
							if oldy then
								if tpTick < tick() then
									local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
									root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
									tpToggle = true
									oldy = nil
								else
									mass = 0
								end
							end
						end
					elseif Mode.Value == "Jump" then
						
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						if tpToggle then
							local airleft = (tick() - entitylib.character.AirTime)
							if airleft > 2 then
								if not oldy then
									local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
									if ray and TP.Enabled then
										tpToggle = false
										oldy = root.Position.Y
										tpTick = tick() + 0.11
										root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
									end
								end
							end
						else
							if oldy then
								if tpTick < tick() then
									local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
									root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
									tpToggle = true
									oldy = nil
								else
									mass = 0
								end
							end
						end
					end
				end))
			end
		end,
		ExtraText = function() return Mode.Value or "HeatSeeker" end
	})
	Mode = InfiniteFly:CreateDropdown({
		Name = "Mode",
		List = {"Jump", "Velocity"}
	})
	TP = InfiniteFly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)



run(function()
	local BackTrack
	local NetworkClient = cloneref(game:GetService("NetworkClient"))
	local NetworkSettings = settings():GetService("NetworkSettings")
	local BackTrackIncoming
	local KPS
	local Ticks
	local Lag
	local Types
	local heartbeatDt = 1 / 60


	local function applyNetwork()
		if not BackTrack.Enabled then
			NetworkClient:SetOutgoingKBPSLimit(math.huge)
			NetworkSettings.IncomingReplicationLag = 0
			return
		end
		BackTrack:Clean(runService.Heartbeat:Connect(function(dt)
			heartbeatDt = dt
		end))
		NetworkClient:SetOutgoingKBPSLimit(math.max(1, KPS.Value))

		if BackTrackIncoming.Enabled then
			local tickLag = Ticks.Value * heartbeatDt
			local baseLag = Lag.Value / 1000

			local finalLag = math.clamp(baseLag + tickLag, 0, 5)
			if Types.Value == "Dynamic" then
				local velocity = entitylib.character.HumanoidRootPart.Velocity.Magnitude
				if velocity > 20 then
					finalLag = finalLag * (1 + 3 * 0.5)
				end
					
				local lastDamage = entitylib.character.Character:GetAttribute('LastDamageTakenTime') or 0
				if tick() - lastDamage < 2 then
					finalLag = finalLag * (1 + 3 * 0.7)
				end
			elseif Types.Value == "LagBased" then
				local LastTP = lplr:GetAttribute('LastTeleport') or (os.time() - 2)
				local dec = 1 + (math.random() + Random.new():NextNumber(2,4))
				LastTP = LastTP + dec
				if os.time() - LastTP < 2 then
					finalLag = finalLag * (1 + 3 * 0.8)
				else
					finalLag = finalLag * (1 + 3 * 0.3)
				end
			elseif Types.Value == "Manual" then
				finalLag = finalLag - ((math.random() + Random.new():NextNumber(2,4)))
			end
			NetworkSettings.IncomingReplicationLag = finalLag
		else
			NetworkSettings.IncomingReplicationLag = 0
		end
	end

	BackTrack = vape.Categories.Blatant:CreateModule({
		Name = "BackTrack",
		Tooltip = "PositionRaper",
		Function = function(callback)
			if callback then
				applyNetwork()
			else
				NetworkClient:SetOutgoingKBPSLimit(math.huge)
				NetworkSettings.IncomingReplicationLag = 0
			end
		end
	})

	Types = BackTrack:CreateDropdown({
		Name = "Types",
		List = {'LagBased','Dynamic','Manual'},
		Default = 'Manual'
	})
	
	BackTrackIncoming = BackTrack:CreateToggle({
		Name = "Incoming",
		Default = true,
		Function = function()
			applyNetwork()
		end
	})

	KPS = BackTrack:CreateSlider({
		Name = "KPS Limit",
		Min = 1,
		Max = 250,
		Default = 25,
		Function = function()
			applyNetwork()
		end
	})

	Ticks = BackTrack:CreateSlider({
		Name = "Ticks",
		Min = 0,
		Max = 30,
		Default = 8,
		Function = function()
			applyNetwork()
		end
	})

	Lag = BackTrack:CreateSlider({
		Name = "Lag",
		Min = 0,
		Max = 1000,
		Default = 362,
		Suffix = 'ms',		
		Function = function()
			applyNetwork()
		end
	})
end)



run(function()
	local ZoomUncapper
	local ZoomAmount = {Value = 500}
	local oldMaxZoom
	
	ZoomUncapper = vape.Categories.Legit:CreateModule({
		Name = 'ZoomUncapper',
		Function = function(callback)
			if callback then
				oldMaxZoom = lplr.CameraMaxZoomDistance
				lplr.CameraMaxZoomDistance = ZoomAmount.Value
			else
				if oldMaxZoom then
					lplr.CameraMaxZoomDistance = oldMaxZoom
				end
			end
		end,
		Tooltip = 'Uncaps camera zoom distance'
	})
	
	ZoomAmount = ZoomUncapper:CreateSlider({
		Name = 'Zoom Distance',
		Min = 20,
		Max = 600,
		Default = 100,
		Function = function(val)
			if ZoomUncapper.Enabled then
				lplr.CameraMaxZoomDistance = val
			end
		end
	})
end)


	
run(function()
    local FakeLag
    local Mode
    local Delay
    local TransmissionOffset
    local DynamicIntensity
    local originalRemotes = {}
    local queuedCalls = {}
    local isProcessing = false
    local callInterception = {}
    
    local function backupRemoteMethods()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = bedwars.Client.Get
        callInterception.oldGet = oldGet
        
        for name, path in pairs(remotes) do
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.SendToServer then
                originalRemotes[path] = remote.SendToServer
            end
        end
    end
    
    local function processDelayedCalls()
        if isProcessing then return end
        isProcessing = true
        
        task.spawn(function()
            while FakeLag.Enabled and #queuedCalls > 0 do
                local currentTime = tick()
                local toExecute = {}
                
                for i = #queuedCalls, 1, -1 do
                    local call = queuedCalls[i]
                    if currentTime >= call.executeTime then
                        table.insert(toExecute, 1, call)
                        table.remove(queuedCalls, i)
                    end
                end
                
                for _, call in ipairs(toExecute) do
                    pcall(function()
                        if call.remote and call.method == "FireServer" then
                            call.remote:FireServer(unpack(call.args))
                        elseif call.remote and call.method == "InvokeServer" then
                            call.remote:InvokeServer(unpack(call.args))
                        elseif call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                
                task.wait(0.001)
            end
            isProcessing = false
        end)
    end
    
    local function queueRemoteCall(remote, method, originalFunc, ...)
        local currentDelay = Delay.Value
        
        if Mode.Value == "Dynamic" then
            if entitylib.isAlive then
                local intensity = DynamicIntensity.Value / 100
                
                local velocity = entitylib.character.HumanoidRootPart.Velocity.Magnitude
                if velocity > 20 then
                    currentDelay = currentDelay * (1 + intensity * 0.5)
                end
                
                local lastDamage = entitylib.character.Character:GetAttribute('LastDamageTakenTime') or 0
                if tick() - lastDamage < 2 then
                    currentDelay = currentDelay * (1 + intensity * 0.7)
                end
            end
        elseif Mode.Value == "Track" then
            if entitylib.isAlive then
                local nearestDist = math.huge
                for _, entity in ipairs(entitylib.List) do
                    if entity.Targetable and entity.Player and entity.Player ~= lplr then
                        local dist = (entity.RootPart.Position - entitylib.character.RootPart.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                        end
                    end
                end
                
                if nearestDist < 15 then
                    local TrackFactor = (15 - nearestDist) / 15
                    currentDelay = currentDelay * (1 + (TrackFactor * 2))
                end
            end
        end
        
        table.insert(queuedCalls, {
            remote = remote,
            method = method,
            originalFunc = originalFunc,
            args = {...},
            executeTime = tick() + (currentDelay / 1000)
        })
        
        processDelayedCalls()
    end
    
    local function interceptRemotes()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = callInterception.oldGet
        bedwars.Client.Get = function(self, remotePath)
            local remote = oldGet(self, remotePath)
            
            if remote and remote.SendToServer then
                local originalSend = remote.SendToServer
                remote.SendToServer = function(self, ...)
                    if FakeLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "SendToServer", originalSend, ...)
                        return
                    end
                    return originalSend(self, ...)
                end
            end
            
            return remote
        end
        
        local function interceptSpecificRemote(path)
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.FireServer then
                local originalFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    if FakeLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "FireServer", originalFire, ...)
                        return
                    end
                    return originalFire(self, ...)
                end
            end
        end
        
        if remotes.AttackEntity then interceptSpecificRemote(remotes.AttackEntity) end
        if remotes.PlaceBlockEvent then interceptSpecificRemote(remotes.PlaceBlockEvent) end
        if remotes.BreakBlockEvent then interceptSpecificRemote(remotes.BreakBlockEvent) end
    end
    
    FakeLag = vape.Categories.World:CreateModule({
        Name = 'FakeLag',
        Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
            if callback then
                backupRemoteMethods()
                interceptRemotes()
            else
                if callInterception.oldGet then
                    bedwars.Client.Get = callInterception.oldGet
                end
                
                for _, call in ipairs(queuedCalls) do
                    pcall(function()
                        if call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                table.clear(queuedCalls)
            end
        end,
        Tooltip = 'Delays your character\'s network updates to simulate high ping'
    })
    
    Mode = FakeLag:CreateDropdown({
        Name = 'Mode',
        List = {'Latency', 'Dynamic', 'Track'},
        Function = function(v)
			if v == "Dynamic" then
				DynamicIntensity.Object.Visible = true
			else
				DynamicIntensity.Object.Visible = false
			end
		end
    })
    
    Delay = FakeLag:CreateSlider({
        Name = 'Delay',
        Min = 0,
        Max = 500,
        Default = 150,
        Suffix = 'ms'
    })
    
    DynamicIntensity = FakeLag:CreateSlider({
        Name = 'Intensity',
        Min = 0,
        Max = 100,
        Default = 50,
        Suffix = '%'
    })
end)
	

run(function()
	local BetterCait
	local distance
	local Sync
	local Visualiser
	local SelectType
	local ContractVisuals
	local oldVisuals = {}
	local hitPlayers = {} 
	local FillTransparency
	local OutlineTransparency
	local Deselect
	local DeselectTimer
	local Limits
	local Notify
    local function findActiveContractTarget()
        for _, player in pairs(playersService:GetPlayers()) do
            if player ~= lplr and player.Character then
                for _, obj in pairs(player.Character:GetDescendants()) do
                    if obj:IsA("Highlight") and obj.Name ~= "Highlight" and obj.Name ~= "_DamageHighlight_" then
                        return player, player.Character, obj
                    end
                end
            end
        end
        return nil, nil, nil
    end
    
    local function enhanceHighlight()
        if not ContractVisuals.Enabled then return end
        
        local targetPlayer, targetChar, highlight = findActiveContractTarget()
        
        if highlight then
            if not oldVisuals[highlight] then
                oldVisuals[highlight] = {
                    FillColor = highlight.FillColor,
                    FillTransparency = highlight.FillTransparency,
                    OutlineColor = highlight.OutlineColor,
                    OutlineTransparency = highlight.OutlineTransparency,
                    DepthMode = highlight.DepthMode
                }
            end
            
            activeHighlight = highlight
            
            highlight.FillTransparency = FillTransparency.Value
            highlight.OutlineTransparency = OutlineTransparency.Value
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            local color = Color3.fromHSV(Visualiser.Hue, Visualiser.Sat, Visualiser.Value)
            highlight.FillColor = color
            highlight.OutlineColor = color
        else
            activeHighlight = nil
        end
    end
    
    local function restoreHighlight()
        for highlight, settings in pairs(oldVisuals) do
            if highlight and highlight.Parent then
                highlight.FillColor = settings.FillColor
                highlight.FillTransparency = settings.FillTransparency
                highlight.OutlineColor = settings.OutlineColor
                highlight.OutlineTransparency = settings.OutlineTransparency
                highlight.DepthMode = settings.DepthMode
            end
        end
        table.clear(oldVisuals)
    end

	local function Select(attacker,victim,old)
		local new = tick()
		if Sync.Enabled then
			new = tick()
			local delta = (new - old)
			task.wait(delta - (1 / 120))
		end
		if Limits.Enabled then
			if store.hand.tool.Name ~= 'sword' then
				return
			end
		end
		if Deselect.Enabled then
			task.delay(DeselectTimer.Value,function()
				if Notify.Enabled then
					notif('AutoCaitlyn','Deselected current contract',6)
				end
				bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({})
			end)
		end
		if SelectType.Value == "First Hit" then
			if attacker == lplr and victim and victim ~= lplr then
				local dis = (attacker.Character.HumanoidRootPart.Position - entitylib.character.RootPart.Position).Magnitude
					if dis <= distance.Value then
					hitPlayers[victim] = true
					local storeState = bedwars.Store:getState()
					local activeContract = storeState.Kit.activeContract
					local availableContracts = storeState.Kit.availableContracts or {}	
					if not activeContract then
						for _, contract in availableContracts do
							if contract.target == victim then
								if Notify.Enabled then
									notif('AutoCaitlyn',`Selected contract on {victim} with the id {contract.id}`,8)
								end
								bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({
									contractId = contract.id
								})
								break
							end
						end
					end
				end
			end
		elseif SelectType.Value == "Far Range" then
			if attacker == lplr and victim and victim ~= lplr then
				local dis = (attacker.Character.HumanoidRootPart.Position - entitylib.character.RootPart.Position).Magnitude
					if dis >= 32 then
					hitPlayers[victim] = true
					local storeState = bedwars.Store:getState()
					local activeContract = storeState.Kit.activeContract
					local availableContracts = storeState.Kit.availableContracts or {}	
					if not activeContract then
						for _, contract in availableContracts do
							if contract.target == victim then
								if Notify.Enabled then
									notif('AutoCaitlyn',`Selected contract on {victim} with the id {contract.id}`,8)
								end
								bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({
									contractId = contract.id
								})
								break
							end
						end
					end
				end
			end
		elseif SelectType.Value == "Low HP" then
			if attacker == lplr and victim and victim ~= lplr then
				local dis = (attacker.Character.HumanoidRootPart.Position - entitylib.character.RootPart.Position).Magnitude
					if dis <= distance.Value then
					repeat 
						task.wait(0.1)
					until victim.Humanoid.Health <= 30 or not BetterCait.Enabled
					hitPlayers[victim] = true
					local storeState = bedwars.Store:getState()
					local activeContract = storeState.Kit.activeContract
					local availableContracts = storeState.Kit.availableContracts or {}	
					if not activeContract then
						for _, contract in availableContracts do
							if contract.target == victim then
								if Notify.Enabled then
									notif('AutoCaitlyn',`Selected contract on {victim} with the id {contract.id}`,8)
								end
								bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({
									contractId = contract.id
								})
								break
							end
						end
					end
				end
			end			
		end
	end

	BetterCait = vape.Categories.Kits:CreateModule({
		Name = 'AutoCaitlyn',
		Function = function(callback)
			if store.equippedKit ~= "blood_assassin" then
				vape:CreateNotification("AutoCaitlyn","Kit required only!",8,"warning")
				return
			end
			BetterCait:Clean(runService.RenderStepped:Connect(function()
				if not BetterCait.Enabled or not ContractVisuals.Enabled then return end
				enhanceHighlight()
			end))

			BetterCait:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
				if not entitylib.isAlive then return end
					
				local attacker = playersService:GetPlayerFromCharacter(damageTable.fromEntity)
				local victim = playersService:GetPlayerFromCharacter(damageTable.entityInstance)
				local old = 0
				if Sync.Enabled then
					old = tick()
				else
					old = 0
				end
				Select(attacker,victim,old)
			end))
			repeat task.wait(0.01) until not entitylib.isAlive or not BetterCait.Enabled
			table.clear(hitPlayers)
		end,
		Tooltip = 'Makes you look better with caitlyn'
	})
	SelectType = BetterCait:CreateDropdown({
		Name = 'type',
		List = {'Low HP','Far Range','First Hit'},
		Default = 'First Hit',
		Tooltip = 'Low HP - Selects the contract when the target is on Low hp(under 30) and follows the distance value\nFar Range - Selects the contract when the target is over 32 studs and ignores the distance value\nFirst Hit - Selects the contract whenever u the target one time(normal mode) uses the distance value'
	})
	distance = BetterCait:CreateSlider({
		Name = "Distance",
		Max = 32,
		Min = 1,
		Default = 16,
		Suffix = 'studs'
	})
	Visualiser = BetterCait:CreateColorSlider({
		Name = 'Visualiser',
        DefaultValue = 0,
        DefaultOpacity = 1,		
	})
    FillTransparency = BetterCait:CreateSlider({
        Name = 'Fill Transparency',
        Min = 0,
        Max = 1,
        Default = 0.3,
        Decimal = 100,
        Visible = false,
        Tooltip = 'Lower = more cool fill'
    })
    OutlineTransparency = BetterCait:CreateSlider({
        Name = 'Outline Transparency',
        Min = 0,
        Max = 1,
        Default = 0,
        Decimal = 100,
        Visible = false,
        Tooltip = 'Lower = more cool outline'
    })
	ContractVisuals = BetterCait:CreateToggle({Name='Contract Visuals'})
	Sync = BetterCait:CreateToggle({Name='Sync',Tooltip='Syncs the contract selection on the game making it better selections'})
	Limits = BetterCait:CreateToggle({Name='Limits to item',Tooltip='makes it only select when ur sword is out'})
	DeselectTimer = BetterCait:CreateSlider({
		Name = "Deselect Time",
		Min = 0,
		Max = 60,
		Default = 30,
		Darker = true,
		Visible = false
	})
	Deselect = BetterCait:CreateToggle({
		Name = 'Deselect',
		Default = false,
		Function = function(v)
			DeselectTimer.Object.Visible = V
		end
	})
	Notify = BetterCait:CreateToggle({Name='Notify',Tooltip='Notifys when a contract has been selected/deselected'})

end)

run(function()
    local AutoDodge
    local Distance = 15
    local D

    AutoDodge = vape.Categories.Blatant:CreateModule({
        Name = 'AutoDodge',
        Tooltip = 'Automatically dodges arrows for you -- close range only',
        Function = function(callback)
            if not callback then return end
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
            AutoDodge:Clean(workspace.DescendantAdded:Connect(function(arrow)
                    if not AutoDodge.Enabled then return end
                    if not entitylib.isAlive then return end

                    if (arrow.Name == "crossbow_arrow" or arrow.Name == "arrow" or arrow.Name == "headhunter_arrow")and arrow:IsA("Model") then

                        if arrow:GetAttribute("ProjectileShooter") == lplr.UserId then return end

                        local root = arrow:FindFirstChildWhichIsA("BasePart")
                        if not root then return end

                        while AutoDodge.Enabled and root and root.Parent and entitylib.isAlive do
                            local char = lplr.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not hrp or not hum then break end

                            local dist = (hrp.Position - root.Position).Magnitude
                            if dist <= (Distance + 5) then
                                local dodgePos = hrp.Position + Vector3.new(8, 0, 0)
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
                                hum:MoveTo(dodgePos)
                                break
                            end

                            task.wait(0.05)
                        end
                    end
                end)
            )
        end
    })

    D = AutoDodge:CreateSlider({
        Name = "Distance",
        Min = 1,
        Max = 30,
        Default = 15,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Distance = val
        end
    })
end)

run(function()
    local BetterKaida
	local isCasting = false
	local UpdateRate
    local CastDistance
    local AttackRange
    local Angle
    local Targets
	local CastChecks
	local MaxTargets
	local Sorts
	local GUICheck
	local CanAttack = true
    BetterKaida = vape.Categories.Kits:CreateModule({
        Name = "AutoKaida",
        Tooltip = "Killaura-style Kaida",
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if store.equippedKit ~= "summoner" then
				vape:CreateNotification("AutoKaida","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
		            local plrs = entitylib.AllPosition({
		                Range = AttackRange.Value,
		                Wallcheck = Targets.Walls.Enabled,
		                Part = "RootPart",
		                Players = Targets.Players.Enabled,
		                NPCs = Targets.NPCs.Enabled,
		                Limit = MaxTargets.Value,
		                Sort = sortmethods[Sorts.Value]
		            })
					local castplrs = nil

					if CastChecks.Enabled then
						castplrs = entitylib.AllPosition({
							Range = CastDistance.Value,
							Wallcheck = Targets.Walls.Enabled,
							Part = "RootPart",
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sorts.Value]
		            	})
					end
		
		            local char = entitylib.character
		            local root = char.RootPart
					if lplr.Character:GetAttribute("Casting") or lplr.Character:GetAttribute("UsingAbility") or	lplr.Character:GetAttribute("SummonerCasting") then
						isCasting = true
					end
		            if plrs then
		                local ent = plrs[1]
		                if ent and ent.RootPart and CanAttack then
							CanAttack = false
		                    local delta = ent.RootPart.Position - root.Position
		                    local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		                    local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		                    if angle > (math.rad(Angle.Value) / 2) then task.wait(0.1); continue end
							if isCasting then task.wait(0.05); continue end
								if GUICheck.Enabled then
									if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then task.wait(0.1); continue end
								end
		                        local localPosition = root.Position
		                        local shootDir = CFrame.lookAt(localPosition, ent.RootPart.Position).LookVector
		                        localPosition = localPosition + shootDir * math.max((localPosition - ent.RootPart.Position).Magnitude - 16, 0)
		                        bedwars.AnimationUtil:playAnimation(lplr, bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CHARACTER_SWIPE),{looped = false})
		
		                        task.spawn(function()
										local KaidaSkin = 'Summoner_DragonClaw'
										local ApplyRGB = false
										if bedwars.KitController:getKitSkin(lplr.Character) == bedwars.BedwarsKitSkin.WITCH_KAIDA then
											KaidaSkin = "Witch_Summoner_DragonClaw"
											ApplyRGB = false
										elseif bedwars.KitController:getKitSkin(lplr.Character) == bedwars.BedwarsKitSkin.SNOWANGEL_KAIDA then
											KaidaSkin = "SnowAngel_Summoner_DragonClaw"
											ApplyRGB = false
										elseif bedwars.KitController:getKitSkin(lplr.Character) == bedwars.BedwarsKitSkin.PRISMATIC_KAIDA then
											KaidaSkin = "Summoner_DragonClaw"
											ApplyRGB = true
										else
											KaidaSkin = "Summoner_DragonClaw"
											ApplyRGB = false
										end
		                                local clawModel = replicatedStorage.Assets.Misc.Kaida[KaidaSkin]:Clone()
		                                clawModel.Parent = workspace
										task.spawn(function()
											local levelclaw = lplr:GetAttribute('Summoner_ClawLevel') or 1
											local claw1 = Color3.fromRGB(66,66,66)
											local claw2 = Color3.fromRGB(176,182,195)
											local claw3 = Color3.fromRGB(43,229,229)
											local claw4 = Color3.fromRGB(49,229,94)
											if levelclaw == 1 then
												clawModel:FindFirstChild('dragon_claw_nail_mesh').Color = claw1
											elseif levelclaw == 2 then
												clawModel:FindFirstChild('dragon_claw_nail_mesh').Color = claw2
											elseif levelclaw == 3 then
												clawModel:FindFirstChild('dragon_claw_nail_mesh').Color = claw3
											elseif levelclaw == 4 then
												clawModel:FindFirstChild('dragon_claw_nail_mesh').Color = claw4
											else
												clawModel:FindFirstChild('dragon_claw_nail_mesh').Color = claw2
											end
										end)
										if ApplyRGB then
											bedwars.SummonerKitSkinController.applyClawRGB(clawModel)											
										end
		                                if gameCamera.CFrame.Position and (gameCamera.CFrame.Position - root.Position).Magnitude < 1 then
		                                    for _, part in clawModel:GetDescendants() do
		                                        if part:IsA("MeshPart") then
		                                            part.Transparency = 0.6
		                                        end
		                                    end
		                                end
		
		                                local unitDir = Vector3.new(shootDir.X, 0, shootDir.Z).Unit
		                                local startPos = root.Position + unitDir:Cross(Vector3.new(0, 1, 0)).Unit * -5 + unitDir * 6
		                                local direction = (startPos + shootDir * 13 - startPos).Unit
		                                clawModel:PivotTo(CFrame.new(startPos, startPos + direction))
		                                clawModel.PrimaryPart.Anchored = true
		
		                                if clawModel:FindFirstChild("AnimationController") then
		                                    local animator = clawModel.AnimationController:FindFirstChildOfClass("Animator")
		                                    if animator then
		                                        bedwars.AnimationUtil:playAnimation(animator,bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CLAW_ATTACK),{looped = false, speed = 1})
		                                    end
		                                end
										bedwars.Client:Get(remotes.SummonerClawAttack):SendToServer({
											position = localPosition,
											direction = shootDir,
											clientTime = workspace:GetServerTimeNow()
										})
										task.spawn(function()
												local sounds = {
													bedwars.SoundList.SUMMONER_CLAW_ATTACK_1,
													bedwars.SoundList.SUMMONER_CLAW_ATTACK_2,
													bedwars.SoundList.SUMMONER_CLAW_ATTACK_3,
													bedwars.SoundList.SUMMONER_CLAW_ATTACK_4
												}
												bedwars.SoundManager:playSound(sounds[math.random(1, #sounds)], { position = root.Position })

												task.spawn(function()
													task.wait(0.75)
													clawModel:Destroy()
												end)
												task.wait(0.56)
												CanAttack = true
										end)
		                        end)
		                    end
		            end
					if castplrs then
		                local ent = castplrs[1]
		                if ent and ent.RootPart and CanAttack then
							if CastChecks.Enabled then
								CanAttack = false
								if bedwars.AbilityController:canUseAbility('summoner_start_charging') then
									bedwars.AbilityController:useAbility('summoner_start_charging')
									task.wait(1)
									if bedwars.AbilityController:canUseAbility('summoner_finish_charging') then
										bedwars.AbilityController:useAbility('summoner_finish_charging')
									else
										task.wait(0.95)
										bedwars.AbilityController:useAbility('summoner_finish_charging')
									end
								end
								task.wait(0.68)
								CanAttack = true
							end
						end
					end
					task.wait(1 / UpdateRate.Value)
				until not BetterKaida.Enabled
			end
        end
    })
    Targets = BetterKaida:CreateTargets({
        Players = true,
        NPCs = true,
        Walls = true
    })
	Sorts = BetterKaida:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
	MaxTargets = BetterKaida:CreateSlider({
		Name = "Max Targets",
		Min = 1,
		Max = 5,
		Default = 2
	})
    CastDistance = BetterKaida:CreateSlider({
        Name = "Cast Distance",
        Min = 1,
        Max = 10,
        Default = 5,
		Visible = false
    })
	CastChecks = BetterKaida:CreateToggle({
		Name = "Cast Checks",
		Tooltip = 'this allows you to use the cast ability',
		Default = false,
		Function = function(v)
			CastDistance.Object.Visible = v
		end
	})
    Angle = BetterKaida:CreateSlider({
        Name = "Angle",
        Min = 0,
        Max = 360,
        Default = 180
    })
    AttackRange = BetterKaida:CreateSlider({
        Name = "Attack Range",
        Min = 1,
        Max = 18,
        Default = 18,
        Suffix = function(val) return val == 1 and "stud" or "studs" end
    })
	UpdateRate = BetterKaida:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 360,
		Default = 60,
		Suffix = 'hz'
	})
	GUICheck = BetterKaida:CreateToggle({Name='GUI Check'})
end)

run(function()
		local BetterNazar
		local AutoHeal

		BetterNazar = vape.Categories.Kits:CreateModule({
			Name = "AutoNazar",
			Tooltip = "makes you look good with nazar lmfao",
			Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if store.equippedKit ~= "nazar" then
				vape:CreateNotification("AutoNazar","Kit required only!",8,"warning")
				return
			end
				if callback then
					local lastHitTime = 0
					local hitTimeout = 3
					BetterNazar:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
						if not entitylib.isAlive then return end
							
						local attacker = playersService:GetPlayerFromCharacter(damageTable.fromEntity)
						local victim = playersService:GetPlayerFromCharacter(damageTable.entityInstance)
							
						if attacker == lplr and victim and victim ~= lplr then
							lastHitTime = workspace:GetServerTimeNow()
							NazarController:request('enabled')
						end
					end))
						
					BetterNazar:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if not entitylib.isAlive then return end
							
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
							
						if killer == lplr and killed and killed ~= lplr then
							NazarController:request('disabled')
						end
					end))
						
					repeat
						if entitylib.isAlive then
							local currentTime = workspace:GetServerTimeNow()
								
							if empoweredMode and (currentTime - lastHitTime) >= hitTimeout then
								NazarController:request('disabled')
							end

							if  entitylib.character.Humanoid.Health <= AutoHeal.Value then
								NazarController:request('heal')
							end

						else
							if empoweredMode then
								NazarController:request('disabled')
							end
						end
							
						task.wait(0.1)
					until not BetterNazar.Enabled
						
					if empoweredMode then
						NazarController:request('disabled')
					end
				end
			end
		})

		AutoHeal = BetterNazar:CreateSlider({
			Name = "Heal",
			Min = 35,
			Max = 85,
			Default = 75,
			Suffix = "%"
		})
end)




run(function()
    local BetterAdetunde
    local BetterAdetunde_List

    local adetunde_remotes = {
        ["Shield"] = function()
            local args = { [1] = "shield" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Speed"] = function()
            local args = { [1] = "speed" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Strength"] = function()
            local args = { [1] = "strength" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end
    }

    local current_upgrador = "Shield"
    local hasnt_upgraded_everything = true
    local testing = 1

    BetterAdetunde = vape.Categories.Kits:CreateModule({
        Name = 'AutoAdetunde',
        Function = function(calling)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
            if calling then 
                if store.equippedKit == "frost_hammer_kit" then
					current_upgrador = BetterAdetunde_List.Value
					task.spawn(function()
						repeat
							local returning_table = adetunde_remotes[current_upgrador]()
							
							if type(returning_table) == "table" then
								local Speed = returning_table["speed"]
								local Strength = returning_table["strength"]
								local Shield = returning_table["shield"]

								if returning_table[string.lower(current_upgrador)] == 3 then
									if Strength and Shield and Speed then
										if Strength == 3 or Speed == 3 or Shield == 3 then
											if (Strength == 3 and Speed == 2 and Shield == 2) or
											(Strength == 2 and Speed == 3 and Shield == 2) or
											(Strength == 2 and Speed == 2 and Shield == 3) then
												vape:CreateNotification("BetterAdetunde", "Fully upgraded everything possible!", 7,'warning')
												hasnt_upgraded_everything = false
											else
												local things = {}
												for i, v in pairs(adetunde_remotes) do
													table.insert(things, i)
												end
												for i, v in pairs(things) do
													if things[i] == current_upgrador then
														table.remove(things, i)
													end
												end
												local random = things[math.random(1, #things)]
												current_upgrador = random
											end
										end
									end
								end
							else
								local things = {}
								for i, v in pairs(adetunde_remotes) do
									table.insert(things, i)
								end
								for i, v in pairs(things) do
									if things[i] == current_upgrador then
										table.remove(things, i)
									end
								end
								local random = things[math.random(1, #things)]
								current_upgrador = random
							end
							task.wait(0.1)
						until not BetterAdetunde.Enabled or not hasnt_upgraded_everything
					end)
                else
                	vape:CreateNotification("AutoAdetunde", "Kit required only!", 5,'warning')
					BetterAdetunde:Toggle(false)
                end
            end
        end
    })

    local real_list = {}
    for i, v in pairs(adetunde_remotes) do
        table.insert(real_list, i)
    end

    BetterAdetunde_List = BetterAdetunde:CreateDropdown({
        Name = 'Preferred Upgrade',
        List = real_list,
        Function = function() end,
        Default = "Shield"
    })
end)

run(function()
	local NoNameTag
	NoNameTag = vape.Categories.Legit:CreateModule({
		Name = 'NoNameTag',
        Tooltip = 'Removes your NameTag.',
		Function = function(callback)
			if callback then
				NoNameTag:Clean(runService.RenderStepped:Connect(function()
					pcall(function()
						lplr.Character.Head.Nametag:Destroy()
					end)
				end))
			end
		end,
	})
end)


run(function()
	local CustomTags
	local Color
	local TAG
	local old, old2
	local tagConnections = {}
	local tagRenderConn
	local tagGuiConn


	local function Color3ToHex(r, g, b)
		return string.lower(string.format("#%02X%02X%02X", r, g, b))
	end

	local function CompleteTagEffect()
		if not lplr:FindFirstChild("Tags") then return end
		local tagObj = lplr.Tags:FindFirstChild("0")
		if not tagObj then return end

		if not old then
			old = tagObj.Value
			old2 = tagObj:GetAttribute("Text")
		end

		local color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		local R = math.floor(color.R * 255)
		local G = math.floor(color.G * 255)
		local B = math.floor(color.B * 255)

		tagObj.Value = string.format("<font color='rgb(%d,%d,%d)'>[%s]</font>",R, G, B, TAG.Value)
		tagObj:SetAttribute("Text", TAG.Value)
		lplr:SetAttribute("ClanTag", TAG.Value)

		if tagRenderConn then
			tagRenderConn:Disconnect()
			tagRenderConn = nil
		end
		if tagGuiConn then
			tagGuiConn:Disconnect()
			tagGuiConn = nil
		end

		tagGuiConn = lplr.PlayerGui.ChildAdded:Connect(function(child)
			if child.Name ~= "TabListScreenGui" or not child:IsA("ScreenGui") then return end
			tagRenderConn = runService.RenderStepped:Connect(function()
				local nameToFind = (lplr.DisplayName == "" or lplr.DisplayName == lplr.Name) and lplr.Name or lplr.DisplayName
				for _, v in ipairs(child:GetDescendants()) do
					if v:IsA("TextLabel") and string.find(string.lower(v.Text), string.lower(nameToFind)) then
						v.Text = string.format('<font transparency="0.3" color="%s">[%s]</font> %s',Color3ToHex(R, G, B),TAG.Value,nameToFind)
					end
				end
			end)
		end)
	end
	
	local function RemoveTagEffect()
		if tagRenderConn then
			tagRenderConn:Disconnect()
			tagRenderConn = nil
		end

		if tagGuiConn then
			tagGuiConn:Disconnect()
			tagGuiConn = nil
		end

		if lplr:FindFirstChild("Tags") then
			local tagObj = lplr.Tags:FindFirstChild("0")
			if tagObj then
				if old then
					tagObj.Value = old
				end
				if old2 then
					tagObj:SetAttribute("Text", old2)
				end
			end
		end

		if lplr:GetAttribute("ClanTag") then
			lplr:SetAttribute("ClanTag", old)
		end

		old = nil
		old2 = nil
	end

	CustomTags = vape.Categories.Render:CreateModule({
		Name = "CustomTags",
		Tooltip = "Client-Sided visual custom clan tag on-chat",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"  then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if callback then
				CompleteTagEffect()
			else
 				RemoveTagEffect()
			end
		end
	})

	Color = CustomTags:CreateColorSlider({
		Name = 'Color',
		Function = function()
			if CustomTags.Enabled then
				CompleteTagEffect()
			end
		end
	})

	TAG = CustomTags:CreateTextBox({
		Name = 'Tag',
		Default = "KKK",
		Function = function()
			if CustomTags.Enabled then
				CompleteTagEffect()
			end
		end
	})
end)
run(function()
    local BuyBlocksModule
    local GUICheck
    local DelaySlider
    local running = false

    local function getShopNPC()
        local shopFound = false
        if entitylib.isAlive then
            local localPosition = entitylib.character.RootPart.Position
            for _, v in store.shop do
                if (v.RootPart.Position - localPosition).Magnitude <= 20 then
                    shopFound = true
                    break
                end
            end
        end
        return shopFound
    end

    BuyBlocksModule = vape.Categories.Utility:CreateModule({
        Name = "BuyBlocks",
        Function = function(cb)
            running = cb

            if cb then
                task.spawn(function()
                    while running do
                        local canBuy = true
                        
                        if GUICheck.Enabled then
                            if bedwars.AppController:isAppOpen('BedwarsItemShopApp') then
                                canBuy = true
                            else
                                canBuy = false
                            end
                        else
                            canBuy = getShopNPC()
                        end

                        if canBuy then
                            local args = {
                                {
                                    shopItem = {
                                        currency = "iron",
                                        itemType = "wool_white",
                                        amount = 16,
                                        price = 8,
                                        category = "Blocks"
                                    },
                                    shopId = "2_item_shop_1"
                                }
                            }

                            pcall(function()
                                game:GetService("ReplicatedStorage")
                                :WaitForChild("rbxts_include")
                                :WaitForChild("node_modules")
                                :WaitForChild("@rbxts")
                                :WaitForChild("net")
                                :WaitForChild("out")
                                :WaitForChild("_NetManaged")
                                :WaitForChild("BedwarsPurchaseItem")
                                :InvokeServer(unpack(args))
                            end)
                        end

                        task.wait(1 / DelaySlider.GetRandomValue())
                    end
                end)
            end
        end,
        Tooltip = "Automatically buys wool blocks for your lazy ass(thanks to synv4 for giving me this script)"
    })

    GUICheck = BuyBlocksModule:CreateToggle({
        Name = "GUI Check",
        Tooltip = "Only buy when shop GUI is open",
        Default = false
    })

    DelaySlider = BuyBlocksModule:CreateTwoSlider({
        Name = "Delay",
        Min = 0.1,
        Max = 2,
		DefaultMin = 0.1,
		DefaultMax = 0.4,
        Decimal = 10,
		Suffix = "s",
        Tooltip = "Delay between purchases"
    })
end)

run(function()
	local AEGT
	local e
	local function Reset()
		if #playersService:GetChildren() == 1 then return end
		local TeleportService = game:GetService("TeleportService")
		local data = TeleportService:GetLocalPlayerTeleportData()
		AEGT:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
	end
	AEGT = vape.Categories.AltFarm:CreateModule({
		Name = 'AutoEmptyGameTP',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if callback then
				if E.Enabled then
					AEGT:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							Reset()
						end
					end))
					AEGT:Clean(vapeEvents.MatchEndEvent.Event:Connect(Reset))
				else
                    if #playersService:GetChildren() > 1 then
                        vape:CreateNotification("AutoEmptyGameTP", "Teleporting to Empty Game!", 6)
                        task.wait((6 / 3.335))
						Reset()
					end
				end
			else
				return
			end
		end,
		Tooltip = 'Makes you automatically TP to a empty game'
	})
	E = AEGT:CreateToggle({
		Name = "Game Ended",
		Default = true,
		Tooltip = "Makes you TP whenever you win/lose a match causing you to reset the history"
	})
end)


run(function()
	local MouseTP
	local mode
	local pos
	local function getNearestPlayer()
		local character = entitylib.character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local nearestPlayer = nil
		local shortestDistance = math.huge or (2^1024-1)
		local myPos = hrp.Position

		for _, player in ipairs(playersService:GetPlayers()) do
			if player ~= lplr then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if root and hum and hum.Health > 0 then
					local dist = (root.Position - myPos).Magnitude
					if dist < shortestDistance then
						nearestPlayer = player
					end
				end
			end
		end

		return nearestPlayer
	end
	local function Elektra(type)
        local oldEle = nil
		if type == "Mouse" then
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
			if bedwars.AbilityController:canUseAbility('ELECTRIC_DASH') then
				local info = TweenInfo.new(0,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
				local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)})
				tween:Play()
				task.wait(0.05)
				bedwars.AbilityController:useAbility('ELECTRIC_DASH')
				MouseTP:Toggle(false)
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				
				if bedwars.AbilityController:canUseAbility('ELECTRIC_DASH') then
					local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
					local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)})
					tween:Play()
					task.wait(0.69)
					bedwars.AbilityController:useAbility('ELECTRIC_DASH')
					MouseTP:Toggle(false)
				end
			end
		end
	end
	
	local function Davey(type)
		if type == "Mouse" then
			local Cannon = getItem("cannon")
			local ray = cloneref(lplr:GetMouse()).UnitRay
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)

			if not position then
				notif('MouseTP', 'No position found.', 5,"warning")
				MouseTP:Toggle(false)
				return
			end

				
			if not Cannon then
				notif('MouseTP', 'No cannon found.', 5,"warning")
				MouseTP:Toggle(false)
				return
			end

			if not entitylib.isAlive then
				notif('MouseTP', 'Cannot locate where i am at?', 5,"warning")
				MouseTP:Toggle(false)
				return
			end
			local pos = entitylib.character.RootPart.Position
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			bedwars.placeBlock(rounded, 'cannon', false)
			local block, blockpos = getPlacedBlock(rounded)
			if block then
				if block.Name == "cannon" then
					if (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
						bedwars.Client:Get(remotes.CannonAim):SendToServer({
							cannonBlockPos = blockpos,
							lookVector = position
						})
						local broken = 0.1
						if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
							broken = 0.4
							bedwars.breakBlock(block, true, true)
						end
			
						task.delay(broken, function()
							for _ = 1, 3 do
								local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
								if call then
									bedwars.breakBlock(block, true, true)
									break
								end
								task.wait(0.1)
							end
						end)
						MouseTP:Toggle(false)
					end
				end
			end
		else
			local Cannon = getItem("cannon")
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				local old = nil
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				if not Cannon then
					notif('MouseTP', 'No cannon found.', 5,"warning")
					MouseTP:Toggle(false)
					return
				end

				if not entitylib.isAlive then
					notif('MouseTP', 'Cannot locate where i am at?', 5,"warning")
					MouseTP:Toggle(false)
					return
				end
				local pos = entitylib.character.RootPart.Position
				pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
				local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
				bedwars.placeBlock(rounded, 'cannon', false)
				local block, blockpos = getPlacedBlock(rounded)
				if block then
					if block.Name == "cannon" then
						if (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
							bedwars.Client:Get(remotes.CannonAim):SendToServer({
								cannonBlockPos = blockpos,
								lookVector = position
							})
							local broken = 0.1
							if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
								broken = 0.4
								bedwars.breakBlock(block, true, true)
							end
				
							task.delay(broken, function()
								for _ = 1, 3 do
									local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
									if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
										humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
									end
									if call then
										bedwars.breakBlock(block, true, true)
										break
									end
									task.wait(0.1)
								end
							end)
							MouseTP:Toggle(false)
						end
					end
				end
			end
		end
	end

	local function Yuzi(type)
		if type == "Mouse" then
			local old = nil
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
			
			if bedwars.AbilityController:canUseAbility('dash') then
				old = bedwars.YuziController.dashForward
				bedwars.YuziController.dashForward = function(v1,v2)
					local arg = nil
					if v1 then
						arg = v1
					else
						arg = v2
					end
					if entitylib.isAlive then
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position,entitylib.character.RootPart.Position + arg * Vector3.new(1, 0, 1))
						entitylib.character.Humanoid.JumpHeight = 0.5
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						entitylib.character.RootPart:ApplyImpulse(CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector))
						bedwars.JumpHeightController:setJumpHeight(cloneref(game:GetService("StarterPlayer")).CharacterJumpHeight)
						bedwars.SoundManager:playSound(bedwars.SoundList.DAO_SLASH)
						local any_playAnimation_result1 = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.DAO_DASH)
						if any_playAnimation_result1 ~= nil then
							any_playAnimation_result1:AdjustSpeed(2.5)
						end
					end
				end
				bedwars.AbilityController:useAbility('dash',nil,{
					direction = gameCamera.CFrame.LookVector,
					origin = entitylib.character.RootPart.Position,
					weapon = store.hand.tool.Name.itemType,
				})
				task.wait(0.15)
				bedwars.YuziController.dashForward = old
				old = nil
				MouseTP:Toggle(false)
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				local old = nil
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				
				if bedwars.AbilityController:canUseAbility('dash') then
					old = bedwars.YuziController.dashForward
					bedwars.YuziController.dashForward = function(v1,v2)
						local arg = nil
						if v1 then
							arg = v1
						else
							arg = v2
						end
						if entitylib.isAlive then
							entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position,entitylib.character.RootPart.Position + arg * Vector3.new(1, 0, 1))
							entitylib.character.Humanoid.JumpHeight = 0.5
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							entitylib.character.RootPart:ApplyImpulse(CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector))
							bedwars.JumpHeightController:setJumpHeight(cloneref(game:GetService("StarterPlayer")).CharacterJumpHeight)
							bedwars.SoundManager:playSound(bedwars.SoundList.DAO_SLASH)
							local any_playAnimation_result1 = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.DAO_DASH)
							if any_playAnimation_result1 ~= nil then
								any_playAnimation_result1:AdjustSpeed(2.5)
							end
						end
					end
					bedwars.AbilityController:useAbility('dash',nil,{
						direction = gameCamera.CFrame.LookVector,
						origin = entitylib.character.RootPart.Position,
						weapon = store.hand.tool.Name.itemType,
					})
					task.wait(0.15)
					bedwars.YuziController.dashForward = old
					old = nil
					MouseTP:Toggle(false)
				end
			end
		end
	end

	local function Zar(type)
		notif('MouseTP', 'Comming soon!', 8,'warning')
		MouseTP:Toggle(false)
		return
	end

	local function Mouse(type)
		if type == "Mouse" then
			local position
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			entitylib.character.RootPart.CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)
		
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				entitylib.character.RootPart.CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)
				if not position then
					notif('MouseTP', 'No player found.', 5)
					MouseTP:Toggle(false)
					return
				end
			end
		end
		MouseTP:Toggle(false)
	end

	MouseTP = vape.Categories.Utility:CreateModule({
		Name = 'MouseTP',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"  then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if not callback then return end
			if callback then
				if mode.Value == "Mouse" then
					Mouse(pos.Value)
				elseif mode.Value == "Kits" then
					if store.equippedKit == "elektra" then
						Elektra(pos.Value)
					elseif store.equippedKit == "davey" then
						Davey(pos.Value)
					elseif store.equippedKit == "dasher" then
						Yuzi(pos.Value)
					elseif store.equippedKit == "gun_blade" then
						Zar(pos.Value)
					else
						vape:CreateNotification("MouseTP", "Current kit is not supported for MouseTP", 4.5, "warning")
						MouseTP:Toggle(false)
						return
					end
				else
					Mouse()
				end
			end
		end,
	})
	mode = MouseTP:CreateDropdown({
		Name = "Mode",
		List = {'Mouse','Kits'}
	})
	pos =  MouseTP:CreateDropdown({
		Name = "Position",
		List = {'Cloeset Player', 'Mouse'}
	})
end)

run(function()
	local shooting, old = false
	local AutoShootInterval
	local AutoShootSwitchSpeed
	local AutoShootRange
	local AutoShootFOV
	local AutoShootWaitDelay
	local lastAutoShootTime = 0
	local autoShootEnabled = false
	local KillauraTargetCheck
	local FirstPersonCheck
	
	_G.autoShootLock = _G.autoShootLock or false
	
	local VirtualInputManager = vim
	
	local function leftClick()
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			task.wait(0.05)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end)
	end
	
	local function hasArrows()
		local arrowItem = getItem('arrow')
		return arrowItem and arrowItem.amount > 0
	end
	
	local function getBows()
		local bows = {}
		for i, v in store.inventory.hotbar do
			if v.item and v.item.itemType then
				local itemMeta = bedwars.ItemMeta[v.item.itemType]
				if itemMeta and itemMeta.projectileSource then
					local projectileSource = itemMeta.projectileSource
					if projectileSource.ammoItemTypes and table.find(projectileSource.ammoItemTypes, 'arrow') then
						table.insert(bows, i - 1)
					end
				end
			end
		end
		return bows
	end
	
	local function getSwordSlot()
		for i, v in store.inventory.hotbar do
			if v.item and bedwars.ItemMeta[v.item.itemType] then
				local meta = bedwars.ItemMeta[v.item.itemType]
				if meta.sword then
					return i - 1
				end
			end
		end
		return nil
	end
	
	local function hasValidTarget()
		if KillauraTargetCheck.Enabled then
			return store.KillauraTarget ~= nil
		else
			if not entitylib.isAlive then return false end
			
			local myPos = entitylib.character.RootPart.Position
			local myLook = entitylib.character.RootPart.CFrame.LookVector
			
			for _, entity in entitylib.List do
				if entity.Player == lplr then continue end
				if not entity.Character then continue end
				if not entity.RootPart then continue end
				
				if entity.Player then
					if lplr:GetAttribute('Team') == entity.Player:GetAttribute('Team') then
						continue
					end
				else
					if not entity.Targetable then
						continue
					end
				end
				
				local distance = (entity.RootPart.Position - myPos).Magnitude
				if distance > AutoShootRange.Value then continue end
				
				local toTarget = (entity.RootPart.Position - myPos).Unit
				local dot = myLook:Dot(toTarget)
				local angle = math.acos(dot)
				local fovRad = math.rad(AutoShootFOV.Value)
				
				if angle <= fovRad then
					return true
				end
			end
			
			return false
		end
	end
	
	local AutoShoot = vape.Categories.Inventory:CreateModule({
		Name = 'AutoShoot',
		Function = function(callback)
			if callback then
				autoShootEnabled = true
				old = bedwars.ProjectileController.createLocalProjectile
				bedwars.ProjectileController.createLocalProjectile = function(...)
					local source, data, proj = ...
					if source and proj and (proj == 'arrow' or bedwars.ProjectileMeta[proj] and bedwars.ProjectileMeta[proj].combat) and not _G.autoShootLock then
						task.spawn(function()
							if not hasArrows() then
								return
							end
							
							if FirstPersonCheck.Enabled and not isFirstPerson() then
								return
							end
							
							if KillauraTargetCheck.Enabled then
								if not store.KillauraTarget then
									return
								end
							else
								if not hasValidTarget() then
									return
								end
							end
							
							local bows = getBows()
							if #bows > 0 then
								_G.autoShootLock = true
								task.wait(AutoShootWaitDelay.Value)
								local selected = store.inventory.hotbarSlot
								for _, v in bows do
									if hotbarSwitch(v) then
										task.wait(0.05)
										leftClick()
										task.wait(0.05)
									end
								end
								hotbarSwitch(selected)
								_G.autoShootLock = false
							end
						end)
					end
					return old(...)
				end
				
				task.spawn(function()
					repeat
						task.wait(0.1)
						if autoShootEnabled and not _G.autoShootLock then
							if not hasArrows() then
								continue
							end
							
							if FirstPersonCheck.Enabled and not isFirstPerson() then
								continue
							end
							
							if KillauraTargetCheck.Enabled then
								if not store.KillauraTarget then
									continue
								end
							else
								if not hasValidTarget() then
									continue
								end
							end
							
							local currentTime = tick()
							if (currentTime - lastAutoShootTime) >= AutoShootInterval.Value then
								local bows = getBows()
								local swordSlot = getSwordSlot()
								
								if #bows > 0 then
									_G.autoShootLock = true
									lastAutoShootTime = currentTime
									local originalSlot = store.inventory.hotbarSlot
									
									for _, bowSlot in bows do
										if hotbarSwitch(bowSlot) then
											task.wait(AutoShootSwitchSpeed.Value)
											leftClick()
											task.wait(0.05)
										end
									end
									
									if swordSlot then
										hotbarSwitch(swordSlot)
									else
										hotbarSwitch(originalSlot)
									end
									
									_G.autoShootLock = false
								end
							end
						end
					until not autoShootEnabled
				end)
			else
				autoShootEnabled = false
				if old then
					bedwars.ProjectileController.createLocalProjectile = old
				end
				_G.autoShootLock = false
			end
		end,
		Tooltip = 'Automatically switches to bows and shoots them'
	})
	
	AutoShootInterval = AutoShoot:CreateSlider({
		Name = 'Shoot Interval',
		Min = 0.1,
		Max = 3,
		Default = 0.5,
		Decimal = 10,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end,
		Tooltip = 'How often to auto-shoot bows'
	})
	
	AutoShootSwitchSpeed = AutoShoot:CreateSlider({
		Name = 'Switch Delay',
		Min = 0,
		Max = 0.2,
		Default = 0.05,
		Decimal = 100,
		Suffix = 's',
		Tooltip = 'Delay between switching and shooting (lower = faster)'
	})
	
	AutoShootWaitDelay = AutoShoot:CreateSlider({
		Name = 'Wait Delay',
		Min = 0,
		Max = 1,
		Default = 0,
		Decimal = 100,
		Suffix = 's',
		Tooltip = 'Delay before shooting (helps prevent ghosting)'
	})
	
	AutoShootRange = AutoShoot:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 20,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Maximum range to auto-shoot'
	})
	
	AutoShootFOV = AutoShoot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 180,
		Default = 90,
		Tooltip = 'Field of view for target detection (1-180 degrees)'
	})
	
	KillauraTargetCheck = AutoShoot:CreateToggle({
		Name = 'Require Killaura Target',
		Default = false,
		Tooltip = 'Only auto-shoot when Killaura has a target (overrides Range/FOV)'
	})
	
	FirstPersonCheck = AutoShoot:CreateToggle({
		Name = 'First Person Only',
		Default = false,
		Tooltip = 'Only works in first person mode'
	})
end)

run(function()
    local HitFix
	local PingBased
	local Options
    HitFix = vape.Categories.Blatant:CreateModule({
        Name = 'HitFix',
        Function = function(callback)
            if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
                vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
                return
            end  

            local function getPing()
                local stats = game:GetService("Stats")
                local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                return tonumber(ping:match("%d+")) or 50
            end

            local function getDelay()
                local ping = getPing()

                if PingBased.Enabled then
                    if Options.Value == "Blatant" then
                        return math.clamp(0.08 + (ping / 1000), 0.08, 0.14)
                    else
                        return math.clamp(0.11 + (ping / 1200), 0.11, 0.15)
                    end
                end

                return Options.Value == "Blatant" and 0.1 or 0.13
            end

            if callback then
                pcall(function()
                    if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
                        local func = bedwars.SwordController.swingSwordAtMouse

                        if Options.Value == "Blatant" then
                            debug.setconstant(func, 23, "raycast")
                            debug.setupvalue(func, 4, bedwars.QueryUtil)
                        end

                        for i, v in ipairs(debug.getconstants(func)) do
                            if typeof(v) == "number" and (v == 28) then
                                debug.setconstant(func, i, getDelay())
                            end
                        end
                    end
                end)
            else
                pcall(function()
                    if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
                        local func = bedwars.SwordController.swingSwordAtMouse

                        debug.setconstant(func, 23, "Raycast")
                        debug.setupvalue(func, 4, workspace)

                        for i, v in ipairs(debug.getconstants(func)) do
                            if typeof(v) == "number" then
                                if v < 0.15 then
                                    debug.setconstant(func, i, 0.15)
                                end
                            end
                        end
                    end
                end)
            end
        end,
        Tooltip = 'Improves hit registration and decreases the chances of a ghost hit'
    })

    Options = HitFix:CreateDropdown({
        Name = "Mode",
        List = {"Blatant", "Legit"},
    })

    PingBased = HitFix:CreateToggle({
        Name = "Ping Based",
        Default = false,
    })
end)

run(function()
	local BetterMetal
	local StreamerMode
	local Delay
	local Animation
	local Distance
	local Limits
	local Legit
	BetterMetal = vape.Categories.Kits:CreateModule({
		Name = "AutoMetal",
		Tooltip = 'makes you play like bobcat at metal or any1 whos good(js naming sm1 i know who mains metal)',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end 
			if store.equippedKit ~= "metal_detector" then
				vape:CreateNotification("AutoMetal","Kit required only!",8,"warning")
				return
			end
			task.spawn(function()
				while BetterMetal.Enabled do
					if not entitylib.isAlive then task.wait(0.1); continue end
					local character = entitylib.character
					if not character or not character.RootPart then task.wait(0.1); continue end
					if Limits.Enabled then
						local tool = (store and store.hand and store.hand.tool) and store.hand.tool or nil
						if not tool or tool.Name ~= "metal_detector" then task.wait(0.5); continue end
					end
					local localPos = character.RootPart.Position
					local metals = collectionService:GetTagged("hidden-metal")
					for _, obj in pairs(metals) do
						if obj:IsA("Model") and obj.PrimaryPart then
							local metalPos = obj.PrimaryPart.Position
							local distance = (localPos - metalPos).Magnitude
							local range = Legit.Enabled and 10 or (Distance.Value or 8)
							if distance <= range then
								if StreamerMode.Enabled then
									local Key = obj:FindFirstChild('hidden-metal-prompt').KeyboardKeyCode
									vim:SendKeyEvent(true, Key, false, game)
									task.wait(obj:FindFirstChild('hidden-metal-prompt').HoldDuration + math.random())
									vim:SendKeyEvent(false, Key, false, game)
								else
									local waitTime = Legit.Enabled and .854 or (1 / (Delay.GetRandomValue and Delay:GetRandomValue() or 1))
									task.wait(waitTime)
									if Legit.Enabled or Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.SHOVEL_DIG)
										bedwars.SoundManager:playSound(bedwars.SoundList.SNAP_TRAP_CONSUME_MARK)
									end
									pcall(function()
										bedwars.Client:Get('CollectCollectableEntity'):SendToServer({id = obj:GetAttribute("Id")})
									end)
									task.wait(0.1)
								end
							end
						end
					end
					task.wait(0.1)
				end
			end)
		end
	})
	Limits = BetterMetal:CreateToggle({Name='Limit To Item',Default=false})
	StreamerMode = BetterMetal:CreateToggle({Name='Streamer Mode',Default=false})
	Distance = BetterMetal:CreateSlider({Name='Range',Min=6,Max=12,Default=8})
	Delay = BetterMetal:CreateTwoSlider({
		Name = "Delay",
		Min = 0,
		Max = 2,
		DefaultMin = 0.4,
		DefaultMax = 1,
		Suffix = 's',
        Decimal = 10,	
	})
	Animation = BetterMetal:CreateToggle({Name='Animations',Default=true})
	Legit = BetterMetal:CreateToggle({
		Name='Legit',
		Default=true,
		Darker=true,
		Function = function(v)
			Animation.Object.Visible = (not v)
			Delay.Object.Visible = (not v)
			Distance.Object.Visible = (not v)
			Limits.Object.Visible = (not v)
		end
	})

end)

run(function()
	local BetterRamil
	local Distance
	local Sorts
	local Angle
	local MaxTargets
	local Targets
	local MovingTornadoDistance
	local UseTornandos
	local Rate
	BetterRamil = vape.Categories.Kits:CreateModule({
		Name = "AutoRamil",
		Tooltip = 'makes you play like me at ramil(i like ramil)',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if store.equippedKit ~= "airbender" then
				vape:CreateNotification("AutoRamil","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
		            local plrs = entitylib.AllPosition({
		                Range = Distance.Value,
		                Wallcheck = Targets.Walls.Enabled,
		                Part = "RootPart",
		                Players = Targets.Players.Enabled,
		                NPCs = Targets.NPCs.Enabled,
		                Limit = MaxTargets.Value,
		                Sort = sortmethods[Sorts.Value]
		            })
					local castplrs = nil

					if UseTornandos.Enabled then
						castplrs = entitylib.AllPosition({
							Range = MovingTornadoDistance.Value,
							Wallcheck = Targets.Walls.Enabled,
							Part = "RootPart",
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sorts.Value]
		            	})
					end
		
		            local char = entitylib.character
		            local root = char.RootPart
		
		            if plrs then
		                local ent = plrs[1]
		                if ent and ent.RootPart then
		                    local delta = ent.RootPart.Position - root.Position
		                    local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		                    local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		                    if angle > (math.rad(Angle.Value) / 2) then task.wait(0.1); continue end
							if bedwars.AbilityController:canUseAbility('airbender_tornado') then
								bedwars.AbilityController:useAbility('airbender_tornado')
							end
		                end
		            end
					if castplrs then
		                local ent = castplrs[1]
		                if ent and ent.RootPart then
							if UseTornandos.Enabled then
								if bedwars.AbilityController:canUseAbility('airbender_moving_tornado') then
									bedwars.AbilityController:useAbility('airbender_moving_tornado')
								end
							end
						end
					end
					task.wait(1 / Rate.Value or 0.2)
				until not BetterRamil.Enabled
			end


		end
	})
	Targets = BetterRamil:CreateTargets({Players = true,NPCs = false,Walls = true})
    Angle = BetterRamil:CreateSlider({
        Name = "Angle",
        Min = 0,
        Max = 360,
        Default = 180
    })
	Sorts = BetterRamil:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
	MaxTargets = BetterRamil:CreateSlider({
		Name = "Max Targets",
		Min = 1,
		Max = 3,
		Default = 2
	})
	Distance = BetterRamil:CreateSlider({
		Name = "Distance",
		Min = 1,
		Max = 25,
		Default = 18,
		Suffix = function(v)
			if v <= 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	MovingTornadoDistance = BetterRamil:CreateSlider({
		Darker = true,
		Name = "Tornado Distance",
		Min = 1,
		Max = 31,
		Default = 18,
		Suffix = function(v)
			if v <= 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	UseTornandos = BetterRamil:CreateToggle({Name='Use Moving Tornado\'s',Default=false,Function=function(v) MovingTornadoDistance.Object.Visible = v end})
	Rate = BetterRamil:CreateSlider({
		Name = "Update Rate",
		Min = 1,
		Max = 360,
		Default = 60,
		Suffix = "hz"
	})
end)

run(function()
	local hooked = false
	local oldFire
	local oldLaunch
	local Victorious
	ClientEffects = vape.Categories.Render:CreateModule({
		Name = "ClientEffects",
		Function = function(callback)
			if callback then
				if hooked then return end
				hooked = true
						local Sound = ''
						local cannon = ''
						if Victorious.Value == "Gold" then
							Sound = 'CANNON_FIRE_VICTORIOUS_GOLD'
							cannon = 'cannon_gold_victorious'
						end
						if Victorious.Value == "Platinum" then
							Sound = 'CANNON_FIRE_VICTORIOUS_PLATINUM'
							cannon = 'cannon_platinum_victorious'
						end
						if Victorious.Value == "Diamond" then
							Sound = 'CANNON_FIRE_VICTORIOUS_DIAMOND'
							cannon = 'cannon_diamond_victorious'
						end
						if Victorious.Value == "Emerald" then
							Sound = 'CANNON_FIRE_VICTORIOUS_EMERALD'
							cannon = 'cannon_emerald_victorious'
						end
						if Victorious.Value == "Nightmare" then
							Sound = 'CANNON_FIRE_VICTORIOUS_NIGHTMARE'
							cannon = 'cannon_nightmare_victorious'
						end
					task.spawn(function()

						local RESKIN_SOURCE = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Blocks"):WaitForChild(cannon)
						local TARGET_NAME = "cannon"
						local OFFSET_HELD = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
						local OFFSET_PLACED = CFrame.new(0, -2.0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
						local tagged = setmetatable({}, { __mode = "k" })
						local function firstBasePart(root: Instance)
							for _, d in ipairs(root:GetDescendants()) do
								if d:IsA("BasePart") then
									return d
								end
							end
							return nil
						end
						local function makeLocalInvisible(root: Instance)
							for _, d in ipairs(root:GetDescendants()) do
								if d:IsA("BasePart") then
									d.LocalTransparencyModifier = 1
									d.Transparency = 1       
								elseif d:IsA("Decal") or d:IsA("Texture") then
									d.Transparency = 1
								end
							end
						end
						local function setNoCollide(model: Instance)
							for _, d in ipairs(model:GetDescendants()) do
								if d:IsA("BasePart") then
									d.CanCollide = false
									d.CanTouch = false
									d.CanQuery = false
									d.Massless = true
									d.Anchored = false
								end
							end
						end
						local function weldAllToPrimary(model: Model)
							local primary = model.PrimaryPart
							if not primary then return end

							for _, d in ipairs(model:GetDescendants()) do
								if d:IsA("BasePart") and d ~= primary then
									local wc = Instance.new("WeldConstraint")
									wc.Part0 = primary
									wc.Part1 = d
									wc.Parent = primary
								end
							end
						end
						local function weldModelToPart(model: Model, targetPart: BasePart)
							if not model.PrimaryPart then
								local p = firstBasePart(model)
								if p then
									pcall(function() model.PrimaryPart = p end)
								end
							end
							if not model.PrimaryPart then return false end

							setNoCollide(model)

							pcall(function()
								model:PivotTo(targetPart.CFrame * OFFSET_HELD)
							end)

							weldAllToPrimary(model)

							local wc = Instance.new("WeldConstraint")
							wc.Part0 = targetPart
							wc.Part1 = model.PrimaryPart
							wc.Parent = model.PrimaryPart

							return true
						end
						local function attachReskinTo(targetRoot: Instance, offset: CFrame)
							if not targetRoot or tagged[targetRoot] then return end
							tagged[targetRoot] = true

							local targetPart = targetRoot:FindFirstChild("Handle")
							if not (targetPart and targetPart:IsA("BasePart")) then
								targetPart = firstBasePart(targetRoot)
							end
							if not targetPart then
								tagged[targetRoot] = nil
								return
							end
							makeLocalInvisible(targetRoot)
							local clone = RESKIN_SOURCE:Clone()
							clone.Name = "LOCAL_CANNON_RESKIN"
							if clone:IsA("Model") then
								if not clone.PrimaryPart then
									local p = firstBasePart(clone)
									if p then
										pcall(function() clone.PrimaryPart = p end)
									end
								end
								if not clone.PrimaryPart then
									clone:Destroy()
									tagged[targetRoot] = nil
									return
								end

								setNoCollide(clone)
								clone.Parent = targetRoot

								pcall(function()
									clone:PivotTo(targetPart.CFrame * offset)
								end)

								weldAllToPrimary(clone)

								local wcMain = Instance.new("WeldConstraint")
								wcMain.Part0 = targetPart
								wcMain.Part1 = clone.PrimaryPart
								wcMain.Parent = clone.PrimaryPart
							else
								clone.Parent = targetRoot
							end
						end
						local function hookViewmodel()
							local cam = workspace.CurrentCamera
							if not cam then return end

							local function hookVM(vm: Instance)
								for _, child in ipairs(vm:GetChildren()) do
									if child.Name == TARGET_NAME then
										attachReskinTo(child, OFFSET_HELD)
									end
								end

								vm.ChildAdded:Connect(function(child)
									if child.Name == TARGET_NAME then
										task.wait()
										attachReskinTo(child, OFFSET_HELD)
									end
								end)
							end

							local vm = cam:FindFirstChild("Viewmodel")
							if vm then hookVM(vm) end

							cam.ChildAdded:Connect(function(child)
								if child.Name == "Viewmodel" then
									task.wait()
									hookVM(child)
								end
							end)
						end
						local function hookThirdPersonInHand(character: Model)
							local function onChildAdded(child)
								if child:IsA("Tool") and child.Name == TARGET_NAME then
									task.wait()

									local handle = child:FindFirstChild("Handle")
									if not (handle and handle:IsA("BasePart")) then
										handle = firstBasePart(child)
									end
									if not handle then return end
									local existing = child:FindFirstChild("LOCAL_CANNON_RESKIN")
									if existing then
										existing:Destroy()
									end

									local reskin = RESKIN_SOURCE:Clone()
									reskin.Name = "LOCAL_CANNON_RESKIN"
									reskin.Parent = child

									if reskin:IsA("Model") then
										weldModelToPart(reskin, handle)
									end
									local start = time()
									local conn
									conn = runService.RenderStepped:Connect(function()
										if not child.Parent then
											conn:Disconnect()
											return
										end

										makeLocalInvisible(child)

										if reskin and reskin.Parent and reskin:IsA("Model") and reskin.PrimaryPart then
											pcall(function()
												reskin:PivotTo(handle.CFrame * OFFSET_HELD)
											end)
										end

										if time() - start > 2 then
											conn:Disconnect()
										end
									end)
								end
							end

							for _, c in ipairs(character:GetChildren()) do
								onChildAdded(c)
							end

							character.ChildAdded:Connect(onChildAdded)
						end
						local function hookTools(container: Instance)
							for _, child in ipairs(container:GetChildren()) do
								if child:IsA("Tool") and child.Name == TARGET_NAME then
									attachReskinTo(child, OFFSET_HELD)
								end
							end

							ClientEffects:Clean(container.ChildAdded:Connect(function(child)
								if child:IsA("Tool") and child.Name == TARGET_NAME then
									task.wait()
									attachReskinTo(child, OFFSET_HELD)
								end
							end))
						end
						local function hookBlocksFolder(blocksFolder: Instance)
							for _, child in ipairs(blocksFolder:GetChildren()) do
								if child.Name == TARGET_NAME then
									attachReskinTo(child, OFFSET_PLACED)
								end
							end

							ClientEffects:Clean(blocksFolder.ChildAdded:Connect(function(child)
								if child.Name == TARGET_NAME then
									task.wait()
									attachReskinTo(child, OFFSET_PLACED)
									task.wait()
									child:SetAttribute('ItemSkin',cannon)
									local skin = child:FindFirstChild("LOCAL_CANNON_RESKIN")
									if not (skin and skin:IsA("Model") and skin.PrimaryPart) then return end
									local baseCF = skin.PrimaryPart.CFrame
									local y = baseCF.Position.Y
									local snappedY = math.floor(y)
									local KUSH = snappedY - 1
									local New = KUSH + 0.99
									skin:PivotTo(CFrame.new(Vector3.new(baseCF.Position.X,New,baseCF.Position.Z)))
								end
							end))
						end
						local function hookAllWorldBlocks()
							local map = workspace:FindFirstChild("Map")
							if not map then return end

							local worlds = map:FindFirstChild("Worlds")
							if not worlds then return end

							for _, world in ipairs(worlds:GetChildren()) do
								local blocks = world:FindFirstChild("Blocks")
								if blocks then
									hookBlocksFolder(blocks)
								end
							end

							ClientEffects:Clean(worlds.ChildAdded:Connect(function(world)
								task.wait()
								local blocks = world:FindFirstChild("Blocks")
								if blocks then
									hookBlocksFolder(blocks)
								end
							end))
						end
						hookViewmodel()
						hookAllWorldBlocks()
						local function onCharacterAdded(character: Model)
							task.wait(0.2)
							hookTools(lplr.Backpack)
							hookTools(character)
							hookThirdPersonInHand(character)
						end
						if lplr.Character then
							onCharacterAdded(lplr.Character)
						end
						ClientEffects:Clean(lplr.CharacterAdded:Connect(onCharacterAdded))

					end)

				oldFire = bedwars.CannonHandController.fireCannon
				oldLaunch = bedwars.CannonHandController.launchSelf

				bedwars.CannonHandController.fireCannon = function(...)
					for _, v in ipairs(workspace.SoundPool:GetChildren()) do
						if v:IsA("Sound") and v.SoundId == "rbxassetid://7121064180" then
							v:Destroy()
						end
					end

					bedwars.SoundManager:playSound(bedwars.SoundList[Sound])
					return oldFire(...)
				end

				bedwars.CannonHandController.launchSelf = function(...)
					for _, v in ipairs(workspace.SoundPool:GetChildren()) do
						if v:IsA("Sound") and v.SoundId == "rbxassetid://7121064180" then
							v:Destroy()
						end
					end

					bedwars.SoundManager:playSound(bedwars.SoundList[Sound])
					return oldLaunch(...)
				end
			else
				if hooked then
					bedwars.CannonHandController.fireCannon = oldFire
					bedwars.CannonHandController.launchSelf = oldLaunch
					oldFire = nil
					oldLaunch = nil
					hooked = false
				end
			end
		end
	})
	Victorious = ClientEffects:CreateDropdown({
		Name = "Victorious",
		List = {'Nightmare','Emerald','Diamond','Platinum','Gold'}
	})
end)


run(function()
	local BetterLani
	local Legit
	local Delay
	local Player
	local t = 0
	BetterLani = vape.Categories.Kits:CreateModule({
		Name = "AutoLani",
		Tooltip = 'allows you to tp to a targetted player no matter what!',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= 'premium' and role ~= 'user' then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if store.equippedKit ~= "paladin" then
				vape:CreateNotification("AutoLani","Kit required only!",8,"warning")
				return
			end
			if callback then
				if Legit.Enabled then
					t = 1.33
				else
					t = (1 / Delay.GetRandomValue()) or 0.859
				end
				BetterLani:Clean(lplr:GetAttributeChangedSignal("PaladinStartTime"):Connect(function()
					task.wait(t)
					if bedwars.AbilityController:canUseAbility('PALADIN_ABILITY') then
						local plr = playersService:WaitForChild(Player.Value)
						if plr.Character and plr then
							bedwars.Client:Get("PaladinAbilityRequest"):SendToServer({target = plr})
						else
							bedwars.Client:Get("PaladinAbilityRequest"):SendToServer({})
						end	
						task.wait(0.022)
						bedwars.AbilityController:useAbility('PALADIN_ABILITY')
					end
				end))
			else
				t = 0
			end
		end
	})
	Delay = BetterLani:CreateTwoSlider({
		Name = "Delay",
		Min = 0,
		Max = 2,
		DefaultMin = 0.4,
		DefaultMax = 1.33,
		Suffix = 's',
        Decimal = 10,
		Visible = false	
	})
	Player = BetterLani:CreateTextBox({
		Name = "Player",
		Tooltip = 'enter the player\'s USERNAME not DISPLAY'
	})
	Legit = BetterLani:CreateToggle({
		Name = "Legit",
		Darker = true,
		Default = true,
		Function = function(v)
			Delay.Object.Visible = v
		end
	})
end)

run(function()
	local AutoBank
	local GUICheck
	local UIToggle
	local UI
	local Chests
	local Items = {}
	
	local function addItem(itemType, shop)
		local item = Instance.new('ImageLabel')
		item.Image = bedwars.getIcon({itemType = itemType}, true)
		item.Size = UDim2.fromOffset(32, 32)
		item.Name = itemType
		item.BackgroundTransparency = 1
		item.LayoutOrder = #UI:GetChildren() + 99
		item.Parent = UI
		local itemtext = Instance.new('TextLabel')
		itemtext.Name = 'Amount'
		itemtext.Size = UDim2.fromScale(1, 1)
		itemtext.BackgroundTransparency = 1
		itemtext.Text = ''
		itemtext.TextColor3 = Color3.new(1, 1, 1)
		itemtext.TextSize = 16
		itemtext.TextStrokeTransparency = 0.3
		itemtext.Font = Enum.Font.Arial
		itemtext.Parent = item
		Items[itemType] = {Object = itemtext, Type = shop}
	end
	
	local function refreshBank(echest)
		for i, v in Items do
			local item = echest:FindFirstChild(i)
			v.Object.Text = item and item:GetAttribute('Amount') or ''
		end
	end
	
	local function nearChest()
		if entitylib.isAlive then
			local pos = entitylib.character.RootPart.Position
			for _, chest in Chests do
				if (chest.Position - pos).Magnitude < 20 then
					return true
				end
			end
		end
	end
	
	local function handleState()
		local chest = replicatedStorage.Inventories:FindFirstChild(lplr.Name..'_personal')
		if not chest then return end
	
		local mapCF = workspace.MapCFrames:FindFirstChild((lplr:GetAttribute('Team') or 1)..'_spawn')
		if mapCF and (entitylib.character.RootPart.Position - mapCF.Value.Position).Magnitude < 80 then
			for _, v in chest:GetChildren() do
				local item = Items[v.Name]
				if item then
					task.spawn(function()
						bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						refreshBank(chest)
					end)
				end
			end
		else
			for _, v in store.inventory.inventory.items do
				local item = Items[v.itemType]
				if item then
					task.spawn(function()
						bedwars.Client:GetNamespace('Inventory'):Get('ChestGiveItem'):CallServer(chest, v.tool)
						refreshBank(chest)
					end)
				end
			end
		end
	end
	
	AutoBank = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBank',
		Function = function(callback)
			if callback then
				if GUICheck.Enabled then
					if bedwars.AppController:isAppOpen('ChestApp') then
						Chests = collection('personal-chest', AutoBank)
						UI = Instance.new('Frame')
						UI.Size = UDim2.new(1, 0, 0, 32)
						UI.Position = UDim2.fromOffset(0, -240)
						UI.BackgroundTransparency = 1
						UI.Visible = UIToggle.Enabled
						UI.Parent = vape.gui
						AutoBank:Clean(UI)
						local Sort = Instance.new('UIListLayout')
						Sort.FillDirection = Enum.FillDirection.Horizontal
						Sort.HorizontalAlignment = Enum.HorizontalAlignment.Center
						Sort.SortOrder = Enum.SortOrder.LayoutOrder
						Sort.Parent = UI
						addItem('iron', true)
						addItem('gold', true)
						addItem('diamond', false)
						addItem('emerald', true)
						addItem('void_crystal', true)
			
						repeat
							local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
							hotbar = hotbar and hotbar['1']:FindFirstChild('HotbarHealthbarContainer')
							if hotbar then
								UI.Position = UDim2.fromOffset(0, (hotbar.AbsolutePosition.Y + guiService:GetGuiInset().Y) - 40)
							end
			
							local newState = nearChest()
							if newState then
								handleState()
							end
			
							task.wait(0.1)
						until (not AutoBank.Enabled)
					end
				else
						Chests = collection('personal-chest', AutoBank)
						UI = Instance.new('Frame')
						UI.Size = UDim2.new(1, 0, 0, 32)
						UI.Position = UDim2.fromOffset(0, -240)
						UI.BackgroundTransparency = 1
						UI.Visible = UIToggle.Enabled
						UI.Parent = vape.gui
						AutoBank:Clean(UI)
						local Sort = Instance.new('UIListLayout')
						Sort.FillDirection = Enum.FillDirection.Horizontal
						Sort.HorizontalAlignment = Enum.HorizontalAlignment.Center
						Sort.SortOrder = Enum.SortOrder.LayoutOrder
						Sort.Parent = UI
						addItem('iron', true)
						addItem('gold', true)
						addItem('diamond', false)
						addItem('emerald', true)
						addItem('void_crystal', true)
			
						repeat
							local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
							hotbar = hotbar and hotbar['1']:FindFirstChild('HotbarHealthbarContainer')
							if hotbar then
								UI.Position = UDim2.fromOffset(0, (hotbar.AbsolutePosition.Y + guiService:GetGuiInset().Y) - 40)
							end
			
							local newState = nearChest()
							if newState then
								handleState()
							end
			
							task.wait(0.1)
						until (not AutoBank.Enabled)
				end
			else
				table.clear(Items)
			end
		end,
		Tooltip = 'Automatically puts resources in ender chest'
	})
	UIToggle = AutoBank:CreateToggle({
		Name = 'UI',
		Function = function(callback)
			if AutoBank.Enabled then
				UI.Visible = callback
			end
		end,
		Default = true
	})
	GUICheck = AutoBank:CreateToggle({Name='GUICheck'})
end)

run(function()
	local TriggerBot
	local CPS
	local rayParams = RaycastParams.new()
	local BowCheck
    local function isHoldingProjectile()
        if not store.hand or not store.hand.tool then return false end
        local toolName = store.hand.tool.Name
        if toolName == "headhunter" then
            return true
        end
        if toolName:lower():find("headhunter") then
            return true
        end
        if toolName:lower():find("bow") then
            return true
        end
        if toolName:lower():find("crossbow") then
            return true
        end
        local toolMeta = bedwars.ItemMeta[toolName]
        if toolMeta and toolMeta.projectileSource then
            return true
        end
        return false
    end
	TriggerBot = vape.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			if callback then
				repeat
					local doAttack
					if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
						if entitylib.isAlive and store.hand.toolType == 'sword' and bedwars.DaoController.chargingMaid == nil then
							local attackRange = bedwars.ItemMeta[store.hand.tool.Name].sword.attackRange
							rayParams.FilterDescendantsInstances = {lplr.Character}
	
							local unit = lplr:GetMouse().UnitRay
							local localPos = entitylib.character.RootPart.Position
							local rayRange = (attackRange or 14.4)
							local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
							if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
								local limit = (attackRange)
								for _, ent in entitylib.List do
									doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
									if doAttack then
										break
									end
								end
							end
	
							doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
							if doAttack then
								bedwars.SwordController:swingSwordAtMouse()
							end
						end
						if BowCheck.Enabled then
							if isHoldingProjectile() then
								local attackRange = 23
								rayParams.FilterDescendantsInstances = {lplr.Character}
		
								local unit = lplr:GetMouse().UnitRay
								local localPos = entitylib.character.RootPart.Position
								local rayRange = (attackRange)
								local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
								if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
									local limit = (attackRange)
									for _, ent in entitylib.List do
										doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
										if doAttack then
											break
										end
									end
								end
		
								doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
								if doAttack then
									mouse1click()
								end
							end
						end
					end
	
					task.wait(doAttack and 1 / CPS.GetRandomValue() or 0.016)
				until not TriggerBot.Enabled
			end
		end,
		Tooltip = 'Automatically swings when hovering over a entity'
	})
	CPS = TriggerBot:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 36,
		DefaultMin = 7,
		DefaultMax = 7
	})
	BowCheck = TriggerBot:CreateToggle({Name='Bow Check'})
end)
	
run(function()
	local RemoveHitHighlight
	RemoveHitHighlight = vape.Categories.Legit:CreateModule({
		Name = "RemoveHitHighlight",
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= 'premium' and role ~= 'user' then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			repeat
				for i, v in entitylib.List do 
					local highlight = v.Character and v.Character:FindFirstChild('_DamageHighlight_')
					if highlight then 
						highlight:Destroy()
					end
				end
				task.wait(0.1)
			until not RemoveHitHighlight.Enabled
		end
	})
end)

run(function()
	local BetterZeno
	local Delay
	local Distance
	local Targets
	local Angle
	local Sorts
	local ShockWaveChance
	math.randomseed(os.clock() * 1e6)
	local roll = math.random(0,100)
	BetterZeno = vape.Categories.Kits:CreateModule({
		Name = "AutoZeno",
		Tooltip = 'makes you play like yuta(demon at zeno for those who know ☠️☠️)',
		Function = function(callback)
	   		if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= 'premium' and role ~= 'user' then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if store.equippedKit ~= "wizard" then
				vape:CreateNotification("AutoZeno","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
		            local plrs = entitylib.AllPosition({
		                Range = Distance.Value,
		                Wallcheck = Targets.Walls.Enabled,
		                Part = "RootPart",
		                Players = Targets.Players.Enabled,
		                NPCs = Targets.NPCs.Enabled,
		                Sort = sortmethods[Sorts.Value]
		            })
		
		            local char = entitylib.character
		            local root = char.RootPart
		
		            if plrs then
		                local ent = plrs[1]
		                if ent and ent.RootPart then
		                    local delta = ent.RootPart.Position - root.Position
		                    local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		                    local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		                	if angle > (math.rad(Angle.Value) / 2) then task.wait(0.1); continue end
		                    local localPosition = root.Position
		                    local shootDir = CFrame.lookAt(localPosition, ent.RootPart.Position).LookVector
		                    localPosition = localPosition + shootDir * math.max((localPosition - ent.RootPart.Position).Magnitude - 16, 0)
							local ability = lplr:GetAttribute("WizardAbility")
							if not ability then
								task.wait(0.85)
								continue
							end
							local itemType = store.hand.tool.Name.itemType
							local targetPos = ent.RootPart.Position
							if bedwars.AbilityController:canUseAbility(ability) then
								bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
								 roll = math.random(0,100)
							end
							if itemType == "wizard_staff_2" or itemType == "wizard_staff_3" then
								if roll >= ShockWaveChance.Value then
									if bedwars.AbilityController:canUseAbility("SHOCKWAVE") then
										bedwars.AbilityController:useAbility("SHOCKWAVE",newproxy(true),{target = Vector3.zero})
										 roll = math.random(0,100)
									end
								else
									if bedwars.AbilityController:canUseAbility(ability) then
										bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
										 roll = math.random(0,100)
									end
								end
							end
							if itemType == "wizard_staff_3" then
								if roll >= math.min(100, ShockWaveChance.Value + ShockWaveChance.Value)then
									if bedwars.AbilityController:canUseAbility("LIGHTNING_STORM") then
										bedwars.AbilityController:useAbility("LIGHTNING_STORM",newproxy(true),{target = targetPos})
										 roll = math.random(0,100)
									end
								elseif roll >= ShockWaveChance.Value then
									if bedwars.AbilityController:canUseAbility("SHOCKWAVE") then
										bedwars.AbilityController:useAbility("SHOCKWAVE",newproxy(true),{target = Vector3.zero})
										 roll = math.random(0,100)
									end
								else
									if bedwars.AbilityController:canUseAbility(ability) then
										bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
										 roll = math.random(0,100)
									end								
								end
							end
		                end
		            end
					task.wait(1 / Delay.GetRandomValue() - math.random())
				until not BetterZeno.Enabled
			end
		end
	})
    Targets = BetterZeno:CreateTargets({
        Players = true,
        NPCs = true,
        Walls = true
    })
	Sorts = BetterZeno:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
    Angle = BetterZeno:CreateSlider({
        Name = "Angle",
        Min = 0,
        Max = 360,
        Default = math.random(120,180)
    })
	Delay = BetterZeno:CreateTwoSlider({
		Name = 'Delay',
		Min = 0.2,
		Max = 3,
		Suffix = 's',
        Decimal = 10,
		DefaultMin = 0.5,
		DefaultMax = 1
	})
    Distance = BetterZeno:CreateSlider({
        Name = "Range",
        Min = 1,
        Max = 18,
        Default = 25,
        Suffix = function(val) return val == 1 and "stud" or "studs" end
    })
    ShockWaveChance = BetterZeno:CreateSlider({
        Name = "ShockWave Chance",
        Min = 0,
        Max = 100,
        Default = 40,
    })
end)

run(function()
	local BetterWarden
	local Legit
	local Range
	local Delay
	local Angle
	local tip = ''
	if user == 'kolifyz' then
		tip = "makes you play like kolifyz(DEMON AT WARDEN BOI)"
	else
		tip = "makes you play like jewlifyz"
	end
	local function kitCollection(id, func, range, angle,d)
		local objs = type(id) == 'table' and id or collection(id, BetterWarden)
		repeat
			if entitylib.isAlive then
				local localPosition = entitylib.character.RootPart.Position
				for _, v in objs do
					if InfiniteFly.Enabled or not BetterWarden.Enabled then break end
					local part = not v:IsA('Model') and v or v.PrimaryPart
		            local delta = part.Position - localPosition
		            local localFacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		            local a = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		            if a > (math.rad(angle) / 2) then continue end
					if part and (part.Position - localPosition).Magnitude <= (range) then
						func(v)
					end
				end
			end
			task.wait(d)
		until not BetterWarden.Enabled
	end

	BetterWarden = vape.Categories.Kits:CreateModule({
		Name = "BetterWarden",
		Tooltip = tip,
		Function = function(callback)
	   		if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= 'premium' and role ~= 'user' then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if store.equippedKit ~= "jailor" then
				vape:CreateNotification("BetterWarden","Kit required only!",8,"warning")
				return
			end
			if callback then
				local range = 0
				local angle = 0
				local d = 0
				if Legit.Enabled then
					range = 6
					angle = 120
					d = 1.115
				else
					range = Range.Value
					angle = Angle.Value
					d = (1 / Delay.GetRandomValue())
				end
				kitCollection('jailor_soul', function(v)
					bedwars.JailorController:collectEntity(lplr, v, 'JailorSoul')
				end, range, angle,d)
			end
		end
	})
	Range = BetterWarden:CreateSlider({
		Name = "Distance",
		Min = 1,
		Max = 12,
		Default = math.random(4,12),
		Visible = false
	})
	Angle = BetterWarden:CreateSlider({
		Name = "Angle",
		Min = 1,
		Max = 360,
		Default = 120,
		Visible = false
	})
	Delay = BetterWarden:CreateTwoSlider({
		Name = 'Delay',
		Min = 0.1,
		Max = 1,
		Suffix = 's',
        Decimal = 10,
		DefaultMin = 0.2,
		DefaultMax = 1,
		Visible = false
	})
	Legit = BetterWarden:CreateToggle({
		Name = "Legit",
		Darker = true,
		Default = true,
		Function = function(v)
			local V = (not v)
			Range.Object.Visible = V
			Delay.Object.Visible = V
			Angle.Object.Visible = V
		end
	})
end)

run(function()
	local BetterUma
	local CycleMode
	local AttackMode
	local HealMode
	local Range
	local AutoSummon
	local TargetVisualiser
	local PriorityDropdown
	local selectedTarget = nil
	local targetOutline = nil
	local hovering = false
	local old
	local summonThread = nil
	local currentAffinity = nil
	
	local priorityOrders = {
		['Emerald > Diamond > Iron'] = {'emerald', 'diamond', 'iron'},
		['Diamond > Emerald > Iron'] = {'diamond', 'emerald', 'iron'},
		['Iron > Diamond > Emerald'] = {'iron', 'diamond', 'emerald'}
	}
	
	local function updateOutline(target)
		if targetOutline then
			targetOutline:Destroy()
			targetOutline = nil
		end
		if target and TargetVisualiser.Enabled then
			targetOutline = Instance.new("Highlight")
			targetOutline.FillTransparency = 0.5
			targetOutline.OutlineColor = Color3.fromRGB(255, 215, 0)
			targetOutline.OutlineTransparency = 0
			targetOutline.Adornee = target
			targetOutline.Parent = target
		end
	end
	
	local function clearOutline()
		if targetOutline then
			targetOutline:Destroy()
			targetOutline = nil
		end
	end
	
	local function getClosestLoot(originPos)
		local closest, closestDist = nil, math.huge
		local priorityOrder = priorityOrders[PriorityDropdown.Value] or priorityOrders['Emerald > Diamond > Iron']
		
		for _, itemType in priorityOrder do
			for _, drop in collectionService:GetTagged('ItemDrop') do
				if not drop:FindFirstChild('Handle') then continue end
				
				local itemName = drop.Name:lower()
				if itemName:find(itemType) then
					local dist = (drop.Handle.Position - originPos).Magnitude
					if dist <= Range.Value and dist < closestDist then
						closest = drop.Handle
						closestDist = dist
					end
				end
			end
			
			if closest then return closest end
		end
		
		return closest
	end
	
	local function switchAffinity(targetAffinity)
		local currentAff = lplr:GetAttribute('SpiritSummonerAffinity')
		if currentAff ~= targetAffinity then
			pcall(function()
				if bedwars.AbilityController:canUseAbility('spirit_summoner_switch_affinity') then
					bedwars.AbilityController:useAbility('spirit_summoner_switch_affinity')
					task.wait(0.1)
				end
			end)
		end
	end
	
	local function getTeammateHealth(plr)
		if not plr.Character then return 100 end
		local health = plr.Character:GetAttribute('Health') or 100
		local maxHealth = plr.Character:GetAttribute('MaxHealth') or 100
		return health, maxHealth
	end
	
	local function getLowHealthTeammate()
		local myTeam = lplr:GetAttribute('Team')
		if not myTeam then return nil end
		
		for _, plr in game:GetService('Players'):GetPlayers() do
			if plr ~= lplr and plr:GetAttribute('Team') == myTeam then
				local health, maxHealth = getTeammateHealth(plr)
				if health <= 40 and health > 0 then
					return plr
				end
			end
		end
		return nil
	end
	
	local function startAutoSummon()
		if summonThread then
			task.cancel(summonThread)
			summonThread = nil
		end
		
		summonThread = task.spawn(function()
			while BetterUma.Enabled and AutoSummon.Enabled do
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end
				
				local hasStaff = false
				for _, item in store.inventory.inventory.items do
					if item.itemType == 'spirit_staff' then
						hasStaff = true
						break
					end
				end
				
				if hasStaff then
					local attackSpirits = lplr:GetAttribute('ReadySummonedAttackSpirits') or 0
					local healSpirits = lplr:GetAttribute('ReadySummonedHealSpirits') or 0
					local totalSpirits = attackSpirits + healSpirits
					
					if totalSpirits < 10 then
						local hasStone = false
						for _, item in store.inventory.inventory.items do
							if item.itemType == 'summon_stone' then
								hasStone = true
								break
							end
						end
						
						if hasStone then
							pcall(function()
								if bedwars.AbilityController:canUseAbility('summon_attack_spirit') then
									bedwars.AbilityController:useAbility('summon_attack_spirit')
									task.wait(0.5)
								end
							end)
						end
					end
				end
				
				task.wait(0.2)
			end
		end)
	end
	
	local function stopAutoSummon()
		if summonThread then
			task.cancel(summonThread)
			summonThread = nil
		end
	end
	
	BetterUma = vape.Categories.Kits:CreateModule({
		Name = 'BetterUma',
		Function = function(callback)
			if callback then
				if store.equippedKit ~= 'spirit_summoner' then
					vape:CreateNotification("BetterUma","Kit required only!",8,"warning")
					return
				end
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
					hovering = true
					local self, projmeta, worldmeta, origin, shootpos = ...
					
					if not (projmeta.projectile == 'attack_spirit' or projmeta.projectile == 'heal_spirit') then
						hovering = false
						clearOutline()
						return old(...)
					end
					
					local originPos = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					local target = nil
					local targetPos = nil
					
					if CycleMode.Enabled then
						local targetLoot = getClosestLoot(originPos)
						if targetLoot and (targetLoot.Position - originPos).Magnitude <= Range.Value then
							target = targetLoot
							targetPos = targetLoot.Position
							updateOutline(targetLoot)
						else
							clearOutline()
						end
					end
					
					if HealMode.Enabled and not CycleMode.Enabled then
						local lowTeammate = getLowHealthTeammate()
						if lowTeammate and lowTeammate.Character and lowTeammate.Character.PrimaryPart then
							switchAffinity('heal')
							local dist = (lowTeammate.Character.PrimaryPart.Position - originPos).Magnitude
							if dist <= Range.Value then
								target = lowTeammate.Character.PrimaryPart
								targetPos = lowTeammate.Character.PrimaryPart.Position + Vector3.new(0, 2, 0)
								updateOutline(lowTeammate.Character)
							else
								clearOutline()
							end
						else
							clearOutline()
						end
					end
					
					if AttackMode.Enabled and not CycleMode.Enabled and not (HealMode.Enabled and getLowHealthTeammate()) then
						switchAffinity('attack')
						local plr = entitylib.EntityMouse({
							Part = 'RootPart',
							Range = 1000,
							Players = true,
							NPCs = true,
							Wallcheck = false,
							Origin = originPos
						})
						
						if plr and plr.RootPart and (plr.RootPart.Position - originPos).Magnitude <= Range.Value then
							target = plr.RootPart
							targetPos = plr.RootPart.Position + Vector3.new(0, 2, 0)
							updateOutline(plr.Character)
						else
							clearOutline()
						end
					end
					
					if target and targetPos then
						local pos = shootpos or self:getLaunchPosition(origin)
						if not pos then
							hovering = false
							clearOutline()
							return old(...)
						end
						
						local meta = projmeta:getProjectileMeta()
						local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
						local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
						local projSpeed = (meta.launchVelocity or 100)
						local offsetpos = pos + projmeta.fromPositionOffset
						
						local direction = (targetPos - offsetpos).Unit
						local distance = (targetPos - offsetpos).Magnitude
						local timeToReach = distance / projSpeed
						local dropAmount = 0.5 * gravity * (timeToReach * timeToReach)
						local adjustedTarget = targetPos + Vector3.new(0, dropAmount, 0)
						
						local newlook = CFrame.new(offsetpos, adjustedTarget)
						
						hovering = false
						return {
							initialVelocity = newlook.LookVector * projSpeed,
							positionFrom = offsetpos,
							deltaT = lifetime,
							gravitationalAcceleration = gravity,
							drawDurationSeconds = 5
						}
					end
					
					hovering = false
					clearOutline()
					return old(...)
				end
				
				if AutoSummon.Enabled then
					startAutoSummon()
				end
			else
				if old then
					bedwars.ProjectileController.calculateImportantLaunchValues = old
				end
				clearOutline()
				stopAutoSummon()
				selectedTarget = nil
			end
		end,
		Tooltip = 'Spirit Summoner automation - lock onto loot, enemies, or heal teammates'
	})
	
	CycleMode = BetterUma:CreateToggle({
		Name = 'Cycle',
		Function = function(callback)
			if callback then
				if AttackMode.Enabled then
					AttackMode:Toggle()
				end
				if HealMode.Enabled then
					HealMode:Toggle()
				end
				PriorityDropdown.Object.Visible = true
			else
				PriorityDropdown.Object.Visible = false
				clearOutline()
			end
		end,
		Tooltip = 'Lock onto loot (iron/diamond/emerald) with priority system'
	})
	
	PriorityDropdown = BetterUma:CreateDropdown({
		Name = 'Loot Priority',
		List = {'Emerald > Diamond > Iron', 'Diamond > Emerald > Iron', 'Iron > Diamond > Emerald'},
		Default = 'Emerald > Diamond > Iron',
		Darker = true
	})
	PriorityDropdown.Object.Visible = false
	
	AttackMode = BetterUma:CreateToggle({
		Name = 'Attack',
		Function = function(callback)
			if callback then
				if CycleMode.Enabled then
					CycleMode:Toggle()
				end
				if HealMode.Enabled then
					HealMode:Toggle()
				end
				clearOutline()
			else
				clearOutline()
			end
		end,
		Tooltip = 'Lock onto enemies and attack them'
	})
	
	HealMode = BetterUma:CreateToggle({
		Name = 'Heal',
		Function = function(callback)
			if callback then
				if CycleMode.Enabled then
					CycleMode:Toggle()
				end
				if AttackMode.Enabled then
					AttackMode:Toggle()
				end
				clearOutline()
			else
				clearOutline()
			end
		end,
		Tooltip = 'Heal teammates below 40 HP (switches to attack above 50 HP)'
	})
	
	Range = BetterUma:CreateSlider({
		Name = 'Lock Range',
		Min = 10,
		Max = 70,
		Default = 70,
		Tooltip = 'Maximum distance to lock onto targets'
	})
	
	AutoSummon = BetterUma:CreateToggle({
		Name = 'Auto Summon',
		Function = function(callback)
			if callback and BetterUma.Enabled then
				startAutoSummon()
			else
				stopAutoSummon()
			end
		end,
		Default = true,
		Tooltip = 'Automatically summons spirits when you have summon stones'
	})
	
	TargetVisualiser = BetterUma:CreateToggle({
		Name = 'Target Visualiser',
		Function = function(callback)
			if not callback then
				clearOutline()
			end
		end,
		Default = true,
		Tooltip = 'Shows gold outline on locked target'
	})
end)




run(function()
	if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
		return
	end
	local TaxRemover
	local oldDispatch
	local oldtax
	local oldadded
	local olditems
	local oldhook
	local oldConnect
	TaxRemover = vape.Categories.Blatant:CreateModule({
		Name = "TaxRemover",
		Function = function(callback)
			if callback then
				oldtax = bedwars.ShopTaxController.isTaxed
				oldadded = bedwars.ShopTaxController.getAddedTax
				olditems = bedwars.ShopTaxController.getTaxedItems
				oldDispatch = bedwars.Store.dispatch
				task.spawn(function()
					bedwars.Store.dispatch = function(...)
						local arg = select(2, ...)
						if arg and typeof(arg) == 'table' and arg.type == 'IncrementTaxState'  then
							return false
						end 	
						return oldDispatch(...)
					end
				end)
				task.spawn(function()
					bedwars.ShopTaxController.isTaxed = function(...)
						return false
					end
				end)
				task.spawn(function()
					bedwars.ShopTaxController.getTaxedItems = function(...)
						return {}
					end
				end)
				task.spawn(function()
					bedwars.ShopTaxController.getAddedTax = function(...)
						return 0
					end
				end)

				task.spawn(function()
					if bedwars.ShopTaxController.taxStateUpdateEvent then
						oldConnect = bedwars.ShopTaxController.taxStateUpdateEvent.Connect
						bedwars.ShopTaxController.taxStateUpdateEvent.Connect = function() 
							return {Disconnect = function() end}
						end
					end
				end)
				task.spawn(function()
					bedwars.ShopTaxController.hasTax = false
					bedwars.ShopTaxController.taxedItems = {}
					bedwars.ShopTaxController.addedTaxMap = {}
				end)
			else
				bedwars.Store.dispatch = oldDispatch
				bedwars.ShopTaxController.isTaxed = oldtax
				bedwars.ShopTaxController.getAddedTax = oldadded
				bedwars.ShopTaxController.getTaxedItems = olditems
				bedwars.ShopTaxController.taxStateUpdateEvent.Connect = oldConnect
				oldDispatch = nil
				oldtax = nil
				oldadded = nil
				olditems = nil
				oldConnect = nil
			end
		end
	})
end)


run(function()
	local BetterFisher
	local old = {
		Dur = nil,
		Marker = nil,
		Fill = nil,
		Drain = nil,
		ZoneSize = nil,
		Speed = nil,
		Gold = nil,
		Minigame  = nil
	}
	local Duration
	local fillAmount
	local drainAmount
	local fishzooneSpeedMuti
	local AutoPlay
	local FishermanUtil = bedwars.FishermanUtil
	local FishType = bedwars.FishMeta.FishType
	local FishMeta = bedwars.FishMeta.FishMeta

	local FishNames = {
		fish_iron = "Iron Fish",
		fish_diamond = "Diamond Fish",
		fish_emerald = "Emerald Fish",
		fish_special = "Special Fish",
		fish_gold = "Gold Fish",
	}	

	BetterFisher = vape.Categories.Kits:CreateModule({
		Name = "AutoFisher",
		Tooltip = 'thanks to render for making this script',
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if store.equippedKit ~= "fisherman" then
				vape:CreateNotification("AutoFisher", "Kit required only!", 6, "warning")
				return
			end
			if callback then

				if AutoPlay.Enabled then
					old.Minigame = bedwars.FishingMinigameController.startMinigame
					bedwars.FishingMinigameController.startMinigame = function(self, Data, results)
						if not AutoPlay.Enabled then
							return old.Minigame(self, Data, results)
						end
						if not Data.fishModel then
							return old.Minigame(self,Data,results)
						end
						vape:CreateNotification("AutoFisher", `You caught an {FishNames[Data.fishModel]} and u will receive {Data.drops[1].itemType} with {Data.drops[1].amount} amount`, 8)
						local pull = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.FISHING_ROD_PULLING)
						local Duration = (Duration.Value / 2.25 + math.random())
						task.wait(Duration)
						if pull then
							pull:Stop()
							pull = nil
						end									
						local success = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.FISHING_ROD_CATCH_SUCCESS)
						task.wait(0.025)
						results({win = true})
						if success then
							success:Stop()
							success = nil
						end	
					end

					BetterFisher:Clean(function()
					  	bedwars.FishingMinigameController.startMinigame = old.Minigame
						old.Minigame = nil
						if pull then
							pull:Stop()
							pull = nil
						end
						if success then
							success:Stop()
							success = nil
						end											
					end)
				else
					old.Dur = FishermanUtil.minigameDuration
					old.Marker = FishermanUtil.markerSize
					old.Fill = FishermanUtil.fillAmount
					old.Drain = FishermanUtil.drainAmount
					old.ZoneSize = FishermanUtil.fishZoneSize
					old.Speed = FishermanUtil.fishZoneSpeedMultiplier
					old.Gold = FishMeta[FishType.GOLD].color
					FishermanUtil.minigameDuration = Duration.Value 
					FishermanUtil.markerSize = UDim2.fromScale(0.5, 1.5) 
					FishermanUtil.fillAmount = fillAmount.Value
					FishermanUtil.drainAmount = drainAmount.Value
					FishermanUtil.fishZoneSize = UDim2.fromScale(0.1, 1.4) 
					FishermanUtil.fishZoneSpeedMultiplier =fishzooneSpeedMuti.Value
					FishMeta[FishType.GOLD].color = Color3.fromRGB(255, 0, 0)
				end
			else
				if old.Dur then
					FishermanUtil.minigameDuration = old.Dur 
					FishermanUtil.markerSize = old.Marker 
					FishermanUtil.fillAmount = old.Fill 
					FishermanUtil.drainAmount = old.Drain 
					FishermanUtil.fishZoneSize = old.ZoneSize 
					FishermanUtil.fishZoneSpeedMultiplier = old.Speed 
					FishMeta[FishType.GOLD].color = old.Gold 
					old.Dur = nil
					old.Marker = nil
					old.Fill = nil
					old.Drain = nil
					old.ZoneSize = nil
					old.Speed = nil
					old.Gold = nil
				end
			end
		end
	})
	Duration = BetterFisher:CreateSlider({
		Name = "Duration",
		Tooltip = 'how long the minigame should be',
		Min = 0,
		Max = 30,
		Default = 10
	})
	fillAmount = BetterFisher:CreateSlider({
		Name = "Fill Amount",
		Tooltip = 'when in ur in the fish zone is how much times it will fill up',
		Min = 0,
		Max = 10,
		Default = 0.02,
		Decimal = 10,
	})
	drainAmount = BetterFisher:CreateSlider({
		Name = "Drain Amount",
		Tooltip = 'when in ur not in the fish zone is how much times it will drain down',
		Min = 0,
		Max = 10,
		Default = 0.001,
		Decimal = 10,
	})
	fishzooneSpeedMuti = BetterFisher:CreateSlider({
		Name = "FishZoneSpeed",
		Tooltip = 'how fast the gaining when in the fish zone',
		Min = 0,
		Max = 60,
		Default = 1,
		Decimal = 5,
	})
	AutoPlay = BetterFisher:CreateToggle({
		Name = "AutoPlay",
		Tooltip = 'hides the minigame and does it for you(loot esp as well)',
		Default = false
	})
end)





run(function()
	local MHA
	MHA = vape.Categories.Exploits:CreateModule({
		Name = "ViewHistory",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end
			if callback then
				MHA:Toggle(false)
				local d = nil
				bedwars.MatchHistroyController:requestMatchHistory(lplr.Name):andThen(function(Data)
					if Data then
						bedwars.AppController:openApp({app = bedwars.MatchHistroyApp,appId = "MatchHistoryApp",},Data)
					end
				end)
			else
				return
			end
		end,
		Tooltip = "allows you to see peoples history without being in the same game with you"
	})																								
end)

run(function()
	local Lobby
	Lobby = vape.Categories.Exploits:CreateModule({
		Name = 'Lobby',
		Tooltip = 'allows you to lobby if u dont have access to the chat(like me not letting jews get my face)',
		Function = function(callback)
			if not callback then
				return
			end
			Lobby:Toggle(false)
			local s,err = pcall(function()
				bedwars.Client:Get("TeleportToLobby"):SendToServer()
			end)
			if not s then
				warn(err)
				task.wait(8)
				lobby()
			end
		end
	})
end)

run(function()
	local IE
	local Text
	IE = vape.Categories.Exploits:CreateModule({
		Name = "Invite Exploit",
		Tooltip = 'allows you to invite anyone ingame',
		Function = function(callback)
			if not callback then
				return
			end
			IE:Toggle(false)
			local plr = playersService:FindFirstChild(Text.Value)
			if plr then
				bedwars.PartyController.invitePlayer(plr)
			else
				vape:CreateNotification('Invite Exploit',Text.Value.." does not exist ingame...",6,'warning')
				return
			end
		end
	})
	Text = IE:CreateTextBox({
		Name = "Username",
		Tooltip = 'THIS MUST BE THE PLAYER\'S USERNAME'
	})
end)

run(function()
	local MiloDisguse
	local Blocks
	local old
	MiloDisguse = vape.Categories.Kits:CreateModule({
		Name = "MiloDisguise",
		Tooltip = 'allows you to be any block u want to hide as',
		Function = function(callback)
			if not callback then
				return
			end
			if store.equippedKit ~= 'mimic' then
				vape:CreateNotification("MiloDisguse",'Kit require only!',6,"warning")
				return
			end
			MiloDisguse:Toggle(false)
			local v88 = {
				["data"] = {
					["blockType"] = Blocks.Value or 'wool_red'
				}
			}

			bedwars.Client:Get("MimicBlock"):SendToServer(v88)
		end
	})
	Blocks = MiloDisguse:CreateTextBox({
		Name = "Blocks",
		Tooltip = 'Meta names only(wool_red)',
		Default = 'wool_brown'
	})
	
end)

run(function()
	local PromptDuration
	local Duration
	if not fireproximityprompt then
		--vape:CreateNotification("Onyx",	`{(identifyexecutor()})[1] does not support Fireproximityprompt for Prompt Duration.`,3,'alert')
		return
	end
	PromptDuration = vape.Categories.Exploits:CreateModule({
		Name = 'Prompt Duration',
		Tooltip = 'Changes duration of proximity prompts',
		Function = function(call)
			if call then
				PromptDuration:Clean(proximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
					if player == lplr then
						task.delay(Duration.Value, fireproximityprompt, prompt)
					end
				end))
			end
		end
	})

	Duration = PromptDuration:CreateSlider({
		Name = 'Duration',
		Min = 0,
		Max = 2,
		Default = 0,
		Suffix = function(val)
			return val > 1 and 'secs' or 'sec'
		end,
		Decimal = 5
	})
end)

run(function()
	local PlayerAttach
	local Range
	local Targets
	local Sorts
	PlayerAttach = vape.Categories.Blatant:CreateModule({
		Name = "PlayerAttach",
		Tooltip = 'teleports you the closest player/npc near you in a specific range',
		Function = function(callback)
			if callback then
				repeat 
					local plrs = entitylib.AllPosition({
						Range = Range.Value,
						Wallcheck = Targets.Walls.Enabled,
						Part = "RootPart",
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Limit = 1,
						Sort = sortmethods[Sorts.Value]
					})
					local char = entitylib.character
					local root = char.RootPart
					if plrs then
						local ent = plrs[1]
						if ent and ent.RootPart then
							local Pos = ent.RootPart.Position
							local Vec = entitylib.character.RootPart.CFrame.LookVector
							local Delta = CFrame.lookAlong(Pos, Vec)
							entitylib.character.RootPart.CFrame = Delta
						end
					end
					task.wait(1.05 - math.random())
				until not PlayerAttach.Enabled
			end
		end
	})
	Range = PlayerAttach:CreateSlider({
		Name = "Distance",
		Min = 0,
		Max = 32,
		Default = 16,
		Suffix = function(val)
			if val == 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	Targets = PlayerAttach:CreateTargets({
		Players=true,
		Walls=true,
		NPCs=true
	})
	Sorts = PlayerAttach:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
end)

run(function()
	local RemoveStatus
	local olds = {
		Vignette = nil,
		Debuff = nil,
		Effects = nil
	}
	RemoveStatus = vape.Categories.Render:CreateModule({
		Name = "RemoveStatus",
		Tooltip = 'removes them annoying ass effects on ur screen(like that static thingy or being glooped)',
		Function = function(callback)
			if callback then
				olds.Vignette = bedwars.VignetteController.createVignette
				olds.Debuff = bedwars.DebuffEffectController.createEffect
				olds.Effects = bedwars.StatusEffectController.createEffect
			    bedwars.VignetteController.createVignette = function(...)
					return nil
				end
				bedwars.StatusEffectController.createEffect = function(...)
					return nil
				end
				bedwars.DebuffEffectController.createEffect = function(...)
					return nil
				end
			else
				bedwars.VignetteController.createVignette = olds.Vignette
				bedwars.DebuffEffectController.createEffect = olds.Debuff
				bedwars.StatusEffectController.createEffect = olds.Effects
				olds.Vignette = nil
				olds.Debuff = nil
				olds.Effects = nil
			end
		end
	})
end)

run(function()
	local FishermanSpy
	local IgnoreTeammates

	local FishNames = {
		fish_iron = "Iron Fish",
		fish_diamond = "Diamond Fish",
		fish_emerald = "Emerald Fish",
		fish_special = "Special Fish",
		fish_gold = "Gold Fish",
	}	
	
	FishermanSpy = vape.Categories.Exploits:CreateModule({
		Name = "FishermanSpy",
		Tooltip = 'notifys whenever a fisher has caught something',
		Function = function(callback)
			if callback then
				bedwars.Client:WaitFor("FishCaught"):andThen(function(rbx)
					FishermanSpy:Clean(rbx:Connect(function(tbl)
						local char = tbl.catchingPlayer.Character
						local fish = tbl.dropData.fishModel
						local plrName = char.Name
						local str = plrName:sub(1, 1):upper()..plrName:sub(2) or 'NIL'
						local strfish = FishNames[tostring(fish)] or 'NIL Fish'
						if IgnoreTeammates.Enabled then
							local currentTeam = lplr.Team
							local currentplr = playersService:GetPlayerFromCharacter(char)
							if currentplr.Team == currentTeam then
							else
								notif("FishermanSpy",`{str} has caught an {strfish}`,8)
							end
						else
							notif("FishermanSpy",`{str} has caught an {strfish}`,8)
						end
					end))
				end)
			end
		end
	})
	IgnoreTeammates = FishermanSpy:CreateToggle({Name='Ignore Teammates',Default=true})
end)


run(function()
	local FishermanESP
	local FishNames = {
		fish_iron = "Iron Fish",
		fish_diamond = "Diamond Fish",
		fish_emerald = "Emerald Fish",
		fish_special = "Special Fish",
		fish_gold = "Gold Fish",
	}
	
	FishermanESP = vape.Categories.Utility:CreateModule({
		Name = "FishermanESP",
		Tooltip = 'shows what fish you are catching before the minigame starts',
		Function = function(callback)
			if store.equippedKit ~= 'fisherman' then
				notify('FishermanESP', 'Kit required only!', 6, 'warning')
				return
			end			
			if callback then		
				local exp = bedwars.Client:WaitFor("FishFound"):expect()
				FishermanESP:Clean(exp:Connect(function(p24)
					local scl = p24.dropData
					local drops = scl.drops and scl.drops[1]																			
					if scl and scl.fishModel then
						local ftype = tostring(scl.fishModel) or 'fish_iron'
						local item = tostring(drops.itemType) or 'nil'
						local amount = tostring(drops.amount) or '0'
						notif('FishermanESP',`Your fish will be {FishNames[ftype]} with {item} and {amount} amount.`,12)	
					end
				end))
			else
			end
		end
	})
end)

run(function()
	local MelodyExploit
	local Heal
	MelodyExploit = vape.Categories.Exploits:CreateModule({
		Name = "MelodyExploit",
		Tooltip = 'only heals ur self, do not use autokit',
		Function = function(callback)
			if callback then
				if store.equippedKit ~= 'melody' then
					notify('MelodyExploit', 'Kit required only!', 6, 'warning')
					return
				end
				repeat
					if entitylib.isAlive and getItem('guitar') then
						if lplr.Character:GetAttribute('Health') <= Heal.Value  then
							bedwars.Client:Get(remotes.GuitarHeal):SendToServer({
								healTarget = entitylib.character
							})
							task.wait(0.7) 
						end
					end
					task.wait(0.105)
				until MelodyExploit.Enabled
			end
		end
	})
	Heal = MelodyExploit:CreateSlider({
		Name = "Health",
		Min = 0.5,
		Max = 100,
		Suffix = "%",
		Default = 85,
		Decimal = 5,
	})
end)

run(function()
	local BetterMelody
    local Limits
    local Targetted
    local Angle
    local Distance
    local Delay
	local UpdateRate
	local Health
	BetterMelody = vape.Categories.Kits:CreateModule({
		Name = "BetterMelody",
		Tooltip = 'makes u godtier at melody boi',
		Function = function(callback)
			if callback then
				if store.equippedKit ~= 'melody' then
					notify('BetterMelody', 'Kit required only!', 6, 'warning')
					return
				end
				repeat
					if entitylib.isAlive then
						if Limits.Enabled then
							local tool = (store and store.hand and store.hand.tool) and store.hand.tool or nil
							if not tool or tool.Name ~= "guitar" then continue end
						end
						local plr = playersService:FindFirstChild(Targetted)
						if plr then
							if (plr.Character.HumanoidRootPart.Positionn - entitylib.character.RootPart).Magnitude <= (Distance.Value) then
								local root = entitylib.character.RootPart
								local delta = plr.Character.HumanoidRootPart.Position - root.Position
								local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle >= (math.rad(Angle.Value) / 2) then continue end
								if plr.Character:GetAttribute("Health") <= Health.Value then
									bedwars.Client:Get(remotes.GuitarHeal):SendToServer({
										healTarget = plr.Character
									})
									task.wait(1 / Delay.GetRandomValue())
								else
									task.wait(1 / Delay.GetRandomValue())
									continue
								end
							else
								continue
							end
						else
							continue
						end
					end
					task.wait(1 / UpdateRate.Value)
				until MelodyExploit.Enabled
			end
		end
	})
	Targetted = BetterMelody:CreateTextBox({
		Name = "Username",
		Tooltip = 'this must be the users USERNAME not DISPLAYNAME',
		Placeholder = 'Roblox'
	})
	Distance = BetterMelody:CreateSlider({
		Name = "Heal Distance",
		Min = 0,
		Max = 45,
		Default = 15,
		Decimal = 5,
		Suffix = function(v)
			if v == 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	Angle = BetterMelody:CreateSlider({
		Name = "Angle",
		Min = 0,
		Max = 360,
		Default = 180
	})
	UpdateRate = BetterMelody:CreateSlider({
		Name = "Update Rate",
		Min = 0,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	Health = BetterMelody:CreateSlider({
		Name = "Health",
		Min = 0,
		Max = 100,
		Default = 75,
		Suffix = '%',
		Decimal = 5,
	})	
	Delay = BetterMelody:CreateTwoSlider({
		Name = "Delay",
		Min = 0,
		Max = 2,
		DefaultMin = 0.2,
		DefaultMax = 0.7
	})
	Limits = BetterMelody:CreateToggle({Name="Limit to items"})

end)



run(function()
	local BetterElder
	local Range
	local Animations
	BetterElder = vape.Categories.Kits:CreateModule({
		Name = 'AutoElder',
		Function = function(callback)
			if callback then
			if store.equippedKit ~= "bigman" then
				vape:CreateNotification("AutoElder","Kit required only!",8,"warning")
				return
			end
			task.spawn(function()
				while BetterElder.Enabled do
					if not entitylib.isAlive then task.wait(0.1); continue end
					local character = entitylib.character
					if not character or not character.RootPart then task.wait(0.1); continue end
					local localPos = character.RootPart.Position
					local trees = collectionService:GetTagged("treeOrb")
					for _, obj in pairs(trees) do
						if obj then
							local Pos = obj.PrimaryPart.Position
							local distance = (localPos - Pos).Magnitude
							local range = (Range.Value or 8)
							if distance <= range then
								local waitTime = .854 
								task.wait(waitTime)
								if Animation.Enabled then
									bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.PUNCH)
									bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
									bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
								end
								pcall(function()
									bedwars.Client:Get('ConsumeTreeOrb'):CallServer({treeOrbSecret = obj:GetAttribute("TreeOrbSecret")})
								end)
								task.wait(0.1)
							end
						end
					end
					task.wait(0.1)
				end
			end)
			end
		end
	})
	Range = BetterElder:CreateSlider({
		Name = "Distance",
		Min = 0,
		Max = 16,
		Default = 8,
		Suffix = "studs",
	})	
	Animations = BetterElder:CreateToggle({Name='Animations',Default=false})
end)


run(function()
	local DamageBoost
	local SM
	local old = nil
	local NewSpeed = 0
	local speed = nil
	DamageBoost = vape.Categories.Combat:CreateModule({
		Name = 'DamageBoost',
		Tooltip = 'makes you little bit faster by taking knockback\nmay anti cheat',
		Function = function(callback)
			if callback then
				old = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(...)
					if entitylib.isAlive then
						if speed then
							speed = speed
						else
							speed = lplr.Character.Humanoid.WalkSpeed
						end
						
						local OldSpeed = SM.Value / 1000
						OldSpeed = OldSpeed * (math.random(10,30) - math.random())
						if OldSpeed < 0 then
							OldSpeed = OldSpeed * -1
						end
						NewSpeed = NewSpeed + OldSpeed
						lplr.Character.Humanoid.WalkSpeed = NewSpeed
						task.delay(6,function()
							lplr.Character.Humanoid.WalkSpeed = speed
							speed = nil
						end)
						return old(...)
					end
					
				end
			else
				bedwars.KnockbackUtil.applyKnockback = old
				old = nil
				if speed then
					lplr.Character.Humanoid.WalkSpeed = speed
				end
			end
		end
	})
	SM = DamageBoost:CreateSlider({
		Name = "Speed Mutipler",
		Min = 1,
		Max = 1000,
		Default = 250,
		Suffix = "ms",
	})	
end)



run(function()
	local ServerSync
	local NetworkClient = cloneref(game:GetService("NetworkClient"))
	local NetworkSettings = settings():GetService("NetworkSettings")
	local Stats = cloneref(game:GetService("Stats"))
	local defaultLag = NetworkSettings.IncomingReplicationLag
	local connection
	local function getPing()
		local pingStat = Stats.Network.ServerStatsItem["Data Ping"]
		if pingStat then
			return pingStat:GetValue() + math.random()
		end
		return (50/2.33)
	end
	local function getFPS()
		return math.floor(1 / runService.RenderStepped:Wait()) + math.random()
	end
	local Ticks
	local Rate
	ServerSync = vape.Categories.Exploits:CreateModule({
		Name = "ServerSync",
		Tooltip = "Synchronizes network limits with your ping and FPS",
		Function = function(callback)
			if callback then
				connection = task.spawn(function()
					while ServerSync.Enabled do
						local ping = getPing()
						local fps = getFPS()
						local kbps = math.clamp((fps * 35) - (ping * 4),512,20000)
						local lag = math.clamp(ping / 1000,0,0.25)
						pcall(function()
							NetworkClient:SetOutgoingKBPSLimit(kbps + math.random())
							NetworkSettings.IncomingReplicationLag = lag - math.random()
							local TickKBPS = (kbps *( 0.5/ Ticks.Value) + math.random(2,5))
							local TickLAG = (lag *( 2 / Ticks.Value) - math.random(5,8))
							NetworkClient:SetOutgoingKBPSLimit(TickKBPS + math.random())
							NetworkSettings.IncomingReplicationLag = TickLAG - math.random()
							task.wait(Rate.Value / 1000 + math.random())
							NetworkClient:SetOutgoingKBPSLimit(kbps + math.random())
							NetworkSettings.IncomingReplicationLag = lag - math.random()							
						end)
						task.wait(0.25)
					end
				end)
			else
				if connection then
					task.cancel(connection)
					connection = nil
				end
				pcall(function()
					NetworkClient:SetOutgoingKBPSLimit(math.huge)
					NetworkSettings.IncomingReplicationLag = defaultLag
				end)
			end
		end
	})
	Rate = ServerSync:CreateSlider({
		Name = "Rate",
		Tooltip = 'the rate for sending a tick to the server',
		Min = 0,
		Max = 2000,
		Default = math.random(100,300),
		Suffix = 'ms'
	})
	Ticks = ServerSync:CreateSlider({
		Name = "Ticks",
		Tooltip = 'the ticks that the server will get',
		Min = 0,
		Max = 360,
		Default = math.random(0,360),
		Suffix = 'hz'
	})
	
end)

run(function()
	local LuciaSpy
	local IgnoreTeammates
	local CheckDespoit
	local util = require(replicatedStorage.TS.games.bedwars.kit.kits['piggy-bank']['piggy-bank-util']).PiggyBankUtil
	LuciaSpy = vape.Categories.Exploits:CreateModule({
		Name = "LuciaSpy",
		Tooltip = 'notifys whenever a lucia has opened their pinata\nmay be annoying for some users',
		Function = function(callback)
			if callback then
				LuciaSpy:Clean(bedwars.Client:Get("PiggyBankIncrement"):Connect(function(Data)
					if not CheckDespoit.Enabled then
						--warn('ignored cuz im jewish')
						return
					end
					local Level = util.getStageFromCoins(Data.coin)
					Level = Level or 0
					vape:CreateNotification("LuciaSpy",`Someone has despoited {Data.coin} candy and is at level {Level}.`,8)
				end))	
				LuciaSpy:Clean(bedwars.Client:Get("PiggyBankPop"):Connect(function(self)
					local plr = self.awardedPlayer
					local rewards = util:getRewardsFromCoins(self.coins)
					local I = rewards[1]
					local D = rewards[2]
					local E = rewards[3]
					local irons = I and I.amount or 0
					local diamond = D and D.amount or 0
					local emeralds = E and E.amount or 0
					if plr then
						if IgnoreTeammates.Enabled then
							if plr.Team == lplr.Team then
								return
							else
								local plrName = plr.Name
								local str = plrName:sub(1, 1):upper()..plrName:sub(2) or 'NIL'
								local loot = irons.." iron's, "..diamond.." diamond's, and "..emeralds.." emerald's"
								vape:CreateNotification("LuciaSpy",`{str} has opened their pinata and got {loot}`,8)
							end
						else
							local plrName = plr.Name
							local str = plrName:sub(1, 1):upper()..plrName:sub(2) or 'NIL'
							local loot = irons.." iron's, "..diamond.." diamond's, and "..emeralds.." emerald's"
							vape:CreateNotification("LuciaSpy",`{str} has opened their pinata and got {loot}`,8)
						end
					end
				end))
			end
		end
	})
	IgnoreTeammates = LuciaSpy:CreateToggle({Name='Ignore Teammates',Default=true})
	CheckDespoit = LuciaSpy:CreateToggle({Name='Check Deposit',Default=false})

end)

run(function()
	local GrimFixer
	GrimFixer = vape.Categories.Exploits:CreateModule({
		Name = 'GrimFixer',
		Function = function(callback)
			if callback then
				GrimFixer:Clean(runService.PreSimulation:Connect(function()
					if not entitylib.isAlive then return end
					local humanoid = entitylib.character.Humanoid
					if humanoid.HipHeight >= 2.1 then
						humanoid.HipHeight = 2.05
					end
				end))
			end
		end,
		Tooltip = 'fixes grim reapers hipheight to a normal state(jewlifyz)'
	})
end)

run(function()
	local StreamRemover
	local old = {}
	StreamRemover = vape.Categories.Legit:CreateModule({
		Name = 'StreamRemover',
		Function = function(callback)
			if callback then
				for _, plrs in playersService:GetPlayers() do
					if plrs == lplr then continue end
					old[plrs] = plrs:GetAttribute("Disguised") or true
					plrs:SetAttribute("Disguised", false)
				end
			else
				for _, plrs in playersService:GetPlayers() do
					if plrs == lplr then continue end
					if old[plrs] then
						local arg = old[plrs] or true
						plrs:SetAttribute("Disguised", arg)
						old[plrs] = nil
					end
					
				end
			end
		end,
		Tooltip = 'removes players streamer mode.'
	})
end)

run(function()
	local FrameBuffer
	local Latency
	local Rate
	FrameBuffer = vape.Categories.Blatant:CreateModule({
		Name = 'FrameBuffer',
		Function = function(callback)
			if callback then
				repeat
					local OG = -2147483648
					if Latency.Value == 1 then
						Latency.Value = 1.5
					end
					local NEW = (OG * (Latency.Value / 1000))
					local NEW2 = (NEW * -1)
					local str = tostring(NEW)
					local str2 = tostring(NEW2)
					setfflag('DFIntDebugDefaultTargetWorldStepsPerFrame', str)
					setfflag('DFIntMaxMissedWorldStepsRemembered', str)
					setfflag('DFIntWorldStepsOffsetAdjustRate', str2)
					setfflag('DFIntDebugSendDistInSteps', str)
					setfflag('DFIntWorldStepMax', str)
					setfflag('DFIntWarpFactor', str2)
					task.wait(1 / Rate.Value)
				until not FrameBuffer.Enabled
			end
		end,
	})
	Latency = FrameBuffer:CreateSlider({
		Name = "Latency",
		Min = 0,
		Max = 1000,
		Default = 250,
		Suffix = 'ms'
	})
	Rate = FrameBuffer:CreateSlider({
		Name = "Rate",
		Min = 0,
		Max = 360,
		Default = 60,
		Suffix = 'hz'
	})	
end)

run(function()
	local AutoKit
	local Legit
	local Sorts
	local Toggles = {}
	local function kitCollection(id, func, range, specific)
		local objs = type(id) == 'table' and id or collection(id, AutoKit)
		repeat
			if entitylib.isAlive then
				local localPosition = entitylib.character.RootPart.Position
				for _, v in objs do
					if InfiniteFly.Enabled or not AutoKit.Enabled then break end
					local part = not v:IsA('Model') and v or v.PrimaryPart
					if part and (part.Position - localPosition).Magnitude <= (range) then
						func(v)
					end
				end
			end
			task.wait(0.1)
		until not AutoKit.Enabled
	end

	
		
	local AutoKitFunctions = {
		jellyfish = function()
			local Jellys = 0
			Jellys = Legit.Enabled and 3 or 1
			local function CheckMyJellyFishes(jelly)
				if jelly:GetAttribute("PlacedByUserId") == lplr.UserId then
					return true
				end
				return false
			end
		end,
		ice_queen = function()
			local AllowedThreshold = 0.045
			local last = 0
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end
				
				
					local plr = entitylib.EntityPosition({
						Range = Legit.Enabled and 20 or 30,
						Part = 'RootPart',
						Players = true,
						NPCs = false,
						Sort = sortmethods.Distance
					})
				
					if plr then
						local new = tick() + 1
						if (new - last) <= AllowedThreshold then
							task.wait(0.01) 
							continue
						end	
						if bedwars.AbilityController:canUseAbility('ice_queen') then
							bedwars.AbilityController:useAbility('ice_queen')
							last = new
							task.wait(0.115)
						end
					end				
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		necromancer = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r = 12
			end
			kitCollection('Gravestone', function(v)
				local armorType = v:GetAttribute('ArmorType')
				local weaponType = v:GetAttribute('SwordType')
				local associatedPlayerUserId = v:GetAttribute('GravestonePlayerUserId')
				local secret = v:GetAttribute('GravestoneSecret')
				local position = v:GetAttribute('GravestonePosition')
				if bedwars.Client:Get('ActivateGravestone'):CallServer({skeletonData={armorType=armorType,weaponType=weaponType,associatedPlayerUserId=associatedPlayerUserId},secret=secret,position=position}) then
					if Legit.Enabled then
						bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
						bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
						bedwars.SoundManager:playSound(bedwars.SoundList.GRAVESTONE_USE)
					end
				end
			end, r, false)
		end,
		paladin = function()
			local t = 0
			if Legit.Enabled then
				t = 1.33
			else
				t = .85
			end
			local function getLowestHPPlayer()
				local lowestPlayer
				local lowestHP = math.huge

				for _, plr in ipairs(playersService:GetPlayers()) do
					if plr ~= lplr and plr.Team == lplr.Team then
						local char = plr.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")

						if hum and hum.Health > 0 then
							if hum.Health < lowestHP then
								lowestPlayer = plr
							end
						end
					end
				end

				return lowestPlayer
			end
			AutoKit:Clean(lplr:GetAttributeChangedSignal("PaladinStartTime"):Connect(function()
				task.wait(t)
				if bedwars.AbilityController:canUseAbility('PALADIN_ABILITY') then
					local plr = getLowestHPPlayer()
					if plr.Character and plr then
						bedwars.Client:Get("PaladinAbilityRequest"):SendToServer({target = plr})
					else
						bedwars.Client:Get("PaladinAbilityRequest"):SendToServer({})
					end	
					task.wait(0.022)
					bedwars.AbilityController:useAbility('PALADIN_ABILITY')
				end
			end))
		end,
		spearman = function()
			local function fireSpear(pos, spot, item)
				local projectileRemote = {InvokeServer = function() end}
				task.spawn(function()
					projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
				end)
				if item then		
					--local spear = getObjSlot('spear')
					--hotbarSwitch(spear)
					local meta = bedwars.ProjectileMeta.spear
					print(meta)
					local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
					if calc then
						local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
						PR:InvokeServer(item.tool, meta, pos, dir,true)
					end
				end
			end
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local spearTool = getItem("spear")


				if not spearTool then task.wait(0.1) continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 15 or (15*2),
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					local pos = plr.RootPart.Position
					local spot = plr.RootPart.Velocity
					if spearTool then
						fireSpear(pos,spot,spearTool)
					end
		        end
				
				task.wait(.025)
		    until not AutoKit.Enabled
		end,
		void_walker = function()
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and (23/2.125) or 23,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('void_walker_warp') then
						bedwars.AbilityController:useAbility('void_walker_warp')
					end
		        end
				
				if lplr.Character:GetAttribute('Health') <= Legit.Enabled and 56 or 64 then
					if bedwars.AbilityController:canUseAbility('void_walker_rewind') then
						bedwars.AbilityController:useAbility('void_walker_rewind')
					end
				end

				task.wait(.233)
		    until not AutoKit.Enabled
		end,
		falconer = function()
			local canRecall = true
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 32 or 100,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value],
					WallCheck = Legit.Enabled
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if plr.RootPart:FindFirstChild("BillboardGui") then  task.wait(0.1); continue end
					if bedwars.AbilityController:canUseAbility('SEND_FALCON') then
						canRecall = true
						bedwars.AbilityController:useAbility('SEND_FALCON',newproxy(true),{
							target = plr.RootPart.Position
						})
					end
				else
					if bedwars.AbilityController:canUseAbility('RECALL_FALCON') and canRecall then
						canRecall = false
						bedwars.AbilityController:useAbility('RECALL_FALCON')
					end													
		        end
				
				task.wait(.233)
		    until not AutoKit.Enabled
		end,
		styx = function()
			local r = 0
			if Legit.Enabled then
				r = 6
			else
				r = 12
			end
			local uuid  = ""
			bedwars.Client:Get("StyxOpenExitPortalFromServer"):Connect(function(v1)
				uuid = v1.exitPortalData.connectedEntrancePortalUUID
			end)
			kitCollection(lplr.Name..":styx_entrance_portal", function(v)
				bedwars.Client:Get("UseStyxPortalFromClient"):SendToServer({
					entrancePortalData = {
						proximityPrompt = v:WaitForChild('ProximityPrompt'),
						uuid = uuid,
						blockPosition = bedwars.BlockController:getBlockPosition(v.Position),
						whirpoolSpinHeartbeatConnection = (nil --[[ RBXScriptConnection | IsConnected: true ]]),
						blockUUID = v:GetAttribute("BlockUUID"),
						beam = workspace:WaitForChild("StyxPortalBeam"),
						worldPosition = bedwars.BlockController:getWorldPosition(v.Position),
						teamId = entitylib.character:GetAttribute("Team")					
					}
				})
			end, r, false)
			AutoKit:Clean(workspace.ChildAdded:Connect(function(obj)
				if obj.Name == "StyxPortal" then
					local MaxStuds = Legit.Enabled and 8 or 16
					local NewDis = (obj.Pivot.Position - entitylib.character.RootPart.Position).Magnitude
					if NewDis <= MaxStuds then
						local args = {uuid}
						replicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("StyxTryOpenExitPortalFromClient"):InvokeServer(unpack(args))
					end
				end
			end))
		end,
		elektra = function()
			math.randomseed(os.time() * 9e6)
			local rng = 0
			rng = Legit.Enabled and 42 or 12
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 5 or 10,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('ELECTRIC_DASH') and math.random(0,100) >= rng then
						bedwars.AbilityController:useAbility('ELECTRIC_DASH')
					end																		
		        end
				
				task.wait(.833)
		    until not AutoKit.Enabled
		end,
		taliyah = function()
			local r = 0
			if Legit.Enabled then
				r = 10
			else
				r = 12
			end
			kitCollection('HarvestableCrop', function(v)
				if bedwars.Client:Get('CropHarvest'):CallServer({position = bedwars.BlockController:getBlockPosition(v.Position)}) then
					if Legit.Enabled then
						bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
						bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
						bedwars.SoundManager:playSound(bedwars.SoundList.CHICKEN_ATTACK_1)
					end
				end
			end, r, false)
		end,
		black_market_trader = function()
			local r = 0
			if Legit.Enabled then
				r = 12
			else
				r = 16
			end
			kitCollection('shadow_coin', function(v)
			    bedwars.Client:Get("CollectCollectableEntity"):SendToServer({id = v:GetAttribute("Id"),collectableName = 'shadow_coin'})
			end, r, false)
		end,
		oasis = function()
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 8 or 18,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('oasis_swap_staff') then
						local str = "oasis"
						local fullstr = ""
						for i, v in replicatedStorage.Inventories[lplr.Name]:GetChildren() do
							if string.find(v.Name, str) then
								fullstr = v.Name
							end
						end
						local slot = getObjSlot(fullstr)
						local ogslot = GetOriginalSlot()
						hotbarSwitch(slot)
						bedwars.AbilityController:useAbility('oasis_swap_staff')
						task.wait(0.225)
						hotbarSwitch(ogslot)
					end																		
		        end

				if lplr.Character:GetAttribute('Health') <= Legit.Enabled and 32 or 50 then
					if bedwars.AbilityController:canUseAbility('oasis_heal_veil') then
						bedwars.AbilityController:useAbility('oasis_heal_veil')
					end
				end
				
				task.wait(.223)
		    until not AutoKit.Enabled
		end,
		rebellion_leader = function()
			local last = 0
			local abilityCooldown = 0.02
		
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 15 or 25,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				local t = 0
				t = Legit.Enabled and 45 or 65
				if lplr.Character:GetAttribute('Health') <= t then
					if bedwars.AbilityController:canUseAbility('rebellion_shield') then
						bedwars.AbilityController:useAbility('rebellion_shield')
					end
				end
					if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
						local new = tick() + 1
						if (new - last) <= abilityCooldown then
							task.wait(0.01) 
							continue
						end	
						task.wait(0.0095)
						last = new
						if bedwars.AbilityController:canUseAbility('rebellion_aura_swap') then
							bedwars.AbilityController:useAbility('rebellion_aura_swap')
						end
													
					end

				
				task.wait(.45)
		    until not AutoKit.Enabled
		end,
		ninja = function()
			local projectileRemote = {InvokeServer = function() end}
			task.spawn(function()
				projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
			end)
			local function fireUmeko(pos, spot, item,slot,charm)
				if item then		
					local originalSlot = store.inventory.hotbarSlot
					hotbarSwitch(slot)
					local meta = bedwars.ProjectileMeta[charm]
					local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
					if calc then
						local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
						bedwars.ProjectileController:createLocalProjectile(meta, charm, charm, pos, nil, dir, {drawDurationSeconds = 1})
						PR:InvokeServer(item.tool, meta, pos, dir)
					end
				end
			end
			local function getCharm()
				local items = inv or store.inventory.inventory.items
				if not items then return end

				for _, item in pairs(items) do
					if item.itemType and item.itemType:lower():find("chakram") then
						return item.itemType
					end
				end
			end
			local function getCharmSlot(charmType)
				if not charmType then return end
				return getObjSlot(charmType)
			end
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end

				local charm = getCharm()
				local charmSlot = getCharmSlot(charm)

				if not charm then
					task.wait(0.1)
					continue
				end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 23 or 32,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					fireUmeko(plr.RootPart.Position,plr.RootPart.Velocity,item,charmSlot,charm)
				end

				task.wait(0.025)
			until not AutoKit.Enabled
		end,
		frosty = function()
			local function fireball(pos, spot, item)
				local projectileRemote = {InvokeServer = function() end}
				task.spawn(function()
					projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
				end)
				if item then		
					local snowball = getObjSlot('frosted_snowball')
					local originalSlot = store.inventory.hotbarSlot
					hotbarSwitch(snowball)
					local meta = bedwars.ProjectileMeta.frosted_snowball
					local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
					if calc then
						local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
						PR:InvokeServer(item.tool, meta, pos,dir,true)
					end
				end
			end
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local SnowBallTool = getItem("frosted_snowball")


				if not SnowBallTool then task.wait(0.1) continue end

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 10 or 15,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					local pos = plr.RootPart.Position
					local spot = plr.RootPart.Velocity
					if SnowBallTool then
						fireball(pos,spot,SnowBallTool)
					end
		        end
				
				task.wait(.025)
		    until not AutoKit.Enabled
		end,
		sheep_herder = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r = 16
			end
			kitCollection('sheep', function(v)
				bedwars.SheepHerderKitController.tameSheep(bedwars.SheepHerderKitController,v)
			end, r, false)
		end,
		regent = function()
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local axe = getItem("void_axe")

				if not axe then task.wait(0.1); continue end

				local Sword = getSwordSlot()
				local Axe = getObjSlot('void_axe')
				local originalSlot = store.inventory.hotbarSlot

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 15 or 25,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('void_axe_jump') then
						hotbarSwitch(Axe)
						bedwars.AbilityController:useAbility('void_axe_jump')
						task.wait(0.23)
						hotbarSwitch(originalSlot)
					end																		
		        end
				
				task.wait(.45)
		    until not AutoKit.Enabled
		end,
		jade = function()

			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local ham = getItem("jade_hammer")
				local originalSlot = store.inventory.hotbarSlot
				if not ham then task.wait(0.1) continue end

				local Sword = getSwordSlot()
				local Ham = getObjSlot('jade_hammer')

				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 13 or 18,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('jade_hammer_jump') then
						hotbarSwitch(Ham)
						bedwars.AbilityController:useAbility('jade_hammer_jump')
						task.wait(0.23)
						hotbarSwitch(originalSlot)
					end																		
		        end
				
				task.wait(.45)
		    until not AutoKit.Enabled
		end,
		yeti = function()
			local function getBedNear()
				local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
				for _, v in collectionService:GetTagged("bed") do
					if (localPosition - v.Position).Magnitude < Legit.Enabled and (15/1.95) or 15 then
						if v:GetAttribute("Team" .. (lplr:GetAttribute("Team") or -1) .. "NoBreak") then 
							return nil 
						end
						return v
					end
				end
			end
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local bed = getBedNear()

				if bed then
					if bedwars.AbilityController:canUseAbility('yeti_glacial_roar') then
						bedwars.AbilityController:useAbility('yeti_glacial_roar')
					end	
				end
				task.wait(.45)
		    until not AutoKit.Enabled
		end,
		dragon_sword = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 5 or 10,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				local plr2 = entitylib.EntityPosition({
					Range = Legit.Enabled and 15 or 30,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				if plr and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					if bedwars.AbilityController:canUseAbility('dragon_sword') then
						bedwars.AbilityController:useAbility('dragon_sword')
					end																		
		        end
			
				if plr2 and (lplr.Character:GetAttribute("Health") or 0) > 0 then
					local swords = lplr:GetAttribute('SwordCount') or 0
					if bedwars.AbilityController:canUseAbility('dragon_sword_ult') and swords >= 3 then
						bedwars.AbilityController:useAbility('dragon_sword_ult')
					end																		
		        end
		        task.wait(.45)
		    until not AutoKit.Enabled
		end,
		defender = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local handItem = lplr.Character:FindFirstChild('HandInvItem')
				local hasScanner = false
				if handItem and handItem.Value then
					local itemType = handItem.Value.Name
					hasScanner = itemType:find('defense_scanner')
				end
				
				if not hasScanner then
					task.wait(0.1)
					continue
				end

				for i, v in workspace:GetChildren() do
					if v:IsA("BasePart") then
						if v.Name == "DefenderSchematicBlock" then
							v.Transparency = 0.85
							v.Grid.Transparency = 1
							local BP = bedwars.BlockController:getBlockPosition(v.Position)
							bedwars.Client:Get("DefenderRequestPlaceBlock"):CallServer({["blockPos"] = BP})
							pcall(function()
								local sounds = {
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_04,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_03,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_02,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_01
								}

								for i = 4, 1, -1 do
									bedwars.SoundManager:playSound(sounds[i], {
										position = BP,
										playbackSpeedMultiplier = 0.8
									})
									task.wait(0.082)
								end
							end)
							
							task.wait(Legit.Enabled and math.random(1,2) - math.random() or (0.5 - math.random()))
						end
					end
				end

				AutoKit:Clean(workspace.ChildAdded:Connect(function(v)
					if v:IsA("BasePart") then
						if v.Name == "DefenderSchematicBlock" then
							v.Transparency = 0.85
							v.Grid.Transparency = 1
							local BP = bedwars.BlockController:getBlockPosition(v.Position)
							bedwars.Client:Get("DefenderRequestPlaceBlock"):SendToServer({["blockPos"] = BP})
							pcall(function()
								local sounds = {
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_04,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_03,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_02,
									bedwars.SoundList.DEFENDER_UPGRADE_DEFENSE_01
								}

								for i = 4, 1, -1 do
									bedwars.SoundManager:playSound(sounds[i], {
										position = BP,
										playbackSpeedMultiplier = 0.8
									})
									task.wait(0.082)
								end
							end)
							
							task.wait(math.random(1,2) - math.random())
						end
					end
				end))
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		shielder = function()
			local Distance = 0
			local Rate = 0
			if Legit.Enabled then
				Distance = 32 / 2
				Rate = 1/60
			else
				Distance = 32
				Rate = 1/360
			end
			AutoKit:Clean(workspace.DescendantAdded:Connect(function(arrow)
				if not AutoKit.Enabled then return end
				if (arrow.Name == "crossbow_arrow" or arrow.Name == "arrow" or arrow.Name == "headhunter_arrow") and arrow:IsA("Model") then
					if arrow:GetAttribute("ProjectileShooter") == lplr.UserId then return end
					local root = arrow:FindFirstChildWhichIsA("BasePart")
					if not root then return end
					local NewDis = (lplr.Character.HumanoidRootPart.Position - root.Position).Magnitude
					while root and root.Parent do
						NewDis = (lplr.Character.HumanoidRootPart.Position - root.Position).Magnitude
						if NewDis <= Distance + (2 + math.random(2,5) - math.random()) then
							bedwars.InfernalShieldController.raiseShield(bedwars.InfernalShieldController)
							task.wait(Rate + math.random(1,2) - math.random())
							bedwars.InfernalShieldController.lowerShield(bedwars.InfernalShieldController)
						end
						task.wait(0.05)
					end
				end
			end))
		end,
        alchemist = function()
			local r= 0
						if Legit.Enabled then
				r = 8
			else
				r = 16
			end
			kitCollection('alchemist_ingedients', function(v)
			    bedwars.Client:Get("CollectCollectableEntity"):SendToServer({id = v:GetAttribute("Id"),collectableName = v.Name})
			end, r, false)
        end,
        midnight = function()
			local old = nil
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local root = entitylib.character.RootPart
				if not root then continue end
				
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and (18/(1.995 + math.random())) or 18,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
					if bedwars.AbilityController:canUseAbility('midnight') then
						bedwars.AbilityController:useAbility('midnight')
						local T = Legit.Enabled and 4.5 or 6.45
                        Speed:Toggle(true)
                        task.wait(T)
                        Speed:Toggle(false)
						task.wait(11)
					end																		
		        end
		
		        task.wait(.45)
		    until not AutoKit.Enabled
        end,
		sorcerer = function()
			local r = 0
						if Legit.Enabled then
				r = 12
			else
				r = 16
			end
			kitCollection('alchemy_crystal', function(v)
			    bedwars.Client:Get("CollectCollectableEntity"):SendToServer({id = v:GetAttribute("Id"),collectableName = v.Name})
			end, r, false)
		end,
		berserker = function()
			local mapCFrames = workspace:FindFirstChild("MapCFrames")
			local teamid = lplr.Character:GetAttribute("Team") or 1
		
			if mapCFrames then
					for _, obj in pairs(mapCFrames:GetChildren()) do
						if obj:IsA("CFrameValue") and string.match(obj.Name, "_bed") then
							if not string.match(obj.Name, teamid .. "_bed") then
								local part = Instance.new("Part")
								part.Transparency = 1
								part.CanCollide = false
								part.Anchored = true
								part.Size = Legit.Enabled and Vector3.new(48, 48, 48) or Vector3.new(72, 72, 72)
								part.CFrame = obj.Value
								part.Parent = workspace
								part.Name = "AutoKitRagnarPart"
								bedwars.QueryUtil:setQueryIgnored(part, true)
								part.Touched:Connect(function(v)
									if v.Parent.Name == lplr.Name then
										if bedwars.AbilityController:canUseAbility('berserker_rage') then
											bedwars.AbilityController:useAbility('berserker_rage')
											if not Legit.Enabled and not FastBreak.Enabled then
												bedwars.BlockBreakController.blockBreaker:setCooldown(0.185)
												task.wait(5)
												bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
											end
										end																																
									end
								end)
							end
						end
					end
			end

			AutoKit:Clean(function()
				for i,v in workspace:GetChildren() do
					if v:IsA("BasePart") and v.Name == "AutoKitRagnarPart" then
						v:Destory()
					end
				end
			end)
		
		end,																																																								
		glacial_skater = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				if Legit.Enabled then
					bedwars.Client:Get("MomentumUpdate"):SendToServer({['momentumValue'] = 100})
				else
					bedwars.Client:Get("MomentumUpdate"):SendToServer({['momentumValue'] = 9e9})
				end
		        task.wait(0.1)
		    until not AutoKit.Enabled
		end,
		cactus = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local root = entitylib.character.RootPart
				if not root then continue end
				
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and (60/1.54) or 80,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				if plr then
					if bedwars.AbilityController:canUseAbility('cactus_fire') then
						bedwars.AbilityController:useAbility('cactus_fire')
					end																		
		        end
		
		        task.wait(1)
		    until not AutoKit.Enabled
		end,
		card = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local root = entitylib.character.RootPart
				if not root then continue end
				
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and (20/3.2) or 20,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				if plr then
		          bedwars.Client:Get("AttemptCardThrow"):SendToServer({
		                ["targetEntityInstance"] = plr.Character
		            })
		        end
		
		        task.wait(0.5)
		    until not AutoKit.Enabled
		end,																																																					
		void_hunter = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and (20/2.8) or 20,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
				
				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
		        	bedwars.Client:Get("VoidHunter_MarkAbilityRequest"):SendToServer({
		            	["originPosition"] = lplr.Character.PrimaryPart.Position,
		            	["direction"] = workspace.CurrentCamera.CFrame.LookVector
		        	})
		        	Speed:Toggle(true)
					task.wait(3)
					Speed:Toggle(false)
			end
			task.wait(0.5)
			until not AutoKit.Enabled	
		end,																																																									
		skeleton = function()
		    repeat
			    if not entitylib.isAlive then task.wait(0.1); continue end
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 5.235 or 10,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})
			
				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
						if bedwars.AbilityController:canUseAbility('skeleton_ability') then
							bedwars.AbilityController:useAbility('skeleton_ability')
						end																																
					Speed:Toggle(true)
					task.wait(3)
					Speed:Toggle(false)
				end
				task.wait(0.5)
	    	until not AutoKit.Enabled		
		end,
		drill = function()
			AutoKit:Clean(workspace.DescendantAdded:Connect(function(obj)
				if not AutoKit.Enabled then return end
				if obj.Name == "Drill" then
					table.insert(drills, obj)
				end
			end))
			repeat
				if not entitylib.isAlive then task.wait(0.3); continue end
				local root = entitylib.character.RootPart
				local drills = {}
				
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj.Name == "Drill" then
						table.insert(drills, obj)
					end
				end
			
				if #drills == 0 then
					task.wait(0.2)
					continue
				end
			
				for _, drillObj in ipairs(drills) do
					if Legit.Enabled then
						if drillObj:FindFirstChild("RootPart") then
							local drillRoot = drillObj.RootPart
							if (drillRoot.Position - root.Position).Magnitude <= 15 then
								bedwars.Client:Get('ExtractFromDrill'):SendToServer({
									drill = drillObj
								})
							end
						end
					else
						bedwars.Client:Get('ExtractFromDrill'):SendToServer({
							drill = drillObj
						})
					end
				end
		
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		airbender = function()
			repeat
				if not entitylib.isAlive then task.wait(0.1); continue end
				local root = entitylib.character.RootPart
				if not root then continue end
			
					local plr = entitylib.EntityPosition({
						Range = Legit.Enabled and 14 and 25,
						Part = "RootPart",
						Players = true,
						Sort = sortmethods[Sorts.Value]
					})
			
					local plr2 = entitylib.EntityPosition({
						Range = Legit.Enabled and 23 and 31,
						Part = "RootPart",
						Players = true,
						Sort = sortmethods[Sorts.Value]
					})
			
					if plr and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
						if bedwars.AbilityController:canUseAbility('airbender_tornado') then
							bedwars.AbilityController:useAbility('airbender_tornado')
						end
					end
			
					if plr2 and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
						local direction = (plr2.RootPart.Position - root.Position).Unit
						if bedwars.AbilityController:canUseAbility('airbender_moving_tornado') then
							bedwars.AbilityController:useAbility('airbender_moving_tornado')
						end
					end
				task.wait(0.5)

				until not AutoKit.Enabled
		end,
		nazar = function()
			local empoweredMode = false
			local lastHitTime = 0
			local hitTimeout = 3
			local LowHealthThreshold = 0
			LowHealthThreshold = Legit.Enabled and 50 or 75
			AutoKit:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
				if not entitylib.isAlive then return end
					
				local attacker = playersService:GetPlayerFromCharacter(damageTable.fromEntity)
				local victim = playersService:GetPlayerFromCharacter(damageTable.entityInstance)
					
				if attacker == lplr and victim and victim ~= lplr then
					lastHitTime = workspace:GetServerTimeNow()
					NazarController:request('enabled')
				end
			end))
				
			AutoKit:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
				if not entitylib.isAlive then return end
					
				local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
				local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
					
				if killer == lplr and killed and killed ~= lplr then
					NazarController:request('disabled')
				end
			end))
				
			repeat
				if entitylib.isAlive then
					local currentTime = workspace:GetServerTimeNow()
						
					if empoweredMode and (currentTime - lastHitTime) >= hitTimeout then
						NazarController:request('disabled')
					end
				else
					if empoweredMode then
						NazarController:request('disabled')
					end
				end

				if lplr.Character:GetAttribute('Health') <= LowHealthThreshold then
					NazarController:request('heal')
				end

				task.wait(0.1)
			until not AutoKit.Enabled
				
			AutoKit:Clean(function()
				if empoweredMode then
					NazarController:request('disabled')
					NazarController:request('heal')
				end
			end)
		end,
		void_knight = function()
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end
					
				local currentTier = lplr:GetAttribute('VoidKnightTier') or 0
				local currentProgress = lplr:GetAttribute('VoidKnightProgress') or 0
				local currentKills = lplr:GetAttribute('VoidKnightKills') or 0
				local haltedProgress = lplr:GetAttribute('VoidKnightHaltedProgress')
					
				if haltedProgress then
					task.wait(0.5)
					continue
				end
					
				if currentTier < 4 then
					if currentTier < 3 then
						local ironAmount = getItem('iron')
						ironAmount = ironAmount and ironAmount.amount or 0
							
						if ironAmount >= 10 and bedwars.AbilityController:canUseAbility('void_knight_consume_iron') then
							bedwars.AbilityController:useAbility('void_knight_consume_iron')
							task.wait(0.5)
						end
					end
						
					if currentTier >= 2 and currentTier < 4 then
						local emeraldAmount = getItem('emerald')
						emeraldAmount = emeraldAmount and emeraldAmount.amount or 0
							
						if emeraldAmount >= 1 and bedwars.AbilityController:canUseAbility('void_knight_consume_emerald') then
							bedwars.AbilityController:useAbility('void_knight_consume_emerald')
							task.wait(0.5)
						end
					end
				end
					
				if currentTier >= 4 and bedwars.AbilityController:canUseAbility('void_knight_ascend') then
					local shouldAscend = false
						
					local health = lplr.Character:GetAttribute('Health') or 100
					local maxHealth = lplr.Character:GetAttribute('MaxHealth') or 100
					if health < (maxHealth * 0.5) then
						shouldAscend = true
					end
						
					if not shouldAscend then
						local plr = entitylib.EntityPosition({
							Range = Legit.Enabled and 30 or 50,
							Part = 'RootPart',
							Players = true,
							Sort = sortmethods[Sorts.Value]
						})
						if plr then
							shouldAscend = true
						end
					end
						
					if shouldAscend then
						bedwars.AbilityController:useAbility('void_knight_ascend')
						task.wait(16)
					end
				end
					
					task.wait(0.5)
				until not AutoKit.Enabled
		end,
		hatter = function()
			local Delay = 0
			Delay = Legit.Enabled and 0.8 or 0.05
			repeat
				for _, text in pairs(lplr.PlayerGui.NotificationApp:GetDescendants()) do
					if text:IsA("TextLabel") then
						local txt = string.lower(text.Text)
						if string.find(txt, "teleport") then
							if bedwars.AbilityController:canUseAbility('HATTER_TELEPORT') then
								task.wait(Delay)
								bedwars.AbilityController:useAbility('HATTER_TELEPORT')
							end																																		
						end
					end
				end
				task.wait(0.34)
			until not AutoKit.Enabled
		end,
		mage = function()
			local r = 0
			if Legit.Enabled then
				r = 10
			else
				r = math.huge or (2^1024-1)
			end
			kitCollection('ElementTome', function(v)
				if Legit.Enabled then bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.PUNCH); bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM) end
				bedwars.Client:Get("LearnElementTome"):SendToServer({secret = v:GetAttribute('TomeSecret')})
				v:Destroy()
				task.wait(0.5)
			end, r, false)
		end,
		pyro = function()
			repeat																																																										
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 10 or 25,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute("Health") or 0) > 0) then
					bedwars.Client:Get("UseFlamethrower"):SendToServer()
					Speed:Toggle(true)
					task.wait(1.85)
					Speed:Toggle(false)
				end
				task.wait(0.1)
			until not AutoKit.Enabled																																																						
		end,
		frost_hammer_kit = function()
			repeat																																																		
				local frost, slot = getItem('frost_crystal')
				local UFH = game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.UpgradeFrostyHammer

				local attributes = { "shield", "strength", "speed" }
				local slots = { [0] = 2, [1] = 5, [2] = 12 }

				for _, attr in ipairs(attributes) do
					local value = lplr:GetAttribute(attr)
					if slots[value] == slot then
						UFH:InvokeServer(attr)
						task.wait(.23)
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled																																																						
		end,
		battery = function()
			repeat
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for i, v in bedwars.BatteryEffectsController.liveBatteries do
						if (v.position - localPosition).Magnitude <= Legit.Enabled and 4 or 10 then
							local BatteryInfo = bedwars.BatteryEffectsController:getBatteryInfo(i)
							if not BatteryInfo or BatteryInfo.activateTime >= workspace:GetServerTimeNow() or BatteryInfo.consumeTime + 1 >= workspace:GetServerTimeNow() then continue end
							BatteryInfo.consumeTime = workspace:GetServerTimeNow()
							bedwars.Client:Get(remotes.ConsumeBattery):SendToServer({batteryId = i})
						end
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		beekeeper = function()
			local r =  0
			if Legit.Enabled then
				r = 8
			else
				r = 16
			end
			kitCollection('bee', function(v)
				if Legit.Enabled  then
					if store.hand.tool.Name == "bee_net" or store.hand.tool.Name == 'bee-net' then
						task.wait(0.05)
						bedwars.Client:Get(remotes.BeePickup):SendToServer({beeId = v:GetAttribute('BeeId')})
					end
				else
					bedwars.Client:Get(remotes.BeePickup):SendToServer({beeId = v:GetAttribute('BeeId')})
				end
				
			end,r, false)
		end,
		bigman = function()
			local r = 0
						if Legit.Enabled then
				r = 8
			else
				r = 12
			end
			local kitskin = bedwars.KitController:getKitSkin(lplr.Character)
			local sond = bedwars.SoundList.CROP_HARVEST

			kitCollection('treeOrb', function(v)
				if Legit.Enabled then
					if bedwars.Client:Get('ConsumeTreeOrb'):CallServer({treeOrbSecret = v:GetAttribute('TreeOrbSecret')}) then
						bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.PUNCH)
						bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
						if kitskin and entitylib.isAlive then
							if kitskin == bedwars.BedwarsKitSkin.BIGMAN_CHRISTMAS then
								local tbl = {
									bedwars.SoundList.CHRISTMAS_ELDERTREE_PICKUP,
									bedwars.SoundList.CHRISTMAS_ELDERTREE_PICKUP_2,
									bedwars.SoundList.CHRISTMAS_ELDERTREE_PICKUP_3,
									bedwars.SoundList.CHRISTMAS_ELDERTREE_PICKUP_4,
									bedwars.SoundList.CHRISTMAS_ELDERTREE_PICKUP_5,
								}
								local rng = math.random(1,#tbl)
								local index = tbl[rng]
								sond = index
							elseif kitskin == bedwars.BedwarsKitSkin.BIGMAN_WITHERED then
								sond = bedwars.SoundList.WITHERED_ELDERTREE_PICKUP
							elseif kitskin == bedwars.BedwarsKitSkin.BIGMAN_REEF then
								sond = bedwars.SoundList.ELDERREEF_PICKUP
							else
								sond = bedwars.SoundList.CROP_HARVEST
							end
						end
						bedwars.SoundManager:playSound(sond)
						v:Destroy()
					end
				else
					if bedwars.Client:Get('ConsumeTreeOrb'):CallServer({treeOrbSecret = v:GetAttribute('TreeOrbSecret')}) then
						v:Destroy()
					end
				end
			end, r, false)
		end,
		block_kicker = function()
			local old = bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition
			bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = function(...)
				local origin, dir = select(2, ...)
				local plr = entitylib.EntityMouse({
					Part = 'RootPart',
					Range = Legit.Enabled and 50 or 250,
					Origin = origin,
					Players = true,
					Wallcheck = Legit.Enabled
				})
		
				if plr then
					local calc = prediction.SolveTrajectory(origin, 100, 20, plr.RootPart.Position, plr.RootPart.Velocity, workspace.Gravity, plr.HipHeight, plr.Jumping and 42.6 or nil)
		
					if calc then
						for i, v in debug.getstack(2) do
							if v == dir then
								debug.setstack(2, i, CFrame.lookAt(origin, calc).LookVector)
							end
						end
					end
				end
		
				return old(...)
			end
		
			AutoKit:Clean(function()
				bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = old
			end)
		end,
		cat = function()
			local old = bedwars.CatController.leap
			bedwars.CatController.leap = function(...)
				vapeEvents.CatPounce:Fire()
				return old(...)
			end
		
			AutoKit:Clean(function()
				bedwars.CatController.leap = old
			end)
		end,
		davey = function()
			local old = bedwars.CannonHandController.launchSelf
			bedwars.CannonHandController.launchSelf = function(...)
				local res = {old(...)}
				local self, block = ...
		
				if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
					if Legit.Enabled then
						local str = "pickaxe"
						local fullstr = ""
						for i, v in replicatedStorage.Inventories[lplr.Name]:GetChildren() do
							if string.find(v.Name, str) then
								fullstr = v.Name
							end
						end
						local pickaxe = getObjSlot(fullstr)
						local OgSlot = GetOriginalSlot()
						hotbarSwitch(pickaxe)
						task.spawn(bedwars.breakBlock, block, false, nil, true)
						task.spawn(bedwars.breakBlock, block, false, nil, true)
						task.wait(0.15)
						hotbarSwitch(OgSlot)
					else
						task.spawn(bedwars.breakBlock, block, false, nil, true)
						task.spawn(bedwars.breakBlock, block, false, nil, true)
					end
				end
		
				return unpack(res)
			end
		
			AutoKit:Clean(function()
				bedwars.CannonHandController.launchSelf = old
			end)
		end,
		dragon_slayer = function()
			local r = 0
			if Legit.Enabled then
				r = 18 / 1.5
			else
				r = 18
			end
			kitCollection('KaliyahPunchInteraction', function(v)
				if Legit.Enabled then
					bedwars.DragonSlayerController:deleteEmblem(v)
					bedwars.DragonSlayerController:playPunchAnimation(Vector3.zero)
					bedwars.Client:Get('RequestDragonPunch'):SendToServer({
						target = v
					})
				else
					bedwars.Client:Get('RequestDragonPunch'):SendToServer({
						target = v
					})
				end
			end, r, true)
		end,
		farmer_cletus = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r = 10
			end
			kitCollection('HarvestableCrop', function(v)
				bedwars.Client:Get('CropHarvest'):CallServer({position = bedwars.BlockController:getBlockPosition(v.Position)})
				if Legit.Enabled then
					bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
					bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
					if lplr.Character:GetAttribute('CropKitSkin') == bedwars.BedwarsKitSkin.FARMER_CLETUS_VALENTINE then
						bedwars.SoundManager:playSound(bedwars.SoundList.VALETINE_CROP_HARVEST)
					else
						bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
					end
				end
			end, r, false)
		end,
		fisherman = function()
			local old = bedwars.FishingMinigameController.startMinigame
			bedwars.FishingMinigameController.startMinigame = function(_, _, result)
				if Legit.Enabled then
					local pull = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.FISHING_ROD_PULLING)
					local Duration = (10 / 2.25 + math.random())
					task.wait(Duration)
					if pull then
						pull:Stop()
						pull = nil
					end									
					local success = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.FISHING_ROD_CATCH_SUCCESS)
					task.wait(0.025)
					results({win = true})
					if success then
						success:Stop()
						success = nil
					end
				else
					results({win = true})
				end
			end
		
			AutoKit:Clean(function()
				bedwars.FishingMinigameController.startMinigame = old
			end)
		end,
		gingerbread_man = function()
			local old = bedwars.LaunchPadController.attemptLaunch
			bedwars.LaunchPadController.attemptLaunch = function(...)
				local res = {old(...)}
				local self, block = ...
		
				if (workspace:GetServerTimeNow() - self.lastLaunch) < 0.4 then
					if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
						if Legit.Enabled then
							local pickaxe = getPickaxeSlot()
							if hotbarSwitch(pickaxe) then
								task.spawn(bedwars.breakBlock, block, false, nil, true)
							end
						else
							task.spawn(bedwars.breakBlock, block, false, nil, true)
						end
					end
				end
		
				return unpack(res)
			end
		
			AutoKit:Clean(function()
				bedwars.LaunchPadController.attemptLaunch = old
			end)
		end,
		hannah = function()
			local r = 0
					if Legit.Enabled then
				r = 15
			else
				r = 30
			end
			kitCollection('HannahExecuteInteraction', function(v)
				local billboard = bedwars.Client:Get(remotes.HannahKill):CallServer({
					user = lplr,
					victimEntity = v
				}) and v:FindFirstChild('Hannah Execution Icon')
		
				if billboard then
					billboard:Destroy()
				end
			end, r, true)
		end,
		jailor = function()
			local r = 0
			if Legit.Enabled then
				r = 9
			else
				r = 20
			end
			kitCollection('jailor_soul', function(v)
				bedwars.JailorController:collectEntity(lplr, v, 'JailorSoul')
			end, r, false)
		end,
		grim_reaper = function()
			local r = 0
			if Legit.Enabled then
				r = 35
			else
				r = 120
			end
			kitCollection(bedwars.GrimReaperController.soulsByPosition, function(v)
				if entitylib.isAlive and lplr.Character:GetAttribute('Health') <= (lplr.Character:GetAttribute('MaxHealth') / 4) and (not lplr.Character:GetAttribute('GrimReaperChannel')) then
					bedwars.Client:Get(remotes.ConsumeSoul):CallServer({
						secret = v:GetAttribute('GrimReaperSoulSecret')
					})
				end
			end,  r, false)
		end,
		melody = function()
				local r = 0
			if Legit.Enabled then
				r = 15
			else
				r = 45
			end
			repeat

				local mag, hp, ent = r, math.huge
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for _, v in entitylib.List do
						if v.Player and v.Player:GetAttribute('Team') == lplr:GetAttribute('Team') then
							local newmag = (localPosition - v.RootPart.Position).Magnitude
							if newmag <= mag and v.Health < hp and v.Health < v.MaxHealth then
								mag, hp, ent = newmag, v.Health, v
							end
						end
					end
				end
		
				if ent and getItem('guitar') then
					bedwars.Client:Get(remotes.GuitarHeal):SendToServer({
						healTarget = ent.Character
					})
				end
		
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		metal_detector = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r = 10
			end
			kitCollection('hidden-metal', function(v)
				if Legit.Enabled and store.hand.tool.Name == "metal_detector" then
					task.wait(1.5)
					bedwars.GameAnimationUtil:playAnimation(lplr,bedwars.AnimationType.SHOVEL_DIG)
					bedwars.SoundManager:playSound(bedwars.SoundList.SNAP_TRAP_CONSUME_MARK)
					bedwars.Client:Get('CollectCollectableEntity'):SendToServer({
						id = v:GetAttribute('Id')
					})
				else
					bedwars.Client:Get('CollectCollectableEntity'):SendToServer({
						id = v:GetAttribute('Id')
					})
				end
			end, r, false)
		end,
		miner = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r = 16
			end
			kitCollection('petrified-player', function(v)
				bedwars.Client:Get(remotes.MinerDig):SendToServer({
					petrifyId = v:GetAttribute('PetrifyId')
				})
			end, r, true)
		end,
		pinata = function()
			local r = 0
			if Legit.Enabled then
				r = 8
			else
				r =18
			end
			kitCollection(lplr.Name..':pinata', function(v)
				if getItem('candy') then
					bedwars.Client:Get('DepositCoins'):CallServer(v)
				end
			end,  r, true)
		end,
		spirit_assassin = function()
			local r = Legit.Enabled and 35 or 120
					if Legit.Enabled then
				r = 35
			else
				r = 120
			end
			kitCollection('EvelynnSoul', function(v)
				bedwars.SpiritAssassinController:useSpirit(lplr, v)
			end, r , true)
		end,
		star_collector = function()
			local r =  Legit.Enabled and 10 or 20
			if Legit.Enabled then
				r = 10
			else
				r = 20
			end
			kitCollection('stars', function(v)
				bedwars.StarCollectorController:collectEntity(lplr, v, v.Name)
			end, r, false)
		end,
		summoner = function()
			local lastAttackTime = 0
			local attackCooldown = 0.55
				
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end
					
				local isCasting = false
				if Legit.Enabled then
					if lplr.Character:GetAttribute("Casting") or 
					lplr.Character:GetAttribute("UsingAbility") or
					lplr.Character:GetAttribute("SummonerCasting") then
						isCasting = true
					end
						
					local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						isCasting = true
					end
				end
					
				if Legit.Enabled and isCasting then
					task.wait(0.1)
					continue
				end
					
				if (workspace:GetServerTimeNow() - lastAttackTime) < attackCooldown then
					task.wait(0.1)
					continue
				end
					
				local handItem = lplr.Character:FindFirstChild('HandInvItem')
				local hasClaw = false
				if handItem and handItem.Value then
					local itemType = handItem.Value.Name
					hasClaw = itemType:find('summoner_claw')
				end
					
				if not hasClaw then
					task.wait(0.1)
					continue
				end
					
				local range = Legit.Enabled and 23 or 35
				local plr = entitylib.EntityPosition({
					Range = range, 
					Part = 'RootPart',
					Players = true,
					NPCs = true,
					Sort = sortmethods[Sorts.Value]
				})

				if plr then
					local distance = (entitylib.character.RootPart.Position - plr.RootPart.Position).Magnitude
					if Legit.Enabled and distance > 23 then
						plr = nil 
					end
				end

				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute('Health') or 0) > 0) then
					local localPosition = entitylib.character.RootPart.Position
					local shootDir = CFrame.lookAt(localPosition, plr.RootPart.Position).LookVector
					localPosition += shootDir * math.max((localPosition - plr.RootPart.Position).Magnitude - 16, 0)

					lastAttackTime = workspace:GetServerTimeNow()

					pcall(function()
						bedwars.AnimationUtil:playAnimation(lplr, bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CHARACTER_SWIPE), {
							looped = false
						})
					end)

					task.spawn(function()
						pcall(function()
							local clawModel = replicatedStorage.Assets.Misc.Kaida.Summoner_DragonClaw:Clone()
									
							clawModel.Parent = workspace
								
							if gameCamera.CFrame.Position and (gameCamera.CFrame.Position - entitylib.character.RootPart.Position).Magnitude < 1 then
								for _, part in clawModel:GetDescendants() do
									if part:IsA('MeshPart') then
										part.Transparency = 0.6
									end
								end
							end
								
							local rootPart = entitylib.character.RootPart
							local Unit = Vector3.new(shootDir.X, 0, shootDir.Z).Unit
							local startPos = rootPart.Position + Unit:Cross(Vector3.new(0, 1, 0)).Unit * -1 * 5 + Unit * 6
							local direction = (startPos + shootDir * 13 - startPos).Unit
							local cframe = CFrame.new(startPos, startPos + direction)
							
							clawModel:PivotTo(cframe)
							clawModel.PrimaryPart.Anchored = true
							
							if clawModel:FindFirstChild('AnimationController') then
								local animator = clawModel.AnimationController:FindFirstChildOfClass('Animator')
								if animator then
									bedwars.AnimationUtil:playAnimation(animator, bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CLAW_ATTACK), {
										looped = false,
										speed = 1
									})
								end
							end
								
							pcall(function()
								local sounds = {
									bedwars.SoundList.SUMMONER_CLAW_ATTACK_1,
									bedwars.SoundList.SUMMONER_CLAW_ATTACK_2,
									bedwars.SoundList.SUMMONER_CLAW_ATTACK_3,
									bedwars.SoundList.SUMMONER_CLAW_ATTACK_4
								}
								bedwars.SoundManager:playSound(sounds[math.random(1, #sounds)], {
									position = rootPart.Position
								})
							end)
								
							task.wait(0.55)
							clawModel:Destroy()
						end)
					end)

					bedwars.Client:Get(remotes.SummonerClawAttack):SendToServer({
						position = localPosition,
						direction = shootDir,
						clientTime = workspace:GetServerTimeNow()
					})
				end

				task.wait(0.1)
				until not AutoKit.Enabled
		end,
		void_dragon = function()
			local oldflap = bedwars.VoidDragonController.flapWings
			local flapped
		
			bedwars.VoidDragonController.flapWings = function(self)
				if not flapped and bedwars.Client:Get(remotes.DragonFly):CallServer() then
					local modifier = bedwars.SprintController:getMovementStatusModifier():addModifier({
						blockSprint = true,
						constantSpeedMultiplier = 2
					})
					self.SpeedMaid:GiveTask(modifier)
					self.SpeedMaid:GiveTask(function()
						flapped = false
					end)
					flapped = true
				end
			end
		
			AutoKit:Clean(function()
				bedwars.VoidDragonController.flapWings = oldflap
			end)
		
			repeat
				if bedwars.VoidDragonController.inDragonForm then
					local plr = entitylib.EntityPosition({
						Range =  Legit.Enabled and 15 or 30,
						Part = 'RootPart',
						Players = true
					})
		
					if plr then
						bedwars.Client:Get(remotes.DragonBreath):SendToServer({
							player = lplr,
							targetPoint = plr.RootPart.Position
						})
					end
				end
				task.wait(0.1)
				until not AutoKit.Enabled
		end,
		warlock = function()
				local lastTarget
				repeat
					if store.hand.tool and store.hand.tool.Name == 'warlock_staff' then
						local plr = entitylib.EntityPosition({
							Range =  Legit.Enabled and (30/2.245) or 30,
							Part = 'RootPart',
							Players = true,
							NPCs = true
						})
		
						if plr and plr.Character ~= lastTarget then
							if not bedwars.Client:Get(remotes.WarlockTarget):CallServer({
								target = plr.Character
							}) then
								plr = nil
							end
						end
		
						lastTarget = plr and plr.Character
					else
						lastTarget = nil
					end
		
					task.wait(0.1)
				until not AutoKit.Enabled
		end,
		spider_queen = function()
				local isAiming = false
				local aimingTarget = nil
				
				repeat
					if entitylib.isAlive and bedwars.AbilityController then
						local plr = entitylib.EntityPosition({
							Range = not Legit.Enabled and 80 or 50,
							Part = 'RootPart',
							Players = true,
							Sort = sortmethods[Sorts.Value]
						})
						
						if plr and not isAiming and bedwars.AbilityController:canUseAbility('spider_queen_web_bridge_aim') then
							bedwars.AbilityController:useAbility('spider_queen_web_bridge_aim')
							isAiming = true
							aimingTarget = plr
							task.wait(0.1)
						end
						
						if isAiming and aimingTarget and aimingTarget.RootPart then
							local localPosition = entitylib.character.RootPart.Position
							local targetPosition = aimingTarget.RootPart.Position
							
							local direction
							if Legit.Enabled then
								local currentLook = entitylib.character.RootPart.CFrame.LookVector
								local targetDir = (targetPosition - localPosition).Unit
								local smooth = 0.08
								direction = currentLook:Lerp(targetDir, smooth).Unit
							else
								direction = (targetPosition - localPosition).Unit
							end
							
							if bedwars.AbilityController:canUseAbility('spider_queen_web_bridge_fire') then
								bedwars.AbilityController:useAbility('spider_queen_web_bridge_fire', newproxy(true), {
									direction = direction
								})
								isAiming = false
								aimingTarget = nil
								task.wait(0.3)
							end
						end
						
						if isAiming and (not aimingTarget or not aimingTarget.RootPart) then
							isAiming = false
							aimingTarget = nil
						end
						
						local summonAbility = 'spider_queen_summon_spiders'
						if bedwars.AbilityController:canUseAbility(summonAbility) then
							bedwars.AbilityController:useAbility(summonAbility)
						end
					end
					
					task.wait(0.05)
				until not AutoKit.Enabled
		end,
		blood_assassin = function()
				local hitPlayers = {} 
				local delay = 0
				if Legit.Enabled then
					delay = 1.55 - (math.random() - (1/144))
				else
					delay = (math.random() - (1/144))
				end
				AutoKit:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if not entitylib.isAlive then return end
					
					local attacker = playersService:GetPlayerFromCharacter(damageTable.fromEntity)
					local victim = playersService:GetPlayerFromCharacter(damageTable.entityInstance)
				
					if attacker == lplr and victim and victim ~= lplr then
						hitPlayers[victim] = true
						
						local storeState = bedwars.Store:getState()
						local activeContract = storeState.Kit.activeContract
						local availableContracts = storeState.Kit.availableContracts or {}
						
						if not activeContract then
							for _, contract in availableContracts do
								if contract.target == victim then
									task.wait(delay)
									bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({
										contractId = contract.id
									})
									break
								end
							end
						end
					end
				end))
				
				repeat
					if entitylib.isAlive then
						local storeState = bedwars.Store:getState()
						local activeContract = storeState.Kit.activeContract
						local availableContracts = storeState.Kit.availableContracts or {}
						
						if not activeContract and #availableContracts > 0 then
							local bestContract = nil
							local highestDifficulty = 0
							
							for _, contract in availableContracts do
								if hitPlayers[contract.target] then
									if contract.difficulty > highestDifficulty then
										bestContract = contract
										highestDifficulty = contract.difficulty
									end
								end
							end
							
							if bestContract then
								task.wait(delay)
								bedwars.Client:Get('BloodAssassinSelectContract'):SendToServer({
									contractId = bestContract.id
								})
								task.wait(0.5)
							end
						end
					else
						table.clear(hitPlayers)
					end
					task.wait(1)
				until not AutoKit.Enabled
				
				table.clear(hitPlayers)
		end,
		mimic = function()
			local rng = 0
			rng = Legit.Enabled and 12 or 30
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
						continue
					end
					
					local localPosition = entitylib.character.RootPart.Position
					for _, v in entitylib.List do
						if v.Targetable and v.Character and v.Player then
							local distance = (v.RootPart.Position - localPosition).Magnitude
							if distance <= (rng + 2) then
								if collectionService:HasTag(v.Character, "MimicBLockPickPocketPlayer") then
									pcall(function()
										local success = bedwars.Client:Get("MimicBlockPickPocketPlayer"):CallServer(v.Player)
									end)
									task.wait(0.85)
								end
							end
						end
					end
					
					task.wait(0.1)
				until not AutoKit.Enabled
		end,
		gun_blade = function()
			local use = 0
			local rng = math.random(0,100)
			use = Legit.Enabled and 64 or 20
			repeat
				if bedwars.AbilityController:canUseAbility('hand_gun') then
					local plr = entitylib.EntityPosition({
						Range = Legit.Enabled and 10 or 20,
						Part = 'RootPart',
						Players = true,
						Sort = sortmethods[Sorts.Value]
					})
			
					if plr and rng >= use then
						bedwars.AbilityController:useAbility('hand_gun')
						rng = math.random(0,100)
					else
						rng = math.random(0,100)
					end
				end
			
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		wizard = function()
			math.randomseed(os.clock() * 1e6)
			local roll = math.random(0,100)
			repeat
				local ability = lplr:GetAttribute("WizardAbility")
				if not ability then
					task.wait(0.85)
					continue
				end
				local plr = entitylib.EntityPosition({
					Range = Legit.Enabled and 32 or 50,
					Part = "RootPart",
					Players = true,
					Sort = sortmethods[Sorts.Value],
					Wallcheck = Legit.Enabled
				})
				if not plr or not store.hand.tool then
					task.wait(0.85)
					continue
				end
				local itemType = store.hand.tooltype
				local targetPos = plr.RootPart.Position
				if bedwars.AbilityController:canUseAbility(ability) then
					bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
				end
				if itemType == "wizard_staff_2" or itemType == "wizard_staff_3" then
					local plr2 = entitylib.EntityPosition({
						Range = Legit.Enabled and 13 or 20,
						Part = "RootPart",
						Players = true,
						Sort = sortmethods[Sorts.Value],
						Wallcheck = Legit.Enabled
					})

					if plr2 then
						if roll <= 50 then
							if bedwars.AbilityController:canUseAbility("SHOCKWAVE") then
								bedwars.AbilityController:useAbility("SHOCKWAVE",newproxy(true),{target = Vector3.zero})
								 roll = math.random(0,100)
							end
						else
							if bedwars.AbilityController:canUseAbility(ability) then
								bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
								 roll = math.random(0,100)
							end
						end
					end
				end
				if itemType == "wizard_staff_3" then
					local plr3 = entitylib.EntityPosition({
						Range = Legit.Enabled and 12 or 18,
						Part = "RootPart",
						Players = true,
						Sort = sortmethods[Sorts.Value],
						Wallcheck = Legit.Enabled
					})
					if plr3 then
						if roll <= 40 then
							if bedwars.AbilityController:canUseAbility(ability) then
								bedwars.AbilityController:useAbility(ability,newproxy(true),{target = targetPos})
								 roll = math.random(0,100)
							end
						elseif roll <= 70 then
							if bedwars.AbilityController:canUseAbility("SHOCKWAVE") then
								bedwars.AbilityController:useAbility("SHOCKWAVE",newproxy(true),{target = Vector3.zero})
								 roll = math.random(0,100)
							end
						else
							if bedwars.AbilityController:canUseAbility("LIGHTNING_STORM") then
								bedwars.AbilityController:useAbility("LIGHTNING_STORM",newproxy(true),{target = targetPos})
								 roll = math.random(0,100)
							end
						end
					end
				end
				task.wait(0.85)
			until not AutoKit.Enabled
		end,
		spirit_summoner = function()
			repeat
				if not entitylib.isAlive then
					task.wait(0.1)
					continue
				end
				
				local hasStaff = false
				for _, item in store.inventory.inventory.items do
					if item.itemType == 'spirit_staff' then
						hasStaff = true
						break
					end
				end
				
				if hasStaff then
					local spiritCount = lplr:GetAttribute('ReadySummonedAttackSpirits') or 0
					if spiritCount < 10 then
						local hasStone = false
						for _, item in store.inventory.inventory.items do
							if item.itemType == 'summon_stone' then
								hasStone = true
								break
							end
						end
						
						if hasStone and bedwars.AbilityController:canUseAbility('summon_attack_spirit') then
							bedwars.AbilityController:useAbility('summon_attack_spirit')
							task.wait(0.5)
						end
					end
				end
				
				task.wait(0.2)
			until not AutoKit.Enabled
		end,		
		--[[wizard = function()
			repeat
				local ability = lplr:GetAttribute('WizardAbility')
				if ability and bedwars.AbilityController:canUseAbility(ability) then
					local plr = entitylib.EntityPosition({
						Range = Legit.Enabled and 32 or 50,
						Part = 'RootPart',
						Players = true,
						Sort = sortmethods[Sorts.Value]
					})
		
					if plr then
						bedwars.AbilityController:useAbility(ability, newproxy(true), {target = plr.RootPart.Position})
					end
				end
		
				task.wait(0.1)
			until not AutoKit.Enabled
		end,--]]
	}
	
	AutoKit = vape.Categories.Kits:CreateModule({
		Name = 'AutoKit',
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You don’t have access to this.", 10, "alert")
				return
			end  
			if callback then
				repeat task.wait(0.1) until store.equippedKit ~= '' and store.matchState ~= 0 or (not AutoKit.Enabled)
				if AutoKit.Enabled and AutoKitFunctions[store.equippedKit] then
					AutoKitFunctions[store.equippedKit]()
				else 
					vape:CreateNotification("AutoKit", "Your current kit is not supported yet!", 4, "warning")
					return
				end
			end
		end,
		Tooltip = 'Automatically uses kit abilities.'
	})
	Legit = AutoKit:CreateToggle({Name = 'Legit'})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end			
	Sorts = AutoKit:CreateDropdown({Name = 'Sort',List=methods})
end)

run(function()
	local DaveyAim
	local Range
	local AutoLaunch
	local AimTypes
	local AimMode

	local function getWorldFolder()
		local Map = workspace:WaitForChild("Map", math.huge)
		local Worlds = Map:WaitForChild("Worlds", math.huge)
		if not Worlds then return nil end
		return Worlds:GetChildren()[1] 
	end

	DaveyAim = vape.Categories.Utility:CreateModule({
		Name = 'DaveyAim',
		Function = function(callback)
			if not callback then return end
			DaveyAim:Toggle(false)
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
			if blocks then
				for i, v in blocks:GetChildren() do
					if v.Name == "cannon" then
						local cannon = v
						local distance = (cannon.Position - entitylib.character.RootPart.Position).Magnitude
						if distance <= Range.Value then
							if AimTypes.Value == "Mouse" then
								local position
								position = cloneref(lplr:GetMouse())
								local ray = gameCamera:ScreenPointToRay(position.X, position.Y)
								position = ray.Direction
								local delay = 0
								if AimMode.Value == "Fast" then
									delay = 0.005
								elseif AimMode.Value == "Normal" then
									delay = 0.15
								elseif AimMode.Value == "Slow" then
									delay = 0.2
								else
									delay = 0.09
								end
								task.wait(delay)
								bedwars.Client:Get('AimCannon'):SendToServer({
									cannonBlockPos = bedwars.BlockController:getBlockPosition(cannon.Position),
									lookVector = position
								})
								if AutoLaunch.Enabled then
									task.wait(math.random() * math.random() * Random.new():NextNumber() + delay)
									local call = bedwars.Client:Get('LaunchSelfFromCannon'):CallServer({cannonBlockPos = bedwars.BlockController:getBlockPosition(cannon.Position)})
									if call then
										local v30 = lplr.Character.PrimaryPart.AssemblyMass
										lplr.Character.PrimaryPart:ApplyImpulse(cannon:GetAttribute('LookVector') * (v30 == nil and 0 or v30) * 200)
										local pickaxe = getPickaxeSlot()
										if hotbarSwitch(pickaxe) or store.hand.tool.Name:lower():find("pickaxe") then
											bedwars.breakBlock(cannon)
											bedwars.breakBlock(cannon)
											if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
												humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
											end
										end
									end
								end								
							else
								local delay = 0
								if AimMode.Value == "Fast" then
									delay = 0.005
								elseif AimMode.Value == "Normal" then
									delay = 0.1
								elseif AimMode.Value == "Slow" then
									delay = 0.125
								else
									delay = 0.105
								end
								task.wait(delay)
								bedwars.Client:Get('AimCannon'):SendToServer({
									cannonBlockPos = bedwars.BlockController:getBlockPosition(cannon.Position),
									lookVector = gameCamera.CFrame.LookVector
								})
								if AutoLaunch.Enabled then
									task.wait(math.random() * math.random() * Random.new():NextNumber() + delay)
									local call = bedwars.Client:Get('LaunchSelfFromCannon'):CallServer({cannonBlockPos = bedwars.BlockController:getBlockPosition(cannon.Position)})
									if call then
										local v30 = lplr.Character.PrimaryPart.AssemblyMass
										lplr.Character.PrimaryPart:ApplyImpulse(cannon:GetAttribute('LookVector') * (v30 == nil and 0 or v30) * 200)
										local pickaxe = getPickaxeSlot()
										if hotbarSwitch(pickaxe) or store.hand.tool.Name:lower():find("pickaxe") then
											bedwars.breakBlock(cannon)
											bedwars.breakBlock(cannon)
											if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
												humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
											end
										end
									end
								end
							end
						end
					end
				end
			else
				return
			end
		end
	})
	Range = DaveyAim:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 16,
		Default = 12
	})
	if inputService.TouchEnabled then
		list = {'Camera'}
	else
		list = {'Camera','Mouse'}
	end
	AimTypes = DaveyAim:CreateDropdown({
		Name = "Aim Types",
		List = list,
		Default = 'Camera'
	})
	AimMode = DaveyAim:CreateDropdown({
		Name = "Aim Modes",
		List = {'Fast','Normal','Slow'},
		Default = 'Normal'
	})	
	AutoLaunch = DaveyAim:CreateToggle({Name='Auto Launch',Default=false})		

end)
run(function()
	local OldKA
	local Targets
	local Sort
	local SwingRange
	local AttackRange
	local ChargeTime
	local UpdateRate
	local AngleSlider
	local MaxTargets
	local Mouse
	local Swing
	local GUI
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local SophiaCheck
	local SC
	local Limit
	local LegitAura = {}
	local Particles, Boxes = {}, {}
	local anims, AnimDelay, AnimTween, armC0 = vape.Libraries.auraanims, tick()
	local AttackRemote = {FireServer = function() end}
	task.spawn(function()
		AttackRemote = bedwars.Client:Get(remotes.AttackEntity).instance
	end)

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		if GUI.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end

		local sword = Limit.Enabled and store.hand or store.tools.sword
		if not sword or not sword.tool then return false end

		local meta = bedwars.ItemMeta[sword.tool.Name]
		if Limit.Enabled then
			if store.hand.toolType ~= 'sword' or bedwars.DaoController.chargingMaid then return false end
		end

		if LegitAura.Enabled then
			if (tick() - bedwars.SwordController.lastSwing) > 0.23 then return false end
		end

		return sword, meta
	end

	OldKA = vape.Categories.Blatant:CreateModule({
		Name = 'OldKA',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = Limit.Enabled
					end)
				end

				if Animation.Enabled and not (identifyexecutor and table.find({'Argon', 'Delta'}, ({identifyexecutor()})[1])) then
					local fake = {
						Controllers = {
							ViewmodelController = {
								isVisible = function()
									return not Attacking
								end,
								playAnimation = function(...)
									if not Attacking then
										bedwars.ViewmodelController:playAnimation(select(2, ...))
									end
								end
							}
						}
					}
					debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, fake)
					debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, fake)

					task.spawn(function()
						local started = false
						repeat
							if Attacking then
								if not armC0 then
									armC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								local first = not started
								started = true

								if AnimationMode.Value == 'Random' then
									anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
								end

								for _, v in anims[AnimationMode.Value] do
									AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and (AnimationTween.Enabled and 0.001 or 0.1) or v.Time / AnimationSpeed.Value, Enum.EasingStyle.Linear), {
										C0 = armC0 * v.CFrame
									})
									AnimTween:Play()
									AnimTween.Completed:Wait()
									first = false
									if (not OldKA.Enabled) or (not Attacking) then break end
								end
							elseif started then
								started = false
								AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
									C0 = armC0
								})
								AnimTween:Play()
							end

							if not started then
								task.wait(1 / UpdateRate.Value)
							end
						until (not OldKA.Enabled) or (not Animation.Enabled)
					end)
				end
				local FROZEN_THRESHOLD = 10
				local CURRENT_LEVEL_FROZEN = 0
				local CurrentSwingTICK = 0
				repeat
					if SophiaCheck.Enabled then
						CURRENT_LEVEL_FROZEN = lplr.Character:GetAttribute("ColdStacks") or lplr.Character:GetAttribute("FrostStacks") or lplr.Character:GetAttribute("FreezeStacks") or 0
						if CURRENT_LEVEL_FROZEN >= FROZEN_THRESHOLD then
							Attacking = false
							store.KillauraTarget = nil
							task.wait(0.3)
							continue
						end
						if not entitylib.isAlive then
							CURRENT_LEVEL_FROZEN = 0
						end
					end		
					local attacked, sword, meta = {}, getAttackData()
					Attacking = false
					store.KillauraTarget = nil
					if sword then
						if SC.Enabled and entitylib.isAlive and lplr.Character:FindFirstChild("elk") then task.wait(math.max(ChargeTime.Value, 0.08)) continue end
						local plrs = entitylib.AllPosition({
							Range = SwingRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sort.Value]
						})

						if #plrs > 0 then
							switchItem(sword.tool, 0)
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

							for _, v in plrs do
								local delta = (v.RootPart.Position - selfpos)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleSlider.Value) / 2) then continue end

								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
								})
								targetinfo.Targets[v] = tick() + 1

								if not Attacking then
									Attacking = true
									store.KillauraTarget = v
									if not Swing.Enabled and AnimDelay < tick() and not LegitAura.Enabled then
										AnimDelay = tick() + (meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed or math.max(ChargeTime.Value, 0.11))
										if not LegitAura.Enabled then
											bedwars.SwordController:playSwordEffect(meta, false)
										end
										if meta.displayName:find(' Scythe') then
											bedwars.ScytheController:playLocalAnimation()
										end

										if vape.ThreadFix then
											setthreadidentity(8)
										end
									end
								end

								if delta.Magnitude > AttackRange.Value then continue end
								if delta.Magnitude < 14.4 and (tick() - swingCooldown) < math.max(ChargeTime.Value, 0.02) then continue end

								local actualRoot = v.Character.PrimaryPart
								if actualRoot then
									local dir = CFrame.lookAt(selfpos, actualRoot.Position).LookVector
									local pos = selfpos + dir * math.max(delta.Magnitude - 14.399, 0)
									swingCooldown = tick()
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									store.attackReach = (delta.Magnitude * 100) // 1 / 100
									store.attackReachUpdate = tick() + 1

									if delta.Magnitude < 14.4 and ChargeTime.Value > 0.11 then
										AnimDelay = tick()
									end

									AttackRemote:FireServer({
										weapon = sword.tool,
										chargedAttack = {chargeRatio = 0},
										entityInstance = v.Character,
										validate = {
											raycast = {
												cameraPosition = {value = pos},
												cursorDirection = {value = dir}
											},
											targetPosition = {value = actualRoot.Position},
											selfPosition = {value = pos}
										}
									})
								end
							end
						end
					end

					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end

					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end

					if Face.Enabled and attacked[1] then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.001, vec.Z))
					end

					--#attacked > 0 and #attacked * 0.02 or
					task.wait(1 / UpdateRate.Value)
				until not OldKA.Enabled
			else
				store.KillauraTarget = nil
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = true
					end)
				end
				debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, bedwars.Knit)
				debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, bedwars.Knit)
				Attacking = false
				if armC0 then
					AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
						C0 = armC0
					})
					AnimTween:Play()
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = OldKA:CreateTargets({
		Players = true,
		NPCs = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	SwingRange = OldKA:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = OldKA:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	ChargeTime = OldKA:CreateSlider({
		Name = 'Swing time',
		Min = 0,
		Max = 0.5,
		Default = 0.42,
		Decimal = 100
	})
	AngleSlider = OldKA:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	UpdateRate = OldKA:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	MaxTargets = OldKA:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 5,
		Default = 5
	})
	Sort = OldKA:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	Mouse = OldKA:CreateToggle({Name = 'Require mouse down'})
	Swing = OldKA:CreateToggle({Name = 'No Swing'})
	GUI = OldKA:CreateToggle({Name = 'GUI check'})
	OldKA:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = OldKA:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = OldKA:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	OldKA:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = OldKA.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = OldKA:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = OldKA:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = OldKA:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = OldKA:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	Face = OldKA:CreateToggle({Name = 'Face target'})
	Animation = OldKA:CreateToggle({
		Name = 'Custom Animation',
		Function = function(callback)
			AnimationMode.Object.Visible = callback
			AnimationTween.Object.Visible = callback
			AnimationSpeed.Object.Visible = callback
			if OldKA.Enabled then
				OldKA:Toggle()
				OldKA:Toggle()
			end
		end
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = OldKA:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true,
		Visible = false
	})
	AnimationSpeed = OldKA:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true,
		Visible = false
	})
	AnimationTween = OldKA:CreateToggle({
		Name = 'No Tween',
		Darker = true,
		Visible = false
	})
	Limit = OldKA:CreateToggle({
		Name = 'Limit to items',
		Function = function(callback)
			if inputService.TouchEnabled and OldKA.Enabled then
				pcall(function()
					lplr.PlayerGui.MobileUI['2'].Visible = callback
				end)
			end
		end,
		Tooltip = 'Only attacks when the sword is held'
	})
	LegitAura = OldKA:CreateToggle({
		Name = 'Swing only',
		Tooltip = 'Only attacks while swinging manually'
	})
	SC = OldKA:CreateToggle({Name='Sigird Check',Default=true})
	SophiaCheck = OldKA:CreateToggle({
		Name='Sophia Check',
		Default=true,
		Function = function(v)
			if not v then
				CURRENT_LEVEL_FROZEN = 0
			end
		end
	})	
end)


run(function()
	local NoCollision
	local last = {}
	NoCollision = vape.Categories.Blatant:CreateModule({
		Name = 'No Collision',
		Tooltip = 'Removes player\'s collision when ur near a bed',
		Function = function(callback)
			if callback then
				NoCollision:Clean(runService.PreSimulation:Connect(function()
					local plrs = {}

					for i, v in entitylib.List do
						if not v.NPC then
							table.insert(plrs, v)
						end
					end

					for _, v in last do
						local found = false

						for _, v2 in plrs do
							if v.Player == v2.Player then
								found = true
								break
							end
						end

						if not found and v.Character then
							for i,v in v.Character:GetDescendants() do
								if v.ClassName == 'Part' or v.ClassName == 'MeshPart' then
									v.CanQuery = true
								end
							end
						end
					end

					for _, v in plrs do
						if v.Character then
							for i,v in v.Character:GetDescendants() do
								if v.ClassName == 'Part' or v.ClassName == 'MeshPart' then
									v.CanQuery = false
									v.CanTouch = false
									v.CanCollide = false
								end
							end
						end
					end

					last = plrs
				end))
			end
		end
	})
end)

run(function()
	local BedAlarm
	local Range
	local Tick
	local Volume
	local HightlightOption
	local Color


	local function getBed()
		if entitylib.isAlive then
			local id = lplr.Character:GetAttribute('Team')
			for i,v in collectionService:GetTagged('bed') do
				if tonumber(id) == tonumber(v:GetAttribute('TeamId')) then
					return v
				end
			end
		end

		return
	end

	BedAlarm = vape.Categories.Exploits:CreateModule({
		Name = 'BedAlarm',
		Function = function(callback)
			if callback then
				local Notifytick = os.clock()
				local highlighted = {}
				repeat
					local bed, localpos = getBed(), nil
					if bed then
						localpos = bed:GetPivot().Position
					end

					if localpos then
						local entity = localpos and entitylib.EntityPosition({
							Origin = localpos,
							Range = Range.Value,
							Part = 'RootPart',
							Players = true
						})

						if os.clock() > Notifytick then
							if entity then
								Notifytick = os.clock() + Tick.Value
								bedwars.NotificationController:sendInfoNotification({
									message = '[Bed Alarm]: An intruder is near your bed!',
								})
								bedwars.SoundManager:playSound(bedwars.SoundList.BED_ALARM, {
									volumeMultiplier = Volume.Value
								})
								if HightlightOption.Enabled then
									pcall(function()
										local plr = playersService:GetPlayerFromCharacter(entity.character)
										for i, v in plr:GetDescendants() do
											if v:IsA("BasePart") then
												local Hightlight = Instance.new("Highlight")
												Hightlight.Adornee = v
												Hightlight.Parent = v
												Hightlight.FillTransparency = 0.3
												Hightlight.OutlineTransparency = 0
												Hightlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
												local color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
												Hightlight.FillColor = color
												Hightlight.OutlineColor = color
												highlighted[plr] = Hightlight
											end
										end
									end)
								end
							else
								if HightlightOption.Enabled then
									pcall(function()
										for plr, hl in highlighted do
											if hl then hl:Destroy() end
											highlighted[plr] = nil
										end
									end)
								end
							end
						end
					end
					task.wait(1/60)
				until not BedAlarm.Enabled
				table.clear(highlighted)
			end
		end,
		Tooltip = 'Notifies when theres an enemy near bed'
	})
	Range = BedAlarm:CreateSlider({
		Name = "Distance",
		Min = 1,
		Max = 100,
		Default = 64,
		Suffix = function(v)
			if v == 1 then
				return 'stud'
			end
			return 'studs'
		end
	})
	Tick = BedAlarm:CreateSlider({
		Name = "Ticks",
		Min = 0,
		Max = 12,
		Decimal = 5,
		Default = 3.05,
		Suffix = 'hz'
	})
	Volume = BedAlarm:CreateSlider({
		Name = "Volume Mutipler",
		Min = 0.1,
		Max = 2,
		Default = 1.5,
		Decimal = 5,
	})
	Color = BedAlarm:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Darker = true
	})
	HightlightOption = BedAlarm:CreateToggle({
		Name = "Hightlight players",
		Default = true,
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
		end
	})


end)

run(function()
    local GeneratorESP
	local GoldToggle = {Enabled=false}
    local DiamondToggle
    local EmeraldToggle
    local TeamGenToggle
    local ShowOwnTeamGen
    local ShowEnemyTeamGen
    local Reference = {}
    local Folder = Instance.new('Folder')
    Folder.Parent = vape.gui
    
    local teamColors = {
        [1] = {name = "Blue", color = Color3.fromRGB(85, 150, 255)},
        [2] = {name = "Orange", color = Color3.fromRGB(255, 150, 50)},
        [3] = {name = "Pink", color = Color3.fromRGB(255, 100, 200)},
        [4] = {name = "Yellow", color = Color3.fromRGB(255, 255, 50)}
    }
    
    local generatorTypes = {
        diamond = {
            keywords = {'diamond'},
            color = Color3.fromRGB(85, 200, 255),
            icon = 'diamond',
            displayName = 'Diamond',
            isTeamGen = false
        },
        emerald = {
            keywords = {'emerald'},
            color = Color3.fromRGB(0, 255, 100),
            icon = 'emerald',
            displayName = 'Emerald',
            isTeamGen = false
        },

    }
    
    local function getMyTeamId()
        local myTeam = lplr:GetAttribute('Team')
        if not myTeam then return nil end
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player == lplr then
                local teamAttr = player:GetAttribute('Team')
                if teamAttr then
                    local teamLower = tostring(teamAttr):lower()
                    if teamLower:find("blue") or teamLower == "0" then return 1
                    elseif teamLower:find("orange") or teamLower == "1" then return 2
                    elseif teamLower:find("pink") or teamLower == "2" then return 3
                    elseif teamLower:find("yellow") or teamLower == "3" then return 4
                    end
                end
            end
        end
        
        return nil
    end
    
    local function getGeneratorTeamId(generatorId)
        if not generatorId then return nil end
        
        local teamNum = generatorId:match("^(%d+)_generator")
        if teamNum then
            return tonumber(teamNum)
        end
        return nil
    end
    
    local function isTeamGenerator(generatorId)
        if not generatorId then return false end
        return generatorId:match("^%d+_generator") ~= nil
    end
    
    local function getGeneratorType(generatorId)
        if not generatorId then return nil, nil end
        local idLower = generatorId:lower()
        
        if isTeamGenerator(generatorId) then
            return 'teamgen', {
                color = Color3.fromRGB(189, 189, 189),
                icon = 'iron',
                displayName = 'Team Gen',
                isTeamGen = true
            }
        end
        
        for genType, config in pairs(generatorTypes) do
            for _, keyword in ipairs(config.keywords) do
                if idLower:find(keyword) then
                    return genType, config
                end
            end
        end
        return nil, nil
    end
    
    local function isGeneratorEnabled(genType, teamId)
        if genType == 'diamond' then
            return DiamondToggle.Enabled
        elseif genType == 'emerald' then
            return EmeraldToggle.Enabled
        elseif genType == 'gold' then
            return GoldToggle.Enabled
        elseif genType == 'teamgen' then
            if not TeamGenToggle.Enabled then return false end
            
            local myTeamId = getMyTeamId()
            if not myTeamId or not teamId then return TeamGenToggle.Enabled end
            
            if teamId == myTeamId then
                return ShowOwnTeamGen.Enabled
            else
                return ShowEnemyTeamGen.Enabled
            end
        end
        return false
    end
    
    local function getProperIcon(iconType)
        local icon = bedwars.getIcon({itemType = iconType}, true)
        if not icon or icon == "" then
            return nil
        end
        return icon
    end
    
    local function getTierText(generatorAdornee)
        if not generatorAdornee then return nil end
        
        if generatorAdornee.Name ~= 'GeneratorAdornee' then return nil end
        
        local reactTree = generatorAdornee:FindFirstChild('RoactTree')
        if not reactTree then return nil end
        
        local teamApp = reactTree:FindFirstChild('TeamOreGeneratorApp')
        if not teamApp then return nil end
        
        local globalGen = teamApp:FindFirstChild('GlobalOreGenerator')
        if globalGen then
            for _, child in pairs(globalGen:GetDescendants()) do
                if child:IsA('TextLabel') then
                    local text = child.Text
                    if text:find("Tier") or text:match("^[IVX]+$") then
                        return child
                    end
                end
            end
        end
        
        local teamGenMain = teamApp:FindFirstChild('TeamGenMain')
        if teamGenMain then
            for _, child in pairs(teamGenMain:GetDescendants()) do
                if child:IsA('TextLabel') then
                    local text = child.Text
                    if text:find("Tier") or text:match("^[IVX]+$") then
                        return child
                    end
                end
            end
        end
        
        return nil
    end
    
    local function extractTierLevel(tierText)
        if not tierText or tierText == "" then return "?" end
        
        local tierMatch = tierText:match("Tier%s+([IVX]+)")
        if tierMatch then
            return tierMatch
        end
        
        if tierText:match("^[IVX]+$") then
            return tierText
        end
        
        local numTier = tierText:match("Tier%s+(%d+)")
        if numTier then
            local num = tonumber(numTier)
            if num == 1 then return "I"
            elseif num == 2 then return "II"
            elseif num == 3 then return "III"
            end
        end
        
        return "?"
    end
    
    local function getCountdownText(generatorAdornee)
        if not generatorAdornee then return nil end
        
        if generatorAdornee.Name ~= 'GeneratorAdornee' then return nil end
        
        local reactTree = generatorAdornee:FindFirstChild('RoactTree')
        if not reactTree then return nil end
        
        local teamApp = reactTree:FindFirstChild('TeamOreGeneratorApp')
        if not teamApp then return nil end
        
        local globalGen = teamApp:FindFirstChild('GlobalOreGenerator')
        if not globalGen then return nil end
        
        local countdown = globalGen:FindFirstChild('Countdown')
        if not countdown then return nil end
        
        local textLabel = countdown:FindFirstChild('Text')
        if not textLabel then
            if countdown:IsA('TextLabel') then
                return countdown
            end
            return nil
        end
        
        return textLabel
    end
    
    local function extractSecondsFromText(text)
        if not text or text == "" then return 0 end
        
        local seconds = text:match("%[(%d+)%]")
        if seconds then
            return tonumber(seconds) or 0
        end
        
        local justNumber = text:match("(%d+)")
        if justNumber then
            return tonumber(justNumber) or 0
        end
        
        return 0
    end
    
    local function getResourceCount(position, resourceType)
        local count = 0
        for _, drop in pairs(CollectionService:GetTagged('ItemDrop')) do
            if drop:FindFirstChild('Handle') then
                local dropName = drop.Name:lower()
                if dropName:find(resourceType) then
                    local dist = (drop.Handle.Position - position).Magnitude
                    if dist <= 10 then
                        local amount = drop:GetAttribute('Amount') or 1
                        count = count + amount
                    end
                end
            end
        end
        return count
    end
    
    local function createESP(generatorAdornee, genType, config, position, teamId)
        if not isGeneratorEnabled(genType, teamId) then return end
        if Reference[generatorAdornee] then return end
        
        local displayColor = config.color
        if config.isTeamGen and teamId and teamColors[teamId] then
            displayColor = teamColors[teamId].color
        end
        
        local billboard = Instance.new('BillboardGui')
        billboard.Parent = Folder
        billboard.Name = 'generator-esp-' .. genType
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.ClipsDescendants = false
        billboard.Adornee = generatorAdornee
        
        if config.isTeamGen then
            billboard.Size = UDim2.fromOffset(180, 35)
        else
            billboard.Size = UDim2.fromOffset(80, 30)
        end
        
        local blur = addBlur(billboard)
        blur.Visible = true
        
        local frame = Instance.new('Frame')
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = billboard
        
        local uicorner = Instance.new('UICorner')
        uicorner.CornerRadius = UDim.new(0, 6)
        uicorner.Parent = frame
        
        if config.isTeamGen then
            local tierLabel = Instance.new('TextLabel')
            tierLabel.Name = 'Tier'
            tierLabel.Size = UDim2.new(0, 25, 1, 0)
            tierLabel.Position = UDim2.new(0, 5, 0, 0)
            tierLabel.BackgroundTransparency = 1
            tierLabel.Text = "?"
            tierLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
            tierLabel.TextSize = 16
            tierLabel.Font = Enum.Font.GothamBold
            tierLabel.TextStrokeTransparency = 0.5
            tierLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            tierLabel.Parent = frame
            
            local resources = {
                {name = 'iron', color = Color3.fromRGB(200, 200, 200), icon = 'iron', xOffset = 35},
                {name = 'diamond', color = Color3.fromRGB(85, 200, 255), icon = 'diamond', xOffset = 85},
                {name = 'emerald', color = Color3.fromRGB(0, 255, 100), icon = 'emerald', xOffset = 135},
            }
            
            local resourceLabels = {}
            
            for i, resource in ipairs(resources) do
                local iconImage = getProperIcon(resource.icon)
                if iconImage then
                    local image = Instance.new('ImageLabel')
                    image.Size = UDim2.fromOffset(18, 18)
                    image.Position = UDim2.new(0, resource.xOffset, 0.5, 0)
                    image.AnchorPoint = Vector2.new(0, 0.5)
                    image.BackgroundTransparency = 1
                    image.Image = iconImage
                    image.Parent = frame
                end
            
                local countLabel = Instance.new('TextLabel')
                countLabel.Name = resource.name .. '_count'
                countLabel.Size = UDim2.new(0, 25, 1, 0)
                countLabel.Position = UDim2.new(0, resource.xOffset + 20, 0, 0)
                countLabel.BackgroundTransparency = 1
                countLabel.Text = "0"
                countLabel.TextColor3 = resource.color
                countLabel.TextSize = 16
                countLabel.Font = Enum.Font.GothamBold
                countLabel.TextStrokeTransparency = 0.5
                countLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                countLabel.TextXAlignment = Enum.TextXAlignment.Left
                countLabel.Parent = frame
                
                resourceLabels[resource.name] = countLabel
            end
            
            Reference[generatorAdornee] = {
                billboard = billboard,
                tierLabel = tierLabel,
                ironLabel = resourceLabels.iron,
                diamondLabel = resourceLabels.diamond,
                emeraldLabel = resourceLabels.emerald,
                genType = genType,
                position = position,
                teamId = teamId,
                isTeamGen = true
            }
        else
            local iconImage = getProperIcon(config.icon)
            if iconImage then
                local image = Instance.new('ImageLabel')
                image.Size = UDim2.fromOffset(20, 20)
                image.Position = UDim2.new(0, 5, 0.5, 0)
                image.AnchorPoint = Vector2.new(0, 0.5)
                image.BackgroundTransparency = 1
                image.Image = iconImage
                image.Parent = frame
            end
            
            local timerLabel = Instance.new('TextLabel')
            timerLabel.Name = 'Timer'
            timerLabel.Size = UDim2.new(0, 30, 1, 0)
            timerLabel.Position = UDim2.new(0.5, 0, 0, 0)
            timerLabel.AnchorPoint = Vector2.new(0.5, 0)
            timerLabel.BackgroundTransparency = 1
            timerLabel.Text = "00"
            timerLabel.TextColor3 = displayColor
            timerLabel.TextSize = 18
            timerLabel.Font = Enum.Font.GothamBold
            timerLabel.TextStrokeTransparency = 0.5
            timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            timerLabel.Parent = frame
            
            local amountLabel = Instance.new('TextLabel')
            amountLabel.Name = 'Amount'
            amountLabel.Size = UDim2.new(0, 20, 1, 0)
            amountLabel.Position = UDim2.new(1, -20, 0, 0)
            amountLabel.BackgroundTransparency = 1
            amountLabel.Text = "0"
            amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            amountLabel.TextSize = 16
            amountLabel.Font = Enum.Font.GothamBold
            amountLabel.TextStrokeTransparency = 0.5
            amountLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            amountLabel.Parent = frame
            
            Reference[generatorAdornee] = {
                billboard = billboard,
                timerLabel = timerLabel,
                amountLabel = amountLabel,
                genType = genType,
                position = position,
                teamId = teamId,
                isTeamGen = false
            }
        end
    end
    
    local function updateESP(generatorAdornee)
        local ref = Reference[generatorAdornee]
        if not ref then return end
        
        if ref.isTeamGen then
            if ref.tierLabel then
                local tierTextLabel = getTierText(generatorAdornee)
                if tierTextLabel and tierTextLabel.Text then
                    local tierLevel = extractTierLevel(tierTextLabel.Text)
                    ref.tierLabel.Text = tierLevel
                else
                    ref.tierLabel.Text = "?"
                end
            end
            
            if ref.ironLabel then
                local ironCount = getResourceCount(ref.position, 'iron')
                ref.ironLabel.Text = tostring(ironCount)
            end
            
            if ref.diamondLabel then
                local diamondCount = getResourceCount(ref.position, 'diamond')
                ref.diamondLabel.Text = tostring(diamondCount)
            end
            
            if ref.emeraldLabel then
                local emeraldCount = getResourceCount(ref.position, 'emerald')
                ref.emeraldLabel.Text = tostring(emeraldCount)
            end
            if ref.goldLabel then
                local goldCount = getResourceCount(ref.position, 'gold')
                ref.goldLabel.Text = tostring(goldCount)
            end			
        else
            local countdownText = getCountdownText(generatorAdornee)
            local timeLeft = 0
            local timerStr = "00"
            
            if countdownText and countdownText.Text then
                timeLeft = extractSecondsFromText(countdownText.Text)
                timerStr = string.format("%02d", timeLeft)
                if ref.timerLabel then
                    ref.timerLabel.Text = timerStr
                    if timeLeft <= 5 then
                        ref.timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50) 
                    elseif timeLeft <= 10 then
                        ref.timerLabel.TextColor3 = Color3.fromRGB(255, 165, 0) 
                    else
                        ref.timerLabel.TextColor3 = generatorTypes[ref.genType].color 
                    end
                end
            else
                if ref.timerLabel then
                    ref.timerLabel.Text = "??"
                    ref.timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
            
            if ref.amountLabel then
                local currentAmount = getResourceCount(ref.position, ref.genType)
                ref.amountLabel.Text = tostring(currentAmount)
            end
        end
    end
    
    local function findAllGenerators()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == 'GeneratorAdornee' then
                local generatorId = obj:GetAttribute('Id')
                if not generatorId then continue end
                
                local position = obj:GetPivot().Position
                local genType, config = getGeneratorType(generatorId)
                
                if genType and config then
                    local teamId = getGeneratorTeamId(generatorId)
                    if isGeneratorEnabled(genType, teamId) then
                        createESP(obj, genType, config, position, teamId)
                    end
                end
            end
        end
    end
    
    local function refreshESP()
        Folder:ClearAllChildren()
        table.clear(Reference)
        
        if GeneratorESP.Enabled then
            findAllGenerators()
        end
    end
    
    local updateTimer = 0
    
    GeneratorESP = vape.Categories.Render:CreateModule({
        Name = 'GeneratorESP',
        Function = function(callback)
            if callback then
                findAllGenerators()
                
                GeneratorESP:Clean(workspace.DescendantAdded:Connect(function(obj)
                    if not GeneratorESP.Enabled then return end
                    
                    if obj.Name == 'GeneratorAdornee' then
                        task.wait(0.2) 
                        
                        local generatorId = obj:GetAttribute('Id')
                        if not generatorId then return end
                        
                        local position = obj:GetPivot().Position
                        local genType, config = getGeneratorType(generatorId)
                        
                        if genType and config then
                            local teamId = getGeneratorTeamId(generatorId)
                            if isGeneratorEnabled(genType, teamId) then
                                createESP(obj, genType, config, position, teamId)
                            end
                        end
                    end
                end))
                
                GeneratorESP:Clean(RunService.Heartbeat:Connect(function(dt)
                    if not GeneratorESP.Enabled then return end
                    
                    updateTimer = updateTimer + dt
                    if updateTimer < 0.2 then return end
                    updateTimer = 0
                    
                    for generatorAdornee, ref in pairs(Reference) do
                        if generatorAdornee and generatorAdornee.Parent then
                            updateESP(generatorAdornee)
                        else
                            if ref.billboard then
                                ref.billboard:Destroy()
                            end
                            Reference[generatorAdornee] = nil
                        end
                    end
                end))
                
                GeneratorESP:Clean(workspace.DescendantRemoving:Connect(function(obj)
                    if not GeneratorESP.Enabled then return end
                    
                    if Reference[obj] then
                        if Reference[obj].billboard then
                            Reference[obj].billboard:Destroy()
                        end
                        Reference[obj] = nil
                    end
                end))
                
            else
                Folder:ClearAllChildren()
                table.clear(Reference)
            end
        end,
        Tooltip = 'ESP for generators showing timer and item counts'
    })
    
    DiamondToggle = GeneratorESP:CreateToggle({
        Name = 'Diamond',
        Function = function(callback)
            refreshESP()
        end,
        Default = true
    })
    
    EmeraldToggle = GeneratorESP:CreateToggle({
        Name = 'Emerald',
        Function = function(callback)
            refreshESP()
        end,
        Default = true
    })
    for i, v in workspace:GetDescendants() do
		if string.find(string.lower(v.Name), "gold") then
			GoldToggle = GeneratorESP:CreateToggle({
				Name = 'Gold',
				Function = function(callback)
					refreshESP()
				end,
				Default = false
			})
		end
	end
    TeamGenToggle = GeneratorESP:CreateToggle({
        Name = 'Team Generators',
        Function = function(callback)
            if ShowOwnTeamGen then
                ShowOwnTeamGen.Object.Visible = callback
            end
            if ShowEnemyTeamGen then
                ShowEnemyTeamGen.Object.Visible = callback
            end
            refreshESP()
        end,
        Default = true
    })
    
    ShowOwnTeamGen = GeneratorESP:CreateToggle({
        Name = 'Show Own Team',
        Function = function(callback)
            refreshESP()
        end,
        Default = false,
        Visible = true
    })
    
    ShowEnemyTeamGen = GeneratorESP:CreateToggle({
        Name = 'Show Enemy Teams',
        Function = function(callback)
            refreshESP()
        end,
        Default = true,
        Visible = true
    })
end)


run(function()
	local AutoNoelle
	local Notify
	local Limits
	local Heal
	local Void
	local Sticky
	local Frosty
    local function getTeammateList()
        local teammates = {}
        local myTeam = lplr:GetAttribute('Team')
        
        if not myTeam then return {} end
        
        for _, player in playersService:GetPlayers() do
            if player ~= lplr then
                local playerTeam = player:GetAttribute('Team')
                if playerTeam and playerTeam == myTeam then
                    table.insert(teammates, player.Name)
                end
            end
        end
        
        table.sort(teammates)
        return teammates
    end

	local slimeKeywords = {
		heal = true,
		void = true,
		sticky = true,
		frosty = true
	}


	local function getSlime()
		local playerName = string.lower(lplr.Name)

		for _, v in ipairs(workspace.SlimeModelFolder:GetChildren()) do
			if v:IsA("Model") then
				local name = string.lower(v.Name)
				if not string.find(name, playerName, 1, true) then
					continue
				end
				for keyword in pairs(slimeKeywords) do
					if string.find(name, keyword) then
						local str = tostring(v.SlimeData.Value)
						local id = str:match("%d+")
						return tonumber(id)
					end
				end
			end
		end
	end

	local function MoveSlime(target,slime)
		if Limits.Enabled then
			if store.hand.tool.Name ~= "slime_tamer_flute" then
				return
			end
		end
		slime = getSlime(slime)
		bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.SLIME_TAMER_FLUTE_USE)
		bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.SLIME_TAMER_FLUTE_USE_FP)
		bedwars.SlimeTamerFluteController.moveSlime({
			targetEntity = target.Character,
			selectedSlimeType = slime
		})
	end

	local function getPlayerByName(name)
		for _, plr in playersService:GetPlayers() do
			if plr.Name == name then
				return plr
			end
		end
	end

	local function isInRange(plr, range)
		if not plr or not plr.Character then return false end
		local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
		local myHrp = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or not myHrp then return false end

		return (hrp.Position - myHrp.Position).Magnitude <= range
	end


	AutoNoelle = vape.Categories.Kits:CreateModule({
		Name = "AutoNoelle",
		Function = function(callback)
			if store.equippedKit ~= "slime_tamer" then
				vape:CreateNotification("AutoNoelle","Kit required only!",8,"warning")
				return
			end
			if callback then
				task.spawn(function()
					AutoNoelle:Clean(playersService.PlayerAdded:Connect(function()
						task.wait(0.5)
						Heal:SetList(getTeammateList())
						Void:SetList(getTeammateList())
						Sticky:SetList(getTeammateList())
						Frosty:SetList(getTeammateList())						
					end))			
					AutoNoelle:Clean(playersService.PlayerRemoving:Connect(function()
						task.wait(0.5)
						Heal:SetList(getTeammateList())
						Void:SetList(getTeammateList())
						Sticky:SetList(getTeammateList())
						Frosty:SetList(getTeammateList())	
					end))			
					AutoNoelle:Clean(lplr:GetAttributeChangedSignal('Team'):Connect(function()
						task.wait(1)
						Heal:SetList(getTeammateList())
						Void:SetList(getTeammateList())
						Sticky:SetList(getTeammateList())
						Frosty:SetList(getTeammateList())	
					end))
				end)
				task.spawn(function()
					while AutoNoelle.Enabled do
						task.wait(0.15)
						if Heal.Value then
							local plr = getPlayerByName(Heal.Value)
							if isInRange(plr, 12) then
								MoveSlime(plr, "Heal")
							end
						end
						if Void.Value then
							local plr = getPlayerByName(Void.Value)
							if isInRange(plr, 12) then
								MoveSlime(plr, "Void")
							end
						end
						if Sticky.Value then
							local plr = getPlayerByName(Sticky.Value)
							if isInRange(plr, 12) then
								MoveSlime(plr, "Sticky")
							end
						end
						if Frosty.Value then
							local plr = getPlayerByName(Frosty.Value)
							if isInRange(plr, 12) then
								MoveSlime(plr, "Frosty")
							end
						end
					end
				end)
			else
				task.wait(0.1)
			end
		end
	})

    
    Heal = AutoNoelle:CreateDropdown({
        Name = "Heal Slime Target",
        List = getTeammateList(),
        Tooltip = "Select teammate to give Heal slime to"
    })
    Void = AutoNoelle:CreateDropdown({
        Name = "Void Slime Target",
        List = getTeammateList(),
        Tooltip = "Select teammate to give Void slime to"
    })	
    Sticky = AutoNoelle:CreateDropdown({
        Name = "Sticky Slime Target",
        List = getTeammateList(),
        Tooltip = "Select teammate to give Sticky slime to"
    })
    Frosty = AutoNoelle:CreateDropdown({
        Name = "Frosty Slime Target",
        List = getTeammateList(),
        Tooltip = "Select teammate to give Frosty slime to"
    })
	Limits = AutoNoelle:CreateToggle({
		Name = "Limit to items",
		Default = true
	})

end)

Tun(function() -- keep this if ur a dev this disables speed n fly whenever you anti cheat
	local whitelist = loadstring(downloadFile('ReVape/games/whitelist.lua'), 'whitelist')()	
	if not isnetworkowner(entitylib.character.RootPart) then
		if Speed.Enabled then
			Speed:Toggle(false)
		end
		if Fly.Enabled then
			Fly:Toggle(false)
		end
	end
end)

Tun(function()
	local CheckExecutor = ({identifyexecutor()})[1]
	if CheckExecutor == nil or CheckExecutor == '' then
		CheckExecutor = 'shitsploit'
	end
	if CheckExecutor == 'shitsploit' then
		vape:CreateNotification('Onyx',"Your executor has been detected as 'ShitSploit', please use a different executor or reinject if you think this is a error",12,'alert')
		return
	end
	if CheckExecutor == 'Delta' or CheckExecutor == 'Volcano' then
		for _, v in {'PlayerAttach','RemoveStatus','DamageBoost','ServerSync','LuciaSpy','GrimFixer','FrameBuffer','BedAlarm','GeneratorESP','OldKA'} do
			vape:Remove(v)
		end
	end
	if CheckExecutor == 'Volt' or CheckExecutor == 'Wave' or CheckExecutor == 'Potassium' then
		for _, v in {'ServerSync','LuciaSpy','GrimFixer','FrameBuffer','GeneratorESP','OldKA'} do
			vape:Remove(v)
		end
	end	
end)


Tun(function()
	if bedwars.CannonLaunch == nil or bedwars.CannonLaunch == '' then
		bedwars.CannonLaunch = {}
		function bedwars.CannonLaunch:CallServer(self)
			if self.cannonBlockPos then
				local cannon = nil
				for i, v in workspace:GetDescendants() do
					if v:IsA("BasePart") and v.Name == 'cannon' then
						cannon = v
						local distance = (cannon.Position - entitylib.character.RootPart.Position).Magnitude
						if distance <= 12 then
							local v30 = lplr.Character.PrimaryPart.AssemblyMass
							lplr.Character.PrimaryPart:ApplyImpulse(cannon:GetAttribute('LookVector') * (v30 == nil and 0 or v30) * 200)
							return true
						end
					end
				end

			end
			return false
		end
	end
end)

run(function()
    local NewAutoWin
	local Methods 
	local hiding = true
	local gui
	local beds,currentbedpos,Dashes = {}, nil, {Value  =2}
	local function create(Name,values)
		local obj = Instance.new(Name)
		for i, v in values do
			obj[i] = v
		end
		return obj
	end
	local function Reset()
		NewAutoWin:Clean(TeleportService:Teleport(game.PlaceId, lplr, TeleportService:GetLocalPlayerTeleportData()))
	end
	local function AllbedPOS()
		if workspace:FindFirstChild("MapCFrames") then
			for _, obj in ipairs(workspace:FindFirstChild("MapCFrames"):GetChildren()) do
				if string.match(obj.Name, "_bed$") then
					table.insert(beds, obj.Value.Position)
				end
			end
		end
	end
	local function UpdateCurrentBedPOS()
		if workspace:FindFirstChild("MapCFrames") then
			local currentTeam =  lplr.Character:GetAttribute("Team")
			if workspace:FindFirstChild("MapCFrames") then
				local CFRameName = tostring(currentTeam).."_bed"
				currentbedpos = workspace:FindFirstChild("MapCFrames"):FindFirstChild(CFRameName).Value.Position
			end
		end
	end
	local function closestBed(origin)
		local closest, dist
		for _, pos in ipairs(beds) do
			if pos ~= currentbedpos then
				local d = (pos - origin).Magnitude
				if not dist or d < dist then
					dist, closest = d, pos
				end
			end
		end
		return closest
	end
	local function tweenToBED(pos)
		if entitylib.isAlive then
			local oldpos = pos
			pos = pos + Vector3.new(0, 5, 0)
			local currentPosition = entitylib.character.RootPart.Position
			if (pos - currentPosition).Magnitude > 0.5 then
				if lplr.Character then
					lplr:SetAttribute('LastTeleported', 0)
				end
				local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
				local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				local tween2 = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				task.spawn(function() tween:Play() end)
				task.spawn(function()
					if Dashes.Value == 1 then
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							vape:CreateNotification("AutoWin", "Dashing to bypass anti cheat!", 1)
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					elseif Dashes.Value == 2 then
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							vape:CreateNotification("AutoWin", "Dashing to bypass anti cheat!", 1)
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							vape:CreateNotification("AutoWin", "Dashing to bypass anti cheat!", 1)
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					else
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							vape:CreateNotification("AutoWin", "Dashing to bypass anti cheat!", 1)
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
							end				
						end
				end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				task.wait(1.45)
				vape:CreateNotification("AutoWin", "Fixing position!", 1)
				task.spawn(function() tween2:Play() end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				task.wait(0.85)
				vape:CreateNotification("AutoWin",'nuking bed...',2)
				if not Breaker.Enabled then
					Breaker:Toggle(true)
					
				end
				NewAutoWin:Clean(lplr.PlayerGui.ChildAdded:Connect(function(obj)
					if obj.Name == "WinningTeam" then
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						vape:CreateNotification("AutoWin",'Match ended you won... Teleporting you to a empty game.',3)
						task.wait(1.5)
						Reset()
					end
				end))
			end
		end
	end
	local function tweenToBED2(pos,msg,oppositeTeam)
		if entitylib.isAlive then
			local oldpos = pos
			pos = pos + Vector3.new(0, 5, 0)
			local currentPosition = entitylib.character.RootPart.Position
			if (pos - currentPosition).Magnitude > 0.5 then
				if lplr.Character then
					lplr:SetAttribute('LastTeleported', 0)
				end
				local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
				local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				local tween2 = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				task.spawn(function() tween:Play() end)
				task.spawn(function()
					if Dashes.Value == 1 then
						msg.Text = "Dashing to bypass Anti-Cheat. (0.36s)"
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					elseif Dashes.Value == 2 then
						msg.Text = "Dashing to bypass Anti-Cheat. (0.36s)"
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
						msg.Text = "Dashing to bypass Anti-Cheat. (0.54s)"
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					else
						msg.Text = "Dashing to bypass Anti-Cheat. (0.54s)"
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
							end				
						end
				end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				msg.Text = `Fixing current positon {bedwars.BlockController:getBlockPosition(entitylib.character.RootPart.Position)} to {pos}. (1.45s)`
				task.wait(1.45)
				task.spawn(function() tween2:Play() end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				msg.Text = `Nuking {oppositeTeam} bed.. (0.85s)`
				task.wait(0.85)
				if not Breaker.Enabled then
					Breaker:Toggle(true)
				end
				NewAutoWin:Clean(lplr.PlayerGui.ChildAdded:Connect(function(obj)
					msg.Text = `Your current Player Level is {lplr:GetAttribute("PlayerLevel")}. (0.85s)`
					task.wait(0.85)
					msg.Text = 'Match ended. ReTeleporting to another Empty Game... (1.5s)'
					task.wait(0.5)
					if obj.Name == "WinningTeam" then
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						task.wait(1)
						Reset()
					end
				end))
			end
		end
	end
	local function tweenToBED3(pos,msg,oppositeTeam,Percent)
		if entitylib.isAlive then
			local oldpos = pos
			pos = pos + Vector3.new(0, 5, 0)
			local currentPosition = entitylib.character.RootPart.Position
			if (pos - currentPosition).Magnitude > 0.5 then
				if lplr.Character then
					lplr:SetAttribute('LastTeleported', 0)
				end
				local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
				local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				local tween2 = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.new(pos)})
				task.spawn(function() tween:Play() end)
				task.spawn(function()
					if Dashes.Value == 1 then
						Percent:SetAttribute("Percent",62)
						msg.Text = "Dashing to bypass Anti-Cheat.. (1)"
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					elseif Dashes.Value == 2 then
						Percent:SetAttribute("Percent",62)
						msg.Text = "Dashing to bypass Anti-Cheat.. (1)"
						task.wait(0.36)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
						Percent:SetAttribute("Percent",72)
						msg.Text = "Dashing to bypass Anti-Cheat.. (2)"
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
						end
					else
						Percent:SetAttribute("Percent",72)
						msg.Text = "Dashing to bypass Anti-Cheat.. (1)"
						task.wait(0.54)
						if bedwars.AbilityController:canUseAbility("ELECTRIC_DASH") then
							bedwars.AbilityController:useAbility('ELECTRIC_DASH')
							end				
						end
				end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				Percent:SetAttribute("Percent",83)
				msg.Text = `Fixing current positon {bedwars.BlockController:getBlockPosition(entitylib.character.RootPart.Position)} to {pos}.`
				task.wait(1.45)
				task.spawn(function() tween2:Play() end)
				task.spawn(function()
					tween.Completed:Wait()
					lplr:SetAttribute('LastTeleported', os.time())
				end)
				lplr:SetAttribute('LastTeleported', os.time())
				task.wait(0.25)
				if lplr.Character then
					task.wait(0.1235)
					lplr:SetAttribute('LastTeleported', os.time())
				end
				Percent:SetAttribute("Percent",99)
				msg.Text = `Nuking {oppositeTeam} bed.. `
				task.wait(0.85)
				if not Breaker.Enabled then
					Breaker:Toggle(true)
				end
				NewAutoWin:Clean(lplr.PlayerGui.NotificationApp.ChildAdded:Connect(function(obj)
					obj:Destroy()
				end))
				NewAutoWin:Clean(lplr.PlayerGui.ChildAdded:Connect(function(obj)
					
					Percent:SetAttribute("Percent",100)
					msg.Text = 'Match ended. ReTeleporting to another Empty Game...'
					task.wait(0.5)
					if obj.Name == "WinningTeam" then
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						task.wait(1)
						Reset()
					end
				end))
			end
		end
	end

	local function MethodOne()
		vape:CreateNotification("AutoWin",'finding all bed positions!',1.85)
		AllbedPOS()
		task.wait(0.958)
		vape:CreateNotification("AutoWin",'Founded my own bed position!',3.85)
		UpdateCurrentBedPOS()
		if currentbedpos then
			task.wait(2.125)
			vape:CreateNotification("AutoWin",'Finding the other team bed!',3.85)
			task.wait(2)
			bedpos = closestBed(entitylib.character.RootPart.Position)
			if bedpos then
				local bp = tostring(bedpos)
				if lplr.Team.Name == "Blue" then
						vape:CreateNotification("AutoWin",`Founded Orange's bed at {bp}`,4.85)
						tweenToBED(bedpos)
					else
						vape:CreateNotification("AutoWin",`Founded Blue's bed at {bp}`,4.85)
						tweenToBED(bedpos)
					end
				else
				if lplr.Team.Name == "Blue" then
					vape:CreateNotification("AutoWin",'Couldnt find Orange\'s bed position? ReTeleporting...','warning',10.85)
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				else
					vape:CreateNotification("AutoWin",'Couldnt find Blue\'s bed position? ReTeleporting...','warning',10.85)
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				end
			end
		else
			vape:CreateNotification("AutoWin",'Couldnt find my bed position? ReTeleporting...','warning',10.85)
			lplr:Kick("Don't disconnect, this will auto teleport you!")
			task.wait(0.5)
			Reset()
		end
	end
	
	local function MethodTwo(TooltipText)
		TooltipText.Text = 'Finding all current beds positions near me! (0.235s)'
		AllbedPOS()
		task.wait(0.2345)
		TooltipText.Text = 'Founded my team\'s bed position! (0.35s)'
		UpdateCurrentBedPOS()
		if currentbedpos then
			task.wait(0.35)
			TooltipText.Text = 'Finding other team\'s bed! (0.5s)'
			task.wait(.5)
			bedpos = closestBed(entitylib.character.RootPart.Position)
			if bedpos then
				local bp = tostring(bedpos)
				if lplr.Team.Name == "Blue" then
						TooltipText.Text = `Founded Orange's bed at {bp} (2s)`
						tweenToBED2(bedpos,TooltipText,'Orange')
					else
						TooltipText.Text = `Founded Blue's bed at {bp} (2s)`
						tweenToBED2(bedpos,TooltipText,'Blue')
					end
				else
				if lplr.Team.Name == "Blue" then
					TooltipText.Text = 'Couldn\'t find my Orange\'s bed position? ReTeleporting... (0.5s)'
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				else
					TooltipText.Text = 'Couldn\'t find my Blue\'s bed position? ReTeleporting... (0.5s)'
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				end
			end
		else
			TooltipText.Text = 'Couldn\'t find my bed position? ReTeleporting... (0.5s)'
			lplr:Kick("Don't disconnect, this will auto teleport you!")
			task.wait(0.5)
			Reset()
		end
		task.spawn(function()
			NewAutoWin:Clean(playersService.PlayerAdded:Connect(function(playerToBlock)
				local NewFoundedPlayersName = playerToBlock.Name
				if playersService:FindFirstChild(NewFoundedPlayersName) then

					local RobloxGui = coreGui:WaitForChild("RobloxGui")
					local CoreGuiModules = RobloxGui:WaitForChild("Modules")
					local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))
					PlayerDropDownModule:InitBlockListAsync()
					local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

					
					if BlockingUtility:IsPlayerBlockedByUserId(playerToBlock.UserId) then
						return
					end
					local successfullyBlocked = BlockingUtility:BlockPlayerAsync(playerToBlock)
					if successfullyBlocked then
						TooltipText.Text = string.format("Successfully blocked %s! lobbying... (1s)",NewFoundedPlayersName)
						writefile('ReVape/profiles/BlockedUsers.txt', isfile('ReVape/profiles/BlockedUsers.txt') and readfile('ReVape/profiles/BlockedUsers.txt') or "" ~= "" and (isfile('ReVape/profiles/BlockedUsers.txt') and readfile('ReVape/profiles/BlockedUsers.txt') or "" .. "\n" .. NewFoundedPlayersName) or NewFoundedPlayersName)
						task.wait(1.015)
					end
					lobby()
				end
			end))
		end)
	end
	
	local function MethodThree(TooltipText,Percent)
		Percent:SetAttribute("Percent",5)
		TooltipText.Text = 'Finding all current beds positions near me...'
		task.wait(0.015825)
		AllbedPOS()
		Percent:SetAttribute("Percent",15)
		task.wait(0.1345)
		Percent:SetAttribute("Percent",35)
		TooltipText.Text = 'Founded my team\'s bed position...'
		UpdateCurrentBedPOS()
		if currentbedpos then
			task.wait(0.15)
			Percent:SetAttribute("Percent",48)
			TooltipText.Text = 'Finding other team\'s bed...'
			task.wait(.485)
			bedpos = closestBed(entitylib.character.RootPart.Position)
			if bedpos then
				Percent:SetAttribute("Percent",54)
				local bp = tostring(bedpos)
				if lplr.Team.Name == "Blue" then
						TooltipText.Text = `Founded Orange's bed at {bp}`
						tweenToBED3(bedpos,TooltipText,'Orange',Percent)
					else
						TooltipText.Text = `Founded Blue's bed at {bp}`
						tweenToBED3(bedpos,TooltipText,'Blue',Percent)
					end
				else
				if lplr.Team.Name == "Blue" then
					TooltipText.Text = 'Couldn\'t find my Orange\'s bed position? ReTeleporting...'
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				else
					TooltipText.Text = 'Couldn\'t find my Blue\'s bed position? ReTeleporting...'
					lplr:Kick("Don't disconnect, this will auto teleport you!")
					task.wait(0.5)
					Reset()
				end
			end
		else
			TooltipText.Text = 'Couldn\'t find my bed position? ReTeleporting...'
			lplr:Kick("Don't disconnect, this will auto teleport you!")
			task.wait(0.5)
			Reset()
		end
		task.spawn(function()
			NewAutoWin:Clean(playersService.PlayerAdded:Connect(function(playerToBlock)
				local NewFoundedPlayersName = playerToBlock.Name
				if playersService:FindFirstChild(NewFoundedPlayersName) then

					local RobloxGui = coreGui:WaitForChild("RobloxGui")
					local CoreGuiModules = RobloxGui:WaitForChild("Modules")
					local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))
					PlayerDropDownModule:InitBlockListAsync()
					local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

					
					if BlockingUtility:IsPlayerBlockedByUserId(playerToBlock.UserId) then
						return
					end
					local successfullyBlocked = BlockingUtility:BlockPlayerAsync(playerToBlock)
					if successfullyBlocked then
						TooltipText.Text = string.format("Successfully blocked %s! lobbying... ",NewFoundedPlayersName)
						task.wait(0.125)
					end
					lobby()
				end
			end))
		end)
	end
	
    NewAutoWin = vape.Categories.AltFarm:CreateModule({
		Name = "NewElektraAutoWin",
		Tooltip = 'must have elektra to use this',
		Function = function(callback) 
			if callback then
				if Methods.Value == "Method 1" then
					local ScreenGui = create("ScreenGui",{Parent = lplr.PlayerGui,ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder =999,Name='AutowinUI'})
					local MainFrame = create("Frame",{Visible=gui.Enabled,Name='AutowinFrame',Parent=ScreenGui,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.05,Size=UDim2.fromScale(1,1)})
					local SecondaryFrame = create("Frame",{Name='SecondaryFrame',Parent=MainFrame,BackgroundColor3=Color3.fromRGB(28,25,27),BackgroundTransparency=0.1,Size=UDim2.fromScale(1,1)})
					local ShowUserBtn = create("TextButton",{Name='UsernameButton',Parent=SecondaryFrame,Position=UDim2.fromScale(0.393,0.788),Size=UDim2.fromOffset(399,97),FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.SemiBold),Text='SHOW USERNAME',TextColor3=Color3.fromRGB(65,65,65),TextSize=32,TextTransparency=0.2,BackgroundColor3=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value)})
					create("UICorner",{CornerRadius=UDim.new(0,6),Parent=ShowUserBtn})
					create("UIStroke",{ApplyStrokeMode='Border',Color=Color3.new(0,0,0),Thickness=5,Parent=ShowUserBtn})
					create("UIStroke",{ApplyStrokeMode='Contextual',Color=Color3.new(0,0,0),Thickness=1,Parent=ShowUserBtn})
					local MainIcon = create("ImageLabel",{Parent=SecondaryFrame,Name='AltFarmIcon',BackgroundTransparency=1,Image=getcustomasset('ReVape/assets/new/af.png'),ImageTransparency=0.63,ImageColor3=Color3.new(0,0,0),Position=UDim2.fromScale(0.388,0.193),Size=UDim2.fromOffset(346,341)})
					local SecondaryIcon = create("ImageLabel",{Parent=MainIcon,Name='MainIconAltFarm',BackgroundTransparency=1,Image=getcustomasset('ReVape/assets/new/af.png'),ImageTransparency=0.24,Position=UDim2.fromScale(0.069,0.053),Size=UDim2.fromOffset(297,305)})
					local Levels = create("TextButton",{Name='LevelText',Parent=SecondaryFrame,BackgroundTransparency=1,Position=UDim2.fromScale(0.435,0.596),Size=UDim2.fromOffset(200,50),FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.SemiBold,Enum.FontStyle.Italic),Text="Level: 0",TextSize=32})
					create("UIStroke",{ApplyStrokeMode='Contextual',Color=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value),Thickness=2.1,Transparency=0.22,Parent=Levels})
					--local Wins = create("TextButton",{Name='WinsText',Parent=SecondaryFrame,BackgroundTransparency=1,Position=UDim2.fromScale(0.435,0.684),Size=UDim2.fromOffset(200,50),FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.SemiBold,Enum.FontStyle.Italic),Text="Wins: 0",TextSize=32})
					--create("UIStroke",{ApplyStrokeMode='Contextual',Color=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value),Thickness=2.1,Transparency=0.22,Parent=Wins})
					local Username = create("TextButton",{Name='WinsText',Parent=SecondaryFrame,BackgroundTransparency=1,Position=UDim2.fromScale(0.365,0),Size=UDim2.fromOffset(425,89),FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.SemiBold,Enum.FontStyle.Italic),Text="Username: [HIDDEN]",TextSize=32})
					create("UIStroke",{ApplyStrokeMode='Contextual',Color=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value),Thickness=2.1,Transparency=0.22,Parent=Username})
					task.spawn(function()
						repeat
							Levels.Text = "Level: "..tostring(lplr:GetAttribute("PlayerLevel")) or "0"
							task.wait(0.1)
						until not NewAutoWin.Enabled
					end)

					ShowUserBtn.Activated:Connect(function()
						if hiding then
							Username.Text = "Username: ["..lplr.Name.."]"
							MainIcon.Image = playersService:GetUserThumbnailAsync(lplr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
							SecondaryIcon.Image = playersService:GetUserThumbnailAsync(lplr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)
						else
							Username.Text = "Username: [HIDDEN]"
							MainIcon.Image =getcustomasset('ReVape/assets/new/af.png')
							SecondaryIcon.Image = getcustomasset('ReVape/assets/new/af.png')
						end
						hiding = not hiding
					end)
					
					vape:CreateNotification("AutoWin",'checking if in empty game...',3)
					task.wait((3 / 1.85))
					if #playersService:GetChildren() ~= 1 then
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						vape:CreateNotification("AutoWin",'players found! teleporting to a empty game!',6)
						task.wait((6 / 3.335))
						Reset()
					else
						repeat task.wait(0.1) until store.equippedKit ~= '' and store.matchState ~= 0 or (not NewAutoWin.Enabled)
						MethodOne()
					end
				elseif Methods.Value == "Method 2" then
					local AutoFarmUI = create("ScreenGui",{Name='AutowinUI',Parent=lplr.PlayerGui,IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=999})
					local AutoFarmFrame = create("Frame",{Name='AutoFarmFrame',BackgroundColor3=Color3.fromRGB(15,15,15),Size=UDim2.fromScale(1,1),Parent=AutoFarmUI})
					local Title = create("TextLabel",{TextColor3=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value),Parent=AutoFarmFrame,BackgroundTransparency=1,Position=UDim2.fromScale(0.396,0.264),Size=UDim2.fromOffset(322,125),Text='AUTOWIN',FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.SemiBold,Enum.FontStyle.Italic),TextSize=32,TextScaled=true})
					local TooltipText = create("TextLabel",{TextColor3=Color3.fromHSV(vape.GUIColor.Hue,vape.GUIColor.Sat,vape.GUIColor.Value),Parent=AutoFarmFrame,BackgroundTransparency=1,Position=UDim2.fromScale(0.435,0.596),Size=UDim2.fromOffset(200,50),Text='...',FontFace=Font.new('rbxasset://fonts/families/Arimo.json',Enum.FontWeight.Medium,Enum.FontStyle.Italic),TextSize=48})
					create("UIStroke",{Color=Color3.fromRGB(56,56,56),Thickness=2.1,Transparency=0.22,Parent=Title})
					create("UIStroke",{Color=Color3.fromRGB(56,56,56),Thickness=2.1,Transparency=0.22,Parent=TooltipText})
					local num = math.floor((3 / 1.85))
					TooltipText.Text = `checking if in empty game... ({num}s)`
					task.wait((3 / 1.85))
					if #playersService:GetChildren() ~= 1 then
						num = math.floor((6 / 3.335))
						TooltipText.Text = `player's found. Teleporting to a Empty Game.. ({num}s)`
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						task.wait((6 / 3.335))
						Reset()
					else
						repeat task.wait(0.1) until store.equippedKit ~= '' and store.matchState ~= 0 or (not NewAutoWin.Enabled)
						MethodTwo(TooltipText)
					end
					
				elseif Methods.Value == 'Method 3' then
					local tips = {
						"you can always be afk while you farm...",
						"this is a tip lol...",
						'you can always sleep while afk farming...',
						'you have 2 other methods for auto farm...',
						'this is the most undetected farming and best method out here...',
						'note to bedwars dev/mods FUCK YOU...'
					}
					local lastTip
					local prefix = "tip: "
					local typeSpeed = 0.085
					local eraseSpeed = 0.04
					local waitBetween = 2
					local hidden = true
					local function AccAgeHook(txt)
						task.spawn(function()
							local daysTotal = math.max(lplr.AccountAge, 1)

							local YEARS = 365
							local MONTHS = 30
							local HOURS_IN_DAY = 24

							local years = math.floor(daysTotal / YEARS)
							local remainingDays = daysTotal % YEARS

							local months = math.floor(remainingDays / MONTHS)
							local days = remainingDays % MONTHS

							local hours = daysTotal == 1 and 1 or 0
							local minutes = daysTotal == 1 and 0 or 0

							local parts = {}

							if years > 0 then
								table.insert(parts, years .. (years == 1 and " year" or " years"))
							end

							if months > 0 then
								table.insert(parts, months .. (months == 1 and " month" or " months"))
							end

							if days > 0 then
								table.insert(parts, days .. (days == 1 and " day" or " days"))
							end

							if daysTotal <= 1 then
								table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
								table.insert(parts, minutes .. " minutes")
							end

							local result = table.concat(parts, ", ")
							txt.Text = 'Account age: '..result
						end)
					end

					local function LevelCheckHook(txt)
						task.spawn(function()
							while NewAutoWin.Enabled do
								txt.Text = 'level: '..tostring(lplr:GetAttribute("PlayerLevel")) or "0"
								task.wait(0.01)
							end
						end)
					end
					
					local function LogoBGBGTween(image)
						local MAX = 0.92
						local MIN = 0.84

						local tweenInfo = TweenInfo.new(
							0.96,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						)


						local growTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MAX
						})

						local shrinkTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MIN
						})

						task.spawn(function()
							while NewAutoWin.Enabled do
								growTween:Play()
								growTween.Completed:Wait()

								shrinkTween:Play()
								shrinkTween.Completed:Wait()
							end
						end)
					end

					local function LogoBGTween(image)
						local MAX = 0.95
						local MIN = 0.9

						local tweenInfo = TweenInfo.new(
							0.96,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						)


						local growTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MAX
						})

						local shrinkTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MIN
						})

						task.spawn(function()
							while NewAutoWin.Enabled do
								growTween:Play()
								growTween.Completed:Wait()

								shrinkTween:Play()
								shrinkTween.Completed:Wait()
							end
						end)
					end

					local function Vig1Tween(image)
						local MAX = 1
						local MIN = 0.85

						local tweenInfo = TweenInfo.new(
							1.5,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						)

						local growTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MAX
						})

						local shrinkTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MIN
						})

						task.spawn(function()
							while NewAutoWin.Enabled do
								growTween:Play()
								growTween.Completed:Wait()

								shrinkTween:Play()
								shrinkTween.Completed:Wait()
							end
						end)
					end

					local function Vig2Tween(image)
						local MAX = 0.98
						local MIN = 0.48

						local tweenInfo = TweenInfo.new(
							1.2,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						)


						local growTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MAX
						})

						local shrinkTween = tweenService:Create(image, tweenInfo, {
							ImageTransparency = MIN
						})

						task.spawn(function()
							while NewAutoWin.Enabled do
								growTween:Play()
								growTween.Completed:Wait()

								shrinkTween:Play()
								shrinkTween.Completed:Wait()
							end
						end)
					end

					local function username(txt,btn)
						hidden = not hidden

						if hidden then
							txt.Text = "username: [HIDDEN]"
							btn.BackgroundColor3 = Color3.fromRGB(236, 78, 78)
							btn.Text = 'Reveal user'
						else
							txt.Text = "username: "..lplr.Name
							btn.BackgroundColor3 = Color3.fromRGB(141, 236, 78)
							btn.Text = 'Conceal user'
						end
					end

					local function playTip(txt)
						local index

						if #tips > 1 then
							repeat
								index = math.random(1, #tips)
							until index ~= lastTip
						else
							index = 1
						end

						lastTip = index
						local tipText = tips[index]

						txt.Text = prefix .. tipText
						txt.MaxVisibleGraphemes = #prefix

						for i = #prefix + 1, #prefix + #tipText do
							txt.MaxVisibleGraphemes = i
							task.wait(typeSpeed)
						end

						task.wait(1.5)

						for i = #prefix + #tipText, #prefix, -1 do
							txt.MaxVisibleGraphemes = i
							task.wait(eraseSpeed)
						end

						task.wait(waitBetween)
					end

					local function StartTips(txt)
						task.wait(2)
						task.spawn(function()
							while true do
								playTip(txt)
							end
						end)
					end

					local function PercentUpdate(txt,per,snd)
						per = math.clamp(per, 0, 100)
						txt.Text = tostring(per).."%"
						local MaxPercent = 100
						local NewPercent = (per / MaxPercent)

						local tweenInfo = TweenInfo.new(
							0.3,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.Out
						)


						local tween = tweenService:Create(snd, tweenInfo, {
							Size = UDim2.fromScale(NewPercent, 1)
						})
						tween:Play()
						tween.Completed:Connect(function()
							task.wait(.1)
							tween:Destroy()
						end)
					end

					local function hookcheck(txt,frame)
						task.spawn(function()
							txt:GetAttributeChangedSignal('Percent'):Connect(function()
								PercentUpdate(txt,txt:GetAttribute("Percent"),frame)
							end)
						end)
					end

					local AutoFarmUI = create("ScreenGui",{Name='AutowinUI',Parent=lplr.PlayerGui,IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=999})
					local MainFrame = create("Frame",{Parent=AutoFarmUI,Name='AutoFarmFrame',BackgroundColor3=Color3.fromRGB(25,25,25),Size=UDim2.fromScale(1,1)})
					local PerFrameMain = create("Frame",{BorderSizePixel=0,Parent=MainFrame,Name='LevelFrame',BackgroundColor3=Color3.fromRGB(40,40,45),Position=UDim2.new(0.5,-150,0.5,80),Size=UDim2.fromOffset(300,3),ZIndex=2})
					local PerFrameSecondary = create("Frame",{BackgroundColor3=Color3.fromRGB(215,215,215),BorderSizePixel=0,Parent=PerFrameMain,Name='Secondary',Size=UDim2.fromScale(0,1),ZIndex=3})
					local PercentText = create("TextLabel",{Name='Percent',Parent=PerFrameMain,BackgroundTransparency=1,Position=UDim2.new(0.5,-50,-26.167,50),TextColor3 = Color3.fromRGB(200, 200, 200),BackgroundColor3=Color3.fromRGB(255,255,255),Size=UDim2.fromOffset(100,20),ZIndex=2,Font=Enum.Font.Code,Text='0%',TextSize=12})
					PercentText:SetAttribute("Percent",0)
					create("UIStroke",{Color=Color3.fromRGB(255,255,255),Transparency=0.8,Parent=PerFrameMain})
					local XPFrameTip = create("Frame",{Name='XPFrame',BackgroundTransparency=1,Position=UDim2.fromScale(0.881,0.742),Size=UDim2.fromOffset(184,219),Parent=MainFrame})
					local div = create("Frame",{Parent=XPFrameTip,Name='Divider',BackgroundColor3=Color3.fromRGB(56,56,56),Position=UDim2.fromScale(0.049,0.146),Size=UDim2.fromOffset(168,4)})
					create("UICorner",{Parent = div})
					create("TextLabel",{Name='d1',BackgroundTransparency=1,Position=UDim2.new(0.598,-110,0.288,-30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='(Day 1) > Level 9',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = XPFrameTip})
					create("TextLabel",{Name='d2',BackgroundTransparency=1,Position=UDim2.new(0.598, -110,0.438, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='(Day 2) > Level 13',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = XPFrameTip})
					create("TextLabel",{Name='d3',BackgroundTransparency=1,Position=UDim2.new(0.598, -110,0.589, -30),Size=UDim2.fromOffset(184,44),ZIndex=2,Font=Enum.Font.Code,Text='(Day 3) > Level 16',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = XPFrameTip})
					create("TextLabel",{Name='d4',BackgroundTransparency=1,Position=UDim2.new(0.598, -110,0.79, -30),Size=UDim2.fromOffset(184,43),ZIndex=2,Font=Enum.Font.Code,Text='(Day 4) > Level 19',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = XPFrameTip})
					create("TextLabel",{Name='d5',BackgroundTransparency=1,Position=UDim2.new(0.598, -110,0.986, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='(Day 5) > Level 20(Rank!)',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = XPFrameTip})
					create("TextLabel",{Name='title',BackgroundTransparency=1,Position=UDim2.new(0.598, -110,0.137, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='XP Capped Level\'s',TextColor3=Color3.fromRGB(120,120,120),TextSize=18,TextWrapped=true,Parent = XPFrameTip})
					local LogoBGBG = create("ImageLabel",{Parent=MainFrame,Name='LogoBGBG',BackgroundTransparency=1,Position=UDim2.new(0.5,-120,0.5,-170),Size=UDim2.fromOffset(240,240),Image='rbxassetid://127677235878436',ImageTransparency=0.84})
					local LogoBG = create("ImageLabel",{Parent=LogoBGBG,Name='LogoBG',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image='rbxassetid://127677235878436',ImageTransparency=0.95})
					local Logo = create("ImageLabel",{Parent=LogoBG,Name='Logo',BackgroundTransparency=1,Position=UDim2.new(0.5,-100,0.708,-150),Size=UDim2.fromOffset(200,200),ZIndex=2,Image='rbxassetid://127677235878436'})
					local Vig1 = create("ImageLabel",{Parent=MainFrame,Name='Vig1',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=2,Image='rbxassetid://135131984221448',ImageTransparency=1})
					local Vig2 = create("ImageLabel",{Parent=MainFrame,Name='Vig2',BackgroundTransparency=1,Size=UDim2.fromScale(2,2),Position=UDim2.fromScale(-0.474,-0.02),Rotation=90,ZIndex=2,Image='rbxassetid://135131984221448',ImageTransparency=1})
					local AccAge = create("TextLabel",{Name='AccAge',BackgroundTransparency=1,Position=UDim2.new(0.068, -110,0.873, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='Account age: ',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = MainFrame})
					local Tip = create("TextLabel",{TextXAlignment='Left',Name='Tip',BackgroundTransparency=1,Position=UDim2.new(0.5,-300,1,-40),Size=UDim2.fromOffset(1171,20),ZIndex=2,Font=Enum.Font.Code,Text='tip: ...',TextColor3=Color3.fromRGB(130,130,130),TextSize=10,TextWrapped=true,Parent = MainFrame})
					local Tooltip = create("TextLabel",{Name='Tooltip',BackgroundTransparency=1,Position=UDim2.new(0.5,-200,0.5,100),Size=UDim2.fromOffset(400,30),ZIndex=2,Font=Enum.Font.Code,Text='...',TextColor3=Color3.fromRGB(200,200,200),TextSize=14,TextWrapped=true,Parent = MainFrame})
					local LvL = create("TextLabel",{Name='lvl',BackgroundTransparency=1,Position=UDim2.new(0.068, -110,0.949, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='level: 0',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = MainFrame})
					local Username = create("TextLabel",{Name='user',BackgroundTransparency=1,Position=UDim2.new(0.068, -110,0.911, -30),Size=UDim2.fromOffset(184,33),ZIndex=2,Font=Enum.Font.Code,Text='username: [HIDDEN]',TextColor3=Color3.fromRGB(120,120,120),TextSize=14,TextWrapped=true,Parent = MainFrame})
					local UserButton = create("TextButton",{Name='btn',TextColor3=Color3.fromRGB(255,255,255),BackgroundColor3=Color3.fromRGB(236,78,78),Position=UDim2.new(4.098, 0,0, 0),Size=UDim2.fromOffset(130,26),ZIndex=1,Font=Enum.Font.Code,Text='Reveal user',TextSize=18,Parent = Username})
					create("UICorner",{Parent = UserButton})

					UserButton.Activated:Connect(function()
						username(Username,UserButton)
					end)
					LevelCheckHook(LvL)
					AccAgeHook(AccAge)
					hookcheck(PercentText,PerFrameSecondary)
					LogoBGTween(LogoBG)
					LogoBGBGTween(LogoBGBG)
					Vig1Tween(Vig1)
					Vig2Tween(Vig2)
					StartTips(Tip)
					local num = math.floor((3 / 1.85))
					Tooltip.Text = 'checking if you are in empty game...'
					task.wait((3 / 1.85))
					if #playersService:GetChildren() ~= 1 then
						num = math.floor((6 / 3.335))
						Tooltip.Text = 'player\'s found. Teleporting to a Empty Game..'
						lplr:Kick("Don't disconnect, this will auto teleport you!")
						task.wait((6 / 3.335))
						Reset()
					else
						Tooltip.Text = 'waiting for match to start...'
						repeat task.wait(0.1) until store.equippedKit ~= '' and store.matchState ~= 0 or (not NewAutoWin.Enabled)
						MethodThree(Tooltip,PercentText)
					end
				else
					vape:CreateNotification("AutoWin",'str64 error','warning',5.245)
				end
			
			else
				entitylib.character.Humanoid.Health = -9e9
				if lplr.PlayerGui:FindFirstChild('AutowinUI') then
					lplr.PlayerGui:FindFirstChild('AutowinUI'):Destroy()
				end
			end
		end
	})
	Methods = NewAutoWin:CreateDropdown({
		Name = "Methods",
		List = {'Method 1', 'Method 2','Method 3'},
		Tooltip = 'Method 1 - normal but undetected and fast\nMethod 2 - faster and blocks people who join(with autolobby) and even more undetected!\n Method 3 - same as method 2 but has faster and better player detections'
	})
	gui = NewAutoWin:CreateToggle({
		Name = "Gui",
		Default = true,
		Function = function(v)
			if lplr.PlayerGui:FindFirstChild('AutowinUI') then
				lplr.PlayerGui:FindFirstChild('AutowinUI').Enabled = v
			end
		end
	})
end)
