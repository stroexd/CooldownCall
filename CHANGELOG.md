# Changelog

All notable changes to **CooldownCall** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-31

### Changed
- Reworked the dark theme to match flat ElvUI / MerfinUI-style UIs: near-black
  background with a thin black border, class colour reserved for names instead
  of the border.
- All text now uses a bundled copy of **Expressway** (the "Merfin Font 1" font)
  with an outline, so the addon matches a MerfinUI setup without depending on it.

## [0.1.1] - 2026-05-30

### Fixed
- Player/cooldown dropdown entries showed an unthemed white background until
  the mouse hovered over them. They are now themed as soon as the list opens.

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
- `{spell}` is sent as a **clickable spell link**; the default message is
  **localized** (German on `deDE` clients, English otherwise).
- **Cooldown countdown**: when the assigned caster casts a tracked spell, the
  bar shows the remaining cooldown (from a hand-curated TBC duration table) and
  desaturates the icon until it is ready again. Combat-log driven, since another
  player's cooldowns can't be queried directly.
- **Dark / light theme**: dark = charcoal background with class-colour accent
  and names; light = class-colour background with charcoal border and text.
- Minimap button (LibDBIcon): left-click opens options, right-click toggles
  calls on/off.
- Slash commands `/cc`, `/cdcall`, `/cooldowncall`: open options, `on`/`off`,
  `lock`/`unlock`, `minimap`, `status`.
- Per-character settings via AceDB.

[0.2.0]: https://github.com/stroexd/CooldownCall/releases/tag/v0.2.0
[0.1.1]: https://github.com/stroexd/CooldownCall/releases/tag/v0.1.1
[0.1.0]: https://github.com/stroexd/CooldownCall/releases/tag/v0.1.0
