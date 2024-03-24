# Modding Basics

This guide will cover the basics of modding in the game.

## Balamod Structure

There are two main folders that you need to know when you are modding the game:

- `apis`: This folder contains the APIs created by mod author. APIs will be loaded at the start of the game. It is fine to ignore this folder if you are not creating an API.
- `mods`: This folder contains main functionality of the mod. Mods will be loaded **after** APIs.

The mod file contains mod entry should be placed in the `mods` folder. Balatro will load the mod when the game is started.

## Modding API

Balamod provides a set of APIs that you can use to modify the game. And there are many helpful functions privided by the Balatro game engine.

The APIs are written in Lua, and you can find part of them in the [API Reference](./api-reference.md) topic.

## Creating a Mod

~~~admonish info
Please refer to the [Community Mods](./community-mods.md) topic for the list of mods created by the community.

That would be a good starting point to learn how to create a mod.
~~~

To create a mod, you need to create a new Lua file in the `mods` folder. The file should contain a table with the following fields:

- `mod_id`(string): A unique identifier for the mod.
- `name`(string): The displayed name of the mod.
- `version`(string): The version of the mod.
- `author`(string): The authors of the mod.
- `description`(arrays of string): The description of the mod.
- `enabled`(boolean): Whether the mod is enabled or not.
- `TRIGGER_FUNCTIONS`(function): The function that will be called when certain events are triggered.

~~~admonish info
The available `TRIGGER_FUNCTIONS` are listed in the [API Reference](./api-reference.md#trigger_functions) topic.
~~~

Here is an example of a mod file:

```lua
local my_mod = {
    mod_id = "my_mod",
    name = "My Mod",
    version = "1.0",
    author = "Awesome Me",
    description = {
        "This is a mod that does something.",
        "It is very cool."
    },
    enabled = true,
    on_enable = function()
        sendDebugMessage("My Mod is enabled!")
    end,
}
table.insert(mods, my_mod)
```

Rename the file to `my_mod.lua` and place it in the `mods` folder. The mod will be loaded when the game is started.

