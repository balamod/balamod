# FAQ

<!-- toc -->

This is a list of frequently asked questions about balamod and Balatro.

~~~admonish info
If you have any questions that are not answered here, feel free to ask in the [Discord server](https://discord.gg/p7DeW7pSzA).
~~~

## What is balamod?

Balamod is a mod-loader and framework for the game Balatro. It allows users and modders to modify the game's code, mechanics and assets.

More information can be found on the [Balamod GitHub repository](https://github.com/UwUDev/balamod) and [Documentation](https://balamod.github.io/).

## How do I install balamod?

Please refer to the [Installation](installation.md) guide for detailed instructions on how to install balamod on your platform.

## In what language are mods/Balatro written in?

Balatro is written in Lua, and so are the mods and APIs.

## Where are my mods/apis stored?

Please refer to the [Mod Loading](mod-loading.md#mod-loading) guide for detailed information on where mods and APIs are stored on your platform.

## How do I create a mod?

In short, you need to create a new lua file in the mods folder, and insert your mod in the mods table.

For more detailed information, please refer to the [Modding Basics](modding-basics.md#creating-a-mod) guide.

## Help, on MacOS, Balatro crashes after installing balamod, and talks about "SSL"!

No worries, this is a known issue. You can fix it by installing OpenSSL using Homebrew.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew install openssl@3
```

## Is this compatible with Steammodded or other mod-loaders?

Yes and no. Balamod is a mod-loader, and as such, injects a lot of code into the game to make things just work. Installing other mod-loaders may work, or may not, but in any case, no support will be provided for such configurations. In theory, you should not need any other mod-loader, as balamod is designed to be as flexible and lightweight as possible, while providing all of the necessary tools for both modders and users. Other mod-loaders include the also popular Steammodded loader, which is not compatible with balamod at this time.