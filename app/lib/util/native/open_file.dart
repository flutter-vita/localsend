import 'package:common/model/file_type.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/util/native/android_saf.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/cannot_open_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

/// Opens the selected file which is stored on the device.
Future<void> openFile(
  BuildContext context,
  FileType fileType,
  String filePath, {
  void Function()? onDeleteTap,
}) async {
  if ((fileType == FileType.apk || filePath.toLowerCase().endsWith('.apk')) && checkPlatform([TargetPlatform.android])) {
    await Permission.requestInstallPackages.request();
  }

  if (filePath.startsWith('content://')) {
    await openContentUri(uri: filePath);
    return;
  }

  // OpenFilex *throws* on the Vita rather than returning a failed result: the
  // port reports TargetPlatform.linux, so open_filex takes its Linux branch and
  // DynamicLibrary.open('libc.so.6') to reach system(). There is no libc.so.6
  // here and no dlopen at all.
  //
  // The throw is what made this a dead tap. CannotOpenFileDialog already
  // exists, is translated, and names the file -- and it was never reached,
  // because the exception escaped before the result was ever looked at.
  ResultType resultType;
  try {
    final fileOpenResult = await OpenFilex.open(filePath);
    resultType = fileOpenResult.type;
  } catch (_) {
    resultType = ResultType.error;
  }
  if (resultType != ResultType.done && context.mounted) {
    await CannotOpenFileDialog.open(context, filePath, onDeleteTap);
  }
}
