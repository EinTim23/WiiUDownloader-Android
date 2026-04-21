import 'package:flutter/services.dart';

class IOSBookmark {
  static const _channel = MethodChannel('dev.eintim.wiiudownloader/bookmark');

  /// Opens the iOS folder picker, creates a security-scoped bookmark,
  /// and returns the folder path. Returns null if the user cancelled.
  static Future<String?> pickAndBookmarkFolder() async {
    return await _channel.invokeMethod<String>('pickAndBookmarkFolder');
  }

  /// Resolves the saved bookmark and returns its path.
  /// Throws if no bookmark exists or resolution fails.
  static Future<String> resolveBookmark() async {
    final path = await _channel.invokeMethod<String>('resolveBookmark');
    return path!;
  }

  /// Starts accessing the security-scoped resource. Must be called before
  /// performing any file I/O on the bookmarked path. Returns the path.
  static Future<String?> startAccessingBookmark() async {
    return await _channel.invokeMethod<String>('startAccessingBookmark');
  }

  /// Stops accessing the security-scoped resource.
  static Future<void> stopAccessingBookmark() async {
    await _channel.invokeMethod<void>('stopAccessingBookmark');
  }

  /// Returns true if a folder bookmark has been saved.
  static Future<bool> hasBookmark() async {
    final result = await _channel.invokeMethod<bool>('hasBookmark');
    return result ?? false;
  }
}
