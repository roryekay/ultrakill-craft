# Privacy / package scope

This install-only package was built from an explicit file allowlist. It excludes development folders, source/decompiled game inspection, saves, options, launcher profiles, logs, screenshots, credentials, authentication data, build caches, debug symbols and original game assets/binaries. The native plugin was rebuilt without debug symbols and uses a configurable Minecraft directory instead of the developer's PC path.

Only an account's public GitHub handle is used in the repository URL. Commit author details use a neutral project name and GitHub noreply address. Original upstream copyright names in licenses are retained for attribution; those are not the developer's private contact information.

Checks inspect UTF-8 and UTF-16 strings in binary payloads and recursively unpack nested jars for private paths, personal email/name and credential markers. The compiled mod/renderer are custom derivatives, not copied proprietary game assemblies. These are bounded checks, not a guarantee against every possible issue.
