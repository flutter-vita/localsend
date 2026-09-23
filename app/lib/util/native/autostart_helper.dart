// The Windows registry branches are stubbed for the Vita build.
//
// win32_registry 2.x renamed the whole API (Registry.openPath, RegistryHive,
// AccessRights, RegistryValue), and the only reason this file is being compiled
// at all is that Dart compiles every branch of a switch on defaultTargetPlatform
// whether or not the platform can occur. Porting Windows autostart to run on a
// PS Vita is not a thing; returning false is.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

const startHiddenFlag = '--hidden';

final _logger = Logger('AutoStartHelper');

Future<bool> enableAutoStart({required bool startHidden}) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        String contents = '''
[Desktop Entry]
Type=Application
Name=${packageInfo.appName}
Comment=${packageInfo.appName} startup script
Exec=${Platform.resolvedExecutable}${startHidden ? ' $startHiddenFlag' : ''}
StartupNotify=false
Terminal=false
''';
        final file = File(_getLinuxFilePath(packageInfo.packageName));
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsStringSync(contents);
        return true;
      case TargetPlatform.macOS:
        final file = File(_getMacOSFilePath(packageInfo.packageName));
        file.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${packageInfo.packageName}</string>
  <key>AssociatedBundleIdentifiers</key>
  <string>${packageInfo.packageName}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${Platform.executable}</string>
    ${startHidden ? '<string>$startHiddenFlag</string>' : ''}
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>StandardErrorPath</key>
  <string>/dev/null</string>
  <key>StandardOutPath</key>
  <string>/dev/null</string>
</dict>
</plist>
        ''');
        return true;
      case TargetPlatform.windows:
        return false;
      default:
        return false;
    }
  } catch (e) {
    _logger.warning('Could enable auto start', e);
    return false;
  }
}

Future<bool> disableAutoStart() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        File(_getLinuxFilePath(packageInfo.packageName)).deleteSync();
        break;
      case TargetPlatform.macOS:
        File(_getMacOSFilePath(packageInfo.packageName)).deleteSync();
        break;
      case TargetPlatform.windows:
        break;
      default:
        break;
    }
    return true;
  } catch (e) {
    _logger.warning('Could disable auto start', e);
    return false;
  }
}

Future<bool> isAutoStartEnabled() async {
  final packageInfo = await PackageInfo.fromPlatform();
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
      return File(_getLinuxFilePath(packageInfo.packageName)).existsSync();
    case TargetPlatform.macOS:
      return File(_getMacOSFilePath(packageInfo.packageName)).existsSync();
    case TargetPlatform.windows:
      return false;
    default:
      return false;
  }
}

Future<bool> isAutoStartHidden() async {
  final packageInfo = await PackageInfo.fromPlatform();
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
      final file = File(_getLinuxFilePath(packageInfo.packageName));
      if (!file.existsSync()) {
        return false;
      }
      return file.readAsStringSync().contains(startHiddenFlag);
    case TargetPlatform.macOS:
      final file = File(_getMacOSFilePath(packageInfo.packageName));
      if (!file.existsSync()) {
        return false;
      }
      return file.readAsStringSync().contains(startHiddenFlag);
    case TargetPlatform.windows:
      return false;
    default:
      return false;
  }
}



String _getLinuxFilePath(String appName) {
  return '${Platform.environment['HOME']}/.config/autostart/$appName.desktop';
}

String _getMacOSFilePath(String appName) {
  return '${Platform.environment['HOME']}/Library/LaunchAgents/$appName.plist';
}
