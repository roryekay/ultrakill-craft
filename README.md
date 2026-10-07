# Ultrakill Craft

Real Minecraft Java blocks, items, hands and hearts over the real ULTRAKILL campaign. Windows x64, single-player prototype. You must own and install both games. This is a fan mod, unaffiliated with either game's developers.

**This mod is almost completely AI-generated.** OpenAI Codex wrote/adapted the integration, build glue and documentation under human direction. Human playtesting drove the fixes. It builds on credited open-source work; the Minecraft and ULTRAKILL graphics/audio come from your own games, not AI-generated or redistributed assets.

## Requirements

- ULTRAKILL for Windows x64, Steam installation. Tested with the locally installed October 2026 build; future patches may break native API hooks.
- Minecraft Java **26.3**, Java/JDK **25**, [Fabric Loader](https://fabricmc.net/use/installer/) **0.19.5**, [Fabric API](https://modrinth.com/mod/fabric-api) **0.161.0+26.3**.
- [BepInEx 5 x64](https://github.com/BepInEx/BepInEx/releases) (5.4.x) installed in ULTRAKILL; run the game once and close it.
- [ReShade](https://reshade.me/) **6.8.0**, the build with full add-on support, installed for ULTRAKILL's DirectX 11 renderer. The loader/runtime installers are downloaded separately from their official sources.
- Enough GPU/RAM for two games at once. Other mod combinations and multiplayer are untested.

## Install

1. Download this repository as ZIP (Code → Download ZIP) and extract it. While private, GitHub access is required. Check `SHA256SUMS.txt` if verifying individual files.
2. Install the requirements above. Make a separate official Minecraft Launcher installation named **Ultrakill Craft**, using Fabric 26.3 and an empty game directory. The recommended directory is `%LOCALAPPDATA%\UltrakillCraft\minecraft-instance`. Use Java 25 with `--enable-native-access=ALL-UNNAMED -Xms512M -Xmx3G` and a 1280×720 window.
3. Put the matching Fabric API jar in that Minecraft directory's `mods` folder. Close both games.
4. Run `Install.ps1` in PowerShell with your actual paths: `./Install.ps1 -GameDir "<ULTRAKILL directory>" -MinecraftDir "<isolated Minecraft game directory>"`. `-WhatIf` previews the copies. The script verifies package hashes, backs up replaced files, copies only this mod, and writes its Minecraft-directory setting. It does not download dependencies, sign in, or change launcher profiles.
5. Start that Minecraft profile. It opens a dedicated void world automatically. Keep its window open and unminimized. Start ULTRAKILL and select a level. The overlay connects automatically.

Manual alternative: copy the contents of `ULTRAKILL/` into the ULTRAKILL game directory and `Minecraft/mods/` into the isolated Minecraft `mods` folder. Back up existing ReShade settings first. Set `[Paths] MinecraftInstanceDirectory = <isolated game directory>` in `BepInEx/config/local.minekill.overlay.cfg` if you used a different directory. Never add a duplicate Minekill.dll directly under plugins.

## Controls and behavior

- **F7** toggles Minecraft items/native weapons; F8 is the native console.
- Hotbar bindings follow that Minecraft instance's saved options, including side mouse buttons. Mouse wheel changes slots; F swaps hands; F5 cycles camera perspectives. Movement remains native ULTRAKILL.
- Sword/empty-hand clicks attempt a 120 ms native parry independently of the sword damage cooldown. Holding left click keeps checking parryable incoming attacks near your aim while a sword/empty hand is selected; release it to stop the assist. The assist expires if Minecraft item state goes stale (250 ms), and does not add automatic sword damage. Projectile parry detection is slightly wider without changing visuals or damage collision. Native blue/unparryable attacks retain their rules. The native white parry flash is carried through the final Minecraft compositor, including hitstop; ULTRAKILL's parry-flash setting is respected. Eligible enemy melee parries, including Gabriel's, use native punch handling.
- Native damage appears in regular Minecraft hearts. Actual Minecraft healing (regeneration, potions, food healing) restores native HP through its native hard-damage cap. Golden-apple regeneration heals; absorption is not mapped to extra native HP.
- Creative mode grants invincibility; a raised shield blocks native damage; each armor piece reduces damage 10%, any material, max 40%.
- Blocks, swords, arrows, crossbows, pearls, TNT and fireworks bridge into native gameplay. Boss bars stay visible. Overlay inventory was removed after an unsuccessful test; use Minecraft's own window to manage equipment.

## Prototype limits

Campaign combat, hotbar binding transfer, shield/armor protection, rendering, third person and projectile parry fixtures have been tested during development. Live Sandbox checks confirmed native projectile reflection (including an off-center shot), visible full-screen white flash and its return to gameplay, rejection of an explicitly unparryable projectile, all 12 rapid-click relay attempts, and a native Gabriel melee parry when his parryable flag is active. Real mouse clicks also reflected incoming Stray projectiles. A missing initialized Feedbacker was fixed without changing the saved arm loadout. Held assist skips already reflected friendly shots. Every Gabriel attack and sustained held-click behavior are not independently verified. This private upload is a review candidate, not a claim of exhaustive testing.

Each native scene currently starts Minecraft in creative mode. For a vulnerable fight, switch to the Minecraft window and run `/gamemode survival`, then return to ULTRAKILL. The current bootstrap also restores starter hotbar items whenever Minecraft starts; arrange desired gear after launching. Both games must stay running; performance and input timing depend on both clients.

## Uninstall / troubleshooting

Close both games. Remove only `BepInEx/plugins/Minekill/Minekill.dll`, `MinekillRenderer.dll`, `reshade-shaders/Shaders/MCPassthrough.fx`, `UltrakillCraftPreset.ini` and the isolated mod jar. Restore ReShade.ini/config files from the installer backup if applicable. Leave shared BepInEx/ReShade/Fabric dependencies alone if other mods use them. Keep your isolated world if you want to retain builds.

No overlay: confirm Minecraft is in the world, unminimized, with matching Fabric/API and Java 25; confirm full-add-on ReShade loaded and MCPassthrough is enabled. Check ULTRAKILL's BepInEx/LogOutput.log and ReShade.log, and the isolated Minecraft logs/latest.log. Hotbar mismatch: check MinecraftInstanceDirectory and save Minecraft keybind changes (reload takes about 2 seconds). Only run one pair; the link uses loopback port 25598 and shared memory Local\MinekillFrame.

See [CREDITS.md](CREDITS.md) and `licenses/` for attribution. No game executables, game assets, decompiled game code, saves, personal settings, credentials or personal logs are included. Binary-only install package, as requested; source tooling/development history is omitted.
