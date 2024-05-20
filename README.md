# Balamod

Mod loader, Injector and Decompiler that supports **in-game code injection for Balatro**

[![Balamod Discord](https://discordapp.com/api/guilds/1185706070656688128/widget.png?style=banner2)](https://discord.gg/p7DeW7pSzA)

# Summary
- [Balamod](#balamod)
- [Summary](#summary)
- [Easy Install](#easy-install)
    - [Linux](#linux)
    - [Windows](#windows)
    - [MacOS](#macos)
    - [How to Install Mods](#how-to-install-mods)
    - [CLI Usage](#cli-usage)
        - [Example of usages](#example-of-usages)
    - [Modding](#modding)
        - [Modding API](#modding-api)
        - [Events](#events)
    - [How to add you mods to the repos](#how-to-add-you-mods-to-the-repos)
    - [How to Use Code Injection](#how-to-use-code-injection)
    - [How to find the function names, where to inject code, etc...](#how-to-find-the-function-names-where-to-inject-code-etc)

# Easy Install
> [!IMPORTANT]
> **Balamod** currently don't work on macOS i86, but it will work on ARM64 aka M1/M2/M3.
## Linux

```bash
./balamod-v0.1.11-linux -a
```
## Windows

```cmd
balamod-v0.1.11-windows.exe -a
```

## MacOS

Double click the downloaded installer, which will install `balamod` in `/usr/bin/local` by default,
after you went through the installation process.
Then, in a terminal, run :
```bash
balamod -a
```

If `/usr/local/bin` is not in your `PATH` environment variable, you can run balamod like so:

```bash
PATH=/usr/local/bin balamod -a
```

## How to Install Mods

Just put your mods in the `mods` folder, and your API in the `apis` folder on `%appdata%/balatro` for Windows, or `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro` for Linux.

## CLI Usage

Initially, Balamod searches for all Balatro installations.
If a single installation is found, it becomes the default.
For multiple installations, a prompt will allow you to select one.
In case no installation is detected, you will be prompted to specify one using the `-b` flag.

### Example of usages
- Basic Help

    ```bash
    ./balamod --help
    ```
- Full Auto-Injection of the Mod Loader

    ```bash
    ./balamod -a
    ```
- Injecting a File into the Game

    ```bash
    ./balamod -x -i <file> -o <game_file_name>
    ```
- Example to patch an asset file

    ```bash
    ./balamod -x -i balatro.png -o ressources/textures/x4/balatro.png
    ```
- Decompiling the game

    ```bash
    ./balamod -d
    ```
  or to decompile it into multiple folders,
    ```bash
    ./balamod -d -o MyCustomFolder
    ```

If you want to inject game code, you will need to compress it with -c
Example to inject a Lua file:
```bash
./balamod -x -c -i Balatro.lua -o DAT1.jkr
```

## Modding
Once the mod loader is in your game, the next time you will launch it, it will create two folders named `apis` and `mods`.
The `apis` folder is where you can put your API files, then it will load and inject them into the game **before** mods.
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

For modding, you can edit in-game values on the `on enable` function and revert them on the `on disable` function.
You can also inject code into the game or remove code from the game with the `inject` function.

The `inject` function takes three arguments:
- The function name
- The code to replace (Lua pattern)
- The replacement code (string)

The `inject` function will replace the first occurence of the pattern in the desired function allowing you to inject code anywhere in the game.
If you want to replace code outside a function, you can use classic overring.

### Events
Currently *(in 0.1.11)*, the mod loader supports 7 events:
- `on_pre_update` is called before the game update, if true is returned, it will cancel the update (ticking)
- `on_post_update` is called after the game update
- `on_pre_render` is called just before rendering frame functions
- `on_post_render` is called before rendering the frame itself
- `on_key_pressed` is called when a key is pressed with the [key name](https://love2d.org/wiki/KeyConstant)
- `on_pre_load` is called before the game loads
- `on_mouse_pressed` is called when a mouse button is pressed, with the `x` and `y` position, and the button

You can register the events in your mod like this:
```lua
-- sendDebugMessage() function is a custom function from dev tools API

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

These events are not required, you can remove them from your mod if you don't need them.

## How to add you mods to the repos
There's now a rest or "marketplace" system integrated directly into balamod via the mod menu. You can add your mods via the [indexes](https://github.com/UwUDev/balamod/blob/master/repos.index)

For the moment there's only one because I'm going to try and regulate malicious mods and the like, but there's bound to be many more in the future.

If you want to add your mod to an index, make a pull request to the index and add your mod to the bottom of the `mods.index` file.

The format is as follows:
```
mod_id|version|name|description|url
```

> [!WARNING]
> Your mod need to have an id that is unique, and the version

All the files in the current folder and subfolders *(based on the url path)* will be added to the Balatro AppData folder.


## How to Use Code Injection

> Balamod is designed to be lightweight and make minimal changes to the original source code. There is a bundle API that allows you to "hot swap" code while the game is running.

Before the game starts, Balamod will retrieve all the code and store it in a map where one file equals to one key. It allows Balamod to know the current state of the game code, and to overwrite parts of it already loaded by the engine.

To use it, you will need 3 elements:
- The Lua file where you want to inject your code,
- The function name,
- The part of the code you want to replace.

For that, I'll quickly explain with [this example](#modding-api) that changes the multiplactor of Planet cards.

The `inject` function takes 4 parameters which are the 3 elements seen above and the new code as 4th parameter. In the mod, it replaces the part that manages the number of cards to be activated very simply like that:
```lua
local to_replace = 'amount = amount or 1' -- old code
local replacement = 'amount = ' .. planet_multiplicator_strength -- new code
local fun_name = "level_up_hand"
local file_name = "functions/common_events.lua"

inject(file_name, fun_name, to_replace, replacement)
```

## How to find the function names, where to inject code, etc...
You can use the `./balamod -d` command to decompile the game and take a look at the code.