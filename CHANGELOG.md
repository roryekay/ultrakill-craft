# Changes

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
