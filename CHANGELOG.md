# Changelog

All notable changes to **CooldownCall** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-30

First release.

### Added
- Configurable **calls**: a cooldown tied to a specific caster chosen from your
  group/raid. Class and role are detected from the roster.
- Class-filtered cooldown catalog (hand-curated for TBC), plus a **custom**
  field to track any spell by name or id.
- Clickable **on-screen bars**: spell icon + cooldown name + caster name in
  class colour. Sorted by role, resizable (width/height), movable, lockable.
- Clicking a bar (or the *Call* button) sends a configurable **whisper** to the
  assigned caster. Tokens: `{spell}`, `{caster}`, `{target}`. Per-call throttle.
- **Dark / light theme**: dark = charcoal background with class-colour accent
  and names; light = class-colour background with charcoal border and text.
- Minimap button (LibDBIcon): left-click opens options, right-click toggles
  calls on/off.
- Slash commands `/cc`, `/cdcall`, `/cooldowncall`: open options, `on`/`off`,
  `lock`/`unlock`, `minimap`, `status`.
- Per-character settings via AceDB.

[0.1.0]: https://github.com/stroexd/CooldownCall/releases/tag/v0.1.0
