# FixedInst
Makes all your parts created with Instance.new have godmode. Meaning that they cant be changed from how your script has set them to be.

# How to use
Your script needs to have http access and loadstring to use this in one line
```lua
local Instance,_Instance = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Ew-Developer/FixedInst/main/src/main.lua"))()
```

If you dont have http acces or dont have loadstring access, you can apply the source of FixedInst to your project. But you have to remove the return in it.
You can find the source at https://raw.githubusercontent.com/Ew-Developer/FixedInst/main/src/main.lua

Thats it!
Now when you do
```lua
local Part = Instance.new("Part",workspace)
Part.Anchored = true
Part.CFrame = CFrame.new(10,3,10)
```
Then it will create an anchored part in workspace that their cframe is at 10, 3, 10. And it will have godmode so other scripts cant unanchor it or move it.

You can also do "Instance.debug = true" to turn on debug mode. In debug mode it will print when a parts property has changed.
Example:
```
1 Parent
nil
Workspace
```
The "1" is the debug id of the part (the id an instance if given when created), "Parent" is the property that got changed. "Nil" is what the property currently is, and "Workspace" is what it wants it to be.

# Custom properties
The instance will have custom properties, heres a list of them:
- Born

The tick the instance was created at
- LastRefit

The tick the instance was last refitted at
- DebugId

The DebugId the instance has, a number
- Properties

An dictionary of all properties the instance is expected to have
- Instance

The real instance, the thing your script gets is an proxy
- Alive

If the instance is alive and its godmode is active

# Custom functions
It also has some custom functions, hers a list of them:
- Destroy

Destroys the part and removes the godmode
- Refit

Makes the instance refit
- ClearAllChildren

Destroys all parts in it, if any of the parts have godmode on them, it will remove it

# Info

The "_Instance" value is the real Instance.new, it can be used as an alternative to Instance.new("Part",workspace,false). As both wont apply godmode to the instance.
