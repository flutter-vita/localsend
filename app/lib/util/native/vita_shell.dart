import 'package:flutter/services.dart';

/// Handing a folder to VitaShell, the console's file manager.
///
/// The Vita has no file associations and no way to show a folder next to a
/// running app, so "open this file" and "show it in a folder" have no native
/// answer here. VitaShell is the closest thing, and it is a separate
/// application: opening it **closes this one**, because the console runs one
/// app at a time. Every caller has to say so before it happens.
///
/// There is no deep link. VitaShell's `main()` takes argc and argv and ignores
/// both, and it registers no URI scheme. What it does do, in `browser.c`, is
/// read `ux0:VitaShell/internal/lastdir.txt` on startup and navigate there, so
/// the embedder writes that file and then launches it. Two consequences worth
/// knowing at this level:
///
///   * It has to be a **directory**. VitaShell validates with
///     `checkFolderExist`, so pointing at the file itself lands the user in
///     `home` instead. [openFolderOf] takes a file path and passes its parent.
///   * If the user holds L while it starts, VitaShell ignores its own config
///     and opens at `home` regardless. Nothing can be done about that here.
class VitaShell {
  VitaShell._();

  /// JSON rather than the standard codec, matching `vita/browser`: the
  /// embedder parses this by hand in C.
  static const _channel = MethodChannel('vita/shell', JSONMethodCodec());

  /// Whether VitaShell is installed on this console.
  ///
  /// It is homebrew, not system software, so plenty of consoles do not have
  /// it. Callers must hide the button rather than offer one that does nothing.
  static Future<bool> available() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Running on a build whose embedder predates the channel.
      return false;
    }
  }

  /// Open VitaShell in the folder holding [filePath]. **Closes this app.**
  ///
  /// Returns false if it could not be launched. It does not return at all when
  /// it succeeds.
  static Future<bool> openFolderOf(String filePath) {
    final i = filePath.lastIndexOf('/');
    final folder = i <= 0 ? filePath : filePath.substring(0, i);
    return openFolder(folder);
  }

  /// Open VitaShell at [folder]. **Closes this app.**
  static Future<bool> openFolder(String folder) async {
    try {
      return await _channel.invokeMethod<bool>('openFolder', {'path': folder}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
