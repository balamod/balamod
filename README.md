# Balamod

Mod loader, Injector and Decompiler that supports **in-game code injection for Balatro**

[![Balamod Discord](https://discordapp.com/api/guilds/1185706070656688128/widget.png?style=banner2)](https://discord.gg/p7DeW7pSzA)

# Summary
- [Balamod](#balamod)
- [Summary](#summary)
- [Easy Install](#easy-install)

- [How to Install Mods](#how-to-install-mods)
- [CLI Usage](#cli-usage)
  - [Example of usages](#example-of-usages)
- [Modding](#modding)
  - [How to Use Code Injection](#how-to-use-code-injection)
  - [How to find the function names, where to inject code, etc...](#how-to-find-the-function-names-where-to-inject-code-etc)

# Easy Install
> [!IMPORTANT]
> **Balamod** currently don't work on macOS i86, but it will work on ARM64 aka M1/M2/M3.

Balamod has now a [GUI installer](https://github.com/balamod/balamod-gui/releases/latest)

## How to Install Mods

Yon can directly install mods from the in game mod menu or just put your mods in the `mods` folder
- **Windows**: `C:\Users\<username>\AppData\Roaming\Balatro` aka `%APPDATA%\Balatro`
- **macOS**: `~/Library/Application Support/Balatro`
- **Linux**: `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro`

## CLI Usage

Initially, Balamod searches for all Balatro installations.
If a single installation is found, it becomes the default.
For multiple installations, a prompt will allow you to select one.
In case no installation is detected, you will be prompted to specify one using the `-b` flag.

> [!WARNING]
> Since balamod is now fully external, the usage of -x should not be used anymore.

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
    ./balamod -x -i balatro.png -o ressources/textures/x2/balatro.png
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

Documentation moved to [balamod.github.io](https://balamod.github.io/modding-basics.html)

For a complete example see [example-mod](https://github.com/balamod/example-mod) which shows events, api, injection and a github action for release

## How to Use Code Injection

Before the game starts, Balamod will retrieve all the code and store it in a map where one file equals to one key. It allows Balamod to know the current state of the game code, and to overwrite parts of it already loaded by the engine.

To use it, you will need 3 elements:
- The Lua file where you want to inject your code,
- The function name,
- The part of the code you want to replace.


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
