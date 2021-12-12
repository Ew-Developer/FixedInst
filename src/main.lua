local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local _Instance = Instance.new
local Instance = {}
local Proxies = {}
local IsProxyTable = {}
local DefaultPropertieCache = {}

function IsDestroyed(i)
	if i.Parent then
		return false
	end
	local s,Destroyed = pcall(function()
		i.Parent = i
	end)
	if s or not Destroyed then
		return false
	else
		return not string.match(Destroyed,"Attempt to set .+ as its own parent")
	end
end
function GetProperties()
	local httpService = game:GetService("HttpService")
	local worked, apiDump = pcall(function()
		return httpService:GetAsync("https://rapidump.ulkonmogo.repl.co")
	end)
	if not worked then
		return error("Unable to get api dumb.\n"..tostring(apiDump))
	end
	apiDump = httpService:JSONDecode(apiDump)

	local classes = {}
	for i, v in next, apiDump.Classes do
		classes[v.Name] = v
	end

	local disallowedProperties = {
		"archivable",
		"Archivable",
		"className",
		"ClassName",
		"focus",
		"CoordinateFrame",
		"TextColor",
		"RobloxLocked",
		"robloxLocked",
		"AbsoluteSize",
		"AbsolutePosition",
		"Occupant",
		"WorldPivot",
	}
	local disallowedCategories = {
		"Derived World Data",
	}
	local disallowedValueTypes = {
		"BrickColor",
	}

	local Properties = {} do
		for classname, class in next, classes do
			if not (class.Tags and table.find(class.Tags, "NotCreatable")) or not class.Tags then
				local props = {}
				local function AddProps(members)
					for _, member in next, members do
						if member.MemberType == "Property" and not table.find(disallowedProperties, member.Name) then
							local doFunny = true
							if member.ThreadSafety == "Unsafe" or member.Security.Read ~= "None" or member.Security.Write ~= "None" then
								doFunny = false
							end
							if member.Tags then
								if table.find(member.Tags, "ReadOnly") or table.find(member.Tags, "Deprecated") or table.find(member.Tags, "Hidden") or table.find(member.Tags, "NotScriptable") then
									doFunny = false
								end
							end
							if table.find(disallowedValueTypes, member.ValueType.Name) or table.find(disallowedCategories, member.Category) or member.Name:find(" ") then
								doFunny = false
							end
							if doFunny and not table.find(props, member.Name) then
								table.insert(props, member.Name)
							end
						end
					end
				end

				AddProps(class.Members)

				local currentClass = class.Superclass

				while true do
					if not currentClass or currentClass == "<<<ROOT>>>" then
						break
					end
					local _class = classes[currentClass]
					if _class.Members then
						AddProps(_class.Members)
					end
					currentClass = _class.Superclass
				end

				table.sort(props)
				Properties[classname] = props
			end
		end
	end

	return Properties
end
local PropertyData = GetProperties()

function GetDefaultProperties(Class,obj)
	if DefaultPropertieCache[Class] then return DefaultPropertieCache[Class] end
	local DefaultProperties = nil
	
	local _Properties = PropertyData[Class]
	if _Properties and #_Properties > 0 then
		DefaultProperties = {}
		
		for _,n in ipairs(_Properties) do
			DefaultProperties[n] = obj[n]
		end
	end
	
	if DefaultProperties then
		DefaultPropertieCache[Class] = DefaultProperties
	end
	return DefaultProperties
end
function IsProxy(Proxy)
	return IsProxyTable[Proxy] == true
end
function GetValue(Value)
	return IsProxy(Value) and Value.Instance or Value
end
function FloatingPointFix(n)
	return math.round(n * 10000) * 0.0001
end
function CompareNumber(n1,n2)
	return FloatingPointFix(n1) == FloatingPointFix(n2)
end

