local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local _Instance = Instance.new
local Instance = {}
local Proxies = {}
local IsProxyTable = {}
local DefaultPropertieCache = {}

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
function Instance.new(Class,Parent,ApplyGodmode)
	assert(Class ~= nil,"invalid argument #1 to 'new' (string expected got nil)")
	assert(typeof(Class) ~= "boolean","invalid argument #1 to 'new' (string expected got boolean)")
	
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
	
	local Refitting = true
	local SetupInstance
	local Refit
	
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
		Refitting = true
		
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
			if Refitting then
				return
			end
			
			if CustomProperties["Properties"][Name] then
				if Name == "Parent" then
					local _Proxy = CustomProperties["Properties"]["Parent"]
					if _Proxy and IsProxy(_Proxy) then
						if _Proxy["Properties"]["Parent"] ~= _Proxy.Parent then
							_Proxy.Refitted:Wait()
						end
					end
				end
				
				local Changed = false
				if typeof(CustomProperties["Properties"][Name]) == "number" then
					Changed = not CompareNumber(CustomProperties["Properties"][Name],instance[Name])
				elseif typeof(CustomProperties["Properties"][Name]) == "Vector3" then
					if not CompareNumber(CustomProperties["Properties"][Name].X,instance[Name].X) then
						Changed = true
					elseif not CompareNumber(CustomProperties["Properties"][Name].Y,instance[Name].Y) then
						Changed = true
					elseif not CompareNumber(CustomProperties["Properties"][Name].Z,instance[Name].Z) then
						Changed = true
					end
				elseif typeof(CustomProperties["Properties"][Name]) == "CFrame" then
					local P = {CustomProperties["Properties"]["CFrame"]:GetComponents()}
					local I = {instance["CFrame"]:GetComponents()}
					
					for i,v in ipairs(P) do
						if i > 3 then
							if not CompareNumber(v*0.1,I[i]*0.1) then
								Changed = true
								
								break
							end
						end
					end
				else
					if instance[Name] ~= GetValue(CustomProperties["Properties"][Name]) then
						Changed = true
					end
				end
				
				if Changed then
					print(DebugId,Name,"\n",tostring(instance[Name]),"\n",tostring(GetValue(CustomProperties["Properties"][Name])),"\n")
					
					Refit()
				end
			end
		end)
		
		Refitting = false
		Events["Refitted"]:Fire(instance)
		
		if CustomProperties["Properties"]["Parent"] then
			instance.Parent = GetValue(CustomProperties["Properties"]["Parent"])
		end
	end
	
	Meta.__index = function(self,Method,...)
		local Args = ...
		
		if CustomProperties[Method] then
			return CustomProperties[Method]
		end
		
		return instance[Method]
	end
	Meta.__newindex = function(self,Name,Value,...)
		local Args = ...
		
		local suc,err = pcall(function()
			CustomProperties["Properties"][Name] = Value
			if instance:IsA("BasePart") then
				if Name == "Position" then
					local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CustomProperties["Properties"]["CFrame"]:GetComponents()
					CustomProperties["Properties"]["CFrame"] = CFrame.new(Value.X, Value.Y, Value.Z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
				elseif Name == "Orientation" or Name == "Rotation" then
					--[[CustomProperties["Properties"]["CFrame"] = CFrame.new(CustomProperties["Properties"]["CFrame"].X,CustomProperties["Properties"]["CFrame"].Y,CustomProperties["Properties"]["CFrame"].Z) * CFrame.Angles(FloatingPointFix(math.rad(Value.X)),FloatingPointFix(math.rad(Value.Y)),FloatingPointFix(math.rad(Value.Z)))
					
					CustomProperties["Properties"]["Orientation"] = Vector3.new(FloatingPointFix(Value.X),FloatingPointFix(Value.Y),FloatingPointFix(Value.Z))
					CustomProperties["Properties"]["Rotation"] = CustomProperties["Properties"]["Orientation"]]
					
					PropertyPart.CFrame = CustomProperties["Properties"]["CFrame"]
					PropertyPart[Name] = Value
					
					CustomProperties["Properties"]["CFrame"] = PropertyPart.CFrame
					CustomProperties["Properties"]["Orientation"] = PropertyPart.Orientation
					CustomProperties["Properties"]["Rotation"] = PropertyPart.Rotation
				elseif Name == "CFrame" then
					CustomProperties["Properties"]["Position"] = Vector3.new(CustomProperties["Properties"]["CFrame"].X,CustomProperties["Properties"]["CFrame"].Y,CustomProperties["Properties"]["CFrame"].Z)
					
					local Rad_X,Rad_Y,Rad_Z = Value:ToOrientation()
					local X = FloatingPointFix(math.deg(Rad_X))
					local Y = FloatingPointFix(math.deg(Rad_Y))
					local Z = FloatingPointFix(math.deg(Rad_Z))
					
					CustomProperties["Properties"]["Orientation"] = Vector3.new(X,Y,Z)
					CustomProperties["Properties"]["Rotation"] = CustomProperties["Properties"]["Orientation"]
				elseif Name == "Color" then
					CustomProperties["Properties"]["BrickColor"] = BrickColor.new(Value)
				elseif Name == "BrickColor" then
					CustomProperties["Properties"]["Color"] = Value.Color
				end
			end
			
			instance[Name] = GetValue(CustomProperties["Properties"][Name])
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
	
	if Parent then
		Proxy.Parent = Parent
	end
	
	SetupInstance()
	
	return Proxy
end

return Instance,_Instance
