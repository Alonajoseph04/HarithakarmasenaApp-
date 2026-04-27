/// Provides [webDownloadBytes] that works on both web and non-web builds.
/// On web  → triggers browser file download via dart:html Blob + Anchor.
/// On mobile/desktop → no-op (use Share instead).
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