local DebugIdCount = 0
local PropertyPart = _Instance("Part",nil)
Instance.debug = false
function Instance.new(Class,Parent,ApplyGodmode)
	assert(typeof(Class) == "string","invalid argument #1 to 'new' (string expected got "..tostring(typeof(Class))..")")
	
	local SetEnabled = false
	if Class == "Part" then
		Class = "SpawnLocation"
		SetEnabled = true
	end
	local instance = _Instance(Class)
	DebugIdCount = DebugIdCount + 1
	local DebugId = DebugIdCount
	
	if ApplyGodmode == nil then
		ApplyGodmode = true
	end
	if ApplyGodmode == false then
		if Parent then
			instance.Parent = Parent
		end
		
		return instance
	end
	
	local DefaultProperties = GetDefaultProperties(Class,instance)
	
	local SetupInstance
	local Refit
	
	local CanChange = {}
	
	local CustomProperties
	local Events
	Events = {
		["Refitted"] = _Instance("BindableEvent");
	}
	CustomProperties = {
		["Born"] = tick();
		["LastRefit"] = tick();
		["DebugId"] = DebugId;
		["Properties"] = {};
		
		["Instance"] = nil;
		["Alive"] = true;
		["Refitting"] = true;
		
		["Destroy"] = function()
			CustomProperties["Alive"] = false
			return instance:Destroy()
		end;
		["Refit"] = function()
			return Refit()
		end;
		["ClearAllChildren"] = function()
			for _,c in ipairs(instance:GetChildren()) do
				pcall(function()
					if Proxies[c] then
						Proxies[c]:Destroy()
					else
						c:Destroy()
					end
				end)
			end
		end;
	}
	for n,v in pairs(DefaultProperties) do
		CustomProperties["Properties"][n] = v
	end
	if SetEnabled then
		CustomProperties["Properties"]["Enabled"] = false
	end
	
	for Name,Value in pairs(Events) do
		CustomProperties[Name] = Value.Event
	end
	
	local Proxy = newproxy(true)
	local Meta = getmetatable(Proxy)
	
	IsProxyTable[Proxy] = true
	
	local ChangedEvent = nil
	
	Refit = function()
		CustomProperties["Refitting"] = true
		
		if ChangedEvent then
			ChangedEvent:Disconnect()
		end
		--[[if CustomProperties["Properties"]["Parent"] and IsProxy(CustomProperties["Properties"]["Parent"]) then
			if CustomProperties["Properties"]["Parent"].Alive == false then
				CustomProperties["ClearAllChildren"]()
				CustomProperties["Destroy"]()
			end
			return
		end]]
		
		local Descendants = instance:GetDescendants()
		
		if instance then
			instance:ClearAllChildren()
			Debris:AddItem(instance,0)
		end

		instance = _Instance(Class)
		SetupInstance()
		
		for _,d in ipairs(Descendants) do
			pcall(function()
				if Proxies[d] then
					Proxies[d]:Refit()
				end
			end)
		end
	end
	SetupInstance = function()
		if ChangedEvent then
			ChangedEvent:Disconnect()
		end
		
		if CustomProperties["Alive"] == false then
			instance:Destroy()
			return
		end
		
		CustomProperties["Instance"] = instance
		CustomProperties["LastRefit"] = tick()
		Proxies[instance] = Proxy
		
		table.clear(CanChange)
		for Name,Value in pairs(CustomProperties["Properties"]) do
			if Name ~= "Parent" then
				pcall(function()
					instance[Name] = GetValue(Value)
				end)
			end
		end
		
		ChangedEvent = instance.Changed:Connect(function(Name)
			if CustomProperties["Alive"] == false then
				if ChangedEvent then
					ChangedEvent:Disconnect()
				end
				
				instance:Destroy()
				return
			end
			if CustomProperties["Refitting"] then
				return
			end
			if CanChange[Name] == true then
				CanChange[Name] = false
				return
			end
			local _Proxy = CustomProperties["Properties"]["Parent"]
			if _Proxy and IsProxy(_Proxy) then
				if _Proxy.Refitting then
					return
				end
			end
			
			if CustomProperties["Properties"][Name] and instance[Name] ~= CustomProperties["Properties"][Name] then
				if Instance.debug == true then
					print(DebugId,Name,"\n",tostring(instance[Name]),"\n",tostring(GetValue(CustomProperties["Properties"][Name])),"\n")
				end
				
				Refit()
			end
		end)
		
		CustomProperties["Refitting"] = false
		Events["Refitted"]:Fire(instance)
		
		if CustomProperties["Properties"]["Parent"] then
			CanChange["Parent"] = true
			pcall(function()
				instance.Parent = GetValue(CustomProperties["Properties"]["Parent"])
			end)
		end
	end
	
	Meta.__index = function(self,Method,...)
		local Args = ...
		
		if CustomProperties[Method] ~= nil then
			return CustomProperties[Method]
		end
		
		return instance[Method]
	end
	Meta.__newindex = function(self,Name,Value,...)
		local Args = ...
		if Name == "Name" and Value ~= tostring(DebugId) then
			return
		end
		
		local suc,err = pcall(function()
			local Allow = {}
			
			Allow[Name] = true
			if instance:IsA("BasePart") then
				if Name == "Position" then
					Allow["CFrame"] = true
				elseif Name == "Orientation" or Name == "Rotation" then
					Allow["CFrame"] = true
					Allow["Orientation"] = true
					Allow["Rotation"] = true
				elseif Name == "CFrame" then
					Allow["Position"] = true
					Allow["Orientation"] = true
					Allow["Rotation"] = true
				elseif Name == "Color" then
					Allow["BrickColor"] = true
				elseif Name == "BrickColor" then
					Allow["Color"] = true
				end
			end
			
			for n,_ in pairs(Allow) do
				CanChange[n] = true
			end
			CustomProperties["Properties"][Name] = Value
			instance[Name] = GetValue(CustomProperties["Properties"][Name])
			for n,_ in pairs(Allow) do
				CanChange[n] = false
			end
		end)
		
		if not suc then
			error("Unable to set '"..tostring(Name).."' to '"..tostring(GetValue(Value)).."' ("..tostring(err or "Unknown")..")")
		end
		
		return self
	end
	Meta.__call = function(self,Method,...)
		return instance(Method,...)
	end
	Meta.__len = function(self)
		return instance
	end
	
	SetupInstance()
	
	if Parent then
		Proxy.Parent = Parent
	end
	Proxy.Name = tostring(DebugId)
	
	return Proxy
end

return Instance,_Instance
