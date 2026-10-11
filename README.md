# Ultrakill Craft

Real Minecraft Java blocks, items, hands and hearts over the real ULTRAKILL campaign. Windows x64, single-player prototype. You must own and install both games. This is a fan mod, unaffiliated with either game's developers.

**This mod is almost completely AI-generated.** OpenAI Codex wrote/adapted the integration, build glue and documentation under human direction. Human playtesting drove the fixes. It builds on credited open-source work; the Minecraft and ULTRAKILL graphics/audio come from your own games, not AI-generated or redistributed assets.

## Requirements

- ULTRAKILL for Windows x64, Steam installation. Tested with the locally installed October 2026 build; future patches may break native API hooks.
- Minecraft Java **26.3**, Java/JDK **25**, [Fabric Loader](https://fabricmc.net/use/installer/) **0.19.5**, [Fabric API](https://modrinth.com/mod/fabric-api) **0.161.0+26.3**.
- [BepInEx 5 x64](https://github.com/BepInEx/BepInEx/releases) **5.4.23.5** installed in ULTRAKILL; run the game once and close it.
- [ReShade](https://reshade.me/) **6.8.0**, the build with full add-on support, installed for ULTRAKILL's DirectX 11 renderer. The loader/runtime installers are downloaded separately from their official sources.
- Enough GPU/RAM for two games at once. Other mod combinations and multiplayer are untested.

## Easy setup (Windows x64)

1. Install ULTRAKILL through Steam and the official Minecraft Launcher. Open Minecraft Launcher once, sign in, then close the launcher and both games.
2. [Download this ZIP](https://github.com/roryekay/ultrakill-craft/archive/refs/heads/main.zip), **extract the whole ZIP**, and double-click **Setup.cmd**. Do not run it from inside the ZIP.
3. Setup finds ULTRAKILL automatically (or asks for its folder), downloads the pinned dependencies, verifies their hashes, installs the mod, creates an isolated **Ultrakill Craft** Minecraft profile, and adds a desktop shortcut. Allow time for the Java download.
4. Use the **Ultrakill Craft** desktop shortcut. In Minecraft Launcher select **Ultrakill Craft** and press **Play**. The launcher downloads Minecraft and Fabric libraries on this first launch. Keep Minecraft open and unminimized while ULTRAKILL runs.

No extra accounts, passwords or paid installer are needed. You must own the games. Authentication and the final Minecraft Play button stay in the official launcher. Setup does not install Steam or the games themselves. Java is private to this mod; your system Java/PATH stays unchanged. Setup.cmd uses PowerShell's process-only execution policy option, without changing Windows' saved policy.

Setup supports standard Steam libraries and both Windows Minecraft Launcher profile formats. It keeps existing profiles/worlds and saves replaced dependency files and launcher profiles under `%LOCALAPPDATA%\UltrakillCraft\backups`. The mod copier also backs up replaced mod/config files under `ULTRAKILL\UltrakillCraft-backups`. Rerunning setup repairs/reinstalls the same pinned versions. Existing ReShade settings and BepInEx loader files are replaced with backups; check compatibility if you already use other mods. Close other Java applications during setup as well.

If the game directory is protected, setup stops before installation. Run Setup.cmd as administrator **using the same Windows account**, or use a writable Steam library. Different administrator credentials would create the profile/shortcut for that account. Download failure or hash mismatch stops installation; retry later instead of skipping verification.

For a preview: `./Setup.ps1 -GameDir "<ULTRAKILL directory>" -WhatIf`. Advanced options include `-MinecraftDir`, `-LauncherDir`, `-SetupDir` and `-NoShortcut`. Download details and hashes are in `Setup.Dependencies.json`; review notes are in [SETUP_REVIEW.md](SETUP_REVIEW.md).

### Manual installation

Install the Requirements above, including Fabric API in an isolated Minecraft game directory. Create an official launcher profile for Fabric 26.3 with Java 25, `--enable-native-access=ALL-UNNAMED -Xms512M -Xmx3G` and a 1280×720 window. Close both games, then run `./Install.ps1 -GameDir "<ULTRAKILL directory>" -MinecraftDir "<isolated Minecraft directory>"`. `-WhatIf` previews the mod copies; Install.ps1 alone does not download dependencies or create profiles.

Alternatively copy `ULTRAKILL/` into the game directory and `Minecraft/mods/` into the isolated Minecraft `mods` folder. Set `[Paths] MinecraftInstanceDirectory = <isolated game directory>` in `BepInEx/config/local.minekill.overlay.cfg`. Never add a duplicate Minekill.dll directly under plugins.

## Controls and behavior

- **F7** toggles Minecraft items/native weapons; F8 is the native console.
- Hotbar bindings follow that Minecraft instance's saved options, including side mouse buttons. Mouse wheel changes slots; F swaps hands; F5 cycles camera perspectives. Movement remains native ULTRAKILL.
- Sword/empty-hand clicks attempt a 120 ms native parry independently of the sword damage cooldown. Holding left click keeps checking parryable incoming attacks near your aim while a sword/empty hand is selected; release it to stop the assist. The assist expires if Minecraft item state goes stale (250 ms), and does not add automatic sword damage. Projectile parry detection is slightly wider without changing visuals or damage collision. Native blue/unparryable attacks retain their rules. The native white parry flash is carried through the final Minecraft compositor, including hitstop; ULTRAKILL's parry-flash setting is respected. Eligible enemy melee parries, including Gabriel's, use native punch handling.
- Native damage appears in regular Minecraft hearts. Actual Minecraft healing (regeneration, potions, food healing) restores native HP through its native hard-damage cap. Golden-apple regeneration heals; absorption is not mapped to extra native HP.
- Creative mode grants invincibility; a raised shield blocks native damage; each armor piece reduces damage 10%, any material, max 40%.
- Blocks, swords, arrows, crossbows, pearls, TNT and fireworks bridge into native gameplay. Boss bars stay visible. Overlay inventory was removed after an unsuccessful test; use Minecraft's own window to manage equipment.

## Prototype limits

Campaign combat, hotbar binding transfer, shield/armor protection, rendering, third person and projectile parry fixtures have been tested during development. Live Sandbox checks confirmed native projectile reflection (including an off-center shot), visible full-screen white flash and its return to gameplay, rejection of an explicitly unparryable projectile, all 12 rapid-click relay attempts, and a native Gabriel melee parry when his parryable flag is active. Real mouse clicks also reflected incoming Stray projectiles. A missing initialized Feedbacker was fixed without changing the saved arm loadout. Held assist skips already reflected friendly shots. Every Gabriel attack and sustained held-click behavior are not independently verified. This is a prototype, not a claim of exhaustive testing.

Each native scene currently starts Minecraft in creative mode. For a vulnerable fight, switch to the Minecraft window and run `/gamemode survival`, then return to ULTRAKILL. The current bootstrap also restores starter hotbar items whenever Minecraft starts; arrange desired gear after launching. Both games must stay running; performance and input timing depend on both clients.

## Uninstall / troubleshooting

Close both games. Remove only `BepInEx/plugins/Minekill/Minekill.dll`, `MinekillRenderer.dll`, `reshade-shaders/Shaders/MCPassthrough.fx`, `UltrakillCraftPreset.ini` and the isolated mod jar. Restore ReShade.ini/config files from the installer backup if applicable. Leave shared BepInEx/ReShade/Fabric dependencies alone if other mods use them. Keep your isolated world if you want to retain builds.

No overlay: confirm Minecraft is in the world, unminimized, with matching Fabric/API and Java 25; confirm full-add-on ReShade loaded and MCPassthrough is enabled. Check ULTRAKILL's BepInEx/LogOutput.log and ReShade.log, and the isolated Minecraft logs/latest.log. Hotbar mismatch: check MinecraftInstanceDirectory and save Minecraft keybind changes (reload takes about 2 seconds). Only run one pair; the link uses loopback port 25598 and shared memory Local\MinekillFrame.

See [CREDITS.md](CREDITS.md) and `licenses/` for attribution. No game executables, game assets, decompiled game code, saves, personal settings, credentials or personal logs are included. Binary-only install package, as requested; source tooling/development history is omitted.
