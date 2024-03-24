# Getting Started

This chapter will guide you how to use more functionalities of Balamod. Such as decompiling and code injection the game.

Balatro is a game that is written in Lua with the [LÖVE](https://love2d.org/) framework. The game is compressed into a single executable file. Balamod can easily decompile the game or inject code into it.

~~~admonish note
Sometimes, the game will be updated, and the decompiled files will be outdated. You need to decompile the game again to get the latest files.
~~~

## Balamod CLI

Balamod CLI is a command-line interface that allows you to interact with the game. You can decompile the game, inject code into it, and more.

Use the following command to see the available commands:

```bash
$ ./balamod --help
Usage: balamod [OPTIONS]

Options:
  -x, --inject
  -b, --balatro-path <BALATRO_PATH>
  -c, --compress
  -a, --auto
  -d, --decompile
  -i, --input <INPUT>
  -o, --output <OUTPUT>
  -u, --uninstall
  -h, --help                         Print help
  -V, --version                      Print version
```

## Decompiling

Use the following command to decompile the game, this will generate `decompiled` folder with the decompiled game lua files:

```bash
./balamod -d
```

Also, you can specify the output folder:

```bash
./balamod -d -o output
```

## Injecting

This is useful when you want to pack your modifications back into the game. Use the following command to inject the game:

```bash
./balamod -x -i <file_to_injected> -o <file_destination>
```

The `file_to_injected` is the path to the file that you want to inject, and the `file_destination` is where the file originally located in game.

For example, if you want to inject the `UI_definitions.lua` file, you can use the following command:

```bash
./balamod -x -i ./my_decompiled_files/functions/UI_definitions.lua -o functions/UI_definitions.lua
```

## Uninstall

If the modloader crashes the game, or any other reason, you want to uninstall the modloader. 

You can restore Balatro game with Steam by verifying the integrity of the game files.

Do it by following these steps:

Steam > Library > Right-click Balatro > Properties > Local Files > Verify Integrity of Game Files