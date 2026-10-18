# Changes

## Windows setup release - 2026-10-17

- Publish an extracted-ZIP/double-click Setup.cmd Windows package; no developer tools required.
- Fix issue #2's fabric.json verification failure by bundling the reviewed Fabric profile instead of hashing a changing live response. Keep dependency/package verification enabled.
- Include verified official Minecraft 26.3 version metadata for fresh launcher installations.
- Install the private Java runtime and Minecraft instance under Games, outside Microsoft Store launcher's AppData virtualization. Refuse a different existing instance folder before making changes so worlds are not silently left behind.
- Forward Setup.cmd arguments and return setup failures correctly. Fix Windows PowerShell 5.1 WhatIf package verification and share verification with manual Install.ps1.
- Add repeatable isolated Windows installer checks in Test-Setup.ps1.

## Parry assist / flash follow-up

- Preserve the real native parry flash over Minecraft items, hearts and blocks during hitstop, respecting the native flash preference.
- Hold left click with a sword/empty hand to keep checking nearby aimed-at attacks with native eligibility rules. No auto sword damage or blue-attack bypass.
- Fresh Minecraft item eligibility is required and expires after 250 ms.
- C#, C++ and Java builds passed; shader compiled in live ReShade. Full gameplay acceptance is still pending.

## Feedbacker initialization fix

- Fix all parry attempts silently failing when no initialized native Feedbacker exists. Initialize a separate native arm from the installed game without modifying saved loadout or bundling game assets.
- Skip already reflected friendly projectiles during held assist.
- Sandbox: projectile reflection, off-center reflection, native white flash visibly present and cleared, explicitly unparryable projectile rejected, 12/12 rapid-click relay attempts, Gabriel native melee parry with his eligibility flag enabled and rejection with it disabled. Real mouse clicks reflected Stray projectiles.
- Full campaign attack coverage and sustained held-input acceptance remain unverified.

## Easy setup — 2026-10-10

- Add Setup.cmd for automatic verified dependency downloads, isolated Minecraft profile and desktop shortcut.
- Support both Windows launcher profile formats; preserve existing profiles, worlds and unrelated mod configuration.
- Back up replaced dependency/profile files and document manual installation and review limits.
