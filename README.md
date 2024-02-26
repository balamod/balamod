# Balamod

Modloader/Injector/Decopiler that support ingame code injection for Balatro

![Discord Banner 2](https://discordapp.com/api/guilds/1185706070656688128/widget.png?style=banner2)

~~Only working on linux with proton for now.~~
  
Working on windows too :)

# Easy install 
## Linux
```bash
./balamod -a
```
## Windows
If you don't know how to use a command line, put balamod.exe and [this file](https://github.com/UwUDev/balamod/blob/master/One%20click%20install.cmd) in the same folder and run the .cmd file.

You can also use the command line:

```cmd
balamod.exe -a
```

[How to use code injection](#how-to-use-code-injection)

## How to install mods

Just put your mods in the `mods` folder and your api in the `apis` folder on `%appdata%/balatro` or `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro` for linux.

## Cli usage

At first, Balamod will try to find all your Balatro installation.
If one is found, it will be used as the default installation.
If you have multiple installations, a prompt will ask you to choose one.
If no installation is found, you will be asked to specify one with the `-b` flag.

### basic help
```bash
./balamod --help
```

### Full auto-injection of the mod loader
```bash
./balamod -a
```

### Inject file into the game
```bash
./balamod -x -i <file> -o <game_file_name>
```
example to patch an asset file
```bash
./balamod -x -i balatro.png -o ressources/textures/x4/balatro.png
```
If you want to inject game code, you need to compress it with -c
Example to inject a lua file:
```bash
./balamod -x -c -i Balatro.lua -o DAT1.jkr
```

### Decompile the game
```bash
./balamod -d
```

Decompile to a custom folder:
```bash
./balamod -d -o MyCustomFolder
```


## Modding
Once the mod loader is in your game, next time you will launch it, it will create an `apis` and `mods` folder.
The `apis` folder is where you can put your api files, and it will load and inject them into the game **before** any mod.
The `mods` folder is where you can put your mods.

### Modding API
Here is an example mod that changes the Planet cards value:
```lua
planet_multiplicator_strength = '998'

table.insert(mods,
        {
            mod_id = "planets_multiplicator",
            name = "Planets Multiplicator",
            enabled = true,
            on_enable = function()
                local to_replace = 'amount = amount or 1'
                local replacement = 'amount = ' .. planet_multiplicator_strength
                local fun_name = "level_up_hand"
                local file_name = "functions/common_events.lua"

                inject(file_name, fun_name, to_replace, replacement)
            end,
            on_disable = function()
                local replacement = 'amount = amount or 1'
                local to_replace = 'amount = ' .. planet_multiplicator_strength
                local fun_name = "level_up_hand"
                local file_name = "functions/common_events.lua"

                inject(file_name, fun_name, to_replace, replacement)
            end,
        }
)
```

For modding, you can edit in game values on the on enable function and revert them on the on disable function.
You can also inject/remove code into the game with the `inject` function.

The `inject` function take three arguments:
- The function name
- The code to replace (lua pattern)
- The replacement code (string)

The `inject` function will replace the first occurence of the pattern in the desired function allowing you to inject code anywhere in the game.
If you want to replace code outside a function, you can use classic overring.

### Events
Currently *(in 0.1.9)*, the mod loader supports seven events:
- `on_pre_update` called before the game update, if you return true, it will cancel the update (ticking)
- `on_post_update` called after the game update
- `on_pre_render` called just before rendering frame functions
- `on_post_render` called before rendering the frame itself
- `on_key_pressed` called when a key is pressed with the [key name](https://love2d.org/wiki/KeyConstant)
- `on_pre_load` called before the game load
- `on_mouse_pressed` called when a mouse button is pressed, with the x and y position and the button

You can register them in your mod like this:
```lua
-- sendDebugMessage() function is a custom function from dev tools api

table.insert(mods,
        {
            mod_id = "test",
            name = "test",
            enabled = true,
            on_pre_load = function()
            end,
            on_enable = function()
            end,
            on_disable = function()
            end,
            on_pre_update = function()
                sendDebugMessage("pre update")
                return false -- use true to cancel the update
            end,
            on_post_update = function()
                sendDebugMessage("post update")
            end,
            on_pre_render = function()
                sendDebugMessage("pre render") 
                return false -- use true to cancel the rendering
            end,
            on_post_render = function()
                sendDebugMessage("post render")
            end,
            on_key_pressed = function(key_name)
                sendDebugMessage("pressed " .. key_name)
            end,
            on_mouse_pressed = function(x, y, button, touches)
                sendDebugMessage("pressed " .. button .. " at " .. x .. " " .. y)
                return false -- use true to cancel the event
            end
        }
)
```

These events are not required, you can just remove them from your mod if you don't need them.

## How to use code injection

Balamod codes with the smallest possible API that supports mods and API loader. But also there is a bundle API that allows you to "hot swap" code while the game is running.

Before starting the game, balamod will retrieve all the code from and store it in a map where one file = one key. This makes it possible to know the current state of the game code and to overwrite parts of the code loaded by the engine.

To use it you need 3 element:
- The lua file where you want to inject your code
- The function name
- The part of the code you want to replace

For that I'll quickly explain with the example of the [mod](#modding-api) that changes the multiplactor of planet cards.

the `inject` function takes 4 parameters which are the 3 points seen above and the new code as 4th parameter. In the mod, it replaces the part that manages the number of cards to be activated very simply like that:
```lua
local to_replace = 'amount = amount or 1' -- old code
local replacement = 'amount = ' .. planet_multiplicator_strength -- new code
local fun_name = "level_up_hand"
local file_name = "functions/common_events.lua"

inject(file_name, fun_name, to_replace, replacement)
```

## How to find the function names, where to inject code, etc...
You can use the `./balamod -d` command to decompile the game and look at the code.
