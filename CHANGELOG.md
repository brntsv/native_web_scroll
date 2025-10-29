# Changelog

## 1.0.1
- Added web-native scrolling with a modular architecture:
  - Core: `ControllerHost` mixin, `NativeScrollConfig`, and types.
  - Base (non-web): uses a regular `ScrollController`.
  - Web: DOM-backed scroller via `HtmlElementView` + bidirectional sync.
- Improved sync and stability:
  - Keeps DOM and Flutter positions in sync without feedback loops.
  - Reacts to `ScrollMetrics` changes to reduce drift when content size updates.
- Non-breaking API: `NativeScrollBuilder` remains; `config` is optional with sensible defaults.
