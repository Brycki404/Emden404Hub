# EmdenHub
A Script Hub for a game called Emden or something for my close friends that wanted it. I think the game is boring but whatever.

Copy and paste this into your lua environment to load the script:
```lua
local TryGet = game.HttpGet or game.HttpGetAsync or nil
assert(TryGet, "No Http GET function found. This script is unavailable for your lua environment.")
loadstring(TryGet(game, "https://raw.githubusercontent.com/CatOnEdge/EmdenHub/refs/heads/main/main.lua", true))()
```
It will print out an error if your lua environment can't run loadstring from a GitHub.
