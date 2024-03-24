# Contributing Guide

This guide is intended to help you get started with contributing to the game. If you have any questions, feel free to ask in the [Discord server](https://discord.gg/p7DeW7pSzA).

## Creating a Pull Request

1. Fork the repository.
2. Clone the forked repository to your local machine.
3. Create a new branch for your changes.
4. Make your changes.
5. Commit your changes.
6. Push the changes to your fork.
7. Create a pull request.

## Add mods to the in-game mod shop

There's now a rest or "marketplace" system integrated directly into balamod via the mod menu. You can add your mods via the [indexes](https://github.com/UwUDev/balamod/blob/master/repos.index)
For the moment there's only one because I'm going to try and regulate malicious mods and the like, but there's bound to be many more in the future.
If you want to add your mod to an index, make a pull request to the index and add your mod to the bottom of the `mods.index` file.

The format is as follows:

```
mod_id|version|name|description|url
```

