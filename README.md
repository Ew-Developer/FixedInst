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

# Info

The "_Instance" value is the real Instance.new, it can be used as an aternative to Instance.new("Part",workspace,false). As both wont apply godmode to the instance.
