# Mod Loading

Balamod can load mods and apis automatically or manually. When balamod mod-loader is installed(by running `balamod -a`), it will create a `mods` folder and `apis` folder on the AppData directory. 

The folder is vary depending on the platform.

- Windows: `C:\Users\<username>\AppData\Roaming\Balatro` aka `%APPDATA%\Balatro`
- macOS: `~/Library/Application Support/Balatro`
- Linux: `~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro`

## Automatic Mod Loading

If user downloads a mod from the in-game mod gallary, the mod will be automatically loaded by balamod. The mod will be placed in the `mods` folder.

## Manual Mod Loading

If user downloads a mod from the internet, the mod file should be placed in the `mods` folder. The mod will be loaded by balamod when the game is started.