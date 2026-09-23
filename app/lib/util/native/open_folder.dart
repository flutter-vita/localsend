import 'package:localsend_app/util/native/android_saf.dart';
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';

final _logger = Logger('OpenFolder');

/// Opens the selected file which is stored on the device.
Future<void> openFolder(String path) async {
  if (path.startsWith('content://')) {
    await openContentUri(uri: path);
    return;
  }

  if (!path.endsWith('/')) {
    path = '$path/';
  }
  // Throws on the Vita rather than returning a failure -- see the note in
  // open_file.dart. Swallowed here because the caller has no failure path to
  // take: there is nothing on this console that shows a folder in place.
  try {
    final result = await OpenFilex.open(path);
    _logger.info('Open folder result: ${result.message}, path: $path');
  } catch (e) {
    _logger.info('Open folder threw: $e, path: $path');
  }
}
