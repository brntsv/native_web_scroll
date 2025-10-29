# native_web_scroll

Web‑native scrolling for Flutter Web with a single `ScrollController`.

- Syncs a Flutter `ScrollController` with a real DOM scroller behind your content.
- Preserves native browser behavior (momentum, accessibility, OS settings).
- Works everywhere: on Web it uses DOM; elsewhere it behaves like a normal controller.
- Also fixes scroll issues with `Draggable` in Telegram and other in‑app browsers by relying on native DOM scrolling and proper wheel event handling.

## Why use this
- You want native browser scrolling feel on Web.
- You need one `ScrollController` for both programmatic control and user scrolling.
- You hit odd scroll behavior (e.g. jitter with `Draggable` inside in‑app browsers).

## Platform support
- Web: native DOM scrolling via `HtmlElementView`.
- Android/iOS/macOS/Windows/Linux: falls back to a regular `ScrollController`.

## Quick start
```dart
import 'package:native_web_scroll/native_web_scroll.dart';

NativeScrollBuilder(
  builder: (context, scrollController) => ListView.builder(
    controller: scrollController,
    itemCount: 100,
    itemBuilder: (context, i) => Text('Item $i'),
  );
);
```

## How it works (Web)
- Registers a platform view and renders an HTML `<div>` with scroll overflow.
- Mirrors scroll position between the DOM and the Flutter `ScrollController` (both ways), avoiding feedback loops.
- Updates a spacer element to reflect `viewport + maxScrollExtent`, reducing drift when content size changes.

## Notes
- Flutter vs browser scrollbars: `hideFlutterScrollbars` hides only Flutter’s scrollbars. Native browser scrollbars are unaffected.
- In‑app browsers (e.g., Telegram): `stopWheelPropagation: true` helps avoid nested scroll conflicts and improves `Draggable` interaction.
- Dynamic layouts: for external initial offsets, set them in a post‑frame callback (`jumpTo/animateTo`) after the controller has clients.

## Troubleshooting
- Double scrollbars: set `hideFlutterScrollbars: true` (or hide native DOM scrollbars via CSS if you prefer Flutter’s).
- Jumps/drift after layout changes: ensure the controller has clients, then `jumpTo/animateTo` in a post‑frame callback.
- Nested scroll conflicts: keep `stopWheelPropagation: true` or tune per layout.
