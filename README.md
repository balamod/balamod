# Balamod

A modloader, injector and decompiler written in Rust that supports in-game code
injection for *Balatro*.

[![Balamod Discord](https://discordapp.com/api/guilds/1185706070656688128/widget.png?style=banner2)](https://discord.gg/p7DeW7pSzA)

# Table of Contents
- [Installation](#installation)
  - [Releases](#releases)
  - [Installing from source](#installing-from-source)
  - [GUI Installer](#gui-installer)
- [Installing Mods](#installing-mods)
- [Usage](#usage)
  - [Decompilation](#decompilation)
  - [Using injected code](#using-injected-code)
  - [Examples](#examples)

# Installation
> [!IMPORTANT]
> **Balamod** currently doesn't work on x86 macOS systems, but it works fine on
ARM64 systems (aka M1/M2/M3).

## Releases

Compiled executable files are provided for x86 Linux and Windows systems for 
[the latest releases](https://github.com/balamod/balamod/releases/latest).
If these do not work on your system, try
[installing from source](#installing-from-source).

## Installing from source

1. If you don't have Rust,
[install it here](https://rust-lang.org/tools/install/).

1. Go to
[the latest release page](https://github.com/balamod/balamod/releases/latest).
and download the source code, either as a zip file or a tarball. Extract it to 
the directory of your choice, and open a terminal in the directory.

1. Run the following commands to build `balamod`:
```bash
cargo build --release
cargo install --path .
```
This will compile the program for your system and install it for use.

## GUI installer

Balamod also has a
[GUI installer](https://github.com/balamod/balamod-gui/releases/latest)
for those who dislike using the command line.

# Installing mods

You can directly install mods from the in game mod menu or just put your mods in
the appropriate `mods` folder:

- **Windows**: `C:\Users\<username>\AppData\Roaming\Balatro` aka `%APPDATA%\Balatro`
- **macOS**: `~/Library/Application Support/Balatro`
- **Linux**: `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro`

# Usage

Initially, Balamod searches for all Balatro installations. If a single installation 
is found, it becomes the default. If multiple installations are found, you will 
be prompted to select one. If no installation is detected, you will be prompted 
to specify one using the `-b` flag.

The modding documentation has been moved to
[balamod.github.io](https://balamod.github.io/modding-basics.html).
For a complete example see
[example-mod](https://github.com/balamod/example-mod)
which shows events, api, injection, and a GitHub release workflow.

## Decompilation

You can use the `./balamod d` command to decompile the game and take a look at 
the game's Lua code when developing mods.

## Using injected code

Before the game starts, Balamod will retrieve all the code and store it in a map 
where one file equals to one key. It allows Balamod to know the current state of 
the game code, and to overwrite parts of it already loaded by the engine.

To use it, you will need 3 elements:
- The Lua file where you want to inject your code,
- The function name,
- The part of the code you want to replace.

## Examples

### Show the full help menu

```bash
./balamod --help
```

### Auto-inject the modloader

```bash
./balamod a
```

> [!WARNING]
> Since balamod is now fully external, the usage of `balamod x` is discouraged and should 
not be used anymore.

### Inject a file into the game **(DEPRECATED)**

```bash
./balamod x -i <file> -o <game_file_name>
```

### Patch an asset file using the injector

```bash
./balamod x -i balatro.png -o resources/textures/x2/balatro.png
```

### Decompile the game

```bash
./balamod d
```

### Inject a Lua file:

> [!IMPORTANT]
> If you want to inject game code, you will need to compress it with `c`

```bash
./balamod x c -i Balatro.lua -o DAT1.jkr
```

The `inject` function takes 4 parameters which are the 3 elements seen above and the new code as 4th parameter. In the mod, it replaces the part that manages the number of cards to be activated very simply like that:
```lua
local to_replace = 'amount = amount or 1' -- old code
local replacement = 'amount = ' .. planet_multiplicator_strength -- new code
local fun_name = "level_up_hand"
local file_name = "functions/common_events.lua"

inject(file_name, fun_name, to_replace, replacement)
```
