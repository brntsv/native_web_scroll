import 'package:flutter/widgets.dart';
import 'package:web/web.dart';

/// {@template dom_scroller.class}
/// A thin DOM adapter used by the web implementation of `NativeScrollBuilder`.
///
/// It owns an HTML `<div>` element that is configured to be scrollable and
/// exposes:
/// - a spacer element to simulate the scrollable extent (height/width),
/// - a callback for native scroll notifications,
/// - imperative methods to read/write scroll position and extents.
///
/// This class is framework-agnostic (no Flutter-specific state) and can be
/// unit-tested by asserting DOM side effects.
/// {@endtemplate}
class DomScroller {
  /// {@macro dom_scroller.class}
  ///
  /// - [axis]: scroll axis; determines which overflow and dimension to control.
  /// - [stopWheelPropagation]: whether to stop the wheel event from propagating
  ///   to parent platform views (helps avoid nested scroll conflicts).

  DomScroller({required Axis axis, required bool stopWheelPropagation})
      : _axis = axis {
    container = HTMLDivElement()
      ..style.overflowX = axis == Axis.horizontal ? 'scroll' : 'hidden'
      ..style.overflowY = axis == Axis.vertical ? 'scroll' : 'hidden'
      ..style.width = '100%'
      ..style.height = '100%';

    if (stopWheelPropagation) {
      container.onWheel.listen((e) => e.stopPropagation());
    }
    container.onScroll.listen((event) {
      final el = event.target! as HTMLDivElement;
      final px = _axis == Axis.horizontal ? el.scrollLeft : el.scrollTop;
      onScroll?.call(px);
      event.stopPropagation();
    });

    spacer = HTMLDivElement();
    container.append(spacer);
  }

  /// Scroll axis used for interpreting pixels and extents.
  final Axis _axis;

  /// The scrollable container `<div>` exposed as a platform view.
  late final HTMLDivElement container;

  /// The spacer `<div>` that defines the scroll extent by its size.
  late final HTMLDivElement spacer;

  /// Updates the spacer size to reflect [viewport] + [maxExtent].
  ///
  /// For vertical scrolling, sets `spacer.style.height`; for horizontal,
  /// sets `spacer.style.width`.
  void setExtent(double viewport, double maxExtent) {
    final size = viewport + maxExtent;
    if (_axis == Axis.vertical) {
      spacer.style.height = '${size}px';
    } else {
      spacer.style.width = '${size}px';
    }
  }

  /// Imperatively sets the native scroll position of the container.
  ///
  /// For vertical scrolling, writes to `scrollTop`; for horizontal,
  /// writes to `scrollLeft`.
  void setPixels(double pixels) {
    if (_axis == Axis.vertical) {
      container.scrollTop = pixels;
    } else {
      container.scrollLeft = pixels;
    }
  }

  /// Callback invoked when the user scrolls the native container.
  ///
  /// The argument is the current scroll offset in logical pixels along [_axis].
  void Function(double pixels)? onScroll;
}
