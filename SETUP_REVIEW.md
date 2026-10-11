# Setup dependency review

Checked 2026-10-10. No suitable popular complete installer for this exact two-game bridge was found. Setup uses the existing vendor runtimes and official metadata, with custom PowerShell glue for this mod's files/profile. Dependency executables are not bundled in the repository. Exact URLs and hashes are pinned in `Setup.Dependencies.json`.

| Component | Reviewed version/interface | Role and license |
| --- | --- | --- |
| [BepInEx](https://github.com/BepInEx/BepInEx/tree/v5.4.23.5) (8,809 stars) | 5.4.23.5, official Windows x64 release archive and GitHub release SHA256 | Unity loader, LGPL-2.1; archive retains its notices. Existing project dependency. |
| [ReShade](https://github.com/crosire/reshade/tree/v6.8.0) (5,587 stars) | 6.8.0 full-add-on setup from reshade.me; x64 DLL extracted from its attached ZIP | DirectX 11 compositor runtime, BSD-3-Clause. License already included. |
| [Fabric installer](https://github.com/FabricMC/fabric-installer/tree/6e7d1acd6a951a19a323060ac955f5e7bc51e3ce) (112 stars) | Official ClientInstaller/ProfileInstaller behavior and build.gradle; loader 0.19.5 for Minecraft 26.3 | Official metadata/profile contract. Apache-2.0 reference; installer code/binary is not copied. Lower-star exception because this is Fabric's own supported installation interface. |
| [Fabric API](https://modrinth.com/mod/fabric-api/version/bNnaTiuM) | 0.161.0+26.3, official project on Modrinth, published SHA512 | Required Minecraft mod API; downloaded unchanged. |
| [Eclipse Temurin](https://github.com/adoptium/temurin25-binaries/releases/tag/jdk-25.0.4.1%2B1) (59 stars for its binary repository) | Java 25.0.4.1+1, official Windows x64 ZIP and vendor SHA256 | Private Java runtime; GPLv2 with Classpath exception, notices retained. Lower-star exception because this is the vendor's release repository, not a third-party installer. |

Review covered ReShade's installation/extraction path, solution/build documentation and license; Fabric's profile and metadata paths, Gradle dependencies/build configuration and license; BepInEx's existing loader dependency, release metadata, README dependencies and project manifest; Java/Fabric API release provenance and published hashes. ReShade's locally pinned download hash detects later changes, but is not an independently published vendor signature. Fabric profile JSON is likewise pinned to the reviewed HTTPS response. Setup downloads and checks all archives before copying installed files; archives are checked for paths escaping their extraction directory. It never runs ReShade's setup executable or third-party installation scripts.

No concerning behavior was found in those reviewed setup paths. This is a limited integration review, not a full audit of every loader, JVM or transitive dependency. Existing game/mod compatibility and a completely fresh PC still require real-world testing.

Setup only reads launcher profile configuration, not Minecraft account/credential files. It preserves unrelated profile data and backs up replaced files. The games and official launcher must already be installed and signed in. The launcher handles licensed Minecraft and library downloads on Play. No system Java/PATH changes, telemetry, credentials, proprietary game files or source/development logs are included.

## Verification

Windows PowerShell 5.1 fixture tests used the real hash-verified dependency archives. They covered clean installation, a second installation, both launcher profile formats, retaining unrelated profiles/settings and a world sentinel, retaining unrelated mod config, replaced-file backups, shortcut creation/arguments, a no-write WhatIf preview, ZIP traversal rejection before extraction, and corrupt-download rejection without replacing a good cache file. Steam auto-detection was checked against an installed Steam library. No games were launched by these installer tests and the existing player installation was not modified. A fresh-machine sign-in/Play sequence was not tested.
