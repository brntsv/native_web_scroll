import 'package:flutter/widgets.dart';

import '../core/config.dart';
import '../core/controller_host.dart';
import '../core/types.dart';

/// {@template native_scroll_base.class}
/// A platform-agnostic version of `NativeScrollBuilder`.
///
/// It builds the scrollable subtree via [builder] and ensures a usable
/// [ScrollController] is available:
/// - On Web, a specialized implementation synchronizes the controller with the
///   browser's native scrolling (see the web version).
/// - On all other platforms, the controller behaves like a standard Flutter
///   [ScrollController].
///
/// Usage:
/// - Provide your own [controller] to manage the lifecycle externally, or let
///   the widget create one and receive it via [onControllerCreated].
///
/// Initial position:
/// - If you DO NOT pass a controller, use [initialScrollOffset] and
///   [keepScrollOffset].
/// - If you pass a controller, set its initial offset yourself (e.g. using a
///   post-frame callback and `jumpTo`/`animateTo`).
/// {@endtemplate}
class NativeScrollBuilder extends StatefulWidget {
  /// {@macro native_scroll_base.class}
  const NativeScrollBuilder({
    required this.builder,
    this.controller,
    this.onControllerCreated,
    this.keepScrollOffset = true,
    this.initialScrollOffset = 0.0,
    this.config = const NativeScrollConfig(),
    super.key,
  });

  /// Builds the widget subtree that should be scrolled.
  ///
  /// Always wire the provided controller into your ScrollView
  /// (e.g. `CustomScrollView`, `ListView`, etc.).
  final NativeScrollWidgetBuilder builder;

  /// Optional externally managed [ScrollController].
  ///
  /// - When provided, you own its lifecycle (this widget will NOT dispose it).
  /// - When null, this widget creates and disposes an internal controller.
  /// - If provided, [initialScrollOffset] and [keepScrollOffset] are ignored.
  final ScrollController? controller;

  /// Invoked when the effective [ScrollController] 
  /// becomes available or changes.
  ///
  /// Called in `initState` and again if the effective controller source changes
  /// (e.g. switching between external and internal controllers).
  final ValueChanged<ScrollController>? onControllerCreated;

  /// Whether to keep the scroll offset when the widget is recreated.
  ///
  /// Used only when this widget creates the internal controller.
  final bool keepScrollOffset;

  /// The initial scroll offset used if this widget creates the controller.
  ///
  /// Ignored when an external [controller] is provided.
  final double initialScrollOffset;

  /// Additional configuration affecting behavior and presentation.
  final NativeScrollConfig config;

  @override
  State<NativeScrollBuilder> createState() => _NativeScrollBuilderState();
}

class _NativeScrollBuilderState extends State<NativeScrollBuilder>
    with ControllerHost<NativeScrollBuilder> {
  @override
  void initState() {
    super.initState();
    initController(
      external: widget.controller,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
      onCreated: widget.onControllerCreated,
    );
  }

  @override
  void didUpdateWidget(covariant NativeScrollBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateControllerSource(
      oldExternal: oldWidget.controller,
      newExternal: widget.controller,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
      onCreated: widget.onControllerCreated,
    );
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, controller);
}
