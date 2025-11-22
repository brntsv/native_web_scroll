import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '../core/config.dart';
import '../core/controller_host.dart';
import '../core/types.dart';
import 'dom_scroller.dart';

/// {@template native_web_scroll.class}
/// Web implementation of `NativeScrollBuilder` that synchronizes a Flutter
/// [ScrollController] with an underlying native DOM scroller.
///
/// How it works:
/// - Renders an HTML `<div>` (via a platform view) configured to scroll.
/// - Keeps the DOM position and the Flutter [ScrollController] in bidirectional
///   sync, avoiding feedback loops with flags.
/// - Re-applies the DOM position when Flutter scroll metrics change to prevent
///   drift when content sizes update.
///
/// Why:
/// - Preserves native scrolling behavior on the Web (momentum, overscroll,
///   accessibility), while still allowing programmatic control with the same
///   [ScrollController].
///
/// Usage:
/// - Prefer passing your own [controller] if you want to control scroll outside
///   the widget, or let the widget create one and receive it via
///   [onControllerCreated].
///
/// Initial position:
/// - If you DO NOT pass a controller, use [initialScrollOffset] and
///   [keepScrollOffset].
/// - If you pass a controller, set its initial offset yourself (e.g. using a
///   post-frame callback and `jumpTo`/`animateTo`).
/// {@endtemplate}
class NativeScrollBuilder extends StatefulWidget {
  /// {@macro native_web_scroll.class}
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

  /// Invoked when the effective [ScrollController] becomes
  /// available or changes.
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
  static int _globalId = 0;

  late final String _viewId;
  DomScroller? _dom;

  bool _syncFromFlutter = false;
  bool _syncFromNative = false;

  double? _lastExtentSize;

  ScrollController get _c => controller;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    initController(
      external: widget.controller,
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
      onCreated: widget.onControllerCreated,
    );

    _globalId++;
    _viewId = 'native-scroll-view-$_globalId';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) {
      final dom = DomScroller(
        axis: widget.config.axis,
        stopWheelPropagation: widget.config.stopWheelPropagation,
      )..onScroll = _onNativeScroll;

      _dom = dom;
      return dom.container;
    });

    _attachController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      _updateDomExtent();
      _syncDomToController();
      if (_c.hasClients) {
        _c.position.addListener(_updateDomExtent);
      }
    });
  }

  void _attachController() {
    _c.addListener(_onFlutterScroll);
  }

  void _detachController(ScrollController c) {
    c.removeListener(_onFlutterScroll);
    if (c.hasClients) {
      c.position.removeListener(_updateDomExtent);
    }
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
      onDetach: _detachController,
      onAttach: (_) {
        _attachController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _disposed) return;
          _updateDomExtent();
          _syncDomToController();
          if (_c.hasClients) {
            _c.position.addListener(_updateDomExtent);
          }
        });
      },
    );

    if (oldWidget.config != widget.config) {
      // Config changed: resync DOM with current metrics.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _disposed) return;
        _updateDomExtent();
        _syncDomToController();
      });
    }
  }

  void _onFlutterScroll() {
    if (_syncFromNative) return;
    if (!_c.hasClients) return;
    if (!mounted || _disposed) return;

    _updateDomExtent();
    _syncDomToController();
  }

  void _onNativeScroll(double pixels) {
    if (_syncFromFlutter) return;
    if (!_c.hasClients) return;
    if (!mounted || _disposed) return;

    _syncFromNative = true;
    try {
      _c.jumpTo(pixels);
    } finally {
      _syncFromNative = false;
    }
  }

  void _syncDomToController() {
    if (_dom == null) return;
    if (!_c.hasClients) return;
    if (!mounted || _disposed) return;

    _syncFromFlutter = true;
    try {
      _dom!.setPixels(_c.position.pixels);
    } finally {
      _syncFromFlutter = false;
    }
  }

  void _updateDomExtent() {
    if (_dom == null) return;
    if (!_c.hasClients) return;
    if (!mounted || _disposed) return;

    final viewport = _c.position.viewportDimension;
    final maxExtent = _c.position.maxScrollExtent;
    final size = viewport + maxExtent;

    if (_lastExtentSize != size) {
      _lastExtentSize = size;
      _dom!.setExtent(viewport, maxExtent);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _detachController(_c);
    disposeController();
    if (_dom != null) {
      _dom!.onScroll = null;
    }
    _dom = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context).copyWith(
      // Hide Flutter scrollbars only if requested via config.
      scrollbars: widget.config.hideFlutterScrollbars ? false : null,
    );

    return Stack(
      children: [
        HtmlElementView(viewType: _viewId),
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            if (!mounted || _disposed) return false;
            _updateDomExtent();
            _syncDomToController();
            return false;
          },
          child: ScrollConfiguration(
            behavior: behavior,
            child: widget.builder(context, _c),
          ),
        ),
      ],
    );
  }
}
