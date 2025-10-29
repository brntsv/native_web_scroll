/// Public entrypoint that conditionally exports the platform implementation.
///
/// - On Web, exports `src/web/native_web_scroll.dart`.
/// - On other platforms, exports `src/base/native_scroll_base.dart`.
library;

export 'src/base/native_scroll_base.dart'
    if (dart.library.html) 'src/web/native_web_scroll.dart';
export 'src/core/config.dart' show NativeScrollConfig;
export 'src/core/types.dart' show NativeScrollWidgetBuilder;
