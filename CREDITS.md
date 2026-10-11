# Credits and licenses

- **Duocor3 — [Minepunk](https://github.com/Duocor3/minepunk)**, MIT, reviewed commit `8d6ca48d7f59d7814b2f68898ee1a7a8913ba3c8`: Minecraft passthrough bridge, native WebSocket/compositor base, shader foundation. Adapted for ULTRAKILL; original copyright notices retained in licenses/Minepunk-MIT.txt.
- **Rehan and universal-modder contributors — [universal-modder](https://github.com/rehan-remade/universal-modder)**, MIT: underlying Minecraft/rendering/loopback implementation and modding workflow used by Minepunk. Notice retained in licenses/universal-modder-MIT.txt.
- **alfr0762 / Ultracraft contributors — [Ultracraft](https://github.com/alfr0762/ultracraft)**, MIT, reviewed commit `f422bde55832038489eaa3ad721923a5f770db4d`: reference for installed native APIs and scale; its full plugin/assets are not bundled. This project is separate from that Ultracraft and from absolutelyaya's similarly named Minecraft recreation.
- **crosire and ReShade contributors — [ReShade](https://github.com/crosire/reshade)**: renderer add-on API. Included shader support headers originate from its shader ecosystem; ReShade.fxh is marked CC0-1.0; ReShadeUI.fxh attribution retained here. Runtime not bundled. ReShade license included in licenses/ReShade.txt.
- **Nathan Rajlich / TooTallNate and Java-WebSocket contributors — [Java-WebSocket](https://github.com/TooTallNate/Java-WebSocket)**, MIT, version 1.6.0: nested WebSocket library in the Minecraft mod. License included in licenses/Java-WebSocket.txt.
- **[Fabric](https://fabricmc.net)**, **[BepInEx](https://github.com/BepInEx/BepInEx)** and **[Harmony](https://github.com/pardeike/Harmony)**: mod loaders and managed patching. Downloaded from their official projects by setup or installed manually; not bundled in this package.
- **Hakita / Arsi Patala, ULTRAKILL contributors and New Blood Interactive**: ULTRAKILL and its native gameplay/art/audio, loaded from each player's purchased game.
- **Mojang Studios / Microsoft**: Minecraft Java and its assets, loaded from each player's legitimate installation.
- **OpenAI Codex**: almost all custom integration code and packaging were generated/adapted with AI, with human direction and playtesting. No AI-generated art or audio is included.

The custom integration and adapted MIT portions are under the included MIT license. Third-party components retain their licenses and copyrights. Game intellectual property is not covered by the mod's license or redistributed. References are credited separately from code actually bundled.

- **Eclipse Adoptium / OpenJDK contributors � [Eclipse Temurin](https://adoptium.net/)**: private Java 25 runtime downloaded by setup (GPLv2 with Classpath exception). Its archive retains vendor license notices; Java is not bundled here.
- Setup follows the official Fabric metadata/profile interface and ReShade 6.8.0 embedded ZIP layout; custom setup glue is AI-generated. See SETUP_REVIEW.md for pinned versions and review limits.
