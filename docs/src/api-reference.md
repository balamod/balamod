# API Reference

<!-- toc -->

This topic provides a reference for the APIs that you can use to modify the game.

~~~admonish warning

This topic is still under development. The APIs listed here may not be complete or outdated!
Please refer to the [source code](https://github.com/UwUDev/balamod/tree/master/src/dependencies) for more information.

~~~

## GLOBALS

Global variables that can be accessed by the mod.

### `mods`

A table that contains all the mods that are loaded in `mods` folder.

### `repoMods`

A table that contains all the mods created by the community from internet.

Will be loaded at the start of the game. Index entry can be located at [Here](https://github.com/UwUDev/balamod/blob/master/repos.index).

## TRIGGER_FUNCTIONS

Functions that can be used by mods to trigger events.

### `on_enable()`

Function that will be called when the mod is enabled.

### `on_disable()`

Function that will be called when the mod is disabled.

### `on_pre_update()`

Function that will be called before the game update. If `true` is returned, it will cancel the update (ticking).

### `on_post_update()`

Function that will be called after the game update.

### `on_pre_render()`

Function that will be called just before rendering frame functions.

### `on_post_render()`

Function that will be called before rendering the frame itself.

### `on_key_pressed(key: string)`

Function that will be called when a key is pressed with the key name.

### `on_pre_load()`

Function that will be called before the game loads.

### `on_mouse_pressed(x: number, y: number, button: number)`

Function that will be called when a mouse button is pressed, with the x and y position, and the button.


## FUNCTIONS

Functions that can be used by mods.

### `sendDebugMessage(message: string)`

Send a debug message to the console. Need `dev_console` mod to be enabled.

### `inject(path, function_name, to_replace, replacement)`

Inject a function to another function. 

- `path` is the path to the function
- `function_name` is the name of the function
- `to_replace` is the function to replace
- `replacement` is the function to replace with.

### `getMod(mod_id: string)`