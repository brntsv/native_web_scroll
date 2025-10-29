import 'package:flutter/widgets.dart';

/// {@template controller_host.mixin}
/// A reusable mixin that encapsulates owning or adopting a [ScrollController].
///
/// It supports:
/// - creating an internal controller with `initialScrollOffset` 
///   and `keepScrollOffset` via [initController] or [updateControllerSource],
/// - adopting an external controller (without taking ownership),
/// - switching between external and internal sources at runtime,
/// - notifying clients via `onCreated`, `onAttach`, and `onDetach` callbacks.
///
/// This mixin does not add any UI and can be used by multiple widget states
/// that need the same controller lifecycle semantics.
/// {@endtemplate}
mixin ControllerHost<T extends StatefulWidget> on State<T> {
  ScrollController? _owned;
  ScrollController? _external;

  /// The effective [ScrollController] (external if provided, otherwise owned).
  ScrollController get controller => (_external ?? _owned)!;

  /// Initializes the effective controller.
  ///
  /// - If [external] is non-null, it becomes the effective controller and the
  ///   mixin does not own/Dispose it.
  /// - If [external] is null, an internal [ScrollController] is created using
  ///   [initialScrollOffset] and [keepScrollOffset] and will be disposed in
  ///   [disposeController].
  ///
  /// If provided, [onCreated] is invoked with the effective controller.
  void initController({
    required ScrollController? external,
    required double initialScrollOffset,
    required bool keepScrollOffset,
    ValueChanged<ScrollController>? onCreated,
  }) {
    _external = external;
    if (external == null) {
      _owned = ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
      );
    }
    onCreated?.call(controller);
  }

  /// Updates the source of the controller when the external reference changes.
  ///
  /// - When switching from internal to external, the owned controller is
  ///   disposed.
  /// - When switching from external to internal, a new owned controller is
  ///   created using [initialScrollOffset] and [keepScrollOffset].
  ///
  /// Lifecycle hooks:
  /// - [onDetach] is called with the previous effective controller before
  ///   switching (useful to remove listeners).
  /// - [onAttach] is called with the new effective controller after switching
  ///   (useful to add listeners).
  /// - [onCreated] mirrors [initController]'s callback for convenience.
  void updateControllerSource({
    required ScrollController? oldExternal,
    required ScrollController? newExternal,
    required double initialScrollOffset,
    required bool keepScrollOffset,
    ValueChanged<ScrollController>? onCreated,
    void Function(ScrollController oldCtrl)? onDetach,
    void Function(ScrollController newCtrl)? onAttach,
  }) {
    if (oldExternal == newExternal) return;

    if (oldExternal == null && newExternal != null) {
      _owned?.dispose();
      _owned = null;
    }
    if (oldExternal != null && newExternal == null) {
      _owned = ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
      );
    }
    _external = newExternal;
    onCreated?.call(controller);
    if (onAttach != null) onAttach(controller);
    if (oldExternal != null && onDetach != null) onDetach(oldExternal);
  }

  /// Disposes the owned controller if any.
  @mustCallSuper
  void disposeController() {
    _owned?.dispose();
  }
}
