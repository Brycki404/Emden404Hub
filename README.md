# Emden404Hub
A Script Hub for a game called Emden or something for my close friends that wanted it. I think the game is boring but whatever.

Copy and paste this into your executor to load the script:
```lua
local TryGet = game.HttpGet or game.HttpGetAsync or nil
assert(TryGet, "No Http GET function found. This script is unavailable for your executor.")
loadstring(TryGet(game, "https://raw.githubusercontent.com/Brycki404/BetterLib/refs/heads/main/main.lua", true))()
```
It will print out an error if your executor can't run loadstring from a GitHub.
