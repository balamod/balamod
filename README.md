# Balamod

### https://discord.gg/p7DeW7pSzA

~Only working on linux with proton for now.~  
~I'll try to make it work on windows soon :)~  
  
Working on windows too :)

# Easy install 
## Linux
```bash
./balamod -a
```
## Windows
```cmd
balamod.exe -a
```

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

### Decompile the game
```bash
./balamod -d
```
You can use the `-o` flag to specify the output directory

### Iject file into the game
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

### Implement the mod loader
```bash
./balamod -m
```
By default, the file is `Balatro.lua` but you can specify it with the `-i` flag

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
                local to_replace = 'arg_616_3 = arg_616_3 or 1'
                local replacement = 'arg_616_3 = ' .. planet_multiplicator_strength
                local fun_name = "level_up_hand"

                inject(fun_name, to_replace, replacement)
            end,
            on_disable = function()
                local replacement = 'arg_616_3 = arg_616_3 or 1'
                local to_replace = 'arg_616_3 = ' .. planet_multiplicator_strength
                local fun_name = "level_up_hand"

                inject(fun_name, to_replace, replacement)
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
Currently *(in 0.1.6)*, the mod loader supports five events:
- `on_pre_update` called before the game update, if you return true, it will cancel the update (ticking)
- `on_post_update` called after the game update
- `on_pre_render` called just before rendering frame functions
- `on_post_render` called before rendering the frame itself
- `on_key_pressed` called when a key is pressed with 3 args (current instance, key name (string), long pressed (bool))

You can register them in your mod like this:
```lua
table.insert(mods,
        {
            mod_id = "test",
            name = "test",
            enabled = true,
            on_enable = function()
            end,
            on_disable = function()
            end,
            on_pre_update = function()
                print("pre update")
                return false
            end,
            on_post_update = function()
                print("post update")
            end
            on_pre_render = function()
                print("pre render")
                return false
            end,
            on_post_render = function()
                print("post render")
            end
            on_key_pressed = function(this, key_name, long_pressed)
                print("pressed " .. key_name)
            end
        }
)
```

These events are not required, you can just remove them from your mod if you don't need them.


## How to find the function names, where to inject code, etc...
You can use the `./balamod -d` command to decompile the game and look at the code.
